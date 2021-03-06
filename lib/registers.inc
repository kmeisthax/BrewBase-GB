;Locations and names for common hardware registers.

REG_JOYP EQU $FF00
REG_SB EQU $FF01
REG_SC EQU $FF02
REG_IF EQU $FF0F
REG_NR10 EQU $FF10
REG_NR11 EQU $FF11
REG_NR12 EQU $FF12
REG_NR13 EQU $FF13
REG_NR14 EQU $FF14
REG_NR21 EQU $FF16
REG_NR22 EQU $FF17
REG_NR23 EQU $FF18
REG_NR24 EQU $FF19
REG_NR30 EQU $FF1A
REG_NR31 EQU $FF1B
REG_NR32 EQU $FF1C
REG_NR33 EQU $FF1D
REG_NR34 EQU $FF1E
REG_NR41 EQU $FF20
REG_NR42 EQU $FF21
REG_NR43 EQU $FF22
REG_NR44 EQU $FF23
REG_NR50 EQU $FF24
REG_NR51 EQU $FF25
REG_NR52 EQU $FF26
REG_LCDC EQU $FF40
REG_STAT EQU $FF41
REG_SCY EQU $FF42
REG_SCX EQU $FF43
REG_LY EQU $FF44
REG_LYC EQU $FF45
REG_DMA EQU $FF46
REG_BGP EQU $FF47
REG_OBP0 EQU $FF48
REG_OBP1 EQU $FF49
REG_WY EQU $FF4A
REG_WX EQU $FF4B
REG_KEY1 EQU $FF4D
REG_VBK EQU $FF4F
REG_HDMA1 EQU $FF51
REG_HDMA2 EQU $FF52
REG_HDMA3 EQU $FF53
REG_HDMA4 EQU $FF54
REG_HDMA5 EQU $FF55
REG_RP EQU $FF56
REG_BGPI EQU $FF68
REG_BGPD EQU $FF69
REG_OBPI EQU $FF6A
REG_OBPD EQU $FF6B
REG_SVBK EQU $FF70
REG_IE EQU $FFFF

;Locations and names for MBC3-specific registers

REG_MBC3_SRAMENABLE EQU $0000
REG_MBC3_ROMBANK EQU $2000
REG_MBC3_SRAMBANK EQU $4000
REG_MBC3_RTCLATCH EQU $6000

;Hardware-specified VRAM locations

VRAM_TPT0 EQU $8000 ;Tile Pattern Table 0, can be used by sprites and BG.
VRAM_TPT1 EQU $8800 ;Tile Pattern Table 1, can be used by BG and window.
VRAM_TMAP0 EQU $9800 ;Tile Maps ("nametable" in NESspeak)
VRAM_TMAP1 EQU $9C00

M_VRAM_TMAPSIZE EQU $400

;Boot ROM specified hardware class values

M_BIOS_CPU_DMG EQU $01 ;also SGB
M_BIOS_CPU_MGB EQU $FF ;also SGB2
M_BIOS_CPU_CGB EQU $11 ;also GBA