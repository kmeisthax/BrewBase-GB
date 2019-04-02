INCLUDE "lib/brewbase.inc"

SECTION "SRAM State Machine Memory", WRAM0
W_SRAMTest_StateMachineState:: ds 1
W_SRAMTest_StringPtr:: ds 2

SECTION "SRAM State Machine", ROMX, BANK[2]
;Execute one step of the main state machine.
;All registers are assumed clobbered.
SRAMTest_StateMachine::
    ld a, [W_SRAMTest_StateMachineState]
    cp (.table_end - .table) / 2
    jr nc, .invalid_state
    
    ld hl, .table
    call System_StateMachineLookupJump
    jp hl
    
.table
    dw SRAMTest_StateLoadScreen
    dw SRAMTest_PersistenceText
    dw SRAMTest_DrawPersistenceText
.table_end

.invalid_state
    ret

SRAMTest_StateLoadScreen::
    ld a, %11100100
    ld [W_LCDC_ShadowBGP], a
    ld a, %10000001
    ld [W_LCDC_ShadowLCDC], a
    
    ld a, $20
    ld [W_LCDC_ShadowLYC], a
    
    ld a, %01000000
    ld [REG_STAT], a
    
    ;If a spurious interrupt was generated, kill it
    ld a, [REG_IF]
    res 1, a
    ld [REG_IF], a
    
    ld a, [REG_IE]
    set 1, a
    ld [REG_IE], a
    
    ld a, $FF
    ld [W_LCDC_PaletteBGShadow + 0], a
    ld a, $7F
    ld [W_LCDC_PaletteBGShadow + 1], a
    ld a, $52
    ld [W_LCDC_PaletteBGShadow + 2], a
    ld a, $4A
    ld [W_LCDC_PaletteBGShadow + 3], a
    ld a, $8C
    ld [W_LCDC_PaletteBGShadow + 4], a
    ld a, $31
    ld [W_LCDC_PaletteBGShadow + 5], a
    ld a, $00
    ld [W_LCDC_PaletteBGShadow + 6], a
    ld a, $00
    ld [W_LCDC_PaletteBGShadow + 7], a
    
    ld a, M_LCDC_PalettesDirty
    ld [W_LCDC_PaletteBGShadowStatus], a

    call SRAMTest_ConsoleInit
    
    ld a, 1
    ld [W_SRAMTest_StateMachineState], a
    
    ret

SRAMTest_PersistenceText::
    ld bc, .text
    call SRAMTest_QueueText
    
    ld a, 2
    ld [W_SRAMTest_StateMachineState], a

    ret

.text
    db "Persistence: ", 0
.text_end

SRAMTest_DrawPersistenceText::
    call SRAMTest_DrawText
    cp a, 0
    ret z
    
    ld a, 3
    ld [W_SRAMTest_StateMachineState], a

    ret