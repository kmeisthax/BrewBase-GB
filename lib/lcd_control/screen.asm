INCLUDE "lib/brewbase.inc"

SECTION "LCDC Screen Memory", WRAM0
W_LCDC_ShadowLCDC:: ds 1
W_LCDC_ShadowSCY:: ds 1
W_LCDC_ShadowSCX:: ds 1
W_LCDC_ShadowWY:: ds 1
W_LCDC_ShadowWX:: ds 1
W_LCDC_ShadowLYC:: ds 1
W_LCDC_ShadowBGP:: ds 1
W_LCDC_ShadowOBP0:: ds 1
W_LCDC_ShadowOBP1:: ds 1

SECTION "LCDC Screen Control", ROM0
;Update various per-frame screen control variables.
;
;This function should only be called during VBlank. Doing so at any other time
;may damage hardware.
;
;This is also the only safe way to turn the screen off. DMG does not have a
;proper forced-blanking mechanism and the LCD will... supposedly fail if you
;turn it off mid frame. Or at least, Nintendo thought it would, so we're taking
;their advice.
LCDC_ScreenControlUpdate::
    push af
    
    ld a, [W_LCDC_ShadowLCDC]
    ld [REG_LCDC], a
    ld a, [W_LCDC_ShadowSCY]
    ld [REG_SCY], a
    ld a, [W_LCDC_ShadowSCX]
    ld [REG_SCX], a
    ld a, [W_LCDC_ShadowWY]
    ld [REG_WY], a
    ld a, [W_LCDC_ShadowWX]
    ld [REG_WX], a
    ld a, [W_LCDC_ShadowLYC]
    ld [REG_LYC], a
    ld a, [W_LCDC_ShadowBGP]
    ld [REG_BGP], a
    ld a, [W_LCDC_ShadowOBP0]
    ld [REG_OBP0], a
    ld a, [W_LCDC_ShadowOBP1]
    ld [REG_OBP1], a
    
    pop af
    ret