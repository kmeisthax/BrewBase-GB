INCLUDE "lib/brewbase.inc"

SECTION "LCDC Valloc Utils", ROM0
; Given the necessary parameters, initialize a given Valloc.
; 
; The valloc will be marked dirty so that it's written to at the end of 
; 
; A = Valloc ID to initialize
; BC = Backing store near pointer (4bit aligned)
; D = Backing store bank
; E = Valloc size (16-byte units)
; SP+2 = VRAM pointer
; SP+4 = VRAM bank (high byte)
LCDC_CreateVallocMapping::
    push bc
    
    ld hl, W_LCDC_VallocArena
    ld b, 0
    ld c, a
    
    sla c
    rl b
    sla c
    rl b
    sla c
    rl b
    add hl, bc
    
    pop bc
    push hl
    inc hl
    ld a, e
    ld [hli], a
    
    ld a, c
    ld [hli], a
    
    ld a, b
    ld [hli], a
    
    ld a, d
    ld [hli], a
    
    add sp, 4
    pop bc
    pop de
    add sp, -8
    
    ld a, c
    ld [hli], a
    
    ld a, b
    ld [hli], a
    
    ld a, d
    ld [hli], a
    
    pop hl
    ld a, M_LCDC_VallocStatusDirty
    ld [hli], a
    
    ret