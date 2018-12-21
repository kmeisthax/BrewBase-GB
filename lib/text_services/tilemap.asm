INCLUDE "lib/brewbase.inc"

SECTION "Text Services Tilemap Generators", ROMX, BANK[$1]
;Given a window, draw it's tilemap onto the background or window layers.
;
; HL = Pointer to window structure
TextServices_DrawWindowTilemap::
    push af
    push de
    push bc
    
    ld de, M_TextServices_WindowWidth
    add hl, de
    ld a, [hli]
    ld b, a
    ld a, [hli]
    ld c, a
    
    ld de, (M_TextServices_WindowTileAttr - (M_TextServices_WindowHeight + 1))
    add hl, de
    ld d, b ;M_TextServices_WindowWidth
    ld e, c ;M_TextServices_WindowHeight
    ld a, [hld]
    ld c, a ;M_TextServices_WindowTileAttr
    ld a, [hld]
    ld b, a ;M_TextServices_WindowTileIndex
    ld a, [hld]
    ld l, [hl]
    ld h, a ;M_TextServices_WindowTilePtr
    
    push de
    push hl
    
    xor a
    ld [REG_VBK], a
    
.tile_row_loop
    push de

.tile_tile_loop
    di
    
    ;TIMING CRITICAL AREA
.tile_vram_sync
    ld a, [REG_STAT]
    bit 1, a
    jr nz, .tile_vram_sync
    
.tile_vram_safe
    ld [hl], b
    ;END TIMING CRITICAL AREA
    
    ei
    
.tile_end_tile_loop
    inc b
    inc hl
    dec d
    jr nz, .tile_tile_loop
    
.tile_end_row_loop
    pop de
    
    ;HL += (32 - WindowWidth)
    ld a, 32
    sub d
    add l
    ld l, a
    ld a, h
    adc a, 0
    ld h, a
    
    dec e
    jr nz, .tile_row_loop
    
.begin_attr_draw
    pop hl
    pop de
    
    ld a, [W_System_ARegStartup]
    cp M_BIOS_CPU_CGB
    jr nz, .no_attrs
    
    ld a, 1
    ld [REG_VBK], a
    
.attr_row_loop
    push de

.attr_tile_loop
    di
    
    ;TIMING CRITICAL AREA
.attr_vram_sync
    ld a, [REG_STAT]
    bit 1, a
    jr nz, .attr_vram_sync
    
.attr_vram_safe
    ld [hl], c
    ;END TIMING CRITICAL AREA
    
    ei
    
.attr_end_tile_loop
    inc hl
    dec d
    jr nz, .attr_tile_loop
    
.attr_end_row_loop
    pop de
    
    ;HL += (32 - WindowWidth)
    ld a, 32
    sub d
    add a, l
    ld l, a
    ld a, h
    adc a, 0
    ld h, a
    
    dec e
    jr nz, .attr_row_loop
    
.no_attrs
    pop bc
    pop de
    pop af
    ret