            :BasicUpstart2(main)

            // .var picture = LoadBinary("bg.koa", BF_KOALA)

            // .const ART_TEMPLATE = "Bitmap=$0000, ScreenRam=$1f40, BorderColor = $2328"
            // .var picture = LoadBinary("background.art", ART_TEMPLATE)

            // .const AART_TEMPLATE = "Bitmap=$0000, ScreenRam=$1f40, BorderColor=$2328, BackgroundColor=$2329, ColorRam=$2338"
            // .var picture = LoadBinary("background.ocp", AART_TEMPLATE)

            .const color_ram = $d800
            .const border_color = $d020
            .const bg_color = $d021
            .const screen_ram = $0400
            .const screen_control_register = $d011
            .const screen_control_register2 = $d016
            .const memory_setup_register = $d018

main:
                jsr setup
                rts


setup:
                lda #GREY
                sta border_color
                // enable bitmap mode
                lda screen_control_register
                ora #%00100000
                sta screen_control_register
                // enable multi-color mode
                // lda screen_control_register2
                // ora #%00010000
                // sta screen_control_register2


                // choose screen memory
                choose_screen_memory(3)
                choose_bitmap_memory(1)

                // load border color
                // lda #picture.getBackgroundColor()
                // sta border_color
                // sta bg_color
                // sta bg_color + 1
                // sta bg_color + 2
                // sta bg_color + 3

                rts

            // .pc = color_ram
            //     .fill picture.getColorRamSize(), picture.getColorRam(i)

            .pc = screen_memory(3) "Bitmap Color"
                // .fill picture.getScreenRamSize(), picture.getScreenRam(i)
                // .fill 1000, GRAY << 4 | LIGHT_GRAY
                .import binary "bg.scr"

            .pc = bitmap_memory(1) "Bitmap Pixels"
                // .fill picture.getBitmapSize(), picture.getBitmap(i)
                .import binary "bg.map"

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

            .macro set_bank(screenram,bitmap) {
                .var cur_dd00   = [ >screenram >> 6 ] ^ %00000011
                .eval screenram = screenram & $3fff
                .eval bitmap    = bitmap & $3fff
                .var cur_d018   = [ [ >screenram << 2 ] + [ >bitmap >> 2 ] ]

                lda $dd00
                and #%1111100
                ora #cur_dd00
                sta $dd00
                lda #cur_d018
                sta $d018
            }
