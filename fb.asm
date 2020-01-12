#import "std.lib"

.const vic_bank = 3                     // last bank, under kernel and io
.const bitmap_memory = 1                // upper half of bank
.const screen_memory = 7                // beginning of bank
.const min_sprite_memory = 0            // start after screen
.const max_sprite_memory = 112          // after this comes the bitmap

.namespace sprite_images {
    .label hires_z = 1
}

.file [name="fb.prg", segments="ExtraMemory,Code,Data,Sprites,Screen,Bitmap"]
.segmentdef ExtraMemory [start=$0200]   // space between zeropage stack and code
.segmentdef Code [start=$0801]
.segmentdef Data [start=$8000]
.segmentdef Sprites [start=get_sprite_memory(vic_bank, min_sprite_memory)]
.segmentdef Screen [start=get_screen_memory(vic_bank, screen_memory)]
.segmentdef Bitmap [start=get_bitmap_memory(vic_bank, bitmap_memory)]

.segment Code
BasicUpstart2(main)

main:{
    jsr setup
    jsr gameloop
    jsr highscore
}

setup:{
    // configureMemory(std.RAM_IO_KERNAL)
    hires_mode(1)
    multicolor_mode(1)
    set_vic_bank(vic_bank)

    .var background_pic = LoadBinary("./fb.kla", BF_KOALA)

    set_screen_memory(screen_memory)
    .segment Screen
    .fill background_pic.getScreenRamSize(), background_pic.getScreenRam(i)
    .segment Code

    set_background_color(background_pic.getBackgroundColor())

    set_bitmap_memory(bitmap_memory)
    .segment Bitmap
    .fill background_pic.getBitmapSize(), background_pic.getBitmap(i)
    .segment Code

    copy_color_ram(background_color)
    .segment Data
background_color:.fill background_pic.getColorRamSize(), background_pic.getColorRam(i)
    .segment Code

    set_sprite_memory(vic_bank, screen_memory, 0, min_sprite_memory)
    .segment Sprites
    *=get_sprite_memory(vic_bank, min_sprite_memory)
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
    .segment Code
    set_sprite_position(0, 170, 200)
    enable_sprite(0, true)
    set_sprite_color(0, GREEN)

    set_border_color(BLUE)
    set_background_color(PURPLE)
    set_extra_background_color(BLACK, 0)
    set_extra_background_color(RED, 1)
    set_extra_background_color(CYAN, 2)

    rts
}

gameloop:{
    nop
    nop
    jmp gameloop
    rts
}

highscore:{
    rts
}

.macro sprite_row(value) {
    .byte extract_byte(value, 2), extract_byte(value, 1), extract_byte(value, 0)
}

.function extract_byte(value, byte_id) {
    .var bits = byte_id * 8
    .eval value = value >> bits
    .return value & 255
}
