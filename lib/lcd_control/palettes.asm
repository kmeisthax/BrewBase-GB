INCLUDE "lib/brewbase.inc"

SECTION "LCDC Palette Memory", WRAM0
W_LCDC_PaletteBGShadow:: ds M_LCDC_PaletteSize
W_LCDC_PaletteOBShadow:: ds M_LCDC_PaletteSize

W_LCDC_PaletteBGShadowStatus:: ds 1
W_LCDC_PaletteOBShadowStatus:: ds 1

SECTION "LCDC Palette Utils", ROM0
; Copy the background palettes shadow to color RAM.
; 
; This routine does nothing if palette shadow memory isn't flagged as dirty.
; Once a transfer has completed, palettes will be flagged as clean. Thus, to
; periodically update palettes, you must mark them as dirty every frame.
; 
; This routine is intended to be run during VBlank. Timing-sensitive cases,
; such as mid-scanline palette replacement, requrire a more optimized routine.
LCDC_FlushBGPShadow::
    push af
    push bc
    push hl
    
    ld a, [W_LCDC_PaletteBGShadowStatus]
    cp M_LCDC_PalettesDirty
    jr nz, .exit
    
    ld a, $80
    ld [REG_BGPI], a ;Autoindex from the top
    
    ld hl, W_LCDC_PaletteBGShadow
    ld b, M_LCDC_PaletteSize
    
.copy_loop
    ld a, [hli]
    ld [REG_BGPD], a
    dec b
    jr nz, .copy_loop
    
    ld a, M_LCDC_PalettesClean
    ld [W_LCDC_PaletteBGShadowStatus], a
    
.exit
    pop hl
    pop bc
    pop af
    ret

; Copy the object palettes shadow to color RAM.
; 
; This routine does nothing if palette shadow memory isn't flagged as dirty.
; Once a transfer has completed, palettes will be flagged as clean. Thus, to
; periodically update palettes, you must mark them as dirty every frame.
; 
; This routine is intended to be run during VBlank. Timing-sensitive cases,
; such as mid-scanline palette replacement, requrire a more optimized routine.
LCDC_FlushOBPShadow::
    push af
    push bc
    push hl
    
    ld a, [W_LCDC_PaletteOBShadowStatus]
    cp M_LCDC_PalettesDirty
    jr nz, .exit
    
    ld a, $80
    ld [REG_BGPI], a ;Autoindex from the top
    
    ld hl, W_LCDC_PaletteOBShadow
    ld b, M_LCDC_PaletteSize
    
.copy_loop
    ld a, [hli]
    ld [REG_BGPD], a
    dec b
    jr nz, .copy_loop
    
    ld a, M_LCDC_PalettesClean
    ld [W_LCDC_PaletteBGShadowStatus], a
    
.exit
    pop hl
    pop bc
    pop af
    ret