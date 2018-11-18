INCLUDE "lib/brewbase.inc"

SECTION "Text Services - Tile Composition Memory", WRAM0
TextServices_GlyphCacheArea: ds 8

SECTION "Text Services - Tile Composition", ROM0
;Calculate the vertical shifting parameters for PrepareGlyphForComposition.
;
;NOTE: This does not consider glyph or window metrics such as baseline. Make
;sure to adjust Cursor Y for baseline before computing the shift parameter.
;   
;   B = Top Edge of Glyph (Cursor Y at start of drawing, pixels)
;   C = Glyph Height
;   D = Current Window Cursor Y (Cursor Y at start, current tile Y after, pixels)
; Returns
;   A = Cache mask configuration
;       (hi nybble: Vertical line shift count)
;       (lo nybble: Line copy count)
;   B = Vertical copy start position (relative to glyph)
TextServices_ComputeVerticalShiftingParameters::
    ld a, d
    sub b
    push af ;Store the vertical copy start position
    
    ;Compute how many lines remain in the glyph if we copy from that point
    ld b, a
    ld a, c
    sub a, b
    ld c, a
    
    ;Compute the starting line
    ld a, d
    and $07
    push af
    
    ;Compute the maximum number of remaining lines
    ld d, a
    ld a, 8
    sub a, d
    
    cp c
    jr nc, .glyph_too_short
    jr .compose_cache_mask
    
.glyph_too_short
    ld a, c
    
.compose_cache_mask
    pop bc
    swap b
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
    
    push bc
    
    ld b, a
    xor a
    
.pre_clear_loop
    ld [de], a
    inc de
    dec b
    jr nz, .pre_clear_loop
    
    pop bc
    
.no_line_offset
    pop af
    and $0F
    ld b, a
    ld a, c
    ld c, b
    ld b, 0
    M_System_FarCopy
    
    ;This only works 'cause it's 8 bytes
    ld a, (TextServices_GlyphCacheArea + 8) & $FF
    sub a, e
    jr z, .exit
    
    ld b, a
    xor a
.post_clear_loop
    ld [de], a
    inc de
    dec b
    jr nz, .post_clear_loop
    
.exit
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
.compose_loop
    push af
    push de
    
    ld a, [bc]
    inc bc
    
    ;TODO: Find a better way to test for zero without clobbering all our shit
    dec d
    inc d
    jr z, .recolor_1bpp_graphics
    
    bit 7, d
    jr nz, .negative_shift
    
.positive_shift_loop
    srl a
    dec d
    jr nz, .positive_shift_loop
    jr .recolor_1bpp_graphics
    
.negative_shift
    push af
    xor a
    sub a, d
    ld d, a
    pop af
    
.negative_shift_loop
    sla a
    dec d
    jr nz, .negative_shift_loop
    
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