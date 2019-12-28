            :BasicUpstart2(main)
            .import source "stdlib.asm"

            .const sprite_start = 254

main:
                jsr setup
game_loop:
                nop
                jmp game_loop
                rts


enable_hires_mode:
                hires_mode(1)
                multicolor_mode(0)
                // border and bg
                lda #GRAY
                sta border_color
                sta bg_color
                set_bank(screen_memory(3), bitmap_memory(1))
                rts

draw_background:
                jsr enable_hires_mode
                rts


setup:
                jsr draw_background

                lda #GREY
                sta border_color

                lda #%11
                sta sprites.enable_bits

                ldx #180
                stx sprites.positions + 0
                stx sprites.positions + 2
                ldy #140
                sty sprites.positions + 1
                sty sprites.positions + 3
                lda #BROWN
                sta sprites.colors
                lda #BLACK
                sta sprites.colors + 1

                lda #sprite_start
                sta sprites.pointers + screen_ram
                lda #sprite_start + 1
                sta sprites.pointers + 1 + screen_ram


                rts

            // .pc = color_ram
            //     .fill picture.getColorRamSize(), picture.getColorRam(i)

            .pc = 64 * sprite_start "Cannon Sprite"
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

            .pc = screen_memory(3) "Bitmap"
                .import binary "bg.scr"

            .pc = bitmap_memory(1) "Bitmap Pixels"
                // .fill picture.getBitmapSize(), picture.getBitmap(i)
                .import binary "bg.map"
