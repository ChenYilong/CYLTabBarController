/**
 * [EN] FIX: issue #415. The SVGA 2.x decoder (CYLSVGADecoder.ts, pure TypeScript with its own inflate, unit tested with Node)
 *      under the names cyltabbar and the renderer import. `cylLoadSVGAMovie` keeps its asynchronous signature.
 * [CN] FIX: issue #415。SVGA 2.x 解码器（CYLSVGADecoder.ts，纯 TypeScript，自带 inflate，用 Node 做单元测试），以 cyltabbar 与渲染器使用的名称导出。
 *      `cylLoadSVGAMovie` 保持异步签名。
 */
import { CYLSVGAMovie, cylInflateSVGAMovie } from './CYLSVGADecoder';

export {
  CYLSVGALayout, CYLSVGATransform, CYLSVGAColor, CYLSVGAStyle, CYLSVGARect, CYLSVGAEllipse, CYLSVGAShape, CYLSVGAFrame,
  CYLSVGASprite, CYLSVGAMovie, cylDecodeSVGAMovie, cylInflateSVGAMovie
} from './CYLSVGADecoder';

/** [EN] Inflates and decodes the bytes of an .svga file (rejects SVGA 1.x and damaged files). [CN] 解压并解码 .svga 文件的字节。 */
export async function cylLoadSVGAMovie(data: Uint8Array): Promise<CYLSVGAMovie> {
  return cylInflateSVGAMovie(data);
}
