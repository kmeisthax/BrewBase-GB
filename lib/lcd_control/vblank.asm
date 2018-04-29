INCLUDE "lib/brewbase.inc"

SECTION "BBase VBlank Service OAM Shadow", WRAM0[$C000]
W_LCDC_OAMStagingArea:: ds $9F

SECTION "BBase VBlank Service Memory", WRAM0
W_LCDC_VBlankExecuted:: ds 1

SECTION "BBase VBlank Services IRQ Handler", ROM0[$0040]
LCDC_VBlankIRQ:
    jp vblank
    
SECTION "BBase VBlank Services", ROM0
;Triggers OAM DMA transfer. Should never be run from ROM!
;Call LCDC_VBlankOAMTransfer to get the HRAM version.
_LCDC_VBlank_OAMRoutine:
    ld a, (W_LCDC_OAMStagingArea / $100)
    ld [REG_DMA], a
    
    ;Now that DMA is started, burn some cycles since the entire system bus is
    ;offline right now. Pan Docs recommends 0x28 spins.
    ;TODO: Verify on real hardware, including CGB overclock
    ld a, $28
.spin
    dec a
    jr nz, .spin
    ret
    
_LCDC_VBlank_OAMRoutine_END:
_LCDC_VBlank_OAMRoutine_LENGTH EQU _LCDC_VBlank_OAMRoutine_END - _LCDC_VBlank_OAMRoutine

SECTION "BBase VBlank Service HighMemory", HRAM
H_LCDC_VBlank_OAMRoutine: ds _LCDC_VBlank_OAMRoutine_LENGTH

SECTION "BBase VBlank Services 2", ROM0
;Trigger an OAM transfer.
;Must not be called before initializing the VBlank service!
;Must be called during VBlank!
;Clobbers AF.
LCDC_VBlankOAMTransfer::
    jp H_LCDC_VBlank_OAMRoutine
    
;Initialize Vblank services.
;After the call, vblank interrupts will be enabled.
;Clobbers all the things
LCDC_VBlankInit::
    xor a
    ld [W_LCDC_VBlankExecuted], a
    
    ;Copy the OAM DMA routine into high memory.
    ld bc, H_LCDC_VBlank_OAMRoutine
    ld hl, _LCDC_VBlank_OAMRoutine
    ld d, _LCDC_VBlank_OAMRoutine_LENGTH
    
.copyLoop:
    ld a, [hli]
    ld [bc], a
    inc bc
    dec d
    jp nz, .copyLoop
    
    ;Enable VBlank
    ld a, [REG_IE]
    set 0, a
    ld [REG_IE], a
    
    ret