INCLUDE "lib/brewbase.inc"

SECTION "SRAM Console Memory", WRAM0
W_SRAMTest_ConsoleStringPtr:: ds 2

SECTION "SRAM Console", ROMX, BANK[2]
SRAMTest_ConsoleInit::
    push hl
    push de
    push bc
    push af
    
    ld hl, W_Game_Window
    ld d, 20
    ld e, 4
    ld b, 12
    ld c, 10
    M_System_FarCall TextServices_SetWindowSize
    
    ld hl, W_Game_Window
    ld a, BANK(Game_Font)
    ld bc, Game_Font
    M_System_FarCall TextServices_SetWindowFont
    
    ld hl, W_Game_Window
    ld a, BANK(W_Game_WindowBuffer)
    ld bc, W_Game_WindowBuffer
    M_System_FarCall TextServices_SetWindowBacking
    
    ld hl, W_Game_Window
    ld b, 0
    ld c, 0
    M_System_FarCall TextServices_SetWindowCursorPosition
    
    ld hl, W_Game_Window
    ld bc, $9800
    ld d, $10
    ld e, 0
    M_System_FarCall TextServices_SetWindowTiles

    ld hl, W_Game_Window
    M_System_FarCall TextServices_DrawWindowTilemap

    pop af
    pop bc
    pop de
    pop hl
    ret

SRAMTest_ConsoleNewline::
    push hl
    push de
    push bc
    push af

    ld hl, W_Game_Window
    ld b, 0
    M_System_FarCall TextServices_SetWindowCursorX

    ld hl, W_Game_Window
    ld b, 0
    ld c, 8
    M_System_FarCall TextServices_AdjustWindowCursorPosition

    pop af
    pop bc
    pop de
    pop hl
    ret

;Queue a string to be drawn to the screen.
;
;BC = Pointer to string to draw (in same bank)
SRAMTest_QueueText::
    push hl

    ld hl, W_SRAMTest_ConsoleStringPtr
    
    ld [hl], b
    inc hl
    ld [hl], c
    
    pop hl
    ret
    
;Execute drawing.
;
;Returns A=1 if done, A=0 if not.
SRAMTest_DrawText::
    push hl
    push de
    push bc

    ld hl, W_SRAMTest_ConsoleStringPtr
    
    ld d, [hl]
    inc hl
    ld e, [hl]
    
.loop
    ld a, [de]
    or a
    jr z, .string_done
    
    ld b, 0
    ld c, a
    ld hl, W_Game_Window
    M_System_FarCall TextServices_DrawGlyphToWindow
    
    push de
    ld d, 0
    ld e, a
    ld hl, W_Game_Window
    M_System_FarCall TextServices_AddGlyphWidthToCursor
    pop de
    inc de
    jr .loop
    
.string_not_done
    ld hl, W_SRAMTest_ConsoleStringPtr
    
    ld [hl], d
    inc hl
    ld [hl], e
    
    ld a, 0
    push af
    ld hl, $9100
    push hl
    ld a, 1
    ld e, (W_Game_Window - W_Game_WindowBuffer) / 16 - 1
    ld bc, W_Game_WindowBuffer
    ld d, BANK(W_Game_WindowBuffer)
    call LCDC_CreateVallocMapping
    add sp, 4
    
    ld a, 0
    pop bc
    pop de
    pop hl
    ret
    
.string_done
    ld a, 0
    push af
    ld hl, $9100
    push hl
    ld a, 1
    ld e, (W_Game_Window - W_Game_WindowBuffer) / 16 - 1
    ld bc, W_Game_WindowBuffer
    ld d, BANK(W_Game_WindowBuffer)
    call LCDC_CreateVallocMapping
    add sp, 4
    
    ld a, 1
    pop bc
    pop de
    pop hl
    ret