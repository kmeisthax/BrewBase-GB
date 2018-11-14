INCLUDE "lib/brewbase.inc"

SECTION "System Memory Init", ROM0
;Clear system WRAM.
;
;NOTE: This does not follow standard callee-cleanup procedures since it's an
;init utility.
;
;WARN: Do not call this routine while SP is in WRAM or you will crash the game.
System_MemoryInit::
    ld hl, $C000
    ld de, $1000
    call System_Memclear
    
    ld a, 1
.bank_clear
    ld [REG_SVBK], a
    ld hl, $D000
    ld de, $1000
    call System_Memclear
    
    inc a
    cp 8
    jr nc, .bank_clear
    ret
    
;Clear a block of memory.
;
;HL = Start
;DE = Length
System_Memclear::
    push af
    
.do_overwrite
    dec de
    xor a
    or a, d
    or a, e
    jr z, .overwrite_done
    
.no_carry
    xor a
    ld [hli], a
    jr .do_overwrite
    
.overwrite_done
    pop af
    ret