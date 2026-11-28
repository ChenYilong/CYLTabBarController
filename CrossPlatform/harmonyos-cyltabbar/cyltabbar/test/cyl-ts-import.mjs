// [EN] Registers cyl-ts-resolve.mjs; a test imports this first, then the module under test with a dynamic import().
// [CN] 注册 cyl-ts-resolve.mjs；测试先导入本文件，再用动态 import() 导入被测模块。
import { register } from 'node:module';

register('./cyl-ts-resolve.mjs', import.meta.url);
