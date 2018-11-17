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
    
    ld a, 8
    ld [hli], a ;Width 8 tiles
    
    ld a, 2
    ld [hli], a ;Height 2 tiles
    
    ld a, 8
    ld [hli], a ;Row height 8 pixels
    
    ld a, 6
    ld [hli], a ;Baseline at 6 pixels from top
    
    xor a
    ld [hli], a ;Cursor X
    ld [hli], a ;Cursor Y
    
    ld de, W_Game_Window
    ld a, e
    ld [hli], a
    ld a, d
    ld [hli], a ;Cursor pointer
    
    xor a
    ld [hli], a ;Cursor shift X
    ld [hli], a ;Cursor shift Y
    
    ld a, BANK(Game_Font)
    ld [hli], a
    ld de, Game_Font
    ld a, e
    ld [hli], a
    ld a, d
    ld [hli], a ;Font far pointer
    
    ld a, 0
    ld [hli], a
    ld de, W_Game_WindowBuffer
    ld a, e
    ld [hli], a
    ld a, d
    ld [hli], a ;Backing far pointer
    
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