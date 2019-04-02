INCLUDE "lib/brewbase.inc"

SECTION "Double Speed Mode", ROM0
;Enable CPU double speed mode.
;
;This function has no effect on non-Color class hardware (DMG, SGB/SGB2, very
;pedantic emulators).
System_EnableDoubleSpeed::
    ld a, [REG_KEY1]
    bit 7, a
    ret nz
    jr System_SwitchDoubleSpeed

;Disable CPU double speed mode.
;
;This function has no effect on non-Color class hardware (DMG, SGB/SGB2, very
;pedantic emulators).
System_DisableDoubleSpeed::
    ld a, [REG_KEY1]
    bit 7, a
    ret z

;Toggle CPU double speed mode.
;
;This function has no effect on non-Color class hardware (DMG, SGB/SGB2, very
;pedantic emulators).
System_SwitchDoubleSpeed::
    ld a, $30
    ld [REG_JOYP], a

    ld a, 1
    ld [REG_KEY1], a
    stop
    ret