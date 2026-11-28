import { taskpool } from '@kit.ArkTS';
import {
  CYLLocalizedString, CYLTabBarConfiguration, CYLTabBarConfigurationParser,
  CYLTabBarConfigurationError, CYLTabBarConfigurationResult
} from 'cyltabbar';

/**
 * [EN] Item 44: configuration file, simulated failures (iOS CYLConfigurationEdgeCasesViewController, Android
 *      DemoConfiguration.edgeCases): each case feeds a broken or unusual configuration to the parser and shows what
 *      happened: a typed error (CYLTabBarConfigurationErrorDomain code and message) or the tab bar created safely
 *      (tab count, identifiers). Nothing may crash. The case IDs are those of iOS and Android (A2–E1).
 * [CN] 第 44 项：配置文件模拟意外情况：每个用例把损坏或异常的配置交给解析器，显示结果：带错误码与说明的错误，或安全创建的 TabBar
 *      （Tab 数量、标识）。不能崩溃。用例编号与 iOS、Android 相同（A2–E1）。
 */
interface CYLFailureCase {
  id: string;
  title: string;
  /** [EN] The file name (its extension picks the format), or '' for a raw file that does not exist. [CN] 文件名（扩展名决定格式）。 */
  file: string;
  text: string;
}

interface CYLFailureResult {
  id: string;
  title: string;
  outcome: string;
  ok: boolean;
}

const TABS: string = '"CYLTabBarControllerTabBarItemsAttributes": [{"CYLTabBarItemTitle": "Home", "CYLTabBarItemIdentifier": "home"}]';

function cylCases(): CYLFailureCase[] {
  return [
    { id: 'A2', title: 'Missing file', file: '', text: '' },
    { id: 'A3', title: 'Empty file', file: 'empty.json', text: '' },
    { id: 'A4', title: 'Comments only', file: 'comments.yaml', text: '# nothing but comments\n' },
    { id: 'A7', title: 'YAML in a .json file', file: 'yaml.json', text: 'CYLTabBarControllerTabBarItemsAttributes:\n  - CYLTabBarItemTitle: Home\n' },
    { id: 'A9', title: 'A 6 MB file', file: 'huge.json', text: ' '.repeat(6 * 1024 * 1024) },
    { id: 'A10', title: 'Nested 10,000 levels', file: 'deep.json', text: `{"CYLTabBarControllerTabBarItemsAttributes": ${'['.repeat(10000)}${']'.repeat(10000)}}` },
    { id: 'A11', title: 'Top level is a list', file: 'list.json', text: `[{${TABS}}]` },
    { id: 'A13', title: 'Malformed JSON', file: 'malformed.json', text: '{"CYLTabBarControllerTabBarItemsAttributes": [ {"CYLTabBarItemTitle": "Home" ' },
    { id: 'A14', title: 'XML external entity', file: 'xxe.xml', text: '<?xml version="1.0"?>\n<!DOCTYPE r [<!ENTITY xxe SYSTEM "file:///etc/passwd">]>\n<r><CYLTabBarControllerContext>&xxe;</CYLTabBarControllerContext></r>' },
    { id: 'B1', title: 'No tabs', file: 'no_tabs.json', text: '{"CYLTabBarControllerContext": "NoTabs"}' },
    { id: 'B5', title: 'Wrong types and null', file: 'types.json', text: '{"CYLTabBarControllerContext": [1, 2], "CYLTabBarControllerTabBarItemsAttributes": [{"CYLTabBarItemTitle": ["a", "list"], "CYLTabBarItemIdentifier": null}, null, 7, {"CYLTabBarItemTitle": "Home", "CYLTabBarItemIdentifier": "home"}]}' },
    { id: 'B7', title: 'NaN and Infinity insets', file: 'nan.json5', text: '{CYLTabBarControllerTitlePositionAdjustment: [Infinity, NaN], ' + TABS + '}' },
    { id: 'B9', title: 'Unknown style', file: 'style.json', text: `{"CYLTabBarControllerStyleType": 99, ${TABS}}` },
    { id: 'B11', title: 'Misspelled keys', file: 'typos.json', text: '{"CYLTabBarControllerContxt": "typo", "CYLTabBarControllerTabBarItemsAttributes": [{"CYLTabBarItemTitel": "Typo", "CYLTabBarItemTitle": "Home", "CYLTabBarItemIdentifier": "home"}]}' },
    { id: 'B12', title: 'Duplicate identifiers', file: 'ids.json', text: '{"CYLTabBarControllerTabBarItemsAttributes": [{"CYLTabBarItemTitle": "A", "CYLTabBarItemIdentifier": "tab"}, {"CYLTabBarItemTitle": "B", "CYLTabBarItemIdentifier": "tab"}]}' },
    { id: 'B13', title: 'Invalid URLs and Lottie files', file: 'urls.json', text: '{"CYLTabBarControllerTabBarItemsAttributes": [{"CYLTabBarItemTitle": "Home", "CYLTabBarItemIdentifier": "home", "CYLTabBarItemImageURL": "ht tp://bad url", "CYLTabBarLottieFilePath": "missing.json"}]}' },
    { id: 'B19', title: 'Invalid colors and fonts', file: 'colors.json', text: '{"CYLTabBarControllerTintColor": "#GGHHII", "CYLTabBarControllerTabBarItemsAttributes": [{"CYLTabBarItemTitle": "Home", "CYLTabBarItemIdentifier": "home", "CYLTabBarItemTitleColor": "notacolor"}]}' },
    { id: 'B21', title: 'Empty strings', file: 'empty_strings.json', text: '{"CYLTabBarControllerTabBarItemsAttributes": [{"CYLTabBarItemTitle": "", "CYLTabBarItemImage": "", "CYLTabBarLottieFilePath": "", "CYLTabBarItemIdentifier": ""}]}' },
    { id: 'B22', title: 'Other platforms and newer versions', file: 'platforms.json', text: '{"CYLTabBarControllerTabBarItemsAttributes": [{"CYLTabBarItemTitle": "Home", "CYLTabBarItemIdentifier": "home"}, {"CYLTabBarItemTitle": "iOS only", "CYLTabBarItemIdentifier": "ios", "CYLTabBarItemPlatforms": "ios"}, {"CYLTabBarItemTitle": "Next version", "CYLTabBarItemIdentifier": "next", "CYLTabBarItemMinimumAppVersion": "99.0"}]}' },
    { id: 'D7', title: 'An HTML page (file)', file: 'portal.xml', text: '<html><head><title>Wi-Fi</title></head><body><form>Accept</form></body></html>' },
  ];
}

/** [EN] One case: parse, then build the tab bar; a typed error or a summary. [CN] 一个用例：解析并创建 TabBar；返回错误或摘要。 */
function cylRun(context: Context, item: CYLFailureCase): CYLFailureResult {
  try {
    const configuration = item.file.length === 0
      ? CYLTabBarConfiguration.configurationWithRawFile(context, 'configurations/does_not_exist.json')
      : CYLTabBarConfigurationParser.configurationWithString(item.text,
        CYLTabBarConfigurationParser.formatForPathExtension(item.file.substring(item.file.lastIndexOf('.') + 1)));
    const result: CYLTabBarConfigurationResult = CYLTabBarConfiguration.resultWithConfiguration(configuration, '1.0.0', false);
    const ids = result.items.map((tab) => tab.identifier).join(', ');
    return { id: item.id, title: item.title, ok: true,
      outcome: CYLLocalizedString('已安全创建 TabBarController：%@ 个 Tab', result.items.length) + ` (${ids})` };
  } catch (error) {
    const failure = error as CYLTabBarConfigurationError;
    return { id: item.id, title: item.title, ok: false,
      outcome: `${failure.domain ?? 'Error'} ${failure.code ?? ''}: ${failure.message}` };
  }
}

/**
 * [EN] E1: parses on a background thread (taskpool); only the parse runs there, the tab bar is made on the UI thread.
 * [CN] E1：在后台线程（taskpool）解析；只有解析在后台，TabBar 在 UI 线程创建。
 */
@Concurrent
function cylParseInBackground(text: string): number {
  const configuration = JSON.parse(text) as Record<string, Object>;
  const tabs = configuration['CYLTabBarControllerTabBarItemsAttributes'] as Object[];
  return tabs.length;
}

@Entry
@Component
struct ConfigurationFailures {
  @State results: CYLFailureResult[] = [];

  aboutToAppear(): void {
    const context = this.getUIContext().getHostContext() as Context;
    this.results = cylCases().map((item: CYLFailureCase) => cylRun(context, item));
    taskpool.execute(cylParseInBackground, `{${TABS}}`).then((count: Object) => {
      const background: CYLFailureResult = { id: 'E1', title: 'Created on a background thread', ok: true,
        outcome: CYLLocalizedString('已安全创建 TabBarController：%@ 个 Tab', count as number) + ' (taskpool parse, UI thread tab bar)' };
      this.results = this.results.concat([background]);
    }).catch((error: Error) => {
      const background: CYLFailureResult = { id: 'E1', title: 'Created on a background thread', ok: false, outcome: error.message };
      this.results = this.results.concat([background]);
    });
  }

  build() {
    Column() {
      Row() {
        Text('‹ ' + CYLLocalizedString('Back'))
          .fontSize(16)
          .fontColor('#007AFF')
          .id('cyl-back')
          .onClick(() => this.getUIContext().getRouter().back())
        Text(CYLLocalizedString('配置文件：模拟意外情况'))
          .fontSize(17)
          .fontWeight(FontWeight.Medium)

          // One line, ending with an ellipsis (UINavigationBar): long titles wrapped to two lines.

          .maxLines(1)

          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .layoutWeight(1)
          // [EN] One line: long titles shrink to 12 fp, then end with an ellipsis (issue list #26). [CN] 单行：长标题缩小到 12 fp，再以省略号结尾（问题 #26）。
          .maxLines(1)
          .minFontSize(12)
          .maxFontSize(17)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .textAlign(TextAlign.Center)
          .margin({ right: 52 })
      }
      .height(44)
      .width('100%')
      .padding({ left: 12 })
      .backgroundColor($r('app.color.cyl_bar_background'))

      List() {
        ForEach(this.results, (result: CYLFailureResult) => {
          ListItem() {
            Column() {
              Text(`${result.id}. ${result.title}`)
                .fontSize(15)
                .fontColor($r('app.color.cyl_label'))
              Text(result.outcome)
                .fontSize(12)
                .fontColor(result.ok ? '#34C759' : '#FF9500')
                .margin({ top: 3 })
                .maxLines(3)
            }
            .alignItems(HorizontalAlign.Start)
            .width('100%')
            .padding({ left: 16, right: 16, top: 8, bottom: 8 })
            .backgroundColor($r('app.color.cyl_row_background'))
            .accessibilityGroup(true)
            .accessibilityText(`${result.id}. ${result.title}`)
            .accessibilityDescription(result.outcome)
            .id(`cyl-row-failure-${result.id}`)
          }
        }, (result: CYLFailureResult) => result.id)
      }
      .divider({ strokeWidth: 0.5, color: '#E5E5E5', startMargin: 16 })
      .layoutWeight(1)
      .contentEndOffset(40)
      .backgroundColor($r('app.color.cyl_grouped_background'))
    }
    .width('100%')
    .height('100%')
  }
}
