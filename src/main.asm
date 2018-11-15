INCLUDE "lib/brewbase.inc"

SECTION "Main", ROM0
;The start of your program.
;Feel free to alter this to establish your own game code and logic.
;The first instruction must be present for valid hardware autodetection.
main::
    call System_DetectGatherStartup
    call System_MemoryInit
    
    ld hl, $CFFF
    ld sp, hl
    call System_HiMemoryInit
    call System_BankInit
    call LCDC_VBlankInit
    ei
    
    ;Executed once per frame.
    ;Place code here that needs to run once per frame in non-interrupt context.
    ;Code that needs to run in vblank instead must be called from the vblank
    ;handler.
.gameLoop
    xor a
    ld [W_LCDC_VBlankExecuted], a
    call Game_StateMachine
    
    ;Stop processing until we get a Vblank interrupt.
.interruptFilter
    halt
    nop
    
    ld a, [W_LCDC_VBlankExecuted]
    cp 1
    jp nz, .interruptFilter
    
    jp .gameLoop