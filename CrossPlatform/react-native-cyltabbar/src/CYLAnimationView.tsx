import { forwardRef } from 'react';
import type { CYLAnimationViewHandle, CYLAnimationViewProps } from './CYLAnimationView.native';

export const CYLAnimationView = forwardRef<CYLAnimationViewHandle, CYLAnimationViewProps>(function CYLAnimationView(): never {
  throw new Error("'react-native-cyltabbar' is only supported on iOS and Android.");
});
export { animationURLWithOptions } from './CYLAnimationView.native';
