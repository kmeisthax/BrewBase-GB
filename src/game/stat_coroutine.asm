INCLUDE "lib/brewbase.inc"

SECTION "Test Case StatIRQ Coroutine", ROM0
Game_StatIRQHandler::
    ld a, $10
    ld [REG_SCY], a
    ld a, $10
    ld [REG_LYC], a
    M_LCDC_HBlankYield
    
    ld a, $4
    ld [REG_SCY], a
    ld a, $12
    ld [REG_LYC], a
    M_LCDC_HBlankYield
    
    ld a, $0
    ld [REG_SCY], a
    ld a, $14
    ld [REG_LYC], a
    M_LCDC_HBlankYield
    
    ld a, $0F
    ld [REG_SCY], a
    ld a, $15
    ld [REG_LYC], a
    M_LCDC_HBlankYield
    
    ld a, 0
    ld [REG_SCY], a
    ld a, $FF
    ld [REG_LYC], a
    M_LCDC_HBlankYieldJp Game_StatIRQHandler