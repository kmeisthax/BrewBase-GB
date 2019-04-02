INCLUDE "lib/brewbase.inc"
INCLUDE "lib/cart/mbc5/save_ram.inc"

SECTION "Save RAM Routines", ROM0
;Enable save RAM.
;
;This causes memory at $A000-BFFF to become usable. Depending on the state of
;the cartridge, this memory region may optionally persist between executions of
;the program.
Cart_OpenSaveData::
    push af

    ld a, M_Cart_RAM_UNLOCKED
    ld [M_Cart_REG_RAMENABLE], a

    xor a
    ld [M_Cart_REG_RAMBANK], a

    pop af
    ret

;Disable save RAM.
;
;This causes memory at $A000-BFFF to become unusable.
Cart_CloseSaveData::
    push af

    ld a, M_Cart_RAM_LOCKED
    ld [M_Cart_REG_RAMENABLE], a

    pop af
    ret

;Select a specific save bank.
;
;This causes memory at $A000-BFFF to be mapped to the bank named in register A.
;The bank number must not exceed the amount of SRAM physically present in the
;cartridge.
Cart_ChangeSaveBank::
    and a, M_Cart_RAMMASK
    ld [M_Cart_REG_RAMBANK], a
    ret
