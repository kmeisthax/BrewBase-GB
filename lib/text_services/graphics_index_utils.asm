INCLUDE "lib/brewbase.inc"

SECTION "Text Services - Graphics Index Utils", ROMX, BANK[1]
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
TextServices_IncrementByTiles::
    push de
    
    ld d, 0
    sla a
    rl d
    sla a
    rl d
    sla a
    rl d
    sla a
    rl d
    ld e, a
    add hl, de
    
    pop de
    ret

;Increment by some number of tile rows
;A = Number of tiles in a row
;C = Number of rows to increment
;HL = Current tile pointer
;Returns HL = New tile pointer
TextServices_IncrementByTileRows::
    push af
    push de
    
    ld d, 0
    sla a
    rl d
    sla a
    rl d
    sla a
    rl d
    sla a
    rl d
    ld e, a
    
    ld a, c
.y_mul_loop
    cp 0
    jr z, .done_y_mul
    dec a
    add hl, de
    jr .y_mul_loop
    
.done_y_mul
    pop de
    pop af
    ret

;Index by a number of glyphs
;B = Glyph width / 8
;C = Glyph height
;DE = Glyph index
;HL = Glyph base pointer
;Returns HL = Individual glyph pointer
;TODO: This returns an offset, not a pointer.
;TODO: The glyph value will almost always be larger than the tile size, can we
;      reverse the order of multiplication for a speedup?
TextServices_IndexGlyphs::
    push af
    push hl
    push de
    
    ld h, 0
    ld l, 0
    ld d, 0
    ld e, c
    
    ld a, b
.glyph_mul_loop
    cp 0
    jr z, .done_glyph_mul
    dec a
    add hl, de
    jr .glyph_mul_loop

.done_glyph_mul
    ld d, h
    ld e, l
    ld hl, 0
    pop bc ;RENAMED: Glyph Index
    
.index_mul_loop
    xor a
    or a, d
    or a, e
    jr z, .add_base_offset
    dec de
    add hl, bc
    jr .index_mul_loop
    
.add_base_offset
    pop bc ;RENAMED: Base pointer
    add hl, bc
    
    pop af
    ret

;Index a metrics table by a number of glyphs
;DE = Glyph index
;HL = Metrics base pointer
;
;Returns HL = Indexed metrics pointer
TextServices_IndexMetrics::
    sla e
    rl d
    sla e
    rl d
    add hl, de
    ret