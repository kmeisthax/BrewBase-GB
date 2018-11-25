INCLUDE "lib/brewbase.inc"

SECTION "Root State Machine Memory", WRAM0
W_Game_StateMachineState:: ds 1

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
    dw Game_StateDrawText
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
    
    ld a, 1
    ld [W_Game_StateMachineState], a
    
    ret
    
Game_StateDrawText::
    ld hl, W_Game_Window
    ld d, 8
    ld e, 2
    ld b, 8
    ld c, 6
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
    
    ld bc, $41
    ld hl, W_Game_Window
    M_System_FarCall TextServices_DrawGlyphToWindow
    
    ld hl, W_Game_Window
    ld b, 8
    ld c, 0
    M_System_FarCall TextServices_SetWindowCursorPosition
    
    ld bc, $62
    ld hl, W_Game_Window
    M_System_FarCall TextServices_DrawGlyphToWindow
    
    ld hl, W_Game_Window
    ld b, 16
    ld c, 0
    M_System_FarCall TextServices_SetWindowCursorPosition
    
    ld bc, $65
    ld hl, W_Game_Window
    M_System_FarCall TextServices_DrawGlyphToWindow
    
    ld hl, W_Game_Window
    ld b, 24
    ld c, 0
    M_System_FarCall TextServices_SetWindowCursorPosition
    
    ld bc, $21
    ld hl, W_Game_Window
    M_System_FarCall TextServices_DrawGlyphToWindow
    
    ld a, 0
    push af
    ld hl, $9100
    push hl
    ld a, 1
    ld e, 15
    ld bc, W_Game_WindowBuffer
    ld d, BANK(W_Game_WindowBuffer)
    call LCDC_CreateVallocMapping
    add sp, 4
    
    ld a, 2
    ld [W_Game_StateMachineState], a
    
    ret