// Usage: swift scripts/release-ram-mirror-displays.swift [--dry-run] [--off]
//
// Mirrors every display of this Mac onto the main display (one framebuffer to draw instead of several), or turns the
// mirroring off again with --off. The change lasts for the login session. With one display there is nothing to do.
// Doc for developers: docs/Release-RAM.md
import CoreGraphics
import Foundation

let arguments = CommandLine.arguments.dropFirst()
let dryRun = arguments.contains("--dry-run")
let off = arguments.contains("--off")

var count: UInt32 = 0
CGGetOnlineDisplayList(0, nil, &count)
var displays = [CGDirectDisplayID](repeating: 0, count: Int(count))
CGGetOnlineDisplayList(count, &displays, &count)

let main = CGMainDisplayID()
let others = displays.filter { $0 != main }
print("release-ram: displays: \(displays.count) online, main display \(main), others \(others)")
if others.isEmpty {
    print("release-ram: displays: only one display, nothing to mirror")
    exit(0)
}
if dryRun {
    print("release-ram: displays: dry run, would \(off ? "turn mirroring off" : "mirror \(others) onto \(main)")")
    exit(0)
}

var config: CGDisplayConfigRef?
guard CGBeginDisplayConfiguration(&config) == .success, let configuration = config else {
    print("release-ram: displays: could not begin a display configuration")
    exit(1)
}
for display in others {
    CGConfigureDisplayMirrorOfDisplay(configuration, display, off ? kCGNullDirectDisplay : main)
}
let result = CGCompleteDisplayConfiguration(configuration, .forSession)
if result == .success {
    print("release-ram: displays: \(off ? "mirroring is off" : "mirrored onto the main display")")
} else {
    CGCancelDisplayConfiguration(configuration)
    print("release-ram: displays: the change failed (CGError \(result.rawValue))")
    exit(1)
}
