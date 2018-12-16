INCLUDE "lib/brewbase.inc"

SECTION "Text Services Window Utilities", ROMX, BANK[1]
;Configure a window's size, including row settings.
;
; B = Text row height in pixels
; C = Text row baseline in pixels
; D = Window width in tiles
; E = Window height in tiles
; HL = Near pointer to window structure
; 
TextServices_SetWindowSize::
    ld a, d
    ld [hli], a ;Width 8 tiles
    
    ld a, e
    ld [hli], a ;Height 2 tiles
    
    ld a, b
    ld [hli], a ;Row height 8 pixels
    
    ld a, c
    ld [hli], a ;Baseline at 6 pixels from top
    
    ;Set cursor to zero.
    xor a
    ld [hli], a
    ld [hli], a
    
    ;Don't initialize the cached cursor pointer, noone uses it
    inc hl
    inc hl
    
    ;Set cursor shift to zero.
    ld [hli], a
    ld [hli], a
    
    ;Don't initialize the cursor font or backing for now...
    ret

;Set a window's font.
; 
; A = Bank of font structure
; BC = Near pointer to font structure
; HL = Near pointer to window structure
TextServices_SetWindowFont::
    push de
    
    ld de, M_TextServices_WindowFont
    add hl, de
    
    ld [hli], a
    ld a, c
    ld [hli], a
    ld [hl], b
    
    pop de
    ret

;Set a window's backing memory.
; 
; A = Bank of font structure
; BC = Near pointer to backing structure
; HL = Near pointer to window structure
TextServices_SetWindowBacking::
    push de
    
    ld de, M_TextServices_WindowBacking
    add hl, de
    
    ld [hli], a
    ld a, c
    ld [hli], a
    ld [hl], b
    
    pop de
    ret
    
;Set a window's tilemap display location.
;
;(Only applicable for windows that will be displayed on a tilemap)
; BC = VRAM pointer to first tile of the window
; D = Index of first tile in the window
; E = Attributes for all tiles in the window
; HL = Near pointer to window structure
TextServices_SetWindowTiles::
    push af
    
    ld a, M_TextServices_WindowTilePtr
    add a, l
    ld l, a
    ld a, h
    adc a, 0
    ld h, a
    
    ld a, c
    ld [hli], a
    ld a, b
    ld [hli], a
    ld a, d
    ld [hli], a
    ld a, e
    ld [hli], a
    
    pop af
    ret
    
;Position a window's text cursor.
;
; B = Cursor X position in pixels
; C = Cursor Y position in pixels
; HL = Near pointer to window structure
TextServices_SetWindowCursorPosition::
    push af
    push de
    
    ld de, M_TextServices_WindowCursorX
    add hl, de
    
    ld a, b
    ld [hli], a
    
    ld a, c
    ld [hli], a
    
    push hl
    
    ld de, (M_TextServices_WindowWidth - M_TextServices_WindowCursor)
    add hl, de
    ld d, [hl]
    
    push de
    
    ld de, ((M_TextServices_WindowBacking + 1) - M_TextServices_WindowWidth)
    add hl, de
    ld a, [hli]
    ld h, [hl]
    ld l, a
    
    pop af
    push bc
    
    srl c
    srl c
    srl c
    call TextServices_IncrementByTileRows
    
    pop bc
    
    srl b
    srl b
    srl b
    ld a, b
    call TextServices_IncrementByTiles
    
    ld d, h
    ld e, l
    
    pop hl
    ld a, e
    ld [hli], a
    ld a, d
    ld [hli], a
    
    pop de
    pop af
    ret

;Add an offset to a window's text cursor.
;
; B = Cursor X position in pixels
; C = Cursor Y position in pixels
; HL = Near pointer to window structure
TextServices_AdjustWindowCursorPosition::
    push af
    push de
    
    ld de, M_TextServices_WindowWidth
    add hl, de
    ld a, [hl]
    sla a
    sla a
    sla a
    
    ld de, (M_TextServices_WindowCursorX - M_TextServices_WindowWidth)
    add hl, de
    ld d, a
    ld a, [hli]
    add a, b
    cp d
    jr c, .no_overflow
    
.x_cursor_overflow
    sub a, d
    inc c
    
.no_overflow
    ld b, a
    
    ld a, [hl]
    add a, c
    ld c, a
    
    ld de, (0 - M_TextServices_WindowCursorY)
    add hl, de
    call TextServices_SetWindowCursorPosition
    
    pop de
    pop af
    
    ret

;Add the width of a particular glyph to the window cursor.
;
;DE = Glyph drawn
;HL = Near pointer to window structure
TextServices_AddGlyphWidthToCursor::
    push af
    push bc
    push hl
    push de
    
    ld bc, M_TextServices_WindowFont
    add hl, bc
    
    ld a, [hli]
    ld b, a
    ld a, [hli]
    ld h, [hl]
    ld l, a
    ld a, b
    ld bc, M_TextServices_FontMetricsData
    add hl, bc
    M_System_FarSnap
    
    ;WARNING: This depends on M_TextServices_FontMetricWidth being zero
    pop de
    call TextServices_IndexMetrics
    M_System_FarRead
    
    ;FarRead conveniently returns B = glyph width
    inc b
    ld c, 0
    pop hl
    call TextServices_AdjustWindowCursorPosition
    
    pop bc
    pop af
    ret