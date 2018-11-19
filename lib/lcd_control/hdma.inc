M_LCDC_HDMARequestVblankScreenLine EQU 144
M_LCDC_HDMARequestSafetyBuffer EQU 4 ;How 'close' we're allowed to get to the
                                     ;Vblank scanline before we cut off HDMA.
M_LCDC_HDMARequestTerminationLine EQU M_LCDC_HDMARequestVblankScreenLine - M_LCDC_HDMARequestSafetyBuffer