INCLUDE "lib/brewbase.inc"

SECTION "BBase HBlank Services Memory", WRAM0
W_LCDC_HBlankInstr:: ds 3 ;Hblank handler.
                          ;Always holds a jp to the current code.
SECTION "BBase HBlank Services Memory", HRAM
H_LCDC_HBlankARegPreserve:: ds 1

SECTION "BBase HBlank Services IRQ Handler", ROM0[$0048]
;The actual STAT interrupt handler.
;
;Because STAT is usually responsible for handling LYC triggers, we need to
;allow user code to be both quickly executed and quickly replaced. Invoking
;our STAT handler in this way allows us to get into user code very quickly
;and allows said code to be replaced quickly, too.
;
;Code called from here must satisfy a particularly unusual calling convention.
;You must end your functions with the following preamble:
;
;  pop af
;  reti
LCDC_StatIRQ::
    push af
    jp W_LCDC_HBlankInstr

SECTION "LCDC H-Blank Utilities", ROM0
;Install a given StatIRQ handler into HBlankInstr.
;
; HL = Function pointer to call every IRQ.
LCDC_HBlankInit::
    push af
    
    ld a, $C3
    ld [W_LCDC_HBlankInstr], a
    ld a, l
    ld [W_LCDC_HBlankInstr + 1], a
    ld a, h
    ld [W_LCDC_HBlankInstr + 2], a
    
    pop af
    ret

;Exit a function while scheduling the return address as the next HBlank
;handler.
;
;This routine has an unusual calling convention; you must have the original HL
;that the interrupted code had on the stack. This code satisfies the exit
;convention for a StatIRQ handler.
LCDC_HBlankYield::
    pop hl
    ld a, l
    ld [W_LCDC_HBlankInstr + 1], a
    ld a, h
    ld [W_LCDC_HBlankInstr + 2], a
    
    pop hl
    pop af
    reti
    
;Example code for an HBlank coroutine that splits the window layer across
;parts of the screen. You schedule .start at the top of the frame with an LYC
;value of $10 and ShadowSCY configured appropriately.
;
; my_coroutine::
;   ld a, $10
;   ld [REG_SCY], a
;   ld a, $10
;   ld [REG_LYC], a
;   push hl
;   jp LCDC_HBlankYield
; .start
;   ld a, $FF
;   ld [REG_SCY], a
;   ld a, $80
;   ld [REG_LYC], a
;   push hl
;   jp LCDC_HBlankYield
;   jr .my_coroutine