M_LCDC_VallocStatus EQU $0
M_LCDC_VallocSize EQU $1 ;in 16-byte chunks
M_LCDC_VallocBackingStore EQU $2
M_LCDC_VallocBackingStoreBank EQU $4
M_LCDC_VallocLocation EQU $5
M_LCDC_VallocLocationBank EQU $7

M_LCDC_VallocStructSize EQU $8
M_LCDC_VallocCount EQU $8
M_LCDC_VallocArenaCount EQU M_LCDC_VallocStructSize * M_LCDC_VallocCount

M_LCDC_VallocStatusUndefined EQU $0 ;Entry not valid
M_LCDC_VallocStatusDirty EQU $1     ;VRAM & backing store in use, needs copying
M_LCDC_VallocStatusClean EQU $2     ;VRAM & backing store in use and matching