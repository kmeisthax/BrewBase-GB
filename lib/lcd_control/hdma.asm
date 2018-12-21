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
    push af
    push bc
    push hl
    
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
    
    ;HDMA must NOT be started during mode 0, otherwise Bad Things happen.
    ;We actually wait for Mode 2 for extra safety, here's why:
    ;
    ;Critical path timing: 40 cycles for the check, 28 to produce and write
    ;HDMA5 register. Since we have a transfer safety buffer to rule out VBlank,
    ;we will always see LCDC modes 0, 2, and 3 in that order. The worst case
    ;timing scenario is that we see the end of one particular mode, so we need
    ;to compute conditionals and write the HDMA5 value in less time than LCDC
    ;could possibly move to mode 0.
    ;
    ;We actually check for mode 0 and then mode 2 to ensure that we are
    ;synchronized with the start of OAM Search.
    di
    
.wait_for_not_blanking
    ld a, [REG_STAT]
    and $03
    cp 2
    jr nz, .wait_for_not_blanking
    
    ld a, c
    or $80
    ld [REG_HDMA5], a   ;Trigger the actual HDMA transfer
    ei
    
    ;At this point, HDMA is active, but so is our CPU. HDMA steals cycles so we
    ;just need to stop it if we're running into Vblank.
.idle_loop
    ld a, [REG_HDMA5]
    cp $FF
    jr z, .hdma_completed_naturally
    
    ld a, [REG_LY]
    cp M_LCDC_HDMARequestTerminationLine
    jr nc, .terminate_hdma
    jr .idle_loop
    
.terminate_hdma
    ld a, [REG_HDMA5]
    cp $FF
    jr z, .hdma_completed_naturally
    
    and $7F
    ld [REG_HDMA5], a
    
    ;Preserve the high bit of the transfer length
    bit 7, c
    jr z, .no_oversized_transfer
    
.oversized_transfer
    or a, $80
    
.no_oversized_transfer
    ld hl, W_LCDC_CurrentVallocEntry + M_LCDC_VallocSize
    ld [hli], a
    
    ld a, [REG_HDMA2]
    ld [hli], a
    
    ld a, [REG_HDMA1]
    ld [hli], a
    
    inc hl
    
    ld a, [REG_HDMA4]
    ld [hli], a
    
    ld a, [REG_HDMA3]
    ld [hli], a
    
    pop hl
    pop bc
    pop af
    ret
    
.hdma_completed_naturally
    ;HDMA can only transfer $7F blocks at a time; if we transfer more than that
    ;then we need to queue a second transfer for the other half of the data.
    bit 7, c
    ld a, $7F
    jr nz, .no_oversized_transfer
    
    ld a, M_LCDC_VallocStatusClean
    ld [W_LCDC_CurrentVallocEntry + M_LCDC_VallocStatus], a
    
    pop hl
    pop bc
    pop af
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
;This routine modifies data structures that are shared between HDMA and NDMA. It
;is highly recommended that you do one of the following to prevent unpredictable
;DMA transfer failures:
; 
;  - Disable all interrupts before/after HDMA
;  - Disable V-blank interrupts before/after HDMA
;  - Ensure all non-V-blank interrupt handlers are short-lived
;
;TODO: The current iteration of this routine disables interrupts throughout the
;HDMA transfer period. Come up with a better safety mechanism.
;
;TODO: Support all of the following.
;  - MID-HDMA COMPUTATION NOTICE -
;
;If you are interested in performing computation during HDMA, you must provide
;an idle routine to be executed periodically during HDMA time. The following
;warnings apply to this facility:
;
;  - Your idle routine must respect callee-cleanup calling conventions.
;  - Your idle routine must not execute for longer than the HDMA request safety
;    buffer. If this is unacceptable, you must instead establish your own timing
;    safety and refuse to execute if current LY timing would exceed that buffer.
;    e.g. If the request safety buffer is 4 lines, and your routine needs 8
;    lines of execution time to be efficient, it must check LY and refrain from
;    execution 
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
;
;In the interest of making compliance with the DMA banking restrictions easier,
;the idle routine will be called with the following arguments:
;
; A = Current SOURCE HDMA bank
; HL = Current SOURCE HDMA memory address
;
; With these pieces of information it is possible to dynamically determine if it
; is safe to engage in banked memory access in your idle routine.
LCDC_ResolvePendingHDMA::
    ld a, [W_System_ARegStartup]
    cp M_BIOS_CPU_CGB
    jr nz, .not_a_cgb
    
    push af
    push de
    push hl
    
    ld a, [REG_LY]
    cp M_LCDC_HDMARequestTerminationLine
    jr nc, .no_hdma_plz
    
.hdma_safe
    di
    ld a, [W_LCDC_CurrentVallocEntry + M_LCDC_VallocStatus]
    cp M_LCDC_VallocStatusDirty
    jr nz, .no_current_dirty_transfer
    
    call LCDC_ExecuteCurrentHDMAEntry
    
    ld a, [W_LCDC_CurrentVallocEntry + M_LCDC_VallocStatus]
    cp M_LCDC_VallocStatusClean
    jr nz, .no_current_dirty_transfer
    
    ;Copy back the old status
    ld a, [W_LCDC_CurrentVallocEntryIndex]
    ld d, 0
    sla a
    rl d
    sla a
    rl d
    sla a
    rl d ;Assumes vallocs are 8 bytes. M_LCDC_VallocStructSize may change
    ld e, a
    ld hl, W_LCDC_VallocArena
    add hl, de
    ld a, [W_LCDC_CurrentVallocEntry + M_LCDC_VallocStatus]
    ld [hl], a
    
.no_current_dirty_transfer
    ei
    
.no_hdma_plz
    pop hl
    pop de
    pop af
    
.not_a_cgb
    ret