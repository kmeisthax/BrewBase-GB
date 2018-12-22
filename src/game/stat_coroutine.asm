INCLUDE "lib/brewbase.inc"

SECTION "Test Case StatIRQ Coroutine", ROM0
Game_StatIRQHandler::
    ld a, $E0
    ld [REG_SCY], a
    ld a, $40
    ld [REG_LYC], a
    M_LCDC_HBlankYield
    
    ld a, $B0
    ld [REG_SCY], a
    ld a, $41
    ld [REG_LYC], a
    M_LCDC_HBlankYield
    
.break_loop
    ld a, $B3
    ld [REG_SCY], a
    ld a, $B6
    ld [REG_SCY], a
    ld a, $B9
    ld [REG_SCY], a
    ld a, $BC
    ld [REG_SCY], a
    ld a, $BF
    ld [REG_SCY], a
    ld a, $C2
    ld [REG_SCY], a
    ld a, $B0
    ld [REG_SCY], a
    ld a, [REG_LYC]
    inc a
    cp M_LCDC_HDMARequestVblankScreenLine
    jr z, .exit
    ld [REG_LYC], a
    M_LCDC_HBlankYieldJp .break_loop
    
.exit
    pop af
    reti