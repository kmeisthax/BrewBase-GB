INCLUDE "lib/brewbase.inc"

SECTION "Text Services - Tile Composition Memory", WRAM0
TextServices_GlyphCacheArea: ds 8

SECTION "Text Services - Tile Composition", ROM0
;Cache an 8x8 section of a glyph into the GlyphCacheArea.
;Other routines are responsible for actually calculating glyph X/Y
;to vertically align the glyph correctly. We only copy the data. To
;only copy parts of a glyph, you will need to zero out the bits you
;didn't want after the fact.
;
;   B = Number of lines per glyph column (stride)
;   D = Glyph X (bytes / 8 pixel units)
;   E = Glyph Y (lines / 1 pixel units)
;C:HL = Glyph far pointer
; 
; Returns HL = Near part of pointer to end of copied glyph segment.
;   (This should be useful to somebody.)
;
; NOTE: The implementation of this function places an implicit limit of 255
; bytes max length for a single glyph. If you are making fonts this large there
; is probably something terribly wrong with what you are doing.
TextServices_PrepareGlyphForComposition::
    ld a, 0
.x_stride_loop
    dec d
    jr c, .done_x_stride_loop
    add a, b
    jr .x_stride_loop
    
    inc d
    add a, e
    ld e, a
    add hl, de
    ld a, c
    
    ld bc, 8
    ld de, TextServices_GlyphCacheArea
    
    M_System_FarCopy
    ret

;Given a glyph tile and a window tile, compose them together.
;The glyph data must have already been loaded into the GlyphCacheArea.
;
; D = Compose shift
;       (how far to move the glyph tile, may be negative)
; E = Compose color
;       (what 2bpp color should a 1 bit map to?)
;HL = Near pointer to window tile to overwrite
TextServices_ComposeGlyphWithTile:
    push af
    push bc
    
    ld bc, TextServices_GlyphCacheArea
    
    ld a, 8
    push af
    
.compose_loop
    push de
    
    ld a, [bc]
    inc bc
    
    bit 7, d
    jr nz, .negative_shift
    
.positive_shift_loop
    dec d
    jr c, .recolor_1bpp_graphics
    sra a
    jr .positive_shift_loop
    
.negative_shift
    xor a
    sub a, d
    ld d, a
    
.negative_shift_loop
    dec d
    jr c, .recolor_1bpp_graphics
    sra a
    jr .negative_shift_loop
    
.recolor_1bpp_graphics
    push af
    bit 0, e
    jr nz, .low_color_positive
    
.low_color_negative
    cpl
    and a, [hl]
    jr .recolor_1bpp_graphics_hi

.low_color_positive
    ld d, a
    or a, [hl]
    
.recolor_1bpp_graphics_hi
    ld [hli], a
    pop af
    bit 1, e
    jr nz, .hi_color_positive
    
.hi_color_negative
    cpl
    and a, [hl]
    jr .recolor_1bpp_graphics_done

.hi_color_positive
    ld d, a
    or a, [hl]
    
.recolor_1bpp_graphics_done
    ld [hli], a
    pop de
    pop af
    dec a
    jr nz, .compose_loop
    
    pop bc
    pop af
    ret