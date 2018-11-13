INCLUDE "lib/brewbase.inc"

SECTION "Text Services - Graphics Index Utils", ROM0
;Get the location of the window's current tile
;HL = Window structure
;BC = X and Y tile offsets
;Returns HL = Tile pointer
TextServices_GetWindowCursorTile:
    push de
    
    ;M_TextServices_WindowWidth is $0
    ld a, [hl]
    push af
    
    ld de, M_TextServices_WindowBacking + 1
    add hl, de
    ld a, [hli]
    ld h, [hl]
    ld l, a
    
    pop af
    call TextServices_IncrementByTileRows
    ld a, b
    call TextServices_IncrementByTiles
    
    pop de
    ret

;Increment by some number of tiles
;A = Number of tiles
;HL = Current tile pointer
;Returns HL = New tile pointer
TextServices_IncrementByTiles:
    push de
    
    ld e, 0
    sla a
    rl e
    sla a
    rl e
    sla a
    rl e
    sla a
    rl e
    ld d, a
    add hl, de
    
    pop de
    ret

;Increment by some number of tile rows
;A = Number of tiles in a row
;C = Number of rows to increment
;HL = Current tile pointer
;Returns HL = New tile pointer
TextServices_IncrementByTileRows:
    push de
    
    ld e, 0
    sla a
    rl e
    sla a
    rl e
    sla a
    rl e
    sla a
    rl e
    ld d, a
    
.y_mul_loop
    dec c
    jr c, .done_y_mul
    add hl, de
    jr .y_mul_loop
    
.done_y_mul
    pop de
    ret

;Index by a number of glyphs
;B = Glyph width / 8
;C = Glyph height
;DE = Glyph index
;HL = Glyph base pointer
;Returns HL = Individual glyph pointer
TextServices_IndexGlyphs::
    push de
    push hl
    
    ld h, 0
    ld l, 0
    ld d, 0
    ld e, c
    
.glyph_mul_loop
    dec b
    jr c, .done_glyph_mul
    add hl, de
    jr .glyph_mul_loop

.done_glyph_mul
    ld b, h
    ld c, l
    pop hl
    pop de
    
.index_mul_loop
    dec de
    jr c, .done_index_mul
    add hl, bc
    jr .index_mul_loop
    
.done_index_mul
    ret