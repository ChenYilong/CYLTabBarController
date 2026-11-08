import {
  codegenNativeComponent,
  type CodegenTypes,
  type HostComponent,
  type ViewProps,
} from 'react-native';

export interface NativeProps extends ViewProps {
  /**
   * The animation file: a URL, a path or a file name in the app (iOS main bundle, Android assets), with its options in
   * the fragment, as `CYLTabBarAnimationURLWithOptions()` writes them ("icons.riv#artboard=CHAT&input=active").
   */
  source?: string;
  /** Plays when true, stops when false. */
  playing?: CodegenTypes.WithDefault<boolean, false>;
}

export default codegenNativeComponent<NativeProps>('CyltabbarAnimationView') as HostComponent<NativeProps>;
