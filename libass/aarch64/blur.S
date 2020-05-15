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
