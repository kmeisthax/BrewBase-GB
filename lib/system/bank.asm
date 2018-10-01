INCLUDE "lib/brewbase.inc"

SECTION "PBase Bank Switch Services Memory", HRAM
H_System_CurBank:: ds 1
H_System_CurRamBank:: ds 1

H_System_RegReserveA:: ds 1
H_System_RegReserveH:: ds 1
H_System_RegReserveL:: ds 1
H_System_LastBank:: ds 1

SECTION "PBase RST Bank Services", ROM0[$0000]
;Call code in another bank. Bank and pointer are encoded directly after the RST
;BC and DE can be passed into and returned from far calls directly. A/HL will
;be shuttled through RegReserve for passed arguments and returned arguments.
System_FarCall::
    jp System_FarCall_int

SECTION "PBase RST Bank Services 2", ROM0[$0008]
;Call code in another bank with restricted registers.
;Bank and pointer are encoded directly after the RST.
;Only BC and DE may be passed into and returned from far calls directly.
;This saves 88 cycles over the regular FarCall routine.
System_FarCallRestricted::
    jp System_FarCallRestricted_int

SECTION "PBase RST Bank Services 3", ROM0[$0010]
;Read one byte from A:HL and store it in A, incrementing HL along the way.
System_FarRead::
    jp System_FarRead_int

SECTION "PBase RST Bank Services 4", ROM0[$0018]
;Read two bytes from A:HL and store it in HL.
;Ideal for reading pointers in far memory.
System_FarSnap::
    jp System_FarSnap_int

SECTION "PBase RST Bank Services 5", ROM0[$0020]
;Copy BC bytes from A:HL to DE.
;HL and DE will point to the end of their respective buffers.
System_FarCopy::
    jp System_FarCopy_int

SECTION "PBase Bank Switch Services Initialize", ROM0
;Initialize the bank system, if present, to bank 1.
;We avoid the use of the potentially invalid bank 0.
System_BankInit::
    ld a, 1
    ld [H_System_CurBank], a
    ld [$2000], a
    ret

System_FarCall_int::
    ld [H_System_RegReserveA], a
    ld a, h
    ld [H_System_RegReserveH], a
    ld a, l
    ld [H_System_RegReserveL], a
    pop hl
    
    ;Switch banks
    ld a, [H_System_CurBank]
    ld [H_System_LastBank], a
    
    ld a, [hli] ;Farcall bank ptr
    ld [H_System_CurBank], a
    ld [$2000], a
    push hl
    
    ld a, [H_System_LastBank]
    push af
    
    ld a, [hli] ;Farcall function ptr
    ld l, [hl]
    ld h, a
    call .farjmp
    
    ;Preserve A and HL for return.
    ld [H_System_RegReserveA], a
    ld a, h
    ld [H_System_RegReserveH], a
    ld a, l
    ld [H_System_RegReserveL], a
    
    pop af
    ld [H_System_CurBank], a
    ld [$2000], a
    
    pop hl
    inc hl
    inc hl
.farjmp
    jp hl

System_FarCallRestricted_int::
    pop hl
    
    ;Switch banks
    ld a, [H_System_CurBank]
    ld [H_System_LastBank], a
    
    ld a, [hli] ;Farcall bank ptr
    ld [H_System_CurBank], a
    ld [$2000], a
    push hl
    
    ld a, [H_System_LastBank]
    push af
    
    ld a, [hli] ;Farcall function ptr
    ld l, [hl]
    ld h, a
    call .farjmp
    
    pop af
    ld [H_System_CurBank], a
    ld [$2000], a
    
    pop hl
    inc hl
    inc hl
.farjmp
    jp hl

System_FarRead_int::
    ld [$2000], a
    
    ld a, [hli]
    push af
    
    ld a, [H_System_CurBank]
    ld [$2000], a
    
    pop af
    ret

System_FarSnap_int::
    ld [$2000], a
    
    ld a, [hli]
    ld h, [hl]
    ld l, a
    
    ld a, [H_System_CurBank]
    ld [$2000], a
    
    ret

System_FarCopy_int::
    ld [$2000], a
    
.copy_loop
    ld a, [hli]
    ld [de], a
    inc de
    dec bc
    jp nz, .copy_loop
    
    ld a, [H_System_CurBank]
    ld [$2000], a
    ret