INCLUDE "lib/brewbase.inc"

SECTION "SRAM Test Vectors", ROMX, BANK[2]
SRAMTest_Header::
    db "BREWBASE GB TEST1", 0
.end

;Check if the SRAM header is installed.
;Returns 1 if installed, 0 if not.
SRAMTest_CheckHeader::
    push hl
    push de
    push bc

    call Cart_OpenSaveData

    ld hl, SRAMTest_Header
    ld de, SRAMTest_Header.end - SRAMTest_Header
    ld bc, $A000

.loop
    ld a, [bc]
    cp a, [hl]
    jr nz, .test_failure
    inc hl
    inc bc
    dec de
    jr nz, .loop

    ld a, 1

    call Cart_CloseSaveData
    
    pop bc
    pop de
    pop hl
    ret

.test_failure
    ld a, 0

    call Cart_CloseSaveData

    pop bc
    pop de
    pop hl
    ret

;Install the test header
SRAMTest_InstallHeader::
    push hl
    push de
    push bc
    push af

    call Cart_OpenSaveData

    ld hl, $A000
    ld de, SRAMTest_Header.end - SRAMTest_Header
    ld bc, SRAMTest_Header

.loop
    ld a, [bc]
    ld [hli], a
    inc bc
    dec de
    jr nz, .loop

    call Cart_CloseSaveData

    pop af
    pop bc
    pop de
    pop hl
    ret