INCLUDE "lib/brewbase.inc"

SECTION "Vblank handler", ROM0
vblank::
    push af
    push bc
    push de
    push hl
    
    call LCDC_ScreenControlUpdate
    call LCDC_FlushBGPShadow
    call LCDC_FlushOBPShadow
    call LCDC_VBlankOAMTransfer
    call LCDC_ResolvePendingNDMA
    call LCDC_HBlankRestartCoroutine
    
    ld a, 1
    ld [W_LCDC_VBlankExecuted], a
    
    pop hl
    pop de
    pop bc
    pop af
    reti