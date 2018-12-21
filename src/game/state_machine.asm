INCLUDE "lib/brewbase.inc"

SECTION "Root State Machine Memory", WRAM0
W_Game_StateMachineState:: ds 1
W_Game_StringPtr:: ds 2

SECTION "Root State Machine", ROMX, BANK[2]
;Execute one step of the main state machine.
;All registers are assumed clobbered.
Game_StateMachine::
    ld a, [W_Game_StateMachineState]
    cp (.table_end - .table) / 2
    jr nc, .invalid_state
    
    ld hl, .table
    call System_StateMachineLookupJump
    jp hl
    
.table
    dw Game_StateLoadScreen
    dw Game_StateBeginDrawText
    dw Game_StateDrawText
    dw Game_StateBeginDrawText2
    dw Game_StateDrawText2
.table_end

.invalid_state
    ret

;Game states follow
Game_StateLoadScreen::
    ld a, 0
    push af
    ld hl, $8000
    push hl
    ld a, 0
    ld e, $FE
    ld bc, TestGraphic
    ld d, BANK(TestGraphic)
    call LCDC_CreateVallocMapping
    add sp, 4
    
    ld a, %11100100
    ld [W_LCDC_ShadowBGP], a
    ld a, %10000001
    ld [W_LCDC_ShadowLCDC], a
    
    ld a, 8
    ld [W_LCDC_ShadowLYC], a
    
    ld hl, Game_StatIRQHandler
    call LCDC_HBlankInit
    
    ld a, %01000000
    ld [REG_STAT], a
    
    ;If a spurious interrupt was generated, kill it
    ld a, [REG_IF]
    res 1, a
    ld [REG_IF], a
    
    ld a, [REG_IE]
    set 1, a
    ld [REG_IE], a
    
    ld a, $FF
    ld [W_LCDC_PaletteBGShadow + 0], a
    ld a, $7F
    ld [W_LCDC_PaletteBGShadow + 1], a
    ld a, $52
    ld [W_LCDC_PaletteBGShadow + 2], a
    ld a, $4A
    ld [W_LCDC_PaletteBGShadow + 3], a
    ld a, $8C
    ld [W_LCDC_PaletteBGShadow + 4], a
    ld a, $31
    ld [W_LCDC_PaletteBGShadow + 5], a
    ld a, $00
    ld [W_LCDC_PaletteBGShadow + 6], a
    ld a, $00
    ld [W_LCDC_PaletteBGShadow + 7], a
    
    ld a, M_LCDC_PalettesDirty
    ld [W_LCDC_PaletteBGShadowStatus], a
    
    ld a, 1
    ld [W_Game_StateMachineState], a
    
    ret
    
Game_StateBeginDrawText::
    ld hl, W_Game_StringPtr
    ld bc, Game_StateDrawText.text
    
    ld [hl], b
    inc hl
    ld [hl], c
    
    ld hl, W_Game_Window
    ld d, 16
    ld e, 4
    ld b, 12
    ld c, 10
    M_System_FarCall TextServices_SetWindowSize
    
    ld hl, W_Game_Window
    ld a, BANK(Game_UnrelatedFont)
    ld bc, Game_UnrelatedFont
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
    ld d, 0
    ld e, 0
    M_System_FarCall TextServices_SetWindowTiles
    
    ld hl, W_Game_Window
    M_System_FarCall TextServices_DrawWindowTilemap
    
    ld a, 2
    ld [W_Game_StateMachineState], a
    
    ret
    
Game_StateDrawText::
    ld hl, W_Game_StringPtr
    
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
    ld hl, W_Game_StringPtr
    
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
    
    ld a, 3
    ld [W_Game_StateMachineState], a
    
    ret
    
.text
    db "But it refused.", 0
.text_end
    
Game_StateBeginDrawText2::
    ld hl, W_Game_StringPtr
    ld bc, Game_StateDrawText2.text
    
    ld [hl], b
    inc hl
    ld [hl], c
    
    ld hl, W_Game_Window
    ld d, 16
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
    ld c, 12
    M_System_FarCall TextServices_SetWindowCursorPosition
    
    ld a, 4
    ld [W_Game_StateMachineState], a
    
    ret
    
Game_StateDrawText2::
    ld hl, W_Game_StringPtr
    
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
    ld hl, W_Game_StringPtr
    
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
    
    ld a, 5
    ld [W_Game_StateMachineState], a
    
    ret
    
.text
    db "But nobody came.", 0
.text_end