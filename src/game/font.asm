SECTION "Font", ROMX, BANK[2]
Game_Font::
    db 1, 8, ((Game_FontGlyphs_END - Game_FontGlyphs) / 8)
    db BANK(Game_FontGlyphs)
    dw Game_FontGlyphs
    ;TODO: Metrics
    db $1
    dw $4000
    
Game_FontGlyphs::
    INCBIN "build/src/game/font.1bpp"
Game_FontGlyphs_END