M_System_FarCall: MACRO
    rst $00
    db BANK(\1)
    dw \1
    ENDM

M_System_FarCallRestricted: MACRO
    rst $08
    db BANK(\1)
    dw \1
    ENDM

M_System_FarRead: MACRO
    rst $10
    ENDM

M_System_FarCopy: MACRO
    rst $18
    ENDM