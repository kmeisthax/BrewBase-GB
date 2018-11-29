INCLUDE "lib/brewbase.inc"

SECTION "Font", ROMX, BANK[2]
Game_Font::
    db 1, 8
    dw ((Game_FontGlyphs_END - Game_FontGlyphs) / 8)
    db BANK(Game_FontGlyphs)
    dw Game_FontGlyphs
    db BANK(Game_FontMetrics)
    dw Game_FontMetrics
    
Game_FontGlyphs::
    INCBIN "build/src/game/font.1bpp"
Game_FontGlyphs_END

Game_FontMetrics::
    REPT ((Game_FontGlyphs_END - Game_FontGlyphs) / 8)
    db 8,8,8,0
    ENDR
Game_FontMetrics_END

Game_UnrelatedFont::
    db 1, 16
    dw ((Game_FontGlyphs_END - Game_FontGlyphs) / 16)
    db BANK(Game_UnrelatedFontGlyphs)
    dw Game_UnrelatedFontGlyphs
    db BANK(Game_UnrelatedFontMetrics)
    dw Game_UnrelatedFontMetrics
    
Game_UnrelatedFontGlyphs::
    INCBIN "build/src/game/8bitoperator.1bpp"
Game_UnrelatedFontGlyphs_END

Game_UnrelatedFontMetrics::
    REPT ((Game_UnrelatedFontGlyphs_END - Game_UnrelatedFontGlyphs) / 16)
    db 8,16,8,0
    ENDR
Game_UnrelatedFontMetrics_END

SECTION "Window", WRAM0[$C200]
W_Game_WindowBuffer:: ds $400
W_Game_Window:: ds M_TextServices_WindowSize