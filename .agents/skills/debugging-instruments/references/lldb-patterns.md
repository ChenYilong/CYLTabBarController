# LLDB Patterns Reference

Complete LLDB command reference for iOS debugging. Companion to the main `debugging-instruments` skill.

## Contents

- [Inspection Commands](#inspection-commands)
- [Breakpoint Patterns](#breakpoint-patterns)
- [Expression Evaluation](#expression-evaluation)
- [Watchpoints](#watchpoints)
- [Thread and Stack Navigation](#thread-and-stack-navigation)
- [Memory Inspection](#memory-inspection)
- [Custom Type Summaries](#custom-type-summaries)
- [Python Scripting](#python-scripting)
- [Useful Symbolic Breakpoints](#useful-symbolic-breakpoints)
- [LLDB Init File](#lldb-init-file)

## Inspection Commands

### po vs p vs v

| Command | Mechanism | Side Effects | Speed |
|---------|-----------|--------------|-------|
| `po expr` | Calls `debugDescription` via expression eval | Yes — runs code | Slow |
| `p expr` | LLDB formatter on expression result | Yes — runs code | Medium |
| `v varname` | Reads frame memory directly | No | Fast |

```text
(lldb) po myArray                      # Calls CustomDebugStringConvertible
(lldb) p myArray                       # Shows type + formatted value
(lldb) v myArray                       # Fastest, no code execution
(lldb) v myArray[0]                    # Access elements directly
(lldb) v self.viewModel.state          # Dot-path into properties
```

Use `v` as the default. Fall back to `po` when you need `debugDescription`
or custom string output. Use `p` when you need type information.

### Register and Memory

```text
(lldb) register read                   # All registers
(lldb) register read x0 x1            # Specific registers (ARM64)
(lldb) memory read 0x600003a04000      # Read raw memory
(lldb) memory read -s1 -fx -c32 addr  # 32 bytes as hex
```

## Breakpoint Patterns

### File and Line

```text
(lldb) br set -f ViewModel.swift -l 42
(lldb) br set -f ViewModel.swift -l 42 -c "count > 10"
(lldb) br set -f ViewModel.swift -l 42 --one-shot true   # Delete after first hit
```

### Function and Method Names

```text
(lldb) br set -n viewDidLoad                     # Any function named viewDidLoad
(lldb) br set -n "MyApp.ViewModel.loadData()"    # Fully qualified Swift name
(lldb) br set -S "setValue:forKey:"              # ObjC selector
(lldb) br set -r ".*Error.*"                     # Regex match on symbol name
(lldb) br set -r "MyModule\..*\.deinit"         # All deinits in a module
```

### Breakpoint Actions

```text
(lldb) br set -n loadData
(lldb) br command add 1
> po "loadData called at \(Date())"
> bt
> continue
> DONE
```

### Logpoints (Auto-Continue Breakpoints)

```text
(lldb) br set -f File.swift -l 42
(lldb) br modify 1 --auto-continue true
(lldb) br command add 1
> po "state = \(self.state)"
> DONE
```

This prints the value every time line 42 is hit without stopping execution.
Equivalent to Xcode's "Log Message" breakpoint action with auto-continue.

### Listing and Managing

```text
(lldb) br list                         # Show all breakpoints
(lldb) br disable 1                    # Disable breakpoint 1
(lldb) br enable 1                     # Re-enable
(lldb) br delete 1                     # Remove
(lldb) br delete                       # Remove ALL breakpoints
(lldb) br modify 1 -i 5               # Skip first 5 hits (ignore count)
```

## Expression Evaluation

### Swift Expressions

```text
(lldb) expr myArray.count
(lldb) expr myArray.filter { $0.isActive }.count
(lldb) expr let result = myFunc(); print(result)
(lldb) e -l swift -- import Foundation
(lldb) e -l swift -- self.title = "Debug Title"
```

### Objective-C Expressions (for UIKit internals)

```text
(lldb) e -l objc -- (void)[CATransaction flush]
(lldb) e -l objc -- (void)[[UIApplication sharedApplication] _performMemoryWarning]
(lldb) e -l objc -- (BOOL)[(id)0x7fc... isKindOfClass:[UIView class]]
(lldb) e -l objc -- (void)[0x7fc... recursiveDescription]   # View hierarchy dump
```

### Modifying State at Runtime

```text
(lldb) e self.debugLabel.text = "Modified in debugger"
(lldb) e self.view.backgroundColor = UIColor.red
(lldb) e -l objc -- (void)[CATransaction flush]   # Force redraw
```

### Calling Functions

```text
(lldb) e self.viewModel.reset()
(lldb) e UserDefaults.standard.set(true, forKey: "debug_mode")
(lldb) e NotificationCenter.default.post(name: .init("DebugReload"), object: nil)
```

## Watchpoints

```text
(lldb) w set v self.score                          # Watch for writes
(lldb) w set v self.score -w read                 # Watch for reads
(lldb) w set v self.score -w read_write           # Watch both
(lldb) w set e -- 0x600003a04000                   # Watch memory address
(lldb) w modify 1 -c "self.score > 100"           # Conditional
(lldb) w list                                      # Show active watchpoints
(lldb) w delete 1                                  # Remove
```

Hardware watchpoint limit on Apple Silicon: 4 watchpoints. Use them
sparingly for tracking unexpected mutations.

## Thread and Stack Navigation

```text
(lldb) thread list                                 # All threads with status
(lldb) thread select 3                             # Switch to thread 3
(lldb) bt                                          # Backtrace current thread
(lldb) bt all                                      # Backtrace every thread
(lldb) bt 5                                        # Show only top 5 frames
(lldb) frame select 2                              # Jump to frame #2
(lldb) frame info                                  # Current frame info
(lldb) frame variable                              # All variables in frame
(lldb) up                                          # Move up one frame
(lldb) down                                        # Move down one frame
```

### Thread Return (skip execution)

```text
(lldb) thread return                               # Return from current frame
(lldb) thread return false                         # Return false from a Bool func
```

Use `thread return` to skip the rest of a function during debugging.
Useful for bypassing a crash or testing a different code path.

## Memory Inspection

```text
(lldb) memory read 0x600003a04000                  # Default format
(lldb) memory read -s4 -fx -c8 addr               # 8 x 4-byte hex words
(lldb) memory read -f s addr                       # Read as C string
(lldb) memory find 0x100000 0x200000 -e "DEADBEEF" # Search memory range
(lldb) image lookup -a 0x100004500                 # Symbol at address
(lldb) image lookup -n loadData                    # Address of symbol
(lldb) image list                                  # All loaded images/frameworks
```

### Swift Metadata Inspection

```text
(lldb) e -l swift -- print(type(of: myObject))
(lldb) e -l swift -- dump(myObject)                # Full mirror dump
(lldb) e -l swift -- Mirror(reflecting: myObject).children.map { $0.label }
```

## Custom Type Summaries

Add type summaries to `.lldbinit` for cleaner debugger output:

```text
# ~/.lldbinit

# Show CLLocationCoordinate2D as "lat, lon"
type summary add CLLocationCoordinate2D \
    --summary-string "lat=${var.latitude}, lon=${var.longitude}"

# Show Date as readable string
type summary add Foundation.Date \
    --summary-string "${var.timeIntervalSinceReferenceDate} secs since 2001"

# Custom summary for your own types
type summary add MyApp.UserProfile \
    --summary-string "User(${var.name}, id=${var.id})"
```

## Python Scripting

### Inline Python

```text
(lldb) script import os
(lldb) script print(os.getpid())
(lldb) script lldb.debugger.GetSelectedTarget().GetProcess().GetNumThreads()
```

### Custom Python Command

Create `~/lldb_commands/dump_views.py`:

```python
import lldb

def dump_view_hierarchy(debugger, command, result, internal_dict):
    """Dump the key window's view hierarchy."""
    target = debugger.GetSelectedTarget()
    process = target.GetProcess()
    thread = process.GetSelectedThread()
    frame = thread.GetSelectedFrame()

    expr = '(NSString *)[[UIApplication sharedApplication].keyWindow recursiveDescription]'
    value = frame.EvaluateExpression(expr)
    result.AppendMessage(str(value.GetObjectDescription()))

def __lldb_init_module(debugger, internal_dict):
    debugger.HandleCommand(
        'command script add -f dump_views.dump_view_hierarchy dump_views'
    )
```

Load in `.lldbinit`:

```text
command script import ~/lldb_commands/dump_views.py
```

Then use in LLDB:

```text
(lldb) dump_views
```

## Useful Symbolic Breakpoints

Set these in Xcode's Breakpoint Navigator for common debugging scenarios:

| Symbol | Purpose |
|--------|---------|
| `UIViewAlertForUnsatisfiableConstraints` | Auto Layout constraint conflicts |
| `swift_willThrow` | Break on all Swift throws |
| `malloc_error_break` | Heap corruption detection |
| `_UITraitCollectionChangeObserverNotify` | Track trait collection changes |
| `objc_exception_throw` | Break on ObjC exceptions |
| `-[UIApplication _performMemoryWarning]` | Memory warning simulation |
| `NSInternalInconsistencyException` | Foundation assertion failures |

## LLDB Init File

Place commonly used configuration in `~/.lldbinit`:

```text
# Custom aliases
command alias -- pp e -l swift -- import Foundation
command alias -- pjson e -l swift -- print(String(data: try! JSONSerialization.data(withJSONObject: %1, options: .prettyPrinted), encoding: .utf8)!)

# Type summaries
type summary add --summary-string "${var.rawValue}" -x "^.*RawRepresentable$"

# Load custom scripts
command script import ~/lldb_commands/dump_views.py

# Settings
settings set target.language swift
settings set frame-format "frame #${frame.index}: ${frame.pc}{ ${module.file.basename}{\`${function.name-with-args}{${frame.no-debug}}}}\n"
```
