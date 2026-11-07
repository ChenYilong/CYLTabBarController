// Linux test helper for lower.py: generic subscripts on the GCC runtime. Linux 测试辅助：GCC 运行时下的通用下标。
#import <Foundation/Foundation.h>
static inline id CYLSubGetObj(id c, id k) { return [c objectForKey:k]; }
static inline id CYLSubGetIdx(id c, NSUInteger i) { return [c objectAtIndex:i]; }
#define CYLSubGet(c, k) _Generic((k), int: CYLSubGetIdx, long: CYLSubGetIdx, unsigned long: CYLSubGetIdx, unsigned int: CYLSubGetIdx, default: CYLSubGetObj)((c), (k))
static inline void CYLSubSetObj(id c, id k, id v) { [c setObject:v forKey:k]; }
static inline void CYLSubSetIdx(id c, NSUInteger i, id v) { if (i == [c count]) [c addObject:v]; else [c replaceObjectAtIndex:i withObject:v]; }
#define CYLSubSet(c, k, v) _Generic((k), int: CYLSubSetIdx, long: CYLSubSetIdx, unsigned long: CYLSubSetIdx, unsigned int: CYLSubSetIdx, default: CYLSubSetObj)((c), (k), (v))
