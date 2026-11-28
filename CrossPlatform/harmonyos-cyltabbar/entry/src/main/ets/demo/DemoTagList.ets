import {
  CYLConfiguration, CYLIndexPath, CYLMenuFoldControlKey, CYLMenuStyleKey, CYLTagItemKey, CYLTagListKey, CYLTagListState,
  CYLTagSectionKey
} from '@cyl/classifymenu';
import { DemoRow, DemoSection } from './DemoRows';

/**
 * [EN] The example's sectioned lists are CollectionViewClassifyMenu tag lists (docs/instructions/examples.md): one tag per row
 *      (its title; the subtitle is the long-press callout), a titled header per section, tags as wide as their title, titles
 *      that wrap up to 3 lines, a More / Less control after 3 rows of tags. A tap does what tapping the old row did.
 * [CN] 示例中带分组的列表使用 CollectionViewClassifyMenu 的 TagList（docs/instructions/examples.md）：每行一个 Tag（标题；副标题为长按浮层），
 *      每个分组有标题，Tag 宽度随标题自适应，标题最多换行 3 行，超过 3 行 Tag 后出现 More / Less 控件。点击 Tag 与点击原行效果相同。
 */
export const DEMO_TAG_TITLE_MAX_LINES: number = 3;

export interface DemoTagText {
  title: string;
  subtitle: string;
}

/**
 * [EN] A tag's title is short: what a row's title says in brackets, "(…)" or "（…）", moves behind the row's subtitle (shown on a long press).
 *      A title that is only brackets stays as it is.
 * [CN] Tag 的标题要短：行标题中括号「(…)」或「（…）」里的内容追加到行的副标题之后（长按才显示）。只有括号的标题保持不变。
 */
export function demoTagText(title: string, subtitle: string | undefined): DemoTagText {
  const notes: string[] = [];
  const pattern = /\s*[（(]([^）)]*)[）)]/g;
  let match = pattern.exec(title);
  while (match !== null) {
    const inner = match[1].trim();
    if (inner.length > 0) {
      notes.push(inner);
    }
    match = pattern.exec(title);
  }
  const stripped = title.replace(pattern, '').replace(/\s+/g, ' ').trim();
  if (stripped.length === 0) {
    const kept: DemoTagText = { title: title, subtitle: subtitle ?? '' };
    return kept;
  }
  const parts: string[] = [];
  if (subtitle !== undefined && subtitle.length > 0) {
    parts.push(subtitle);
  }
  notes.forEach((note: string) => parts.push(note));
  const text: DemoTagText = { title: stripped, subtitle: parts.join(' · ') };
  return text;
}
export const DEMO_TAG_VISIBLE_ROWS: number = 3;

/** [EN] The tag list configuration of `sections` (the order of the sections and rows is kept). [CN] `sections` 的 TagList 配置（保持分组与行的顺序）。 */
export function demoTagListConfiguration(sections: DemoSection[]): CYLConfiguration {
  const configuration: CYLConfiguration = {};
  // [EN] `none`: a tap selects nothing but still reports the item, so the host runs the row's action. [CN] `none`：点击不选中，仍回调条目，由宿主执行该行的动作。
  configuration[CYLTagListKey.selectionMode] = 'none';
  configuration[CYLTagListKey.scrollEnabled] = false;
  configuration[CYLTagListKey.longPressAction] = 'callout';
  configuration[CYLTagListKey.defaultVisibleRows] = DEMO_TAG_VISIBLE_ROWS;
  const foldControl: CYLConfiguration = {};
  foldControl[CYLMenuFoldControlKey.position] = 'tail';
  foldControl[CYLMenuFoldControlKey.content] = 'icon';
  configuration[CYLTagListKey.foldControl] = foldControl;
  const style: CYLConfiguration = {};
  style[CYLMenuStyleKey.titleMaxLines] = DEMO_TAG_TITLE_MAX_LINES;
  // [EN] Liquid Glass tags (docs/instructions/examples.md). [CN] 液态玻璃样式的 Tag（docs/instructions/examples.md）。
  style[CYLMenuStyleKey.backgroundStyle] = 'liquidGlass';
  // [EN] The list sits on the page's own grouped background: its default white would hide the (dark mode) header texts. [CN] 列表位于页面自己的分组背景之上：默认的白色会遮住（深色模式下的）标题文字。
  style[CYLMenuStyleKey.backgroundColor] = '#00000000';
  // [EN] The liquid plate: each section is a Liquid Glass card (docs/instructions/examples.md). [CN] 液态背景板：每个分组是一张液态玻璃卡片。
  style[CYLMenuStyleKey.sectionBackgroundStyle] = 'liquidGlass';
  configuration[CYLTagListKey.style] = style;
  const sectionList: CYLConfiguration[] = [];
  sections.forEach((section: DemoSection) => {
    const entry: CYLConfiguration = {};
    entry[CYLTagSectionKey.title] = section.title;
    const items: CYLConfiguration[] = [];
    section.rows.forEach((row: DemoRow) => {
      const item: CYLConfiguration = {};
      item[CYLTagItemKey.identifier] = row.id;
      const text = demoTagText(row.title, row.subtitle);
      item[CYLTagItemKey.title] = text.title;
      if (text.subtitle.length > 0) {
        item[CYLTagItemKey.subtitle] = text.subtitle;
      }
      items.push(item);
    });
    entry[CYLTagSectionKey.items] = items;
    sectionList.push(entry);
  });
  configuration[CYLTagListKey.sections] = sectionList;
  return configuration;
}

/**
 * [EN] One tag list per page. A list is built again when a row's title or subtitle changes (e.g. "当前：海洋" after a skin), and the
 *      sections the user expanded stay expanded.
 * [CN] 每页一个 TagList。行的标题或副标题变化（如换肤后的「当前：海洋」）时重新创建，用户已展开的分组保持展开。
 */
export class DemoTagLists {
  private states: Map<string, CYLTagListState> = new Map<string, CYLTagListState>();
  private signatures: Map<string, string> = new Map<string, string>();
  private rows: Map<string, DemoRow[][]> = new Map<string, DemoRow[][]>();
  /** [EN] Called with the page and the list's content height when it changes. [CN] 内容高度变化时回调（页面，高度）。 */
  onHeight: (page: string, height: number) => void = (page: string, height: number): void => {};

  listFor(page: string, sections: DemoSection[]): CYLTagListState {
    const signature = sections.map((section: DemoSection) =>
      `${section.title}|${section.rows.map((row: DemoRow) => `${row.id}-${row.title}-${row.subtitle ?? ''}`).join('|')}`).join('||');
    const existing = this.states.get(page);
    if (existing !== undefined && this.signatures.get(page) === signature) {
      return existing;
    }
    const state = CYLTagListState.withConfiguration(demoTagListConfiguration(sections));
    const rowsBySection: DemoRow[][] = sections.map((section: DemoSection) => section.rows);
    this.rows.set(page, rowsBySection);
    if (existing !== undefined) {
      for (let section = 0; section < sections.length; section++) {
        if (existing.isSectionExpanded(section)) {
          state.setExpanded(true, section);
        }
      }
    }
    state.menuDelegate = {
      menuDidSelectItem: (menu: Object, indexPath: CYLIndexPath) => {
        const row = this.rows.get(page)?.[indexPath.section]?.[indexPath.item];
        row?.action();
      },
      menuDidChangeContentHeight: (menu: Object, height: number) => this.onHeight(page, height)
    };
    this.states.set(page, state);
    this.signatures.set(page, signature);
    return state;
  }
}
