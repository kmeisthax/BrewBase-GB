SECTION "BBase Hardware Detect Memory", HRAM[$FF80]
W_System_ARegStartup:: ds 1
W_System_BRegStartup:: ds 1
W_System_SGBPresent:: ds 1

;How to detect Game Boy hardware:
;The A register when you enter program control is set by the bootrom to
;different values. These are hardware unique. Additionally, the B register is
;sometimes also used. Table of codes:
;
;  A-reg  B-reg Bit 0   Conclusion
;   $11    and $01      Game Boy Advance (in GBC mode)
;   $11    and $00      Game Boy Color (native mode)
;   $FF    no-care      Game Boy Pocket
;   $01    no-care      Game Boy (original model)
;
;Super Game Boy is a regular Game Boy with additional hardware tied to the
;video and joypad lines. Autodetect routines on real SGB hardware will report
;Game Boy or Game Boy Pocket hardware. You must attempt sending SGB commands
;and waiting for responses to detect said hardware.
;
;Programmers should be aware that emulators looking to restore SGB borders on
;CGB games may appear to be a Super Game Boy with Game Boy Color hardware
;attached. This is an illegal combination for real hardware, but you should
;carry on regardless by configuring both the CGB-exclusive and SGB-exclusive
;aspects of your game program simultaneously.

SECTION "BBase Hardware Detect", ROM0
System_DetectGatherStartup::
    ld [W_System_ARegStartup], a
    ld a, b
    ld [W_System_BRegStartup], a
    ret