# StoreKit 1 to StoreKit 2 Migration

StoreKit 2 (iOS 15+) replaces the original StoreKit API with a modern, async/await-based API for in-app purchases and subscriptions. Transactions are signed with JWS (JSON Web Signature) for simpler verification, and the entire flow is dramatically simpler than the delegate-based StoreKit 1 approach.

## When to Migrate

- You want async/await instead of delegate callbacks for purchase flows.
- You need `Transaction.currentEntitlements` for simpler entitlement checking.
- You want JWS-based transaction verification (local or server-side) instead of receipt parsing.
- You are building new subscription features (offer codes, win-back offers, subscription status).
- You want StoreKit Testing in Xcode for local development without sandbox accounts.
- Your minimum deployment target is iOS 15 or later.

## When NOT to Migrate

- You need to support iOS 14 or earlier. StoreKit 2 requires iOS 15+.
- Server-side receipt validation with `/verifyReceipt` is deeply integrated and working. Note: Apple deprecated `/verifyReceipt` and recommends migrating to App Store Server API, but it still works.
- Custom receipt validation logic (parsing PKCS#7, ASN.1) that is too complex to rewrite on a tight timeline.
- You are using a third-party SDK (e.g., RevenueCat) that handles StoreKit internally. Check if the SDK already supports StoreKit 2 before migrating yourself.

## Concept Mapping

| StoreKit 1 | StoreKit 2 | Notes |
|------------|------------|-------|
| `SKProduct` | `Product` | Loaded via static method |
| `SKProductsRequest` | `Product.products(for:)` | Async, no delegate |
| `SKPayment` + `SKPaymentQueue.add()` | `product.purchase()` | Async, returns result |
| `SKPaymentTransaction` | `Transaction` | JWS-signed |
| `SKPaymentTransactionObserver` | `Transaction.updates` | AsyncSequence |
| `SKPaymentQueue.restoreCompletedTransactions()` | `Transaction.currentEntitlements` or `AppStore.sync()` | No restore button needed |
| `SKReceiptRefreshRequest` | `AppStore.sync()` | Syncs with App Store |
| `appStoreReceiptURL` (receipt file) | `Transaction.currentEntitlements` | JWS per transaction |
| `SKStorefront` | `Storefront.current` | Async property |
| `SKPaymentQueue.canMakePayments()` | `AppStore.canMakePayments` | Same concept |
| `SKPaymentTransactionState` | `Product.PurchaseResult` + `Transaction.VerificationResult` | Separated into purchase result and verification |
| `transaction.finishTransaction()` | `transaction.finish()` | Still required |

## Loading Products

### Before (StoreKit 1)

```swift
class Store: NSObject, SKProductsRequestDelegate {
    var products: [SKProduct] = []

    func loadProducts() {
        let request = SKProductsRequest(productIdentifiers: ["com.app.premium", "com.app.monthly"])
        request.delegate = self
        request.start()
    }

    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        products = response.products
        // Update UI on main thread
    }

    func request(_ request: SKRequest, didFailWithError error: Error) {
        // Handle error
    }
}
```

### After (StoreKit 2)

```swift
class Store {
    var products: [Product] = []

    func loadProducts() async throws {
        products = try await Product.products(for: ["com.app.premium", "com.app.monthly"])
    }
}
```

## Purchasing

### Before (StoreKit 1)

```swift
class Store: NSObject, SKPaymentTransactionObserver {
    func purchase(_ product: SKProduct) {
        let payment = SKPayment(product: product)
        SKPaymentQueue.default().add(payment)
    }

    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            switch transaction.transactionState {
            case .purchased:
                // Validate receipt, unlock content
                queue.finishTransaction(transaction)
            case .failed:
                if let error = transaction.error as? SKError, error.code != .paymentCancelled {
                    // Show error
                }
                queue.finishTransaction(transaction)
            case .restored:
                // Unlock content
                queue.finishTransaction(transaction)
            case .deferred:
                // Ask-to-Buy: waiting for parent approval
                break
            case .purchasing:
                break
            @unknown default:
                break
            }
        }
    }
}
```

### After (StoreKit 2)

```swift
class Store {
    func purchase(_ product: Product) async throws {
        let result = try await product.purchase()

        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            // Unlock content
            await transaction.finish()

        case .userCancelled:
            break

        case .pending:
            // Ask-to-Buy or SCA: waiting for external action
            break

        @unknown default:
            break
        }
    }

    func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .verified(let value):
            return value
        case .unverified(_, let error):
            throw error
        }
    }
}
```

## Transaction Listener

### StoreKit 1

```swift
// AppDelegate.swift
func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: ...) -> Bool {
    SKPaymentQueue.default().add(transactionObserver)
    return true
}

func applicationWillTerminate(_ application: UIApplication) {
    SKPaymentQueue.default().remove(transactionObserver)
}
```

### StoreKit 2

The transaction listener must start at app launch to handle transactions that complete outside your app (renewals, Ask-to-Buy approvals, refunds, revocations).

```swift
@main
struct MyApp: App {
    @State private var store = Store()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(store)
                .task {
                    await store.listenForTransactions()
                }
        }
    }
}

@Observable
class Store {
    private var updateListenerTask: Task<Void, Never>?

    func listenForTransactions() async {
        // Listen for transactions that happen outside the app
        for await result in Transaction.updates {
            do {
                let transaction = try checkVerified(result)
                await updateEntitlements(for: transaction)
                await transaction.finish()
            } catch {
                // Transaction failed verification
            }
        }
    }
}
```

Critical rules:
- Start listening at app launch, not just when the purchase screen appears.
- Handle `Transaction.updates` for the entire app lifetime.
- Always call `transaction.finish()` for every verified transaction.
- During migration, this listener handles transactions from both StoreKit 1 and StoreKit 2.

## Checking Entitlements

### Before (StoreKit 1 -- Receipt Validation)

```swift
// Local receipt validation
func validateReceipt() throws -> [String] {
    guard let receiptURL = Bundle.main.appStoreReceiptURL,
          let receiptData = try? Data(contentsOf: receiptURL) else {
        throw ReceiptError.noReceipt
    }

    // Send to your server
    let encodedReceipt = receiptData.base64EncodedString()
    // Server calls Apple's /verifyReceipt endpoint
    // Server returns parsed receipt with active purchases
    // Parse the response to determine entitlements
}
```

### After (StoreKit 2 -- Transaction.currentEntitlements)

```swift
func updateEntitlements() async {
    var activeSubscriptions: Set<String> = []
    var purchasedProducts: Set<String> = []

    for await result in Transaction.currentEntitlements {
        guard case .verified(let transaction) = result else { continue }

        switch transaction.productType {
        case .autoRenewable:
            activeSubscriptions.insert(transaction.productID)
        case .nonConsumable:
            purchasedProducts.insert(transaction.productID)
        default:
            break
        }
    }

    // Update app state
    self.activeSubscriptions = activeSubscriptions
    self.purchasedProducts = purchasedProducts
}
```

Key differences:
- No receipt file to parse. `Transaction.currentEntitlements` provides all active entitlements.
- Each transaction is individually JWS-signed. Verification is built in (`VerificationResult`).
- `currentEntitlements` automatically excludes expired subscriptions, refunded purchases, and revoked transactions.

## Subscription Status

StoreKit 2 provides direct access to subscription status:

```swift
func checkSubscriptionStatus() async throws -> Product.SubscriptionInfo.Status? {
    guard let product = try await Product.products(for: ["com.app.monthly"]).first,
          let subscription = product.subscription else {
        return nil
    }

    let statuses = try await subscription.status
    // Find the most recent active status
    return statuses.first { status in
        status.state == .subscribed || status.state == .inGracePeriod
    }
}
```

Subscription states: `.subscribed`, `.expired`, `.inBillingRetryPeriod`, `.inGracePeriod`, `.revoked`.

## Restore Purchases

### Before (StoreKit 1)

```swift
// Required: "Restore Purchases" button calling:
SKPaymentQueue.default().restoreCompletedTransactions()

// Delegate callbacks:
func paymentQueueRestoreCompletedTransactionsFinished(_ queue: SKPaymentQueue) { }
func paymentQueue(_ queue: SKPaymentQueue, restoreCompletedTransactionsFailedWithError error: Error) { }
```

### After (StoreKit 2)

```swift
// Transaction.currentEntitlements already provides all active purchases.
// A restore button is typically not needed, but if required:
func restorePurchases() async throws {
    try await AppStore.sync()
    await updateEntitlements()  // Re-check currentEntitlements
}
```

`AppStore.sync()` forces a sync with the App Store. In most cases, `Transaction.currentEntitlements` is sufficient and stays up to date automatically. Apple still recommends providing a restore mechanism for App Review compliance.

## Server-Side Migration

### Before (StoreKit 1)

- Fetch receipt from `appStoreReceiptURL`
- Base64-encode and send to your server
- Server calls Apple's `/verifyReceipt` endpoint
- Parse the monolithic receipt response

### After (StoreKit 2)

- Each `Transaction` contains a `jwsRepresentation` (signed JSON)
- Send the JWS string to your server
- Server verifies the JWS signature using Apple's public key
- Use Apple's **App Store Server API** for server-to-server operations:
  - `GET /inApps/v1/history/{transactionId}` -- transaction history
  - `GET /inApps/v1/subscriptions/{transactionId}` -- subscription status
  - `PUT /inApps/v1/refund/lookup/{transactionId}` -- refund lookup
- Set up **App Store Server Notifications V2** for real-time updates:
  - Subscription renewals, expirations, billing issues
  - Refunds and revocations
  - Offer redemptions

```swift
// Sending JWS to your server
func sendTransactionToServer(_ transaction: Transaction) async throws {
    let jwsRepresentation = transaction.jwsRepresentation

    var request = URLRequest(url: serverURL)
    request.httpMethod = "POST"
    request.httpBody = try JSONEncoder().encode(["jws": jwsRepresentation])
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")

    let (_, response) = try await URLSession.shared.data(for: request)
    guard let httpResponse = response as? HTTPURLResponse,
          httpResponse.statusCode == 200 else {
        throw ServerError.verificationFailed
    }
}
```

## Testing with StoreKit Configuration File

StoreKit 2 provides a local testing environment that does not require a sandbox account.

### Setup

1. File > New > File > StoreKit Configuration File
2. Add products: consumables, non-consumables, auto-renewable subscriptions
3. Edit > Scheme > Run > Options > StoreKit Configuration: select your `.storekit` file

### Testing Scenarios

```swift
// In Xcode, you can simulate:
// - Successful purchases
// - Failed purchases
// - Subscription renewals (accelerated time)
// - Subscription cancellation
// - Subscription expiration
// - Refunds
// - Ask-to-Buy (deferred transactions)
// - Interrupted purchases (SCA - Strong Customer Authentication)
// - Price increases requiring consent
// - Offer code redemption
```

The StoreKit configuration file lets you test the entire purchase flow locally. Xcode's transaction manager (Debug > StoreKit > Manage Transactions) lets you view, delete, and refund test transactions.

### Unit Testing with StoreKit Test

```swift
import StoreKitTest

class PurchaseTests: XCTestCase {
    var session: SKTestSession!

    override func setUp() async throws {
        session = try SKTestSession(configurationFileNamed: "Products")
        session.disableDialogs = true
        session.clearTransactions()
    }

    func testPurchaseNonConsumable() async throws {
        let products = try await Product.products(for: ["com.app.premium"])
        let product = try XCTUnwrap(products.first)

        let result = try await product.purchase()
        guard case .success(let verification) = result,
              case .verified(let transaction) = verification else {
            XCTFail("Purchase failed")
            return
        }

        XCTAssertEqual(transaction.productID, "com.app.premium")
        await transaction.finish()
    }
}
```

## Phased Rollout Strategy

Both StoreKit APIs share the same underlying payment queue. Purchases made with either API are visible to both. This makes coexistence safe.

### Phase 1: Add StoreKit 2 Code Alongside StoreKit 1

Keep existing StoreKit 1 code running. Add StoreKit 2 code for reading entitlements:

```swift
@Observable
class Store {
    // Existing StoreKit 1 code continues to handle purchases
    let paymentQueue = SKPaymentQueue.default()

    // New: use StoreKit 2 for checking entitlements
    func checkEntitlements() async {
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result {
                // Update entitlements using StoreKit 2 data
            }
        }
    }
}
```

### Phase 2: New Users Use StoreKit 2 Purchase Flow

Route new purchases through StoreKit 2 while keeping StoreKit 1 as a fallback:

```swift
func purchase(_ product: Product) async throws {
    if #available(iOS 15, *) {
        // StoreKit 2 purchase flow
        let result = try await product.purchase()
        // Handle result...
    }
}
```

### Phase 3: Verify Entitlements Match

Run both systems in parallel and verify they agree:

```swift
func verifyEntitlementParity() async {
    // StoreKit 2 entitlements
    var sk2Entitlements: Set<String> = []
    for await result in Transaction.currentEntitlements {
        if case .verified(let transaction) = result {
            sk2Entitlements.insert(transaction.productID)
        }
    }

    // Compare with your existing entitlement system
    let existingEntitlements = Set(legacyEntitlementManager.activeProductIDs)

    if sk2Entitlements != existingEntitlements {
        // Log discrepancy for investigation
        logger.warning("Entitlement mismatch: SK2=\(sk2Entitlements), Legacy=\(existingEntitlements)")
    }
}
```

### Phase 4: Remove StoreKit 1 Code

After verifying all transactions are handled correctly:
1. Remove `SKPaymentTransactionObserver` conformance
2. Remove `SKProductsRequestDelegate` code
3. Remove `SKPaymentQueue` usage
4. Remove receipt validation code (`appStoreReceiptURL`, `/verifyReceipt` calls)
5. Remove `StoreKit` import and re-add only `StoreKit` (StoreKit 2 types are in the same module)

## Common Mistakes

```swift
// ❌ Not calling transaction.finish() (transaction stays pending, may re-deliver)
let result = try await product.purchase()
if case .success(let verification) = result {
    let transaction = try checkVerified(verification)
    unlockContent(for: transaction.productID)
    // Missing: await transaction.finish()
}

// ✅ Always finish verified transactions
if case .success(let verification) = result {
    let transaction = try checkVerified(verification)
    unlockContent(for: transaction.productID)
    await transaction.finish()  // Required
}
```

```swift
// ❌ Not listening for Transaction.updates at app startup
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
            // Missing: .task { await store.listenForTransactions() }
        }
    }
}

// ✅ Start listening at app launch
struct MyApp: App {
    @State private var store = Store()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .task {
                    await store.listenForTransactions()
                }
        }
    }
}
```

```swift
// ❌ Ignoring unverified transactions silently
for await result in Transaction.currentEntitlements {
    guard case .verified(let transaction) = result else {
        continue  // Silently ignoring -- could hide real issues
    }
}

// ✅ Log unverified transactions for debugging
for await result in Transaction.currentEntitlements {
    switch result {
    case .verified(let transaction):
        // Process transaction
        break
    case .unverified(let transaction, let error):
        logger.error("Unverified transaction \(transaction.productID): \(error)")
    }
}
```

```swift
// ❌ Using restoreCompletedTransactions() with StoreKit 2
SKPaymentQueue.default().restoreCompletedTransactions()  // StoreKit 1 API

// ✅ Use Transaction.currentEntitlements or AppStore.sync()
try await AppStore.sync()
await updateEntitlements()
```

```swift
// ❌ Assuming StoreKit config file behavior matches production exactly
// Local testing does not validate with App Store servers
// Subscription timing is accelerated (1 hour = a few minutes)

// ✅ Also test in sandbox environment before release
// Use sandbox accounts to verify real App Store behavior
// Test on device, not just simulator, for production-like behavior
```

## Checklist

- [ ] Minimum deployment target is iOS 15+
- [ ] `Product.products(for:)` replaces `SKProductsRequest`
- [ ] `product.purchase()` replaces `SKPaymentQueue.add()`
- [ ] `Transaction.updates` listener running from app startup
- [ ] `Transaction.currentEntitlements` used for entitlement checking
- [ ] `transaction.finish()` called for every processed transaction
- [ ] `VerificationResult` checked for all transactions (`.verified` vs `.unverified`)
- [ ] Receipt validation replaced with JWS verification (local or server-side)
- [ ] Server-side migrated to App Store Server API (from `/verifyReceipt`)
- [ ] App Store Server Notifications V2 configured (if using server notifications)
- [ ] StoreKit configuration file created for local testing
- [ ] Restore purchases uses `AppStore.sync()` or `Transaction.currentEntitlements`
- [ ] Phased rollout plan: both APIs coexist before removing StoreKit 1 code
- [ ] Entitlement parity verified between old and new systems
- [ ] Tested in sandbox environment (not just StoreKit config file)
