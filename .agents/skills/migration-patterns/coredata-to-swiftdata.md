# CoreData to SwiftData Migration

SwiftData replaces CoreData with a declarative, Swift-native persistence framework built on the `@Model` macro. Requires iOS 17 / macOS 14 minimum.

## Concept Mapping

| CoreData | SwiftData | Notes |
|----------|-----------|-------|
| `NSManagedObject` subclass | `@Model` class | No codegen, no .xcdatamodeld |
| `NSPersistentContainer` | `ModelContainer` | Configured in code or SwiftUI modifier |
| `NSManagedObjectContext` | `ModelContext` | Injected via `@Environment(\.modelContext)` |
| `NSFetchRequest` | `FetchDescriptor` | Uses Swift predicates, not NSPredicate |
| `@FetchRequest` | `@Query` | SwiftUI property wrapper |
| `NSPredicate` | `#Predicate` macro | Type-safe, compile-time checked |
| `NSSortDescriptor` | `SortDescriptor` | Swift-native, type-safe |
| `.xcdatamodeld` file | None | Schema defined in code via @Model |
| Lightweight migration | `VersionedSchema` + `SchemaMigrationPlan` | Explicit migration stages |

## NSManagedObject to @Model

### Before (CoreData)

```swift
// Requires .xcdatamodeld file with entity definition
// Codegen produces NSManagedObject subclass or you write manually:

class Item: NSManagedObject {
    @NSManaged var title: String
    @NSManaged var timestamp: Date
    @NSManaged var isComplete: Bool
    @NSManaged var tags: NSSet?  // To-many relationship
}
```

### After (SwiftData)

```swift
import SwiftData

@Model
class Item {
    var title: String
    var timestamp: Date
    var isComplete: Bool
    var tags: [Tag]  // Direct Swift array, not NSSet

    init(title: String, timestamp: Date = .now, isComplete: Bool = false, tags: [Tag] = []) {
        self.title = title
        self.timestamp = timestamp
        self.isComplete = isComplete
        self.tags = tags
    }
}
```

Key differences:
- No .xcdatamodeld file needed. The schema is the Swift class itself.
- No `@NSManaged`. Properties are plain stored properties.
- Relationships use Swift arrays and optional types, not `NSSet`.
- You must provide an `init` -- `@Model` does not synthesize one.
- `@Model` automatically makes all stored properties persistent.

### Excluding Properties from Persistence

```swift
@Model
class Item {
    var title: String
    var timestamp: Date

    // Not persisted
    @Transient var isSelected: Bool = false
}
```

### Unique Constraints

```swift
@Model
class Item {
    #Unique<Item>([\.title, \.timestamp])

    var title: String
    var timestamp: Date
}
```

## NSPersistentContainer to ModelContainer

### Before (CoreData)

```swift
class PersistenceController {
    let container: NSPersistentContainer

    init() {
        container = NSPersistentContainer(name: "MyApp")
        container.loadPersistentStores { description, error in
            if let error {
                fatalError("Failed to load store: \(error)")
            }
        }
    }

    var viewContext: NSManagedObjectContext {
        container.viewContext
    }
}
```

### After (SwiftData)

```swift
// Option 1: In SwiftUI (preferred)
@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [Item.self, Tag.self])
    }
}

// Option 2: Manual configuration
let container = try ModelContainer(
    for: Item.self, Tag.self,
    configurations: ModelConfiguration(
        isStoredInMemoryOnly: false,
        allowsSave: true
    )
)
```

The `.modelContainer` modifier injects both the `ModelContainer` and a `ModelContext` into the SwiftUI environment.

## NSFetchRequest to FetchDescriptor

### Before (CoreData)

```swift
let request: NSFetchRequest<Item> = Item.fetchRequest()
request.predicate = NSPredicate(format: "isComplete == %@ AND title CONTAINS[cd] %@", NSNumber(value: false), searchText)
request.sortDescriptors = [NSSortDescriptor(keyPath: \Item.timestamp, ascending: false)]
request.fetchLimit = 20

let items = try viewContext.fetch(request)
```

### After (SwiftData)

```swift
var descriptor = FetchDescriptor<Item>(
    predicate: #Predicate<Item> { item in
        !item.isComplete && item.title.localizedStandardContains(searchText)
    },
    sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
)
descriptor.fetchLimit = 20

let items = try modelContext.fetch(descriptor)
```

Key differences:
- `#Predicate` is type-safe and checked at compile time. No format strings.
- `SortDescriptor` is Swift-native (not `NSSortDescriptor`).
- Fetch is called on `ModelContext`, not `NSManagedObjectContext`.

## @FetchRequest to @Query

### Before (CoreData)

```swift
struct ItemListView: View {
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Item.timestamp, ascending: false)],
        predicate: NSPredicate(format: "isComplete == NO"),
        animation: .default
    )
    private var items: FetchedResults<Item>

    var body: some View {
        List(items) { item in
            ItemRow(item: item)
        }
    }
}
```

### After (SwiftData)

```swift
struct ItemListView: View {
    @Query(
        filter: #Predicate<Item> { !$0.isComplete },
        sort: \.timestamp,
        order: .reverse
    )
    private var items: [Item]

    var body: some View {
        List(items) { item in
            ItemRow(item: item)
        }
    }
}
```

Key differences:
- `@Query` returns a plain `[Item]` array, not `FetchedResults`.
- Predicates use `#Predicate` macro.
- Sort is specified with keypaths and order directly.
- `@Query` automatically observes the `ModelContext` from the environment.

### Dynamic Queries

If the predicate or sort needs to change at runtime, pass them via `init`:

```swift
struct ItemListView: View {
    @Query private var items: [Item]

    init(showCompleted: Bool) {
        let predicate: Predicate<Item>
        if showCompleted {
            predicate = #Predicate<Item> { _ in true }
        } else {
            predicate = #Predicate<Item> { !$0.isComplete }
        }
        _items = Query(filter: predicate, sort: \.timestamp, order: .reverse)
    }

    var body: some View {
        List(items) { item in
            ItemRow(item: item)
        }
    }
}
```

## NSManagedObjectContext to ModelContext

### Before (CoreData)

```swift
// Insert
let item = Item(context: viewContext)
item.title = "New Item"
item.timestamp = Date()

// Save
try viewContext.save()

// Delete
viewContext.delete(item)
try viewContext.save()
```

### After (SwiftData)

```swift
// Insert
let item = Item(title: "New Item")
modelContext.insert(item)

// Save (automatic by default, or explicit)
try modelContext.save()

// Delete
modelContext.delete(item)
try modelContext.save()
```

Key differences:
- Objects are created with a normal Swift `init`, then inserted into the context.
- SwiftData auto-saves by default. Explicit `save()` is optional but recommended for critical operations.
- No `context:` parameter in the initializer.

## Lightweight Migration (VersionedSchema + SchemaMigrationPlan)

SwiftData requires explicit migration stages when your schema changes between releases.

### Define Versioned Schemas

```swift
enum ItemSchemaV1: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 0, 0)

    static var models: [any PersistentModel.Type] {
        [Item.self]
    }

    @Model
    class Item {
        var title: String
        var timestamp: Date

        init(title: String, timestamp: Date) {
            self.title = title
            self.timestamp = timestamp
        }
    }
}

enum ItemSchemaV2: VersionedSchema {
    static var versionIdentifier = Schema.Version(2, 0, 0)

    static var models: [any PersistentModel.Type] {
        [Item.self]
    }

    @Model
    class Item {
        var title: String
        var timestamp: Date
        var isComplete: Bool  // New property

        init(title: String, timestamp: Date, isComplete: Bool = false) {
            self.title = title
            self.timestamp = timestamp
            self.isComplete = isComplete
        }
    }
}
```

### Define the Migration Plan

```swift
enum ItemMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [ItemSchemaV1.self, ItemSchemaV2.self]
    }

    static var stages: [MigrationStage] {
        [migrateV1toV2]
    }

    static let migrateV1toV2 = MigrationStage.lightweight(
        fromVersion: ItemSchemaV1.self,
        toVersion: ItemSchemaV2.self
    )
}
```

### Use the Migration Plan

```swift
@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(
            for: ItemSchemaV2.Item.self,
            migrationPlan: ItemMigrationPlan.self
        )
    }
}
```

For complex migrations that cannot be handled by lightweight migration, use `.custom`:

```swift
static let migrateV1toV2 = MigrationStage.custom(
    fromVersion: ItemSchemaV1.self,
    toVersion: ItemSchemaV2.self
) { context in
    // willMigrate: runs before schema changes
    // Transform data as needed with the OLD schema
} didMigrate: { context in
    // didMigrate: runs after schema changes
    // Transform data as needed with the NEW schema
    let items = try context.fetch(FetchDescriptor<ItemSchemaV2.Item>())
    for item in items {
        item.isComplete = false
    }
    try context.save()
}
```

## Coexistence Strategy

You can run CoreData and SwiftData side by side during migration. This is the recommended approach for production apps with existing data.

### Shared Persistent Store

Both frameworks can point to the same SQLite file:

```swift
let url = URL.applicationSupportDirectory.appending(path: "MyApp.store")

// CoreData
let description = NSPersistentStoreDescription()
description.url = url
let container = NSPersistentContainer(name: "MyApp")
container.persistentStoreDescriptions = [description]

// SwiftData
let config = ModelConfiguration(url: url)
let swiftDataContainer = try ModelContainer(for: Item.self, configurations: config)
```

### Migration Strategy for Production Apps

1. **Phase 1**: Add SwiftData models alongside CoreData entities. New screens use SwiftData.
2. **Phase 2**: Migrate existing screens one at a time from CoreData to SwiftData.
3. **Phase 3**: Write a one-time data migration that copies remaining CoreData records to SwiftData.
4. **Phase 4**: Remove CoreData stack, .xcdatamodeld file, and NSManagedObject subclasses.

### One-Time Data Migration

```swift
func migrateData(from coreDataContext: NSManagedObjectContext, to modelContext: ModelContext) throws {
    let request: NSFetchRequest<CDItem> = CDItem.fetchRequest()
    let coreDataItems = try coreDataContext.fetch(request)

    for cdItem in coreDataItems {
        let item = Item(
            title: cdItem.title ?? "",
            timestamp: cdItem.timestamp ?? .now,
            isComplete: cdItem.isComplete
        )
        modelContext.insert(item)
    }

    try modelContext.save()
}
```

## When NOT to Migrate

Stay on CoreData if:

- Your minimum deployment target is below iOS 17 / macOS 14.
- You rely on CoreData features SwiftData does not yet support (e.g., abstract entities, derived attributes, fetched properties, complex multi-store configurations).
- You have a large, stable CoreData stack that is well-tested and not causing issues.
- You use CloudKit syncing with CoreData and have not verified SwiftData's CloudKit support meets your needs.
- Third-party libraries in your project depend on NSManagedObject subclasses.

## Common Mistakes

```swift
// ❌ Forgetting to provide init for @Model class
@Model
class Item {
    var title: String
    var timestamp: Date
    // Compiler error: @Model requires explicit init
}

// ✅ Always provide init
@Model
class Item {
    var title: String
    var timestamp: Date

    init(title: String, timestamp: Date = .now) {
        self.title = title
        self.timestamp = timestamp
    }
}
```

```swift
// ❌ Using NSPredicate format strings with @Query
@Query(filter: NSPredicate(format: "isComplete == NO"))  // Wrong type
private var items: [Item]

// ✅ Use #Predicate macro
@Query(filter: #Predicate<Item> { !$0.isComplete })
private var items: [Item]
```

```swift
// ❌ Creating model objects with context parameter (CoreData habit)
let item = Item(context: modelContext)

// ✅ Create normally, then insert
let item = Item(title: "New")
modelContext.insert(item)
```

```swift
// ❌ Using NSSet for relationships
@Model
class Item {
    var tags: NSSet?  // Wrong, use Swift types
}

// ✅ Use Swift arrays
@Model
class Item {
    var tags: [Tag]
}
```

## Checklist

- [ ] Minimum deployment target is iOS 17 / macOS 14
- [ ] All CoreData entities have equivalent @Model classes
- [ ] Relationships use Swift arrays/optionals, not NSSet
- [ ] All @Model classes have explicit `init` methods
- [ ] NSPredicate replaced with #Predicate macro
- [ ] NSSortDescriptor replaced with SortDescriptor
- [ ] @FetchRequest replaced with @Query
- [ ] NSManagedObjectContext usage replaced with ModelContext
- [ ] VersionedSchema and SchemaMigrationPlan set up for existing data
- [ ] One-time data migration tested (if coexisting with CoreData)
- [ ] CloudKit syncing verified (if applicable)
- [ ] .xcdatamodeld file removed after full migration
