            :BasicUpstart2(main)

            .const border_color = $d020
            .const screen_ram = $0400
            .const screen_control_register = $d011
            .const memory_setup_register = $d018

main:
                jsr setup
                rts


setup:
                // set border color
                lda #BLACK
                sta border_color
                // switch to hi-res bitmap mode
                lda screen_control_register
                ora #%00100000
                sta screen_control_register

                // choose screen memory
                choose_screen_memory(3)
                choose_bitmap_memory(1)

                rts

            .pc = screen_memory(3)
                .import binary "background-colors.bin"

            .pc = bitmap_memory(1)
                .import binary "background-pixels.bin"

            .macro choose_screen_memory(index) {
                lda memory_setup_register
                and #%00001111
                ora #[index << 4]
                sta memory_setup_register
            }

            .function screen_memory(index) {
                .return 1024 * index
            }

            .macro choose_bitmap_memory(index) {
                lda memory_setup_register
                and #%11110111
                ora #[index << 3]
                sta memory_setup_register
            }

            .function bitmap_memory(index) {
                .return 1024 * 8 * index
            }
