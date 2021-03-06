p0:                 .byte $0
p1:                 .byte $0

plot_buffer_lo:     .byte <screen
plot_buffer_hi:     .byte >screen
plot_buffer_x:      .byte $28
plot_buffer_y:      .byte $19
plot_char:          .byte $3a
plot_color:         .byte $08

plot_y_offset:      .byte $ff
plot_color_difference: .byte $d4 // Difference in memory between char and color mem

plot_delay:         .byte $00

plot_point: 
            txa
            pha
            tya
            pha

            clc
            lda p0
            cmp plot_buffer_x
            bcs !exit+

            lda p1
            sbc plot_y_offset
            sta p1
            cmp plot_buffer_y    
            bcs !exit+

            lda p1
            pha

            lda plot_buffer_x
            sta num2

//------------------------
// 8bit * 8bit = 16bit multiply
// By White Flame
// Multiplies "num1" by "num2" and stores result in .A (low byte, also in .X) and .Y (high byte)
// uses extra zp var "num1Hi"

// .X and .Y get clobbered.  Change the tax/txa and tay/tya to stack or zp storage if this is an issue.
//  idea to store 16-bit accumulator in .X and .Y instead of zp from bogax

// In this version, both inputs must be unsigned
// Remove the noted line to turn this into a 16bit(either) * 8bit(unsigned) = 16bit multiply.

            lda #$00
            tay
            sty num1+1  // remove this line for 16*8=16bit multiply
            beq enterLoop

doAdd:      clc
            adc p1
            tax

            tya
            adc num1+1
            tay
            txa

!loop:
            asl p1
            rol num1+1
enterLoop:  // accumulating multiply entry point (enter with .A=lo, .Y=hi)
            lsr num2
            bcs doAdd
            bne !loop-
            tya
            adc plot_buffer_hi
            sta $03
            clc
            txa
            adc plot_buffer_lo
            sta $02
            bcc !next+
            inc $03
!next:      ldy p0
            lda plot_char
            sta ($02),y

            // Do color - don't do this on the PET obvs
            lda plot_color_difference
            beq !no_color+
            lda $03
            pha
            clc
            adc plot_color_difference
            sta $03
            lda plot_color
            sta ($02),y
            pla
            sta $03
!no_color:
            pla
            sta p1
            
            lda curve_is_filled
            beq !next+
            jsr plot_vertical
!next:

!exit:      
//             //// Delay

            lda plot_delay
            beq !next+
            ldx #$3f
!loop_i:    ldy #$2f
!loop_ii:   nop
            dey
            bne !loop_ii-
            dex
            bne !loop_i-

//             //// Delay
!next:
            pla
            tay
            pla
            tax
            rts

// rename 'curve' specific variables

plot_vertical:      ldx p1
                    cpx plot_buffer_y
                    beq !exit+    
                    cpy plot_buffer_x
                    bcs !exit+
!loop:              lda $02
                    clc
                    adc plot_buffer_x
                    sta $02
                    bcc !next+
                    inc $03
!next:
                    lda curve_fill_char
                    sta ($02),y

                    // Do color - don't do this on the PET obvs
                    lda plot_color_difference
                    beq !next+
                    lda $03
                    pha
                    clc
                    adc plot_color_difference
                    sta $03
                    lda curve_fill_color
                    sta ($02),y
                    pla
                    sta $03
!next:
                    inx
                    cpx plot_buffer_y
                    bne !loop-

!exit:              rts
