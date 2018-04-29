SECTION "PBase Bank Switch Services Memory", HRAM
W_System_CurBank:: ds 1
W_System_NextBank:: ds 1

W_System_CurRamBank:: ds 1
W_System_NextRamBank:: ds 1

SECTION "PBase RST Bank Enter Services", ROM0[$0000]
;rst $00: Enter bank A. Existing bank will be saved to stack.
;Assumes MBC-like bank switching circuit at $2000.
System_BankEnter::
    ld [W_System_NextBank], a
    ld a, [W_System_CurBank]
    push af
    ld a, [W_System_NextBank]
    jr System_BankExit.set_bank_raw

SECTION "PBase RST Bank Exit Services", ROM0[$0010]
;rst $10: Exit bank A. Previous bank will be switched from stack.
System_BankExit::
    pop af
    
.set_bank_raw
    ld [W_System_CurBank], a
    ld [$2000], a
    ret

SECTION "PBase RST Bank Switch Services", ROM0[$0018]
;rst $18: Switch to a new bank without bookkeeping.
System_BankSwitch::
    ld [W_System_CurBank], a
    ld [$2000], a
    ret
    
SECTION "PBase Bank Switch Services Initialize", ROM0
;Initialize the bank system, if present, to bank 1.
;We avoid the use of the potentially invalid bank 0.
System_BankInit::
    ld a, 1
    ld [W_System_CurBank], a
    ld [W_System_NextBank], a
    ld [$2000], a
    ret