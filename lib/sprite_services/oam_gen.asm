INCLUDE "lib/brewbase.inc"

SECTION "Sprite Services Object-to-OAM Generation", ROMX, BANK[1]

;Apply an object slot's parameters to an OAM sprite in memory.
;
; DE = Object slot structure
; HL = OAM sprite data to apply object parameters to
;
; Returns:
;   HL = Pointer to next OAM entry (end of current one)
SpriteServices_ApplyObjectParamsToOAMSprite::
    push af
    push bc
    
    ld a, M_SpriteServices_ObjectAttrs
    add a, e
    ld e, a
    ld a, d
    adc a, 0
    ld d, a
    ld a, [de]
    ld b, a
    
    ld a, (M_SpriteServices_ObjectAttrs - M_SpriteServices_ObjectXPos)
    sub a, e
    ld e, a
    ld a, d
    sbc a, 0
    ld d, a
    ld a, [de] ;M_SpriteServices_ObjectXPos
    
.sprite_x_check
    bit 5, b
    jr nz, .sprite_x_flipped
    
.sprite_x_normal
    add a, [hl]
    ld [hli], a
    jr .sprite_y_check
    
.sprite_x_flipped
    sub a, [hl]
    ld [hli], a

.sprite_y_check
    inc de
    ld a, [de]
    bit 6, b
    jr nz, .sprite_y_flipped
    
.sprite_y_normal
    add a, [hl]
    ld [hli], a
    jr .sprite_tbase
    
.sprite_y_flipped
    sub a, [hl]
    ld [hli], a
    
.sprite_tbase
    inc de
    ld a, [de]
    add a, [hl]
    ld [hli], a
    
.sprite_attrs
    ld a, [hl]
    add a, b
    and $07
    ld c, a ;mixed CGB palette index only
    
    ld a, [hl]
    xor a, b
    and $F8
    or a, c
    ld [hli], a ;XOR'd bits + summed CGB palette index
    
    pop bc
    pop af
    ret