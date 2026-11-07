//
//  Use this file to import your target's public headers that you would like to expose to Swift.
//

#import "OCSwift.h"

// As a module, not textually: the app's header search paths include the framework's Headers, so a quoted import parsed
// the headers a second time next to the module and warned "duplicate definition of category" (CAAnimation).
@import CYLTabBarController;
