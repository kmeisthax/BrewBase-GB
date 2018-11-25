INCLUDE "lib/brewbase.inc"

SECTION "Text Services - Draw Letter Main Routine Memory", WRAM0
W_TextServices_FontHeaderCache: ds M_TextServices_FontSize

W_TextServices_CurrentVerticalCursor: ds 1
W_TextServices_StartingVerticalCursor: ds 1
W_TextServices_CurrentCacheMask: ds 1
W_TextServices_CurrentVerticalGlyphPosition: ds 1
W_TextServices_CurrentHorizontalTile: ds 1
W_TextServices_CurrentHorizontalShift: ds 1
W_TextServices_CurrentWindowTile: ds 3
W_TextServices_RowStartingTile: ds 2
W_TextServices_CurrentGlyphBase: ds 3

SECTION "Text Services - Draw Letter Main Routine", ROMX, BANK[1]
;Draw a glyph to a window.
;
;BC = Letter to draw
;HL = Near pointer to window structure
TextServices_DrawGlyphToWindow::
    push af
    push de
    push hl
    push bc
    
    ;Get the glyph pointer
    ld de, M_TextServices_WindowFont
    add hl, de
    ld a, [hli]
    ld b, a
    ld a, [hli]
    ld h, [hl]
    ld l, a
    
    ld a, b
    ld bc, M_TextServices_FontSize
    ld de, W_TextServices_FontHeaderCache
    M_System_FarCopy
    
    ld hl, W_TextServices_FontHeaderCache + M_TextServices_FontGlyphData
    ld a, [hli]
    ld d, a
    ld a, [hli]
    ld h, [hl]
    ld l, a
    
    pop bc
    ld a, [W_TextServices_FontHeaderCache + M_TextServices_FontGlyphCount + 1]
    cp b
    jr c, .out_of_bounds
    jr z, .compare_lower_bits
    jr .bounds_check_pass
    
.compare_lower_bits
    ld a, [W_TextServices_FontHeaderCache + M_TextServices_FontGlyphCount]
    cp c
    jr nc, .bounds_check_pass
    
.out_of_bounds
    ld bc, 0
    
.bounds_check_pass
    ld d, b
    ld e, c
    ld hl, W_TextServices_FontHeaderCache + M_TextServices_FontGlyphWidth
    ld a, [hli]
    ld b, a
    ld c, [hl]
    ld hl, W_TextServices_FontHeaderCache + M_TextServices_FontGlyphData + 1
    ld a, [hli]
    ld h, [hl]
    ld l, a
    call TextServices_IndexGlyphs
    
    ld a, [W_TextServices_FontHeaderCache + M_TextServices_FontGlyphData]
    ld [W_TextServices_CurrentGlyphBase], a
    ld a, l
    ld [W_TextServices_CurrentGlyphBase + 1], a
    ld a, h
    ld [W_TextServices_CurrentGlyphBase + 2], a
    
    ;Initial setup of the vertical parameters
    pop de
    push de
    ld hl, M_TextServices_WindowBacking
    add hl, de
    ld a, [hli]
    ld [W_TextServices_CurrentWindowTile], a
    
    pop de
    push de
    ld hl, M_TextServices_WindowCursor
    add hl, de
    ld a, [hli]
    ld [W_TextServices_CurrentWindowTile + 1], a
    ld [W_TextServices_RowStartingTile + 0], a
    ld a, [hli]
    ld [W_TextServices_CurrentWindowTile + 2], a
    ld [W_TextServices_RowStartingTile + 1], a
    
    pop de
    push de
    ld hl, M_TextServices_WindowCursorY
    add hl, de
    ld a, [hl]
    sla a
    sla a
    sla a
    
    pop de
    push de
    ld hl, M_TextServices_WindowShiftY
    add hl, de
    or [hl]
    ld [W_TextServices_StartingVerticalCursor], a
    ld [W_TextServices_CurrentVerticalCursor], a
    
    pop de
    push de
    ld hl, M_TextServices_WindowShiftX
    add hl, de
    ld a, [hl]
    ld [W_TextServices_CurrentHorizontalShift], a
    
.row_loop
    ld a, [W_TextServices_StartingVerticalCursor]
    ld b, a
    ld a, [W_TextServices_FontHeaderCache + M_TextServices_FontGlyphHeight]
    ld c, a
    ld a, [W_TextServices_CurrentVerticalCursor]
    ld d, a
    call TextServices_ComputeVerticalShiftingParameters
    ld [W_TextServices_CurrentCacheMask], a
    ld a, b
    ld [W_TextServices_CurrentVerticalGlyphPosition], a
    
    xor a
    ld [W_TextServices_CurrentHorizontalTile], a
    jr .first_horizontal_tile
    
.tile_loop
    ld a, [W_TextServices_CurrentHorizontalShift]
    cp 0
    jr z, .no_horizontal_glyph_overhang
    
.has_horizontal_glyph_overhang
    ld d, a
    ld a, 8
    sub a, d
    cpl
    inc a
    ld d, a
    ld e, 3 ;TODO: Pull the text window color
    
    ;TODO: VRAM banking.
    ld a, [W_TextServices_CurrentWindowTile + 1]
    ld l, a
    ld a, [W_TextServices_CurrentWindowTile + 2]
    ld h, a
    
    call TextServices_ComposeGlyphWithTile
    
.no_horizontal_glyph_overhang
    ld a, [W_TextServices_CurrentHorizontalTile]
    inc a
    ld [W_TextServices_CurrentHorizontalTile], a
    
.first_horizontal_tile
    ld a, [W_TextServices_FontHeaderCache + M_TextServices_FontGlyphWidth]
    ld b, a
    ld a, [W_TextServices_CurrentHorizontalTile]
    cp b
    jr z, .exit_tile_loop
    
    ld a, [W_TextServices_FontHeaderCache + M_TextServices_FontGlyphHeight]
    ld b, a
    ld a, [W_TextServices_CurrentGlyphBase]
    ld c, a
    ld a, [W_TextServices_CurrentHorizontalTile]
    ld d, a
    ld a, [W_TextServices_CurrentVerticalGlyphPosition]
    ld e, a
    ld a, [W_TextServices_CurrentGlyphBase + 1]
    ld l, a
    ld a, [W_TextServices_CurrentGlyphBase + 2]
    ld h, a
    ld a, [W_TextServices_CurrentCacheMask]
    call TextServices_PrepareGlyphForComposition
    
    ld a, [W_TextServices_CurrentHorizontalShift]
    ld d, a
    ld e, 3 ;TODO: Pull the text window color
    
    ;TODO: VRAM banking.
    ld a, [W_TextServices_CurrentWindowTile + 1]
    ld l, a
    ld a, [W_TextServices_CurrentWindowTile + 2]
    ld h, a
    
    call TextServices_ComposeGlyphWithTile
    
    ld a, l
    ld [W_TextServices_CurrentWindowTile + 1], a
    ld a, h
    ld [W_TextServices_CurrentWindowTile + 2], a
    jr .tile_loop
    
.exit_tile_loop
    ld a, [W_TextServices_CurrentVerticalCursor]
    and $07
    jr z, .aligned_vertical_cursor
    
    ;If we aren't vertically aligned to a tile boundary, then we composed
    ;just the tops of the glyph. Now we need to realign ourselves to the grid.
.unaligned_vertical_cursor
    ld a, [W_TextServices_CurrentVerticalCursor]
    and $F8
    jr .save_new_vertical_cursor
    
    ;If we are vertically aligned to a tile boundary, then we just need to go
    ;to the next one down...
.aligned_vertical_cursor
    ld a, [W_TextServices_CurrentVerticalCursor]
    
.save_new_vertical_cursor
    add a, 8
    ld [W_TextServices_CurrentVerticalCursor], a
    
    ld b, a
    ld a, [W_TextServices_StartingVerticalCursor]
    ld c, a
    ld a, [W_TextServices_FontHeaderCache + M_TextServices_FontGlyphHeight]
    add a, c
    cp b
    jp z, .exit
    jp c, .exit
    
.goto_next_row
    pop de
    push de
    ld hl, M_TextServices_WindowWidth
    add hl, de
    ld b, [hl]
    
    ld a, [W_TextServices_RowStartingTile]
    ld l, a
    ld a, [W_TextServices_RowStartingTile + 1]
    ld h, a
    ld a, b
    call TextServices_IncrementByTiles
    
    ld a, l
    ld [W_TextServices_CurrentWindowTile + 1], a
    ld [W_TextServices_RowStartingTile], a
    ld a, h
    ld [W_TextServices_CurrentWindowTile + 2], a
    ld [W_TextServices_RowStartingTile + 1], a
    
    jp .row_loop
    
.exit
    pop de
    pop de
    pop af
    ret