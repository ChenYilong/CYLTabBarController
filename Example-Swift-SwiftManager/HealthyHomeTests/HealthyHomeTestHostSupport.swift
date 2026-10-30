import CYLTabBarController

// The example assigns RootTabBarController as its delegate, whose SPM-imported
// type also requires this optional FlatDesign delegate protocol. Compile this
// small conformance into the host so the existing example can run unit tests.
extension RootTabBarController: CYLFlatDesignUITabBarControllerDelegate {}
