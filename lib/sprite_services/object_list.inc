M_SpriteServices_ObjectStatus EQU 0 ;Object Status (bitfield, see below)
M_SpriteServices_ObjectXPos EQU 1 ;X Position of object (OAM coordinates)
M_SpriteServices_ObjectYPos EQU 2 ;Y Position of object (OAM coordinates)
M_SpriteServices_ObjectTBase EQU 3 ;Base tile index of object.
                                   ;Will be added to the metasprite's tile
                                   ;index.
M_SpriteServices_ObjectAttrs EQU 4 ;Base attributes of object.
                                   ;Will be added to the metasprite's
                                   ;attributes:
                                   ;
                                   ; Base Priority is XOR'd with sprite
                                   ;      Priority.
                                   ; Base X Flip inverts sprite X coordinates
                                   ;      and is XOR'd with sprite X Flip.
                                   ; Base Y Flip inverts sprite Y coordinates
                                   ;      and is XOR'd with sprite Y Flip.
                                   ;     (Also, Y-flipped sprite lists are
                                   ;      inserted into OAM backwards for the
                                   ;      sake of segmentation.)
                                   ; Base DMG OBJ Palette is XOR'd with sprite.
                                   ; Base tile VRAM bank is added to sprite's.
                                   ;     (Since this is one bit, it's also an
                                   ;      XOR)
                                   ; Base CGB OBJ Palette is added to sprite's
                                   ;      modulo 8.
M_SpriteServices_ObjectSprite EQU 5 ;Far pointer to start of metasprite data.
                                    ;Metasprite data consists of a series of
                                    ;OAM sprite commands and other ancillary
                                    ;data.
M_SpriteServices_ObjectSpriteLine EQU 8 ;Near pointer to the start of the
                                        ;current line of sprites.
M_SpriteServices_ObjectScript EQU $A ;Near pointer to the next script
                                     ;instruction to execute.
M_SpriteServices_ObjectScriptReset EQU $C ;Near pointer to the start of the
                                          ;animation script.
M_SpriteServices_ObjectAnimDelay EQU $E ;Number of animation frames to wait
                                        ;until the current 
M_SpriteServices_ObjectState EQU $F ;Arbitrary object state value to be used by
                                    ;the script to select an animation. Can
                                    ;enumerate things such as a walking
                                    ;direction or something else.
M_SpriteServices_ObjectSize EQU $10

;Object Status Bits
M_SpriteServices_ObjectStatusUnused EQU 0 ;Object slot not in use.
M_SpriteServices_ObjectStatusValid EQU $1 ;When set, object slot is in use and
                                          ;must not be reused.
                                          ;When not set, object slot may be
                                          ;allocated for usage.
M_SpriteServices_ObjectStatusVisible EQU $2 ;When set, object may generate OAM
                                            ;sprites.
M_SpriteServices_ObjectStatusAnimated EQU $4 ;When set, object animation
                                             ;scripts are valid and may execute
                                             ;(if Playing bit is set)
M_SpriteServices_ObjectStatusPlaying EQU $8 ;When set, object delay counters
                                            ;may tick down to zero and, if at
                                            ;zero, object animation scripts may
                                            ;execute (if they exist).

;Object Script Opcodes
M_SpriteServices_ObjectScriptSPR EQU $E0
    ;SPR - Operands: Count of sprites, followed by OAM sprite data
    ;
    ; Sets ObjectSprite and ObjectSpriteLine for the current sprite slot.
    ; 
    ; Up to 255 sprites worth of data may follow the SPR instruction and it's
    ; length opcode. This sprite data shall be mixed with the base values for
    ; the given object slot in order to generate sprite data every frame.
M_SpriteServices_ObjectScriptJMP EQU $E1
    ;JMP - Operands: Near pointer to further code to execute
    ;
    ; Changes the location of the next instruction (ObjectScript) to the
    ; given operand.
M_SpriteServices_ObjectScriptBRA EQU $E2
    ;BRA - Operands: The lower bound, the upper bound, followed by a list of
    ;                pointers to other bits of script to execute.
    ;
    ; Changes the location of the next instruction (ObjectScript) to a given
    ; script, based on the state (ObjectState). The state bounds consist of a
    ; lower and upper bound, in that order. A state value less than the lower
    ; bound, or greater than or equal to the upper bound, will not cause a
    ; branch and will instead continue executing after the BRA instruction.
    ;
    ; Assuming the bounds conditions are met, the lower bound is subtracted
    ; from the state value to produce a table index. This is then used to
    ; index the table immediately following the bounds operands.
    ; 
    ; It is recommended that all sprite animations start with something like
    ; the following:
    ; 
    ; .reset
    ;   BRA 0, 3, .up, .right, .bottom, .left
    ;   STOP 0
M_SpriteServices_ObjectScriptDELAY EQU $E3
    ;DELAY - Operands: A frame count to delay for
    ; 
    ; Pauses script execution for some number of frames. During this time, the
    ; last installed sprite list will continue to be visible. No further script
    ; commands will execute until the delay counter associated with this object
    ; has elapsed.
M_SpriteServices_ObjectScriptSTOP EQU $E4
    ;STOP - Operands: A frame count to delay for
    ;
    ; Stop script animation by revoking the Playing status bit.
    ; 
    ; When stopped, object scripts don't execute and delay counters don't count
    ; down. You still have the option of setting a delay here, which will apply
    ; if the sprite is set to play again.