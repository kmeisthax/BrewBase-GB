INCLUDE "lib/brewbase.inc"

SECTION "BBase HBlank Services High Memory", HRAM
H_LCDC_HBlankARegPreserve:: ds 1
H_LCDC_HBlankInstr:: ds 3 ;Hblank handler.
                          ;Always holds a jp to the current code.

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
;
;Timing information: When using StatIRQ handlers exclusively for LYC or HBlank
;interrupts, user code will have at least 88 cycles to operate in the worst case
;scenario. This is assuming we cannot make use of Mode 2 cycles and the previous
;scanline rendered 10 sprites. This is still enough cycles to write 4 I/O ports
;or a single OAM entry. If you can make use of Mode 2 cycles, then that
;almost doubles to 168 cycles or 8 I/O port writes.
;
;You should take care not to overtune the timings on StatIRQ interrupts as these
;cycles are stolen from gameloop code. Gameloop code is permitted to access VRAM
;during H-Blank, and will disable interrupts whilst doing so. As a result, your
;HBlank handler may have less time in order to accomplish the same task.
LCDC_StatIRQ::
    push af
    jp H_LCDC_HBlankInstr

SECTION "LCDC H-Blank Utilities", ROM0
;Install a given StatIRQ handler into HBlankInstr.
;
; HL = Near function pointer to call every IRQ.
; 
; NOTE: StatIRQ handlers cannot be banked (ROM, WRAM, or SRAM). You must ensure
; that the memory HL points to is always accessible at any time. Typically,
; this means using unbanked memory only. This is because the additional time
; to process banking correctly could significantly reduce the amount of H-Blank
; time available to user code. If you require banking, you must juggle the banks
; yourself.
LCDC_HBlankInit::
    push af
    
    ld a, $C3
    ld [H_LCDC_HBlankInstr], a
    ld a, l
    ld [H_LCDC_HBlankInstr + 1], a
    ld a, h
    ld [H_LCDC_HBlankInstr + 2], a
    
    pop af
    ret
    
;Example code for an HBlank coroutine that splits the window layer across
;parts of the screen. You schedule .start at the top of the frame with an LYC
;value of $10 and ShadowSCY configured appropriately.
;
; my_coroutine::
;   ld a, $10
;   ld [REG_SCY], a
;   ld a, $10
;   ld [REG_LYC], a
;   M_LCDC_HBlankYield
; .start
;   ld a, $FF
;   ld [REG_SCY], a
;   ld a, $80
;   ld [REG_LYC], a
;   M_LCDC_HBlankYield
;   jr .my_coroutine