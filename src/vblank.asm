INCLUDE "lib/brewbase.inc"

SECTION "Vblank handler", ROM0
vblank::
    call LCDC_ScreenControlUpdate
    call LCDC_FlushBGPShadow
    call LCDC_FlushOBPShadow
    call LCDC_VBlankOAMTransfer
    call LCDC_ResolvePendingNDMA
    
    ld a, 1
    ld [W_LCDC_VBlankExecuted], a
    reti