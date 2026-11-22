// Only erasable TypeScript syntax (no enum, namespace or parameter
// properties), so Node can run the sources and tests directly.

/** The events a block can be added to. Names match the iOS `CYLLifecycleEvent`. */
export const LifecycleEvent = {
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
} as const;
export type LifecycleEvent = (typeof LifecycleEvent)[keyof typeof LifecycleEvent];

/**
 * When a block runs relative to the platform's own handling. React has no
 * `super` call: the controller fires `beforeSuper` then `afterSuper` back to
 * back at the single moment the platform reports, and `end` only through
 * `performLifecycle` / `invokeLifecycleCallbacks`.
 */
export const LifecycleTiming = {
  beforeSuper: 'beforeSuper',
  afterSuper: 'afterSuper',
  end: 'end',
} as const;
export type LifecycleTiming = (typeof LifecycleTiming)[keyof typeof LifecycleTiming];

export const allTimings: readonly LifecycleTiming[] = ['beforeSuper', 'afterSuper', 'end'];

export interface Insets {
  top: number;
  left: number;
  bottom: number;
  right: number;
}

/** What a block can read about the event (iOS `CYLLifecycleInfo`). */
export interface LifecycleInfo {
  event: LifecycleEvent | null;
  timing: LifecycleTiming;
  /** Appearance events: the navigation transition is animated. */
  animated?: boolean;
  /** `viewWillTransition`: the new window size. */
  size?: { width: number; height: number };
  /** `traitCollectionDidChange`: the values before the change. */
  previousColorScheme?: string | null;
  previousFontScale?: number;
  /** `viewSafeAreaInsetsDidChange`: the insets before the change. */
  previousInsets?: Insets;
  /** `willMoveToParent` / `didMoveToParent`: attached to (true) or detached from (false) the tree. */
  parentAttached?: boolean;
  /** True for the block of a teardown. */
  isDealloc?: boolean;
}

/** A block: the owner, its own identifier and the info. */
export type LifecycleCallback<T> = (owner: T, identifier: number, info: LifecycleInfo) => void;
