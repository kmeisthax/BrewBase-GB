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
    ld d, 0     ;current arena entry
    ld bc, M_LCDC_NDMARequestProcessingCap    ;total processing time remaining
    ld hl, W_LCDC_VallocArena
    
.processEntry
    ld a, [hli]
    cp M_LCDC_VallocStatusDirty
    jr nz, .skipDMAEntry
    
    push hl
    
    ;Check if servicing this request would exceed the NDMA cap
    ld a, [hli]
    cp c
    jr c, .timeRemains
    
.checkUpperBits
    ld a, b
    and a
    jr z, .exitDMAProcessing
    
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
    ld a, M_LCDC_VallocStatusClean
    ld [hl], a
    
.skipDMAEntry
    inc d
    ld a, d
    cp M_LCDC_VallocCount
    jr z, .exitDMAProcessing
    
    ld a, l
    add M_LCDC_VallocSize
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