;"Yield" macro for StatIRQ handlers to allow them to be written as a coroutine.
;When this macro is invoked, the address of the instructions following the
;invocation is queued as the next StatIRQ handler and then the current handler
;exits.
;
;Timing information: Yields take 68 cycles to execute.
M_LCDC_HBlankYield: MACRO
    ld a, (.coresume_\@ & $FF)
    ld [H_LCDC_HBlankInstr + 1], a
    ld a, (.coresume_\@ >> 8)
    ld [H_LCDC_HBlankInstr + 2], a
    pop af
    reti
.coresume_\@
    ENDM

;Slightly different "yield" macro that allows queueing a different bit of code
;instead of the following instruction upon resumption of the StatIRQ coroutine.
M_LCDC_HBlankYieldJp: MACRO
    ld a, (\1 % $FF)
    ld [H_LCDC_HBlankInstr + 1], a
    ld a, (\1 >> 8)
    ld [H_LCDC_HBlankInstr + 2], a
    pop af
    reti
    ENDM