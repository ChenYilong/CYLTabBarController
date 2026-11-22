/**
 * [EN] When `CYLRiveIcon` repeats a pass while its `loops` is on (pure logic, unit tested with Node:
 *      test/CYLRiveLoopPolicy.test.mjs). `WhileSelected` is the tab bar's meaning: only while the tab is selected (the
 *      default, so the tab bar is unchanged). `WhilePlaying` is the meaning for tags, placeholders and any other
 *      CYLAnimatedItemView: from the first play, selected or not, until `loops` goes off or the item is unselected after it was
 *      selected; a restart asks for a play again. Like the WeChat Mini Program's `cyl-rive` `loop`: turning it on plays at
 *      once, turning it off lets the pass playing finish.
 * [CN] `CYLRiveIcon` 在 `loops` 开启时何时重复播放（纯逻辑，用 Node 做单元测试：test/CYLRiveLoopPolicy.test.mjs）。`WhileSelected` 是 Tab 栏的含义：
 *      仅在 Tab 选中期间循环（默认，因此 Tab 栏不变）。`WhilePlaying` 用于标签、占位图和其他 CYLAnimatedItemView：从第一次播放起，无论是否选中，
 *      直到 `loops` 关闭，或条目在被选中之后又取消选中；重播即再次请求播放。与微信小程序 `cyl-rive` 的 `loop` 一致：打开立即播放，关闭则让正在播放的一遍播完。
 */
export class CYLRiveLoopPolicy {
  /** [EN] Loops only while selected (the tab bar, the default). [CN] 仅在选中期间循环（Tab 栏，默认）。 */
  static readonly WhileSelected: string = 'whileSelected';
  /** [EN] Loops from the first play until stopped (tags, placeholders). [CN] 从第一次播放起循环，直到停止（标签、占位图）。 */
  static readonly WhilePlaying: string = 'whilePlaying';
  /** [EN] `updateAction` result: start a pass. [CN] `updateAction` 的结果：开始一遍播放。 */
  static readonly Play: string = 'play';
  /** [EN] `updateAction` result: stop. [CN] `updateAction` 的结果：停止。 */
  static readonly Stop: string = 'stop';
  /** [EN] `updateAction` result: leave it as it is. [CN] `updateAction` 的结果：保持不变。 */
  static readonly None: string = 'none';

  /**
   * [EN] Whether the view may play and loop now: selected, or (WhilePlaying) not stopped.
   * [CN] 视图现在是否可以播放与循环：已选中，或（WhilePlaying）未被停止。
   */
  static isActive(policy: string, selected: boolean, stopRequested: boolean): boolean {
    return selected || (policy === CYLRiveLoopPolicy.WhilePlaying && !stopRequested);
  }

  /**
   * [EN] Whether a finished pass schedules the next one: `loops` on and the view active.
   * [CN] 一遍播放结束后是否安排下一遍：`loops` 开启且视图处于活动状态。
   */
  static schedulesNextPass(policy: string, loops: boolean, selected: boolean, stopRequested: boolean): boolean {
    return loops && CYLRiveLoopPolicy.isActive(policy, selected, stopRequested);
  }

  /**
   * [EN] What a load or a `selected` change does: selected plays; unselected stops, except a WhilePlaying item that was never
   *      selected (a tag), which plays unless it was stopped.
   * [CN] 加载或 `selected` 变化时做什么：选中则播放；未选中则停止，但从未被选中的 WhilePlaying 条目（标签）除外，它会播放，除非已被停止。
   */
  static updateAction(policy: string, selected: boolean, wasSelected: boolean, stopRequested: boolean): string {
    if (selected) {
      return CYLRiveLoopPolicy.Play;
    }
    if (policy === CYLRiveLoopPolicy.WhilePlaying && !wasSelected) {
      return stopRequested ? CYLRiveLoopPolicy.None : CYLRiveLoopPolicy.Play;
    }
    return CYLRiveLoopPolicy.Stop;
  }
}
