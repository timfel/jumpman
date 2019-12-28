            :BasicUpstart2(main)
            .import source "stdlib.asm"



main:
                jsr setup
game_loop:
                nop
                jmp game_loop
                rts


draw_background:
                hires_mode(1)
                multicolor_mode(0)
                // border and bg
                lda #GRAY
                sta border_color
                sta bg_color
                set_bank(screen_memory(3), bitmap_memory(1))
                rts

            .pc = screen_memory(3) "Bitmap"
                .import binary "bg.scr"

            .pc = bitmap_memory(1) "Bitmap Pixels"
                // .fill picture.getBitmapSize(), picture.getBitmap(i)
                .import binary "bg.map"


setup:
                jsr draw_background

                // lda #GREY
                // sta border_color

                // lda #%11
                // sta sprites.enable_bits

                // ldx #180
                // stx sprites.positions + 0
                // stx sprites.positions + 2
                // ldy #140
                // sty sprites.positions + 1
                // sty sprites.positions + 3
                // lda #BROWN
                // sta sprites.colors
                // lda #BLACK
                // sta sprites.colors + 1

                rts

            // .pc = color_ram
            //     .fill picture.getColorRamSize(), picture.getColorRam(i)

            .pc = sprite_memory(0) "Cannon Sprite"
            // shadow
            :sprite_row(%000000000000000000000000)
            :sprite_row(%000000000000000000000000)
            :sprite_row(%000000000000000000000000)
            :sprite_row(%000000000000000000000000)
            :sprite_row(%000000000000000000000000)
            :sprite_row(%000000000000000000000000)
            :sprite_row(%000000000000000000000000)
            :sprite_row(%000000000111111111100000)
            :sprite_row(%000000000000000011000000)
            :sprite_row(%000000000000000110000000)
            :sprite_row(%000000000000001100000000)
            :sprite_row(%000000000000011000000000)
            :sprite_row(%000000000000110000000000)
            :sprite_row(%000000000001100000000000)
            :sprite_row(%000000000011000000000000)
            :sprite_row(%000000000111111111100000)
            :sprite_row(%000000000000000000000000)
            :sprite_row(%000000000000000000000000)
            :sprite_row(%000000000000000000000000)
            :sprite_row(%000000000000000000000000)
            :sprite_row(%000000000000000000000000)
            // padding
            :sprite_row(%000000000000000000000000)
            :sprite_row(%000000000000000000000000)
            :sprite_row(%000000000000000000000000)
            :sprite_row(%00000000000000000000)
            // lodo
            :sprite_row(%000000000000000000000000)
            :sprite_row(%000000000000000000000000)
            :sprite_row(%000000000000000000000000)
            :sprite_row(%000000000000000000000000)
            :sprite_row(%000000000000000000000000)
            :sprite_row(%000000000000000000000000)
            :sprite_row(%000000011111111110000000)
            :sprite_row(%000000000000001100000000)
            :sprite_row(%000000000000011000000000)
            :sprite_row(%000000000000110000000000)
            :sprite_row(%000000000001100000000000)
            :sprite_row(%000000000011000000000000)
            :sprite_row(%000000000110000000000000)
            :sprite_row(%000000001100000000000000)
            :sprite_row(%000000011111111110000000)
            :sprite_row(%000000000000000000000000)
            :sprite_row(%000000000000000000000000)
            :sprite_row(%000000000000000000000000)
            :sprite_row(%000000000000000000000000)
            :sprite_row(%000000000000000000000000)
            :sprite_row(%000000000000000000000000)

            .macro sprite_row(value) {
                .byte extract_byte(value, 2), extract_byte(value, 1), extract_byte(value, 0)
            }

            .function extract_byte(value, byte_id) {
                .var bits = byte_id * 8
                .eval value = value >> bits
                .return value & 255
            }
