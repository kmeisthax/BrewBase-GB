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