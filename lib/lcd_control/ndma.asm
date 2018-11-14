INCLUDE "lib/brewbase.inc"

SECTION "NDMA Requests", ROM0
;Resolve pending NDMA requests, if any.
;
;Requests are resolved from the top of the arena to the bottom.
;
;NDMA requests handled here will be resolved as general-purpose DMA; this 
;routine is thus unsuitable for use outside of V-blank. Ideally, it should be
;executed first thing as part of the VBlank IRQ. Care is taken within the
;routine to avoid exhausting VBlank time entirely, transfers are capped to 6kb
;total.
LCDC_ResolvePendingNDMA::
    ld a, [W_System_ARegStartup]
    cp M_BIOS_CPU_CGB
    jr nz, LCDC_EmulatePendingNDMA
    
    ld d, 0     ;current arena entry
    ld bc, M_LCDC_NDMARequestProcessingCap    ;total processing time remaining
    ld hl, W_LCDC_VallocArena
    
.processEntry
    ld a, [hl]
    cp M_LCDC_VallocStatusDirty
    jr nz, .skipDMAEntry
    
    push hl
    inc hl
    push hl
    
    ;Check if servicing this request would exceed the NDMA cap
    ld a, [hli]
    cp c
    jr c, .timeRemains
    
.checkUpperBits
    ld a, b
    and a
    jr z, .exitDMAProcessingFromStack
    
    ;At this point we're ready to start talking to the NDMA hardware...
.timeRemains
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
    
    pop hl
    ld a, [hld]
    and $7F
    ld [REG_HDMA5], a   ;Trigger the actual NDMA transfer
    
    ;Subtract from our processing cap.
    cpl
    inc a
    add c
    jr nc, .noSubCarry
    
.subCarry
    dec b
    
.noSubCarry
    ld c, a
    
    ;Mark the transfer as completed.
    pop hl
    ld a, M_LCDC_VallocStatusClean
    ld [hl], a
    
.skipDMAEntry
    inc d
    ld a, d
    cp M_LCDC_VallocCount
    jr z, .exitDMAProcessing
    
    ld a, l
    add M_LCDC_VallocStructSize
    ld l, a
    jr nc, .processEntry
    inc h
    jr .processEntry
    
.exitDMAProcessingFromStack
    add sp, 4
    
.exitDMAProcessing
    ;Unclobber banks. TODO: What of REG_VBK?
    ld a, [H_System_CurBank]
    ld [$2000], a
    ld a, [H_System_CurRamBank]
    ld [REG_SVBK], a
    
    ret
    
;Okay. Someone just plopped your fancy new homebrew cart into a disgustingly
;ancient brick DMG. How are you gonna get your graphics onto it's creamed
;spinach display? With this bad boy.
;
;TODO: Add a facility to split emulated NDMA workloads across multiple frames.
;Currently, if you have a Valloc longer than the processing cap it won't get
;processed at all.
LCDC_EmulatePendingNDMA::
    ld d, 0     ;current arena entry
    ld bc, M_LCDC_NDMARequestEmulatedProcessingCap    ;total processing time remaining
    ld hl, W_LCDC_VallocArena
    
.processEntry
    ld a, [hl]
    cp M_LCDC_VallocStatusDirty
    jr nz, .skipDMAEntry
    
    push hl
    inc hl
    push hl
    
    ;Check if servicing this request would exceed the NDMA cap
    ld a, [hli]
    cp c
    jr c, .timeRemains
    
.checkUpperBits
    ld a, b
    and a
    jr z, .exitDMAProcessingFromStack
    
    ;At this point we're ready to start talking to the NDMA hardware...
.timeRemains
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
    push af
    ld b, a
    inc b
    
    ld a, [hli]
    ld h, [hl]
    ld l, a
    
.copy_loop ;TODO: Can this be faster?
    REPT 16
    ld a, [hli]
    ld [de], a
    inc de
    ENDR
    
    dec b
    jr nz, .copy_loop
    
.done_copying
    ;Subtract from our processing cap.
    pop af
    cpl
    inc a
    add c
    jr nc, .noSubCarry
    
.subCarry
    dec b
    
.noSubCarry
    ld c, a
    
.transfer_complete
    ;Mark the transfer as completed.
    pop hl
    ld a, M_LCDC_VallocStatusClean
    ld [hl], a
    
.skipDMAEntry
    inc d
    ld a, d
    cp M_LCDC_VallocCount
    jr z, .exitDMAProcessing
    
    ld a, l
    add M_LCDC_VallocStructSize
    ld l, a
    jr nc, .processEntry
    inc h
    jr .processEntry
    
.exitDMAProcessingFromStack
    add sp, 4
    
.exitDMAProcessing
    ;Unclobber banks. TODO: What of REG_VBK?
    ld a, [H_System_CurBank]
    ld [$2000], a
    ld a, [H_System_CurRamBank]
    ld [REG_SVBK], a
    
    ret