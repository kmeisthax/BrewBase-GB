INCLUDE "lib/brewbase.inc"

SECTION "Root State Machine Memory", WRAM0
W_Game_StateMachineState:: ds 1

SECTION "Root State Machine", ROM0
;The actual state machine table itself.
;To add states to the state machine, dw the address of the function.
;No bank switching is performed by this code: it is assumed that code will be
;present in HOME or the bank currenty loaded when the state machine is called.
;To do cross-bank calling, you must define a HOME function which enters the
;appropriate bank and calls the function desired.
;Individual states are free to implement their own state tables; the memory
;location System_StateMachine_MainSubState is provided for such use.
Game_StateMachineTable:
    dw Game_StateLoadScreen
    dw Game_StateDrawText
Game_StateMachineTableEND

Game_StateMachineTableLENGTH EQU (Game_StateMachineTableEND - Game_StateMachineTable) / 2

;Execute one step of the main state machine.
;All registers are assumed clobbered.
Game_StateMachine::
    ld a, [W_Game_StateMachineState]
    cp Game_StateMachineTableLENGTH
    jr nc, .invalidState
    
    ld hl, Game_StateMachineTable
    call System_StateMachineLookupJump
    jp hl

.invalidState
    ret

;Game states follow
Game_StateLoadScreen::
    ld a, 0
    push af
    ld hl, $9000
    push hl
    ld a, 0
    ld e, 9
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
    call TextServices_SetWindowSize
    
    ld hl, W_Game_Window
    ld a, BANK(Game_Font)
    ld bc, Game_Font
    call TextServices_SetWindowFont
    
    ld hl, W_Game_Window
    ld a, BANK(W_Game_WindowBuffer)
    ld bc, W_Game_WindowBuffer
    call TextServices_SetWindowBacking
    
    ld hl, W_Game_Window
    ld b, 5
    ld c, 3
    call TextServices_SetWindowCursorPosition
    
    ld bc, $41
    ld hl, W_Game_Window
    call TextServices_DrawGlyphToWindow
    
    ld a, 0
    push af
    ld hl, $9100
    push hl
    ld a, 1
    ld e, 9
    ld bc, W_Game_WindowBuffer
    ld d, BANK(W_Game_WindowBuffer)
    call LCDC_CreateVallocMapping
    add sp, 4
    
    ld a, 2
    ld [W_Game_StateMachineState], a
    
    ret