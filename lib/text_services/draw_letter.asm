INCLUDE "lib/brewbase.inc"

SECTION "Text Services - Draw Letter Main Routine Memory", WRAM0
W_TextServices_FontHeaderCache: ds M_TextServices_FontSize

W_TextServices_CurrentBaselineAdjustment: ds 1
W_TextServices_CurrentVerticalCursor: ds 1
W_TextServices_StartingVerticalCursor: ds 1
W_TextServices_CurrentCacheMask: ds 1
W_TextServices_CurrentHorizontalShift: ds 1
W_TextServices_CurrentWindowTile: ds 3
W_TextServices_RowStartingTile: ds 2

;The following three memory locations are assumed to be contiguous for
;optimization reasons:
W_TextServices_CurrentHorizontalTile: ds 1
W_TextServices_CurrentVerticalGlyphPosition: ds 1
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
    push bc
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
    
    ld hl, W_TextServices_FontHeaderCache + M_TextServices_FontMetricsData
    ld a, [hli]
    ld b, a
    ld a, [hli]
    ld h, [hl]
    ld l, a
    ld a, b
    pop de
    call TextServices_IndexMetrics
    inc hl
    inc hl ;this depends on M_TextServices_FontMetricBaseline's location
           ;faster than setting up a 16bit add or adc chain
    M_System_FarRead
    
    ;Initial setup of the vertical parameters
    pop de
    push de
    ld hl, M_TextServices_WindowBacking
    add hl, de
    ld a, [hli]
    ld [W_TextServices_CurrentWindowTile], a
    
    pop de
    push de
    ld hl, M_TextServices_WindowRowBaseline
    add hl, de
    ld a, [hli]
    sub a, b
    ld b, a
    ld [W_TextServices_CurrentBaselineAdjustment], a
    
    ld a, [hli] ;M_TextServices_WindowCursorX
    and $07
    ld [W_TextServices_CurrentHorizontalShift], a
    
    ld a, [hli] ;M_TextServices_WindowCursorY
    bit 7, b
    jr nz, .cannot_use_baseline_adjustment
    
    ;If the glyph baseline adjustment is positive, the glyph is too short and
    ;we push it down by adjusting the window cursor. If it's negative, it's too
    ;tall and we need to clip it, which is calculated in ComputeVertical ---
    ;ShiftingParameters.
    ;
    ;TODO: What if the baseline adjustment means we need to clip the glyph on
    ;      the bottom?
.adjust_cursor_for_baseline
    add a, b
    
.cannot_use_baseline_adjustment
    ld [W_TextServices_StartingVerticalCursor], a
    ld [W_TextServices_CurrentVerticalCursor], a
    
    ld a, [hli] ;M_TextServices_WindowCursor
    ld [W_TextServices_CurrentWindowTile + 1], a
    ld [W_TextServices_RowStartingTile + 0], a
    ld a, [hli]
    ld [W_TextServices_CurrentWindowTile + 2], a
    ld [W_TextServices_RowStartingTile + 1], a
    
.row_loop
    ld a, [W_TextServices_StartingVerticalCursor]
    ld b, a
    ld a, [W_TextServices_FontHeaderCache + M_TextServices_FontGlyphHeight]
    ld c, a
    ld a, [W_TextServices_CurrentVerticalCursor]
    ld d, a
    ld a, [W_TextServices_CurrentBaselineAdjustment]
    ld e, a
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
    ld hl, W_TextServices_CurrentWindowTile + 1
    ld a, [hli]
    ld h, [hl]
    ld l, a
    call TextServices_ComposeGlyphWithTile
    
.no_horizontal_glyph_overhang
    ld hl, W_TextServices_CurrentHorizontalTile
    ld a, [hl]
    inc a
    ld [hl], a
    
.first_horizontal_tile
    ld a, [W_TextServices_FontHeaderCache + M_TextServices_FontGlyphWidth]
    ld b, a
    ld a, [W_TextServices_CurrentHorizontalTile]
    cp b
    jr z, .exit_tile_loop
    
    ld a, [W_TextServices_FontHeaderCache + M_TextServices_FontGlyphHeight]
    ld b, a
    ld hl, W_TextServices_CurrentHorizontalTile
    ld a, [hli] ;W_TextServices_CurrentHorizontalTile
    ld d, a
    ld a, [hli] ;W_TextServices_CurrentVerticalGlyphPosition
    ld e, a
    ld a, [hli] ;W_TextServices_CurrentGlyphBase
    ld c, a
    ld a, [hli] ;W_TextServices_CurrentGlyphBase + 1
    ld h, [hl]  ;W_TextServices_CurrentGlyphBase + 2
    ld l, a
    ld a, [W_TextServices_CurrentCacheMask]
    call TextServices_PrepareGlyphForComposition
    
    ld a, [W_TextServices_CurrentHorizontalShift]
    ld d, a
    ld e, 3 ;TODO: Pull the text window color
    
    ;TODO: VRAM banking.
    ld hl, W_TextServices_CurrentWindowTile + 1
    ld a, [hli]
    ld h, [hl]
    ld l, a
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