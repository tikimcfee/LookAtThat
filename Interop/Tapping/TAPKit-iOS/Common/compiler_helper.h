/*
 * compiler_helper.h
 *
 *  Created on: Jun 27, 2017
 *      Author: Me
 */

#ifndef COMPILER_HELPER_H_
#define COMPILER_HELPER_H_

#ifdef __cplusplus
extern "C"
{
#endif

//GCC
#ifdef __GNUC__
#define PACKED_STRUCT_TYPEDEF_BEGIN(st) typedef struct __attribute__((packed))
#define PACKED_STRUCT_TYPEDEF_END(st) st
#endif

//IAR
#ifdef __ICCARM__
#define PACKED_STRUCT_TYPEDEF_BEGIN(st) typedef __packed struct
#define PACKED_STRUCT_TYPEDEF_END(st) st
#endif

//CLANG
#ifdef __llvm__
#define PACKED_STRUCT_TYPEDEF_BEGIN(st) typedef struct __attribute__((packed))
#define PACKED_STRUCT_TYPEDEF_END(st) st
#endif

#ifndef PACKED_STRUCT_TYPEDEF_BEGIN
#error "Compiler not detected"
#endif

#ifdef __cplusplus
}
#endif

#endif /* COMPILER_HELPER_H_ */
