import { useSafeAreaInsets } from 'react-native-safe-area-context';

/** The top safe area (status bar, notch). 顶部安全区（状态栏、刘海）。 */
export function useSafeAreaInsetsTop(): number {
  return useSafeAreaInsets().top;
}
