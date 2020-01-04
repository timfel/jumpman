            .importonce

            .const color_ram = $d800
            .const border_color = $d020
            .const bg_color = $d021
            .var screen_ram = $0400
            .const screen_control_register1 = $d011
            .const screen_control_register2 = $d016
            .const memory_setup_register = $d018
            .const VIC2 = $d000

            .namespace sprites {
                .label positions = VIC2
                .label position_x_high_bits = VIC2 + 16
                .label enable_bits = VIC2 + 21
                .label colors = VIC2 + 39
                .label vertical_stretch_bits = VIC2 + 23
                .label horizontal_stretch_bits = VIC2 + 29
                .label pointers = 1024 - 8
                .label multicolor_bits = VIC2 + 28
                .label color1 = VIC2 + 37
                .label color2 = VIC2 + 38
            }

            .macro hires_mode(flag) {
                .if (flag == 1) {
                    lda screen_control_register1
                    ora #%00100000
                    and #%10111111
                    sta screen_control_register1
                } else {
                    lda screen_control_register1
                    and #%11011111
                    ora #%01000000
                    sta screen_control_register1
                }
            }

            .macro multicolor_mode(flag) {
                .if (flag == 1) {
                    lda screen_control_register1
                    ora #%00010000
                    sta screen_control_register2
                } else {
                    lda screen_control_register2
                    and #%11101111
                    sta screen_control_register2
                }
            }

            .macro choose_screen_memory(index) {
                .eval screen_ram = screen_memory(index)
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

            .macro choose_vic_bank(bank) {
                .assert "bank can be 0 - 3", bank & %11111100, 0
                .const cia2_data_port = $dd00
                .var vic_bank = bank ^ %00000011 // vicbank selection is reverse
                lda cia2_data_port
                and #%1111100
                ora #vic_bank
                sta cia2_data_port
            }

            .function bitmap_memory(index) {
                .return 1024 * 8 * index
            }

            .macro set_bank(screenram, bitmap) {
                // select vic bank
                .assert "screenram can only use top 6 bits (2 for vic bank, 4 for location)", screenram & %0000001111111111, 0
                .assert "bitmap can only use top 3 bits (vic bank and 1 bit for location)",   bitmap    & %0001111111111111, 0
                .assert "bitmap bank and screenram bank need to agree", [ >bitmap >> 6 ] - [ >screenram >> 6 ], 0
                choose_vic_bank(>screenram >> 6)
                choose_screen_memory(>screenram >> 2)
                choose_bitmap_memory(>bitmap >> 5)
            }

            .macro choose_sprite_index(sprite, index) {
                choose_sprite_memory(sprite, sprite_memory(index))
            }

            .macro choose_sprite_memory(sprite, memory) {
                lda #memory
                sta screen_ram + sprites.pointers + sprite
            }

            .function sprite_memory(index) {
                .return 64 * index
            }
