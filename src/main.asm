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
    
    ;Enable LCD display and VBlank interrupts by default.
    ld a, $80
    ld [W_LCDC_ShadowLCDC], a
    
    ld a, $08
    ld [W_LCDC_ShadowSTAT], a
    
    ei
    
    ;Executed once per frame.
    ;Place code here that needs to run once per frame in non-interrupt context.
    ;Code that needs to run in vblank instead must be called from the vblank
    ;handler.
.gameLoop
    xor a
    ld [W_LCDC_VBlankExecuted], a
    M_System_FarCall Game_StateMachine
    call LCDC_ResolvePendingHDMA
    
    ;Stop processing until we get a Vblank interrupt.
    ;TODO: Detect if Vblanks are unavailable, and if so, don't wait for them.
.interruptFilter
    halt
    nop
    
    ld a, [W_LCDC_VBlankExecuted]
    cp 1
    jp nz, .interruptFilter
    
    jp .gameLoop