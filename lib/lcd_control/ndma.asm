INCLUDE "lib/brewbase.inc"

SECTION "NDMA Request State", WRAM0
W_LCDC_CurrentVallocEntryIndex:: ds 1
W_LCDC_CurrentVallocEntry:: ds M_LCDC_VallocStructSize

SECTION "NDMA Requests", ROM0
;Execute the NDMA request in CurrentVallocEntry.
;
;This function uses NDMA and is intended for use during Vblank. Attempts to
;execute NDMA transfers outside of Vblank (or screen off) will fail to actually
;transfer data to VRAM.
;
;This routine is aware of Vblank timing and will shorten transfers to remain
;within a given transfer limit. Repeated invocation of this function during
;successive Vblank interrupts will eventually result in a completed transfer.
;
;A = Estimated remaining vblank time (in tiles)
;    This parameter specifies how much NDMA time remains; it is used to cap the
;    transfer length of the current Valloc entry.
;
;[CurrentVallocEntry] = A Valloc structure, presumably marked dirty, to
;                       transfer into VRAM.
;
;RETURNS
;
;A = Estimated remaining vblank time (in tiles) subtracting current transfer
;    length
;
;[CurrentVallocEntry.Status] = Clean if finished completely, Dirty if ongoing.
;[CurrentVallocEntry.Size] = 0 if finished completely, otherwise ongoing.
;[CurrentVallocEntry.BackingStore] = If not finished completely, points to the
;and [CurrentVallocEntry.Location]   remaining portion of the transfer.
LCDC_ExecuteCurrentNDMAEntry::
    push bc
    push hl
    
    ld hl, W_LCDC_CurrentVallocEntry + M_LCDC_VallocSize
    ld a, [hli]
    inc a ;For some reason we store Valloc size as bias -1, which means we have
          ;to unbias it for maths
    
    cp b
    jr c, .no_cap_transfer_rate

.cap_transfer_rate
    ld a, b
    
.no_cap_transfer_rate
    ld c, a
    
    ld a, [W_System_ARegStartup]
    cp M_BIOS_CPU_CGB
    jr nz, .use_emulated_ndma
    
.use_real_ndma
    ld a, [hli]
    ld [REG_HDMA2], a   ;For some reason the NDMA hardware is big endian!?
    
    ld a, [hli]
    ld [REG_HDMA1], a
    
    ;Lock the ROM/WRAM banks to the specified source bank for the duration of
    ;NDMA transfer.
    ld a, [hli]
    ld [$2000], a
    ld [REG_SVBK], a
    
    ld a, [hli]
    ld [REG_HDMA4], a   ;For some reason the NDMA hardware is big endian!?
    
    ld a, [hli]
    ld [REG_HDMA3], a
    
    ;Also lock the VRAM bank to the destination bank.
    ld a, [hli]
    ld [REG_VBK], a
    
    ld a, c
    dec a
    and $7F
    ld [REG_HDMA5], a   ;Trigger the actual NDMA transfer
    jr .update_entry_status
    
.use_emulated_ndma
    push bc
    push de
    
    push hl
    inc hl
    inc hl
    
    ;Lock the ROM/WRAM banks to the specified source bank for the duration of
    ;NDMA transfer.
    ld a, [hli]
    ld [$2000], a
    ld [REG_SVBK], a
    
    ld a, [hli]
    ld e, a
    ld a, [hli]
    ld d, a
    
    ;Also lock the VRAM bank to the destination bank.
    ld a, [hli]
    ld [REG_VBK], a
    
    pop hl
    ld a, [hli]
    ld h, [hl]
    ld l, a
    
.copy_loop ;TODO: Can this be faster?
    REPT 16
    ld a, [hli]
    ld [de], a
    inc de
    ENDR
    
    dec c
    jr nz, .copy_loop
    
    pop de
    pop bc
    
    ld a, c
    dec a
    
.update_entry_status
    ;At this point, we need to update the entry
    ld hl, W_LCDC_CurrentVallocEntry + M_LCDC_VallocSize
    sub [hl]
    jp z, .transfer_complete
    
.transfer_ongoing
    ld [hli], a
    
    push bc
    
    and $F0
    swap a
    ld b, a
    ld a, c
    and $0F
    swap a
    ld c, a
    
    ld a, [hl]
    add a, c
    ld [hli], a
    ld a, [hl]
    adc a, b
    ld [hli], a ;Backing store + Bytes transferred
    
    inc hl
    ld a, [hl]
    add a, c
    ld [hli], a
    ld a, [hl]
    adc a, b
    ld [hli], a ;VRAM location + Bytes transferred
    
    pop bc
    jr .report_time_utilization
    
.transfer_complete
    ld [hld], a
    ld a, M_LCDC_VallocStatusClean
    ld [hl], a
    
.report_time_utilization
    ;B = how much time we started with
    ;C = how much time we took
    ld a, b
    sub a, c
    
    pop hl
    pop bc
    ret

;Resolve pending NDMA requests, if any.
;
;Requests are resolved from the top of the arena to the bottom.
;
;NDMA requests handled here will be resolved as general-purpose DMA; this 
;routine is thus unsuitable for use outside of V-blank. Ideally, it should be
;executed first thing as part of the VBlank IRQ. Care is taken within the
;routine to avoid exhausting VBlank time entirely; transfer speed is throttled
;to a rate of 4kb/frame. This should be plenty for everything but 60fps full
;motion video (and, tbh, you can get up to 7kb/frame by using HDMA)
;
;NOTE: This routine does not respect callee cleanup conventions. You will need
;to push all registers beforehand.
;
;This routine clobbers REG_VBK, we assume all VRAM access will occur using this
;routine. If not the case, you will need to use another routine.
LCDC_ResolvePendingNDMA::
    ld b, M_LCDC_NDMARequestProcessingCap ;total processing time remaining
    
    ld a, [W_LCDC_CurrentVallocEntry + M_LCDC_VallocStatus]
    cp M_LCDC_VallocStatusDirty
    jr nz, .no_dirty_chunk
    
.dirty_chunk_detected
    ld a, b
    call LCDC_ExecuteCurrentNDMAEntry
    ld b, a
    
    ld a, [W_LCDC_CurrentVallocEntry + M_LCDC_VallocStatus]
    cp M_LCDC_VallocStatusClean
    jr nz, .exitDMAProcessing
    
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
    
    ;If we're out of time, we're out of time.
    ;TODO: Actually, we did so much faffing about back there we should probably
    ;be losing DMA cap time for it
    ld a, b
    cp 0
    jr z, .exitDMAProcessing
    
.no_dirty_chunk
    ld c, 0     ;current arena entry
    ld hl, W_LCDC_VallocArena
    
.processEntry
    ld a, [hl]
    cp M_LCDC_VallocStatusDirty
    jr nz, .skipDMAEntry
    
    ld a, c
    ld [W_LCDC_CurrentVallocEntryIndex], a
    
    ld de, W_LCDC_CurrentVallocEntry
    
    REPT M_LCDC_VallocStructSize
    ld a, [hli]
    ld [de], a
    inc de
    ENDR
    
    ld a, b
    call LCDC_ExecuteCurrentNDMAEntry
    ld b, a
    
    ld a, [W_LCDC_CurrentVallocEntry + M_LCDC_VallocStatus]
    cp M_LCDC_VallocStatusClean
    jr nz, .exitDMAProcessing
    
    ;Copy back the old status
    ld de, (M_LCDC_VallocStructSize * -1)
    add hl, de
    ld [hl], a
    
    ld de, M_LCDC_VallocStructSize
    add hl, de
    
    ld a, b
    cp 0
    jr z, .exitDMAProcessing
    
    inc c
    ld a, c
    cp M_LCDC_VallocCount
    jr z, .exitDMAProcessing
    jr .processEntry
    
.skipDMAEntry
    inc c
    ld a, c
    cp M_LCDC_VallocCount
    jr z, .exitDMAProcessing
    
    ld a, l
    add M_LCDC_VallocStructSize
    ld l, a
    jr nc, .processEntry
    inc h
    jr .processEntry
    
.exitDMAProcessing
    ;Unclobber banks. TODO: What of REG_VBK?
    ld a, [H_System_CurBank]
    ld [$2000], a
    ld a, [H_System_CurRamBank]
    ld [REG_SVBK], a
    
    ret