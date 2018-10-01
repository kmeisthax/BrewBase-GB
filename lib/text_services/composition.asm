INCLUDE "lib/brewbase.inc"

SECTION "Text Services - Tile Composition Memory", WRAM0
TextServices_GlyphCacheArea: ds 8

SECTION "Text Services - Tile Composition", ROM0
;Given a glyph tile and a window tile, compose them together.
;The glyph data must have already been loaded into the GlyphCacheArea.
;
;D = Compose shift
;    (how far to move the glyph tile, may be negative)
;E = Compose color
;    (what 2bpp color should a 1 bit map to?)
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
    pop de
    pop af
    dec a
    jr nz, .compose_loop
    
    pop bc
    pop af
    ret