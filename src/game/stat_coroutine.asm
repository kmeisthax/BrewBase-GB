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
    push bc
    ld c, REG_SCY & $FF
    ld a, $B3
    ld [c], a
    ld a, $B5
    ld [c], a
    ld a, $B7
    ld [c], a
    ld a, $B5
    ld [c], a
    ld a, $B3
    ld [c], a
    ld a, $B1
    ld [c], a
    ld a, $B3
    ld [c], a
    ld a, $B5
    ld [c], a
    ld a, $B7
    ld [c], a
    ld a, $B0
    ld [c], a
    pop bc
    
    ld a, [REG_LYC]
    inc a
    ld [REG_LYC], a
    
    M_LCDC_HBlankYieldJp .break_loop
    
.exit
    pop bc
    pop af
    reti