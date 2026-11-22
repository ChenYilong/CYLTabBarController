// Only erasable TypeScript syntax (no enum, namespace or parameter
// properties), so Node can run the sources and tests directly.

/** The events a block can be added to. Names match the iOS `CYLLifecycleEvent`. */
const LifecycleEvent = {
  viewDidLoad: 'viewDidLoad',
  viewWillAppear: 'viewWillAppear',
  viewIsAppearing: 'viewIsAppearing',
  viewDidAppear: 'viewDidAppear',
  viewWillLayoutSubviews: 'viewWillLayoutSubviews',
  viewDidLayoutSubviews: 'viewDidLayoutSubviews',
  viewWillDisappear: 'viewWillDisappear',
  viewDidDisappear: 'viewDidDisappear',
  viewSafeAreaInsetsDidChange: 'viewSafeAreaInsetsDidChange',
  viewLayoutMarginsDidChange: 'viewLayoutMarginsDidChange',
  traitCollectionDidChange: 'traitCollectionDidChange',
  viewWillTransition: 'viewWillTransition',
  willMoveToParent: 'willMoveToParent',
  didMoveToParent: 'didMoveToParent',
  didReceiveMemoryWarning: 'didReceiveMemoryWarning',
}         ;

/**
 * When a block runs relative to the platform's own handling. React has no
 * `super` call: the controller fires `beforeSuper` then `afterSuper` back to
 * back at the single moment the platform reports, and `end` only through
 * `performLifecycle` / `invokeLifecycleCallbacks`.
 */
const LifecycleTiming = {
  beforeSuper: 'beforeSuper',
  afterSuper: 'afterSuper',
  end: 'end',
}         ;

const allTimings                             = ['beforeSuper', 'afterSuper', 'end'];

/** What a block can read about the event (iOS `CYLLifecycleInfo`). */

/** A block: the owner, its own identifier and the info. */


module.exports = { LifecycleEvent, LifecycleTiming, allTimings };
