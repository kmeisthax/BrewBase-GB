INCLUDE "lib/brewbase.inc"

SECTION "Test Case StatIRQ Coroutine", ROM0
Game_StatIRQHandler::
    ld a, $E0
    ld [REG_SCY], a
    ld a, $40
    ld [REG_LYC], a
    M_LCDC_HBlankYield
    
    ld a, $E0
    ld [REG_SCY], a
    ld a, $40
    ld [REG_LYC], a
    M_LCDC_HBlankYield
    
.break_loop
    ld a, $C0
    ld [REG_SCY], a
    ld a, $BF
    ld [REG_SCY], a
    ld a, $BE
    ld [REG_SCY], a
    ld a, $BD
    ld [REG_SCY], a
    ld a, $BC
    ld [REG_SCY], a
    ld a, [REG_LYC]
    inc a
    ld [REG_LYC], a
    M_LCDC_HBlankYieldJp .break_loop