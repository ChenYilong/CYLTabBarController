/**
 * [EN] FIX: issue #415. The SVGA 2.x decoder moved to CYLTabBarController's component (cylanimateditem,
 *      `src/main/ets/svga/CYLSVGAMovie.ets`, the SVGA engine `CYLAnimatedItemSVGA`); re-exported here so cyltabbar's API is unchanged.
 * [CN] FIX: issue #415。SVGA 2.x 解码器已移入组件 cylanimateditem（SVGA 引擎 `CYLAnimatedItemSVGA`）；此处重新导出，cyltabbar 的接口不变。
 */
export {
  CYLSVGALayout, CYLSVGATransform, CYLSVGAColor, CYLSVGAStyle, CYLSVGARect, CYLSVGAEllipse, CYLSVGAShape, CYLSVGAFrame,
  CYLSVGASprite, CYLSVGAMovie, cylDecodeSVGAMovie, cylLoadSVGAMovie
} from 'cylanimateditem';
