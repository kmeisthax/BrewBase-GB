INCLUDE "lib/brewbase.inc"

SECTION "LCDC HDMA Handler Memory", WRAM0
W_LCDC_HDMAIdleRoutine:: ds 3 ;Far pointer to idle routine.
                              ;Do not use banked routines without heeding the
                              ;warnings attached to LCDC_ResolvePendingHDMA.

SECTION "LCDC HDMA Handler", ROM0 ;and it NEEDS to be there, too

;Execute the HDMA request necessary to satisfy CurrentVallocEntry.
;
;This function uses HDMA and is intended for use outside of Vblank. HDMA
;transfers executed within Vblank will not transfer data (hardware limitation).
;
;This routine monitors LY and will terminate the transfer if line 144 (Vblank)
;is "near" enough. We actually terminate a few lines before then so that we have
;enough time to update CurrentVallocEntry before V-blank is actually triggered.
LCDC_ExecuteCurrentHDMAEntry::
    ld hl, W_LCDC_CurrentVallocEntry + M_LCDC_VallocSize
    ld a, [hli]
    ld c, a
    
    ld a, [hli]
    ld [REG_HDMA2], a
    
    ld a, [hli]
    ld [REG_HDMA1], a
    
    ;Check which bank type we should lock. Unlike NDMA, we don't lock everything
    ;because we might wanna run code during idle...
    bit 7, a
    ld a, [hli]
    jr z, .wram_banking
    
.rom_banking
    ld [$2000], a
    jr .set_dest
    
.wram_banking
    ld [REG_SVBK], a
    
.set_dest
    ld a, [hli]
    ld [REG_HDMA4], a
    
    ld a, [hli]
    ld [REG_HDMA3], a
    
    ;Also lock the VRAM bank to the destination bank.
    ld a, [hli]
    ld [REG_VBK], a
    
    ld a, c
    or $80
    ld [REG_HDMA5], a   ;Trigger the actual HDMA transfer
    
    ;At this point, HDMA is active, but so is our CPU. HDMA steals cycles so we
    ;just need to stop it if we're running into Vblank.
.idle_loop
    ld a, [REG_LY]
    cp M_LCDC_HDMARequestTerminationLine
    jr nc, .terminate_hdma
    
.terminate_hdma
    xor a
    ld [REG_HDMA5], a
    ret

;Resolve dirty Valloc blocks, if any, using the H-Blank DMA mechanism (HDMA).
;
;Requests are resolved from the top of the arena to the bottom.
;
;Dirty vallocs handled here will be resolved as H-Blank DMA; this routine is
;thus unsuitable for use outside of screen-on, non-V-blank conditions. Due to
;the limitations of the CGB HDMA mechanism, this routine blocks until HDMA has
;completed or Vblank is about to occur. It is technically possible to execute
;code during HDMA, however; there are numerous challenges to doing so. Thus,
;this routine provides the safest option by means of spinning the CPU until HDMA
;has completed or LY indicates that we are about to enter V-blank.
;
;  - MID-HDMA COMPUTATION NOTICE -
;
;If you are interested in performing computation during HDMA, you must provide
;an idle routine to be executed periodically during HDMA time. The following
;warnings apply to this facility:
;
;  - Your idle routine must respect callee-cleanup calling conventions.
;  - Your idle routine must not execute for longer than 4 screen lines in any
;    possible case.
;  - Your idle routine must be idempotent, as it will be executed repeatedly.
;  - Your idle routine may schedule a different idle routine to be executed. If
;    your idle routine cannot be written to be idempotent, then changing the
;    idle routine upon completion is acceptable.
;  - No other logic must rely upon the execution of your idle routine. In
;    particular, execution of your idle routine is not guaranteed.
;  - Your idle routine must not create any dirty vallocs, nor may it alter
;    existing vallocs.
;  - Your idle routine should not alter the backing store of any dirty valloc.
;    Any such alteration is not guaranteed to be transferred at all.
;  - Your idle routine must exist entirely in the HOME region, including any
;    data it needs to read. If this is unacceptable, you must ensure one of the
;    following:
;     - No dirty vallocs are backed by a banked ROM region, or
;     - All dirty vallocs exist in the same banked ROM region, and your idle
;       routine only accesses the bank as all dirty vallocs in that region.
;  - Your idle routine must not access banked WRAM ($D000-DFFF).
;    If this is unacceptable, you must ensure one of the following:
;     - Take care that no dirty vallocs are backed by a banked WRAM region, or
;     - Ensure that all dirty vallocs exist within the same banked WRAM region,
;       and only access the same WRAM bank as all dirty vallocs in that region.
;  - Your idle routine must not access SRAM ($A000-BFFF).
;    If this is unacceptable, you must:
;     - Take care that no dirty vallocs are backed by SRAM, or
;     - Ensure that all dirty vallocs exist within the same SRAM bank, and only
;       access the same SRAM bank as all dirty vallocs in that region.
LCDC_ResolvePendingHDMA::
    