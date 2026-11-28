import { CYLAnimatedItemView, CYLAnimatedItemBackgroundStyle, CYLAnimatedItemCornerRadiusCapsule } from 'cylanimateditem';
import { LengthMetrics } from '@kit.ArkUI';

/**
 * [EN] docs/Animated-Item-Badge-CrossPlatform.md, step H10: badges on tags that are a CYLAnimatedItemView. A tag only passes badgeValue
 *      and badgeAttributes; nothing is stacked on the icon by this page.
 * [CN] docs/Animated-Item-Badge-CrossPlatform.md，步骤 H10：本身为 CYLAnimatedItemView 的 Tag 上的角标。Tag 只传 badgeValue 与
 *      badgeAttributes；本页面不在图标上叠加任何组件。
 */
interface CYLBadgeTagSample {
  value: string;
  animation: string;
  reduce: boolean;
}

// [EN] The first nine badge samples; repeat counts have no attribute key. [CN] 前九个角标示例；重复次数没有对应的属性键。
const CYL_BADGE_TAG_SAMPLES: CYLBadgeTagSample[] = [
  { value: '3', animation: 'Scale', reduce: false },
  { value: '3', animation: 'Shake', reduce: false },
  { value: '3', animation: 'Bounce', reduce: false },
  { value: '', animation: 'Breathe', reduce: false },
  { value: '3', animation: 'Shake', reduce: true },
  { value: 'new', animation: 'RollingOnce', reduce: false },
  { value: '3', animation: 'ScaleOnce', reduce: false },
  { value: '8', animation: 'None', reduce: false },
  { value: '100', animation: 'None', reduce: false },
];

// [EN] The look of the example's tag lists: CollectionViewClassifyMenu's default tag colors and 10 vp spacing, Liquid Glass tags
//      in a section card, tags as wide as their content (as the iOS badge tags).
// [CN] 示例 TagList 的外观：CollectionViewClassifyMenu 的默认标签颜色与 10 vp 间距，分组卡片中的液态玻璃标签，标签宽度随内容自适应（与 iOS 角标标签相同）。
const CYL_BADGE_TAG_SPACING: number = 10;

// [EN] A component, not a @Builder: by-value @Builder parameters do not update when the state changes.
// [CN] 使用组件而非 @Builder：按值传递的 @Builder 参数不会随状态更新。
@Component
struct CYLBadgeTag {
  title: string = '';
  sample?: CYLBadgeTagSample;
  @Prop shows: boolean = false;
  tagId: string = '';

  private attributes(): Record<string, Object> | undefined {
    const sample = this.sample;
    if (sample === undefined) {
      return undefined;
    }
    const attributes: Record<string, Object> = {};
    attributes['animation'] = sample.animation;
    attributes['respectsReduceMotion'] = sample.reduce;
    return attributes;
  }

  build() {
    CYLAnimatedItemView({
      itemTitle: this.title,
      itemId: this.tagId,
      image: $r('app.media.fishpond_normal'),
      iconSize: 30,
      titleColor: $r('app.color.cyl_tag_text'),
      // [EN] The badge is an overlay: the gap keeps the title clear of it, as the iOS tags do. [CN] 角标是浮层：此间距使标题避开角标，与 iOS 的 Tag 相同。
      spacing: 16,
      reservesBadgeSpace: true,
      badgeValue: this.shows ? this.sample?.value : undefined,
      badgeAttributes: this.attributes(),
      sizesToContent: true,
      itemBackgroundStyle: CYLAnimatedItemBackgroundStyle.liquidGlass,
      itemCornerRadius: CYLAnimatedItemCornerRadiusCapsule,
      itemContentHorizontalInset: 10,
    })
  }
}

@Entry
@Component
struct BadgeTags {
  @State shows: boolean = true;

  build() {
    Column({ space: CYL_BADGE_TAG_SPACING }) {
      Row({ space: 8 }) {
        Button('‹ Back').fontSize(13).id('cyl-back').onClick(() => this.getUIContext().getRouter().back())
        Button(this.shows ? 'badgeValue = undefined' : 'badgeValue').fontSize(13).id('cyl-badge-toggle').onClick(() => {
          this.shows = !this.shows;
        })
      }
      Text('Badges')
        .fontSize(17)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('sys.color.font_primary'))
        .padding({ left: 16, top: 6 })
      Scroll() {
        // [EN] Tags flow and wrap, as in a tag list; nothing clips them, so a badge animation may leave its tag.
        // [CN] 标签像 TagList 一样流式换行；不做任何裁剪，角标动画可以超出标签。
        Flex({
          wrap: FlexWrap.Wrap,
          space: { main: LengthMetrics.vp(CYL_BADGE_TAG_SPACING), cross: LengthMetrics.vp(CYL_BADGE_TAG_SPACING) }
        }) {
          ForEach(CYL_BADGE_TAG_SAMPLES, (sample: CYLBadgeTagSample, index: number) => {
            CYLBadgeTag({
              title: `${index + 1}. ${sample.animation}${sample.reduce ? ', Reduce Motion' : ''}`,
              sample: sample,
              shows: this.shows,
              tagId: `cyl-badge-tag-${index + 1}`,
            })
          }, (sample: CYLBadgeTagSample, index: number) => `${index}`)
          CYLBadgeTag({ title: 'badgeValue = undefined', shows: false, tagId: 'cyl-badge-tag-none' })
        }
        .width('100%')
        .padding(14)
        .borderRadius(20)
        // [EN] The section card: Liquid Glass, as the example's tag lists draw it. [CN] 分组卡片：液态玻璃，与示例 TagList 相同。
        .backgroundBlurStyle(BlurStyle.COMPONENT_THIN)
        .border({ width: 0.5, color: '#40FFFFFF', radius: 20 })
      }
      .align(Alignment.Top)
      .layoutWeight(1)
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .height('100%')
    .padding(16)
    // [EN] The gradient plate of the example's tag lists: the glass tags need colors behind them to show. [CN] 示例 TagList 的渐变背景板：玻璃标签需要背后有颜色才能看出来。
    .linearGradient({ angle: 160, colors: [[$r('app.color.cyl_plate_start'), 0], [$r('app.color.cyl_plate_mid'), 0.5], [$r('app.color.cyl_plate_end'), 1]] })
  }
}
