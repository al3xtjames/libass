/*
 * Copyright (C) 2015 Vabishchevich Nikolay <vabnick@gmail.com>
 *
 * This file is part of libass.
 *
 * Permission to use, copy, modify, and distribute this software for any
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



void DECORATE(fill_solid_tile16)(uint8_t *buf, ptrdiff_t stride, int set);
void DECORATE(fill_solid_tile32)(uint8_t *buf, ptrdiff_t stride, int set);
void DECORATE(fill_halfplane_tile16)(uint8_t *buf, ptrdiff_t stride,
                                     int32_t a, int32_t b, int64_t c, int32_t scale);
void DECORATE(fill_halfplane_tile32)(uint8_t *buf, ptrdiff_t stride,
                                     int32_t a, int32_t b, int64_t c, int32_t scale);
void DECORATE(fill_generic_tile16)(uint8_t *buf, ptrdiff_t stride,
                                   const struct segment *line, size_t n_lines,
                                   int winding);
void DECORATE(fill_generic_tile32)(uint8_t *buf, ptrdiff_t stride,
                                   const struct segment *line, size_t n_lines,
                                   int winding);

void DECORATE(add_bitmaps)(uint8_t *dst, intptr_t dst_stride,
                           uint8_t *src, intptr_t src_stride,
                           intptr_t height, intptr_t width);
void DECORATE(sub_bitmaps)(uint8_t *dst, intptr_t dst_stride,
                           uint8_t *src, intptr_t src_stride,
                           intptr_t height, intptr_t width);
void DECORATE(mul_bitmaps)(uint8_t *dst, intptr_t dst_stride,
                           uint8_t *src1, intptr_t src1_stride,
                           uint8_t *src2, intptr_t src2_stride,
                           intptr_t width, intptr_t height);

void DECORATE(be_blur)(uint8_t *buf, intptr_t w, intptr_t h,
                       intptr_t stride, uint16_t *tmp);

void DECORATE(stripe_unpack)(int16_t *dst, const uint8_t *src, ptrdiff_t src_stride,
                             uintptr_t width, uintptr_t height);
void DECORATE(stripe_pack)(uint8_t *dst, ptrdiff_t dst_stride, const int16_t *src,
                           uintptr_t width, uintptr_t height);
void DECORATE(shrink_horz)(int16_t *dst, const int16_t *src,
                           uintptr_t src_width, uintptr_t src_height);
void DECORATE(shrink_vert)(int16_t *dst, const int16_t *src,
                           uintptr_t src_width, uintptr_t src_height);
void DECORATE(expand_horz)(int16_t *dst, const int16_t *src,
                           uintptr_t src_width, uintptr_t src_height);
void DECORATE(expand_vert)(int16_t *dst, const int16_t *src,
                           uintptr_t src_width, uintptr_t src_height);
void DECORATE(pre_blur1_horz)(int16_t *dst, const int16_t *src,
                              uintptr_t src_width, uintptr_t src_height);
void DECORATE(pre_blur1_vert)(int16_t *dst, const int16_t *src,
                              uintptr_t src_width, uintptr_t src_height);
void DECORATE(pre_blur2_horz)(int16_t *dst, const int16_t *src,
                              uintptr_t src_width, uintptr_t src_height);
void DECORATE(pre_blur2_vert)(int16_t *dst, const int16_t *src,
                              uintptr_t src_width, uintptr_t src_height);
void DECORATE(pre_blur3_horz)(int16_t *dst, const int16_t *src,
                              uintptr_t src_width, uintptr_t src_height);
void DECORATE(pre_blur3_vert)(int16_t *dst, const int16_t *src,
                              uintptr_t src_width, uintptr_t src_height);
void DECORATE(blur1234_horz)(int16_t *dst, const int16_t *src,
                             uintptr_t src_width, uintptr_t src_height,
                             const int16_t *param);
void DECORATE(blur1234_vert)(int16_t *dst, const int16_t *src,
                             uintptr_t src_width, uintptr_t src_height,
                             const int16_t *param);
void DECORATE(blur1235_horz)(int16_t *dst, const int16_t *src,
                             uintptr_t src_width, uintptr_t src_height,
                             const int16_t *param);
void DECORATE(blur1235_vert)(int16_t *dst, const int16_t *src,
                             uintptr_t src_width, uintptr_t src_height,
                             const int16_t *param);
void DECORATE(blur1246_horz)(int16_t *dst, const int16_t *src,
                             uintptr_t src_width, uintptr_t src_height,
                             const int16_t *param);
void DECORATE(blur1246_vert)(int16_t *dst, const int16_t *src,
                             uintptr_t src_width, uintptr_t src_height,
                             const int16_t *param);


// TODO: remove this once we finish the remaining blur funcs
#if defined(__aarch64__) && CONFIG_ASM
void ass_stripe_unpack_neon(int16_t *dst, const uint8_t *src, ptrdiff_t src_stride,
                            uintptr_t width, uintptr_t height);
void ass_stripe_pack_neon(uint8_t *dst, ptrdiff_t dst_stride, const int16_t *src,
                          uintptr_t width, uintptr_t height);
void ass_shrink_horz_neon(int16_t *dst, const int16_t *src,
                          uintptr_t src_width, uintptr_t src_height);
void ass_shrink_vert_neon(int16_t *dst, const int16_t *src,
                          uintptr_t src_width, uintptr_t src_height);
void ass_expand_horz_neon(int16_t *dst, const int16_t *src,
                          uintptr_t src_width, uintptr_t src_height);
void ass_expand_vert_neon(int16_t *dst, const int16_t *src,
                          uintptr_t src_width, uintptr_t src_height);
#endif

const BitmapEngine DECORATE(bitmap_engine) = {
    .align_order = ALIGN,

#if CONFIG_LARGE_TILES
    .tile_order = 5,
    .fill_solid = DECORATE(fill_solid_tile32),
    .fill_halfplane = DECORATE(fill_halfplane_tile32),
    .fill_generic = DECORATE(fill_generic_tile32),
#else
    .tile_order = 4,
    .fill_solid = DECORATE(fill_solid_tile16),
    .fill_halfplane = DECORATE(fill_halfplane_tile16),
    .fill_generic = DECORATE(fill_generic_tile16),
#endif

    .add_bitmaps = DECORATE(add_bitmaps),
#ifdef __x86_64__
    .sub_bitmaps = DECORATE(sub_bitmaps),
    .mul_bitmaps = DECORATE(mul_bitmaps),
#else
    .sub_bitmaps = ass_sub_bitmaps_c,
    .mul_bitmaps = ass_mul_bitmaps_c,
#endif

#ifdef __x86_64__
    .be_blur = DECORATE(be_blur),
#else
    .be_blur = ass_be_blur_c,
#endif

// TODO: remove this once we finish the remaining blur funcs
#if defined(__aarch64__) && CONFIG_ASM
    .stripe_unpack = ass_stripe_unpack_neon,
    .stripe_pack = ass_stripe_pack_neon,
    .shrink_horz = ass_shrink_horz_neon,
    .shrink_vert = ass_shrink_vert_neon,
    .expand_horz = ass_expand_horz_neon,
    .expand_vert = ass_expand_vert_neon,
#else
    .stripe_unpack = DECORATE(stripe_unpack),
    .stripe_pack = DECORATE(stripe_pack),
    .shrink_horz = DECORATE(shrink_horz),
    .shrink_vert = DECORATE(shrink_vert),
    .expand_horz = DECORATE(expand_horz),
    .expand_vert = DECORATE(expand_vert),
#endif
    .pre_blur_horz = { DECORATE(pre_blur1_horz), DECORATE(pre_blur2_horz), DECORATE(pre_blur3_horz) },
    .pre_blur_vert = { DECORATE(pre_blur1_vert), DECORATE(pre_blur2_vert), DECORATE(pre_blur3_vert) },
    .main_blur_horz = { DECORATE(blur1234_horz), DECORATE(blur1235_horz), DECORATE(blur1246_horz) },
    .main_blur_vert = { DECORATE(blur1234_vert), DECORATE(blur1235_vert), DECORATE(blur1246_vert) },
};
