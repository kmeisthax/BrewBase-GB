INCLUDE "lib/brewbase.inc"

SECTION "Text Services - Tile Composition Memory", WRAM0
TextServices_GlyphCacheArea: ds 8

SECTION "Text Services - Tile Composition", ROM0
;Calculate the vertical shifting parameters for PrepareGlyphForComposition.
;
;NOTE: This does not consider glyph or window metrics such as baseline. Make
;sure to adjust Cursor Y for baseline before computing the shift parameter.
;   
;   B = Top Edge of Glyph (Cursor Y at start of drawing)
;   C = Glyph Height
;   D = Current Window Cursor Y (Cursor Y at start, current tile Y after)
; Returns
;   A = Cache mask configuration
;       (hi nybble: Vertical line shift count)
;       (lo nybble: Line copy count)
;   B = Vertical copy start position (relative to glyph)
TextServices_ComputeVerticalShiftingParameters::
    ld a, c
    sub b
    push af ;Store the vertical copy start position
    
    xor a
    add a, b
    add a, c
    sub a, d
    cp 8
    jr nc, .no_max_8
    
.max_8
    ld a, 8
    
.no_max_8
    push af ;Store the maximum tile line count as bounded by the bottom edge.
    
    ld a, d
    and $07
    swap a
    pop bc
    or a, b
    
    pop bc
    
    ret

;Cache an 8x8 section of a glyph into the GlyphCacheArea.
;Other routines are responsible for actually calculating glyph X/Y
;to vertically align the glyph correctly. We only copy the data.
;
;   A = Cache mask configuration.
;       
;       Allows us to shift and mask the cache for when we need to draw less
;       than a full tile.
;       
;       (Upper bits) How many lines down we start from.
;                    
;                    To be used in the case where we are drawing to the top of
;                    a row which does not align to tile boundaries.
;                    
;                    Must not exceed 7. Default is 0.
;                    
;       (Lower bits) Number of lines to copy in total.
;                    
;                    To be used in the case where we are drawing to the bottom
;                    of a row which does not align to tile boundaries.
;                    
;                    Must not contain a value which would cause us to write
;                    outside of the cache area. The bound is equal to 8 minus
;                    the upper value. Default is 8.
;   B = Height of each glyph (aka stride)
;   D = Glyph X (bytes / 8 pixel units)
;       
;       How many tiles in the glyph to load from.
;       
;   E = Glyph Y (lines / 1 pixel units)
;       
;       How many lines down in the glyph to load from.
;C:HL = Glyph far pointer
; 
; Returns HL = Near part of pointer to end of copied glyph segment.
;   (This should be useful to somebody.)
;
; NOTE: The implementation of this function places an implicit limit of 255
; bytes max length for a single glyph. If you are making fonts this large there
; is probably something terribly wrong with what you are doing.
TextServices_PrepareGlyphForComposition::
    push af
    push af
    
    ld a, 0
.x_stride_loop
    dec d
    jr c, .done_x_stride_loop
    add a, b
    jr .x_stride_loop
    
.done_x_stride_loop
    inc d ;this will always be zero, because the above loop counted to $FF
    add a, e
    ld e, a
    add hl, de
    
    pop af
    and $70
    swap a
    
    ld de, TextServices_GlyphCacheArea
    or a
    jr z, .no_line_offset
    
    add a, e
    ld e, a
    jr nc, .no_line_offset
    inc d
    
.no_line_offset
    pop af
    and $0F
    ld b, a
    ld a, c
    ld c, b
    ld b, 0
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
TextServices_ComposeGlyphWithTile::
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