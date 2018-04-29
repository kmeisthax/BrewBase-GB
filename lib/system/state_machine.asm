SECTION "BBase State Machine Services", ROM0
;Read a local jump table.
;A is the desired state; HL is the address of the jump table.
;No bounds checking is performed on HL; invalid A values will crash.
;Untrusted data (e.g. save data, link cable data) must be sanitized.
;Clobbers A, HL, BC, FLAGS. Returns jump vector on HL.
System_StateMachineLookupJump::
    ld b, 0
    ld c, a
    sla c
    rl b
    add hl, bc
    ld a, [hli]
    ld h, [hl]
    ld l, a
    ret

;To be called with your function pointer in HL ready to go.
System_StateMachineIndirectCall::
    jp hl