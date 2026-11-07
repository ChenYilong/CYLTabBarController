---
name: uikit-layouting
description: Horizontal-first slicing methodology with mandatory ASCII preview for UIKit layout design
version: 1.0.0
---

# UIKit Horizontal-First Layouting

A systematic approach to UIKit layout design that prioritizes horizontal slicing and requires ASCII visualization before any code implementation.

## Core Methodology (ALWAYS FOLLOW)

1. **Identify horizontal bands** - Slice UI into rows first
2. **ASCII preview** - ALWAYS show layout before writing ANY code
3. **Implement top-to-bottom** - Build each row sequentially
4. **User confirmation** - Get approval before generating code

## MANDATORY: ASCII Preview Before Code

**CRITICAL**: Before writing ANY UIKit layout code, you MUST:

1. Draw an ASCII diagram of the entire screen
2. Label each horizontal row
3. Show content within each row
4. Mark fixed vs flexible heights
5. Get user confirmation

**NEVER skip this step. NEVER write layout code first.**

## ASCII Preview Format

### Full Screen Template

```
┌─────────────────────────────────────┐
│ [Status Bar - 44pt/54pt]            │  <- Safe area top
├─────────────────────────────────────┤
│ [Navigation Bar - 44pt]             │  <- Fixed height
├─────────────────────────────────────┤
│ [Row 1: Content description]        │  <- Describe content
├─────────────────────────────────────┤
│ [Row 2: Content description]        │
├─────────────────────────────────────┤
│ [                                   │
│    Flexible Content Area            │  <- Mark as flexible
│                                     │
├─────────────────────────────────────┤
│ [Row N: Content description]        │
├─────────────────────────────────────┤
│ [Tab Bar / Safe Area - 34pt/49pt]   │  <- Safe area bottom
└─────────────────────────────────────┘
```

### Row Detail Template

When a row has horizontal content, show the internal layout:

```
Row: [Leading | Center | Trailing]

Example:
┌────────────────────────────────────────┐
│ [48px] │ [Flexible]      │ [32px]      │
│ Icon   │ Title + Subtitle│ Chevron     │
└────────────────────────────────────────┘
```

## Complete Example: Login Screen

### Step 1: ASCII Preview (REQUIRED)

```
┌─────────────────────────────────────┐
│ [Safe Area Top]                     │
├─────────────────────────────────────┤
│ [Row 1: Logo - 120pt]               │  <- Fixed
│        ┌──────┐                     │
│        │ Logo │                     │
│        └──────┘                     │
├─────────────────────────────────────┤
│ [Row 2: Title - 60pt]               │  <- Fixed
│     "Welcome Back"                  │
├─────────────────────────────────────┤
│ [Row 3: Email Field - 80pt]         │  <- Fixed
│  ┌─────────────────────────────┐    │
│  │ Email                       │    │
│  └─────────────────────────────┘    │
│  [Error label]                      │
├─────────────────────────────────────┤
│ [Row 4: Password Field - 80pt]      │  <- Fixed
│  ┌─────────────────────────────┐    │
│  │ Password              [Eye] │    │
│  └─────────────────────────────┘    │
│  [Error label]                      │
├─────────────────────────────────────┤
│ [Row 5: Forgot Password - 44pt]     │  <- Fixed
│            "Forgot Password?"       │
├─────────────────────────────────────┤
│ [                                   │
│      Flexible Spacer                │  <- Flexible
│                                     │
├─────────────────────────────────────┤
│ [Row 6: Login Button - 56pt]        │  <- Fixed
│  ┌─────────────────────────────┐    │
│  │         Login               │    │
│  └─────────────────────────────┘    │
├─────────────────────────────────────┤
│ [Row 7: Signup Link - 44pt]         │  <- Fixed
│    "Don't have account? Sign up"    │
├─────────────────────────────────────┤
│ [Safe Area Bottom]                  │
└─────────────────────────────────────┘
```

### Step 2: Row Breakdown

| Row | Content | Height | Horizontal Layout |
|-----|---------|--------|-------------------|
| 1 | Logo | 120pt fixed | Centered |
| 2 | Title | 60pt fixed | Centered |
| 3 | Email field + error | 80pt fixed | Full width with padding |
| 4 | Password field + error | 80pt fixed | TextField + eye button |
| 5 | Forgot password | 44pt fixed | Centered link |
| Spacer | - | Flexible | - |
| 6 | Login button | 56pt fixed | Full width with padding |
| 7 | Signup link | 44pt fixed | Centered |

### Step 3: User Confirms → Generate Code

```swift
final class LoginViewController: UIViewController {

    // MARK: - UI Elements

    private let rootStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 0
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    // Row 1: Logo
    private let logoRow: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let logoImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.image = UIImage(named: "logo")
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    // Row 2: Title
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Welcome Back"
        label.font = .systemFont(ofSize: 28, weight: .bold)
        label.textAlignment = .center
        return label
    }()

    // Row 3: Email
    private let emailRow: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let emailTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Email"
        tf.borderStyle = .roundedRect
        tf.keyboardType = .emailAddress
        tf.autocapitalizationType = .none
        tf.translatesAutoresizingMaskIntoConstraints = false
        return tf
    }()

    private let emailErrorLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12)
        label.textColor = .systemRed
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    // Row 4: Password
    private let passwordRow: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let passwordTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Password"
        tf.borderStyle = .roundedRect
        tf.isSecureTextEntry = true
        tf.translatesAutoresizingMaskIntoConstraints = false
        return tf
    }()

    private let eyeButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "eye"), for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private let passwordErrorLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12)
        label.textColor = .systemRed
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    // Row 5: Forgot Password
    private let forgotPasswordButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Forgot Password?", for: .normal)
        return button
    }()

    // Flexible Spacer
    private let spacerView: UIView = {
        let view = UIView()
        view.setContentHuggingPriority(.defaultLow, for: .vertical)
        return view
    }()

    // Row 6: Login Button
    private let loginRow: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let loginButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Login", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 12
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    // Row 7: Signup Link
    private let signupButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Don't have account? Sign up", for: .normal)
        return button
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupHierarchy()
        setupConstraints()
    }

    // MARK: - Setup

    private func setupHierarchy() {
        view.addSubview(rootStackView)

        // Row 1: Logo
        logoRow.addSubview(logoImageView)
        rootStackView.addArrangedSubview(logoRow)

        // Row 2: Title
        rootStackView.addArrangedSubview(titleLabel)

        // Row 3: Email
        emailRow.addSubview(emailTextField)
        emailRow.addSubview(emailErrorLabel)
        rootStackView.addArrangedSubview(emailRow)

        // Row 4: Password
        passwordRow.addSubview(passwordTextField)
        passwordRow.addSubview(eyeButton)
        passwordRow.addSubview(passwordErrorLabel)
        rootStackView.addArrangedSubview(passwordRow)

        // Row 5: Forgot Password
        rootStackView.addArrangedSubview(forgotPasswordButton)

        // Flexible Spacer
        rootStackView.addArrangedSubview(spacerView)

        // Row 6: Login Button
        loginRow.addSubview(loginButton)
        rootStackView.addArrangedSubview(loginRow)

        // Row 7: Signup Link
        rootStackView.addArrangedSubview(signupButton)
    }

    private func setupConstraints() {
        let padding: CGFloat = 24

        NSLayoutConstraint.activate([
            // Root stack pinned to safe area
            rootStackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            rootStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            rootStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            rootStackView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),

            // Row 1: Logo - 120pt height
            logoRow.heightAnchor.constraint(equalToConstant: 120),
            logoImageView.centerXAnchor.constraint(equalTo: logoRow.centerXAnchor),
            logoImageView.centerYAnchor.constraint(equalTo: logoRow.centerYAnchor),
            logoImageView.widthAnchor.constraint(equalToConstant: 80),
            logoImageView.heightAnchor.constraint(equalToConstant: 80),

            // Row 2: Title - intrinsic (wrapped by stack)

            // Row 3: Email - 80pt height
            emailRow.heightAnchor.constraint(equalToConstant: 80),
            emailTextField.topAnchor.constraint(equalTo: emailRow.topAnchor, constant: 8),
            emailTextField.leadingAnchor.constraint(equalTo: emailRow.leadingAnchor, constant: padding),
            emailTextField.trailingAnchor.constraint(equalTo: emailRow.trailingAnchor, constant: -padding),
            emailTextField.heightAnchor.constraint(equalToConstant: 44),
            emailErrorLabel.topAnchor.constraint(equalTo: emailTextField.bottomAnchor, constant: 4),
            emailErrorLabel.leadingAnchor.constraint(equalTo: emailTextField.leadingAnchor),
            emailErrorLabel.trailingAnchor.constraint(equalTo: emailTextField.trailingAnchor),

            // Row 4: Password - 80pt height
            passwordRow.heightAnchor.constraint(equalToConstant: 80),
            passwordTextField.topAnchor.constraint(equalTo: passwordRow.topAnchor, constant: 8),
            passwordTextField.leadingAnchor.constraint(equalTo: passwordRow.leadingAnchor, constant: padding),
            passwordTextField.trailingAnchor.constraint(equalTo: passwordRow.trailingAnchor, constant: -padding),
            passwordTextField.heightAnchor.constraint(equalToConstant: 44),
            eyeButton.centerYAnchor.constraint(equalTo: passwordTextField.centerYAnchor),
            eyeButton.trailingAnchor.constraint(equalTo: passwordTextField.trailingAnchor, constant: -12),
            eyeButton.widthAnchor.constraint(equalToConstant: 24),
            passwordErrorLabel.topAnchor.constraint(equalTo: passwordTextField.bottomAnchor, constant: 4),
            passwordErrorLabel.leadingAnchor.constraint(equalTo: passwordTextField.leadingAnchor),
            passwordErrorLabel.trailingAnchor.constraint(equalTo: passwordTextField.trailingAnchor),

            // Row 5: Forgot Password - 44pt (intrinsic)
            forgotPasswordButton.heightAnchor.constraint(equalToConstant: 44),

            // Spacer takes remaining space (low hugging priority)

            // Row 6: Login Button - 56pt height
            loginRow.heightAnchor.constraint(equalToConstant: 56),
            loginButton.topAnchor.constraint(equalTo: loginRow.topAnchor),
            loginButton.leadingAnchor.constraint(equalTo: loginRow.leadingAnchor, constant: padding),
            loginButton.trailingAnchor.constraint(equalTo: loginRow.trailingAnchor, constant: -padding),
            loginButton.bottomAnchor.constraint(equalTo: loginRow.bottomAnchor),

            // Row 7: Signup Link - 44pt (intrinsic)
            signupButton.heightAnchor.constraint(equalToConstant: 44),
        ])
    }
}
```

## Horizontal Slicing Rules

### Rule 1: Top-Level is Always Vertical

The root container is a vertical stack. Each child is a horizontal row.

```swift
let rootStack = UIStackView()
rootStack.axis = .vertical  // ALWAYS
```

### Rule 2: Rows Contain Horizontal Content

Each row manages its own horizontal layout:

```
Row: [Leading Content | Center Content | Trailing Content]
```

### Rule 3: Fixed vs Flexible Heights

Mark heights clearly in ASCII:
- `← Fixed 44pt` - explicit height constraint
- `← Flexible` - uses content hugging/compression resistance

### Rule 4: Safe Areas Are Respected

Always show safe area boundaries:
- Top: Status bar + notch
- Bottom: Home indicator

## Common Row Patterns

### Navigation Row
```
┌────────────────────────────────────────┐
│ [Back] │     [Title]      │ [Action]   │
│  44pt  │     Flexible     │   44pt     │
└────────────────────────────────────────┘
```

### List Cell Row
```
┌────────────────────────────────────────┐
│ [Avatar] │ [Title    ] │ [Accessory]   │
│   48pt   │ [Subtitle ] │    24pt       │
│          │  Flexible   │               │
└────────────────────────────────────────┘
```

### Form Field Row
```
┌────────────────────────────────────────┐
│ [Label]  │ [TextField           ]      │
│  80pt    │        Flexible             │
└────────────────────────────────────────┘
```

### Button Bar Row
```
┌────────────────────────────────────────┐
│ [Cancel]  │  [Spacer]  │  [Confirm]    │
│  Equal    │  Flexible  │    Equal      │
└────────────────────────────────────────┘
```

## Constraint Naming Convention

Use descriptive names that match the ASCII diagram:

```swift
// Row names
let headerRow, contentRow, footerRow

// Element positions
let leadingElement, centerElement, trailingElement

// Sections
let topSection, middleSection, bottomSection
```

## Workflow Summary

```
1. User Request → "Create a settings screen"
                          ↓
2. ASCII Diagram → Draw full screen with all rows
                          ↓
3. Row Breakdown → Table listing content & heights
                          ↓
4. User Confirms → "Looks good" / "Change X"
                          ↓
5. Generate Code → UIKit with proper constraints
```

## Anti-Patterns (NEVER DO)

❌ **Write code without ASCII preview**
❌ **Guess at layout structure**
❌ **Start with individual views before overall structure**
❌ **Mix SwiftUI and UIKit for layout**
❌ **Use Auto Layout without clear row hierarchy**

## Quick Reference: Heights

| Element | Height |
|---------|--------|
| Status bar | 44pt (54pt with notch) |
| Navigation bar | 44pt |
| Large title nav | 96pt |
| Tab bar | 49pt |
| Toolbar | 44pt |
| Standard button | 44pt |
| Large button | 56pt |
| Text field | 44pt |
| Table cell | 44pt minimum |
| Safe area bottom | 34pt (home indicator) |

## Pre-Layout Interview

Before creating any UI layout, gather requirements using `AskUserQuestion`:

### Layout Questions

**Question 1: Screen Type**
- Header: "Screen Type"
- Question: "What type of screen is this?"
- Options:
  - Form screen - Input fields, labels, buttons
  - List screen - Scrollable list of items
  - Detail screen - Display content with actions
  - Dashboard - Multiple sections/cards

**Question 2: Key Components** (multiSelect: true)
- Header: "Components"
- Question: "What UI elements do you need?"
- Options:
  - Text inputs - Text fields, text views
  - Buttons - Action buttons, links
  - Images - Photos, icons, avatars
  - Lists/Tables - Scrollable content

**Question 3: Layout Complexity**
- Header: "Complexity"
- Question: "How complex is the layout?"
- Options:
  - Simple - Few rows, straightforward
  - Medium - Multiple sections, some nesting
  - Complex - Many elements, intricate layout

**Question 4: Scrolling Behavior**
- Header: "Scrolling"
- Question: "Does the content need to scroll?"
- Options:
  - No scrolling - Fixed content fits screen
  - Vertical scroll - Content exceeds screen height
  - Horizontal scroll - Side-scrolling content
  - Both directions - Complex scrollable content

### Interview Flow

1. Ask questions using AskUserQuestion
2. Summarize: "Creating a [screen type] with [components], [complexity] layout, [scrolling] behavior"
3. **ALWAYS show ASCII preview** before any code
4. Get user confirmation
5. Generate UIKit code

### Skip Interview If:
- User provided detailed layout specifications
- User says "skip questions" or "just do it"
- User shared wireframe or design
