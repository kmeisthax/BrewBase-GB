SECTION "BBase Main", ROM0[$0100]
__start:
    nop
    jp main
    
;ROM Header data follows.
;Header data is managed by rgbfix, invoked and configured by the Makefile.