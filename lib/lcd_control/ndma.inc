M_LCDC_NDMARequestProcessingCap EQU $3F
M_LCDC_NDMARequestEmulatedProcessingCap EQU $5

M_LCDC_NDMAVblankTimingReferenceStart EQU $90
M_LCDC_NDMAVblankTimingReferenceEnd EQU $9A

;From semi-empircal testing on a decent emulator:
;We can copy 9 tiles per scanline on CGB.
;We can copy 0.7 tiles per scanline on DMG.
;(Validate this on console sometime, will ya?)