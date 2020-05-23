/*
 * Copyright (C) 2020 Alex James <theracermaster@gmail.com>
 *
 * This file is part of libass.
 *
 * Permission to use, copy, modify, and/or distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 * WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 * ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 * WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 * ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 * OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 */

#include "util.S"

const shorts_zero, align=4
    .rept 8
    .short 0
    .endr
endconst

const shorts_dither0, align=4
    .rept 4
    .short 8, 40
    .endr
endconst

const shorts_dither1, align=4
    .rept 4
    .short 56, 24
    .endr
endconst

/*
 * void ass_stripe_unpack_neon(int16_t *dst, const uint8_t *src, ptrdiff_t src_stride,
 *                             uintptr_t width, uintptr_t height);
 */
function stripe_unpack_neon, export=1
    lsl         x3, x3, #1                  // width *= 2
    add         x3, x3, (vector_size - 1)   // width += vector_size - 1
    and         x3, x3, ~(vector_size - 1)  // width &= ~(vector_size - 1)
    lsr         x5, x3, #1                  // x5 = width >> 1
    mul         x3, x3, x4                  // width *= height
    lsl         x4, x4, #4                  // height *= vector_size
    and         x5, x5, ~(vector_size - 1)  // x5 &= ~(vector_size - 1)
    sub         x3, x3, x4                  // width -= height
    sub         x2, x2, x5                  // src_stride -= x5
    mov         x5, #0                      // x5 = 0
    movi        v2.8h, #1                   // v2 = {1u16} * 8
    b           2f                          // goto row_loop

1:                                          // col_loop
    ldr         q1, [x1]                    // v1 = vld1q_u8(src)
    zip1        v0.16b, v1.16b, v1.16b      // v0 = vzip1q_u8(v1, v1)
    zip2        v1.16b, v1.16b, v1.16b      // v1 = vzip2q_u8(v1, v1)
    ushr        v0.8h, v0.8h, #1            // v0 = vshrq_n_u16(v0, 1)
    ushr        v1.8h, v1.8h, #1            // v1 = vshrq_n_u16(v1, 1)
    add         v0.8h, v0.8h, v2.8h         // v0 = vaddq_u16(v0, v2)
    add         v1.8h, v1.8h, v2.8h         // v1 = vaddq_u16(v1, v2)
    ushr        v0.8h, v0.8h, #1            // v0 = vshrq_n_u16(v0, 1)
    ushr        v1.8h, v1.8h, #1            // v1 = vshrq_n_u16(v1, 1)
    str         q0, [x0, x5]                // vst1q_u16(dst + x5, v0)
    add         x5, x5, x4                  // x5 += height
    str         q1, [x0, x5]                // vst1q_u16(dst + x5, v1)
    add         x5, x5, x4                  // x5 += height
    add         x1, x1, vector_size         // src += vector_size

2:                                          // row_loop
    cmp         x5, x3
    b.lt        1b                          // if (x5 < width) goto col_loop
    sub         x5, x5, x4                  // x5 -= height
    cmp         x5, x3
    b.ge        3f                          // if (x5 >= width) goto skip_odd
    add         x5, x5, x4                  // x5 += height
    ldr         q0, [x1]                    // v0 = vld1q_u8(src)
    zip1        v0.16b, v0.16b, v0.16b      // v0 = vzip1q_u8(v0, v0)
    ushr        v0.8h, v0.8h, #1            // v0 = vshrq_n_u16(v0, 1)
    add         v0.8h, v0.8h, v2.8h         // v0 = vaddq_u16(v0, v2)
    ushr        v0.8h, v0.8h, #1            // v0 = vshrq_n_u16(v0, 1)
    str         q0, [x0, x5]                // vst1q_u16(dst + x5, v0)

3:                                          // skip_odd
    add         x5, x5, vector_size         // x5 += vector_size
    sub         x5, x5, x3                  // x5 -= width
    add         x1, x1, x2                  // src += src_stride
    cmp         x5, x4
    b.lo        2b                          // if (x5 < height) goto row_loop
    ret
endfunc

/*
 * void ass_stripe_pack_neon(uint8_t *dst, ptrdiff_t dst_stride, const int16_t *src,
 *                           uintptr_t width, uintptr_t height);
 */
function stripe_pack_neon, export=1
    lsl         x3, x3, #1                  // width *= 2
    add         x3, x3, (vector_size - 1)   // width += vector_size - 1
    and         x3, x3, ~(vector_size - 1)  // width &= ~(vector_size - 1)
    mov         x5, vector_size             // x5 = vector_size
    mul         x3, x3, x4                  // width *= height
    mul         x6, x1, x4                  // x6 = dst_stride * height
    add         x3, x3, x2                  // width += src
    lsl         x4, x4, #4                  // height *= vector_size
    sub         x5, x5, x6                  // x5 -= x6
    movi        v5.16b, #0                  // v5 = {0u8} * 16
    b           2f                          // goto row_loop

1:                                          // col_loop
    ldr         q0, [x2]                    // v0 = vld1q_u16(src)
    mov         v2.16b, v0.16b              // v2 = v1
    ushr        v2.8h, v2.8h, #8            // v2 = vshrq_n_u16(v2, 8)
    sub         v0.8h, v0.8h, v2.8h         // v0 = vsubq_u16(v0, v2)
    ldr         q1, [x2, x4]                // v1 = vld1q_u16(src + height)
    mov         v2.16b, v1.16b              // v2 = v1
    ushr        v2.8h, v2.8h, #8            // v2 = vshrq_n_u16(v2, 8)
    sub         v1.8h, v1.8h, v2.8h         // v1 = vsubq_u16(v1, v2)
    add         v0.8h, v0.8h, v3.8h         // v0 = vaddq_u16(v0, v3)
    add         v1.8h, v1.8h, v3.8h         // v1 = vaddq_u16(v1, v3)
    ushr        v0.8h, v0.8h, #6            // v0 = vshrq_n_u16(v0, 6)
    ushr        v1.8h, v1.8h, #6            // v1 = vshrq_n_u16(v1, 6)
    sqxtun      v0.8b, v0.8h                // v0 = vqmovun_s16(v0)
    sqxtun2     v0.16b, v1.8h               // v0 = vqmovun_high_s16(v0, v1)
    str         q0, [x0]                    // vst1q_u8(dst, v0)
    mov         v2.16b, v3.16b              // v2 = v3
    mov         v3.16b, v4.16b              // v3 = v4
    mov         v4.16b, v2.16b              // v4 = v2
    add         x2, x2, vector_size         // src += vector_size
    add         x0, x0, x1                  // dst += dst_stride
    cmp         x2, x6
    b.lo        1b                          // if (src < x6) goto col_loop
    add         x0, x0, x5                  // dst += x5
    add         x2, x2, x4                  // src += height

2:                                          // row_loop
    movrel      x7, shorts_dither0
    ldr         q3, [x7]                    // v3 = vld1q_u16(shorts_dither0)
    movrel      x7, shorts_dither1
    ldr         q4, [x7]                    // v4 = vld1q_u16(shorts_dither1)
    add         x6, x2, x4                  // x6 = src + height
    cmp         x6, x3
    b.lo        1b                          // if (x6 < width) goto col_loop
    cmp         x2, x3
    b.lo        3f                          // if (src < width) goto odd_stripe
    ret

3:                                          // odd_stripe
    ldr         q0, [x2]                    // v0 = vld1q_u16(src)
    mov         v2.16b, v0.16b              // v2 = v0
    ushr        v2.8h, v2.8h, #8            // v2 = vshrq_n_u16(v2, 8)
    sub         v0.8h, v0.8h, v2.8h         // v0 = vsubq_u16(v0, v2)
    add         v0.8h, v0.8h, v3.8h         // v0 = vaddq_u16(v0, v3)
    ushr        v0.8h, v0.8h, #6            // v0 = vshrq_n_u16(v0, 6)
    sqxtun      v0.8b, v0.8h                // v0 = vqmovun_s16(v0)
    sqxtun2     v0.16b, v5.8h               // v0 = vqmovun_high_s16(v0, v5)
    str         q0, [x0]                    // vst1q_u8(dst, v0)
    mov         v2.16b, v3.16b              // v2 = v3
    mov         v3.16b, v4.16b              // v3 = v4
    mov         v4.16b, v2.16b              // v4 = v2
    add         x2, x2, vector_size         // src += vector_size
    add         x0, x0, x1                  // dst += dst_stride
    cmp         x2, x6
    b.lo        3b                          // if (src < x6) goto odd_stripe
    ret
endfunc

.macro load_line dst, base, max, zero_offs, offs, tmp
    cmp     \offs, \max
    csel    \tmp, \zero_offs, \offs, CS     // tmp = (offs >= max) : zero_offs ? offs
    ldr     \dst, [\base, \tmp]             // dst = vld1q_u8(base + tmp)
.endm

/*
 * void ass_shrink_vert_neon(int16_t *dst, const int16_t *src,
 *                           uintptr_t src_width, uintptr_t src_height);
 */
function shrink_vert_neon, export=1
    lsl         x2, x2, #1                  // src_width *= 2
    add         x2, x2, (vector_size - 1)   // src_width += vector_size - 1
    add         x5, x3, #5                  // x5 = src_height + 5
    and         x2, x2, ~(vector_size - 1)  // src_width &= ~(vector_size - 1)
    lsr         x5, x5, #1                  // x5 >>= 1
    mul         x2, x2, x5                  // src_width *= x5
    lsl         x3, x3, #4                  // src_height *= vector_size
    add         x2, x2, x0                  // src_width += dst
    movi        v7.8h, #1                   // v7 = {1u16} * 8
    movi        v16.8h, #0x80, lsl #8       // v16 = {0x8000u16} * 8
    movrel      x6, shorts_zero             // x6 = &shorts_zero
    sub         x6, x6, x1                  // x6 -= src

1:                                          // col_loop
    mov         x4, (-4 * vector_size)      // x4 = -4 * vector_size
    movi        v0.16b, #0                  // v0 = {0u8} * 16
    movi        v1.16b, #0                  // v1 = {0u8} * 16
    movi        v2.16b, #0                  // v2 = {0u8} * 16
    movi        v3.16b, #0                  // v3 = {0u8} * 16

2:                                          // row_loop
    add         x8, x4, (4 * vector_size)   // x8 = x4 + (4 * vector_size)
    load_line   q4, x1, x3, x6, x8, x5
    add         x8, x4, (5 * vector_size)   // x8 = x4 + (5 * vector_size)
    load_line   q5, x1, x3, x6, x8, x5
    mov         v6.16b, v16.16b             // v6 = v16
    add         v1.8h, v1.8h, v4.8h         // v1 = vaddq_u16(v1, v4)
    add         v4.8h, v4.8h, v5.8h         // v4 = vaddq_u16(v4, v5)
    and         v6.16b, v6.16b, v0.16b      // v6 = vandq_u8(v6, v0)
    and         v6.16b, v6.16b, v4.16b      // v6 = vandq_u8(v6, v4)
    add         v0.8h, v0.8h, v4.8h         // v0 = vaddq_u16(v0, v4)
    ushr        v0.8h, v0.8h, #1            // v0 = vshrq_n_u16(v0, 1)
    orr         v0.16b, v0.16b, v6.16b      // v0 = vorrq_u8(v0, v6)
    and         v6.16b, v6.16b, v2.16b      // v6 = vandq_u8(v6, v2)
    add         v0.8h, v0.8h, v2.8h         // v0 = vaddq_u16(v0, v2)
    ushr        v0.8h, v0.8h, #1            // v0 = vshrq_n_u16(v0, 1)
    orr         v0.16b, v0.16b, v6.16b      // v0 = vorrq_u8(v0, v6)
    and         v6.16b, v6.16b, v1.16b      // v6 = vandq_u8(v6, v1)
    add         v0.8h, v0.8h, v1.8h         // v0 = vaddq_u16(v0, v1)
    ushr        v0.8h, v0.8h, #1            // v0 = vshrq_n_u16(v0, 1)
    orr         v0.16b, v0.16b, v6.16b      // v0 = vorrq_u8(v0, v6)
    add         v0.8h, v0.8h, v2.8h         // v0 = vaddq_u16(v0, v2)
    ushr        v0.8h, v0.8h, #1            // v0 = vshrq_n_u16(v0, 1)
    orr         v0.16b, v0.16b, v6.16b      // v0 = vorrq_u8(v0, v6)
    add         v0.8h, v0.8h, v7.8h         // v0 = vaddq_u16(v0, v7)
    ushr        v0.8h, v0.8h, #1            // v0 = vshrq_n_u16(v0, 1)
    str         q0, [x0]                    // vst1q_u16(dst, v0)
    add         x4, x4, (2 * vector_size)   // x4 += 2 * vector_size
    add         x0, x0, vector_size         // dst += vector_size
    mov         v0.16b, v2.16b              // v0 = v2
    mov         v1.16b, v3.16b              // v1 = v3
    mov         v2.16b, v4.16b              // v2 = v4
    mov         v3.16b, v5.16b              // v3 = v5
    cmp         x4, x3
    b.lt        2b                          // if (x4 < src_height) goto row_loop
    add         x1, x1, x3                  // src += src_height
    sub         x6, x6, x3                  // x6 -= src_height
    cmp         x0, x2
    b.lo        1b                          // if (dst < src_width) goto col_loop
    ret
endfunc

/*
 * void ass_expand_vert_neon(int16_t *dst, const int16_t *src,
 *                           uintptr_t src_width, uintptr_t src_height);
 */
function expand_vert_neon, export=1
    lsl         x2, x2, #1                  // src_width *= 2
    lsl         x5, x3, #1                  // x5 = x3 * 2
    add         x2, x2, (vector_size - 1)   // src_width += vector_size - 1
    add         x5, x5, #4                  // x5 += 4
    and         x2, x2, ~(vector_size - 1)  // src_width &= ~(vector_size - 1)
    mul         x2, x2, x5                  // src_width *= x5
    lsl         x3, x3, #4                  // src_height *= vector_size
    add         x2, x2, x0                  // src_width += dst
    movi        v4.8h, #1                   // v4 = {1u16} * 8
    movrel      x6, shorts_zero             // x6 = &shorts_zero
    sub         x6, x6, x1                  // x6 -= src

1:                                          // col_loop
    mov         x4, (-2 * vector_size)      // x4 = -2 * vector_size
    movi        v0.16b, #0                  // v0 = {0u8} * 16
    movi        v1.16b, #0                  // v1 = {0u8} * 16

2:                                          // row_loop
    add         x7, x4, (2 * vector_size)   // x7 = x4 + (2 * vector_size)
    load_line   q2, x1, x3, x6, x7, x5
    add         v3.8h, v0.8h, v2.8h         // v3 = vaddq_u16(v0, v2)
    ushr        v3.8h, v3.8h, #1            // v3 = vshrq_n_u16(v3, 1)
    add         v3.8h, v3.8h, v1.8h         // v3 = vaddq_u16(v3, v1)
    ushr        v3.8h, v3.8h, #1            // v3 = vshrq_n_u16(v3, 1)
    add         v0.8h, v0.8h, v3.8h         // v0 = vaddq_u16(v0, v3)
    add         v3.8h, v3.8h, v2.8h         // v3 = vaddq_u16(v3, v2)
    ushr        v0.8h, v0.8h, #1            // v0 = vshrq_n_u16(v0, 1)
    ushr        v3.8h, v3.8h, #1            // v3 = vshrq_n_u16(v3, 1)
    add         v0.8h, v0.8h, v1.8h         // v0 = vaddq_u16(v0, v1)
    add         v3.8h, v3.8h, v1.8h         // v3 = vaddq_u16(v3, v1)
    add         v0.8h, v0.8h, v4.8h         // v0 = vaddq_u16(v0, v4)
    add         v3.8h, v3.8h, v4.8h         // v3 = vaddq_u16(v3, v4)
    ushr        v0.8h, v0.8h, #1            // v0 = vshrq_n_u16(v0, 1)
    ushr        v3.8h, v3.8h, #1            // v3 = vshrq_n_u16(v3, 1)
    str         q0, [x0]                    // vst1q_u16(dst, v0)
    str         q3, [x0, vector_size]       // vst1q_u16(dst + vector_size, v3)
    add         x4, x4, vector_size         // x4 += vector_size
    add         x0, x0, (2 * vector_size)   // dst += 2 * vector_size
    mov         v0.16b, v1.16b              // v0 = v1
    mov         v1.16b, v2.16b              // v1 = v2
    cmp         x4, x3
    b.lt        2b                          // if (x4 < src_height) goto row_loop
    add         x1, x1, x3                  // src += src_height
    sub         x6, x6, x3                  // x6 -= src_height
    cmp         x0, x2
    b.lo        1b                          // if (dst < x2) goto col_loop
    ret
endfunc
