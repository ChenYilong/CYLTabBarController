import { AppRegistry } from 'react-native';
import { SafeAreaProvider } from 'react-native-safe-area-context';
import App from './src/App';
import { name as appName } from './app.json';

AppRegistry.registerComponent(appName, () => () => (
  <SafeAreaProvider>
    <App />
  </SafeAreaProvider>
));
