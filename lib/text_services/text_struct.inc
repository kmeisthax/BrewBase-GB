;Font describes a series of glyphs for use with text services.
M_TextServices_FontGlyphWidth EQU $0  ;How wide glyphs are, in bytes
M_TextServices_FontGlyphHeight EQU $1 ;How tall glyphs are, in pixels
M_TextServices_FontGlyphCount EQU $2  ;How many standalone glyphs there are.
M_TextServices_FontGlyphData EQU $3   ;Where the font glyphs live in ROM.
M_TextServices_FontMetricsData EQU $6 ;Where the font glyph metrics live in ROM.

M_TextServices_FontSize EQU $9 ;Size of the font header structure.

;Glyph data is formatted as an array of tightly packed glyphs.
;Each glyph consists of 1bpp graphics data, organized as GlyphHeight lines of
;GlyphWidth bytes in length. Pixels within a line are stored consecutively.
;For example, a font consisting of 16x16 glyphs will have a GlyphWidth of 2 and
;GlyphHeight of 16, and each glyph will occupy 32 bytes of memory. Whereas an
;8x8 font would instead have a GlyphWidth of 1 and GlyphHeight of 8, occupying
;8 bytes per glyph. Fonts with non-tile-aligned GlyphHeights are explicitly
;allowed, for example one might want to have an 8x12 font with 12 byte glyphs.

M_TextServices_MetricsWidth EQU 0    ;How many pixels of width the glyph
                                     ;occupies, not including tracking.
M_TextServices_MetricsBaseline EQU 1 ;Where the glyph baseline should be.

M_TextServices_MetricsSize EQU $2

;Window describes a location of memory where text tiles may be drawn to.
;TODO: RTL support? Seems like overkill...
M_TextServices_WindowWidth EQU $0    ;How many tiles wide the window is
M_TextServices_WindowHeight EQU $1   ;How many tiles tall the window is

;Windows can be split into rows of text.
;TODO: TBRL support? Only really useful for old-timey-looking Japanese games
;which could also just be old-timey by being RTL
M_TextServices_WindowRowHeight EQU $2;How many lines in a single row of text
M_TextServices_WindowRowBaseline EQU $3;How many lines is the baseline
                                     ;(Used to align disparate fonts)

;The Window Cursor is the graphical location of where to draw the next line of
;text.
M_TextServices_WindowCursorX EQU $4  ;X index of tile currently being drawn to.
M_TextServices_WindowCursorY EQU $5  ;Y index of tile currently being drawn to.
M_TextServices_WindowShiftX EQU $6   ;How many pixels into the current tile
                                     ;we have already drawn
M_TextServices_WindowShiftY EQU $7   ;How many lines down into the current tile
                                     ;we have already drawn

;The Font is the set of glyphs used to draw text.
M_TextServices_WindowFont EQU $8     ;Far pointer to font structure

M_TextServices_WindowBacking EQU $B  ;Far pointer to writable memory buffer
                                     ;large enough to store Width*Height tiles.

M_TextServices_WindowSize EQU $B