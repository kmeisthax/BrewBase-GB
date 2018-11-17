INCLUDE "lib/brewbase.inc"

SECTION "Font", ROMX, BANK[2]
Game_Font::
    db 1, 8
    dw ((Game_FontGlyphs_END - Game_FontGlyphs) / 8)
    db BANK(Game_FontGlyphs)
    dw Game_FontGlyphs
    ;TODO: Metrics
    db $1
    dw $4000
    
Game_FontGlyphs::
    INCBIN "build/src/game/font.1bpp"
Game_FontGlyphs_END

SECTION "Window", WRAM0[$C200]
W_Game_WindowBuffer:: ds $100
W_Game_Window:: ds M_TextServices_WindowSize