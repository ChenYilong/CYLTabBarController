/**
 * [EN] android/build.gradle picks its namespace at build time (com.cyl.tabbar when it compiles the local CYLTabBarController
 *      Android sources), which the CLI cannot read, so the package of the React Native classes is given here.
 * [CN] android/build.gradle 在构建时决定 namespace（编译本地 CYLTabBarController Android 源码时为 com.cyl.tabbar），CLI 无法读取，
 *      因此在此给出 React Native 类所在的包名。
 */
module.exports = {
  dependency: {
    platforms: {
      android: {
        packageName: 'com.cyltabbar',
        packageImportPath: 'import com.cyltabbar.CyltabbarViewPackage;',
        packageInstance: 'new CyltabbarViewPackage()',
      },
    },
  },
};
