#import "std.lib"

.const vic_bank = 3                     // last bank, under kernel and io
.const bitmap_memory = 1                // upper half of bank
.const screen_memory = 0                // beginning of bank
.const min_sprite_memory = 16           // start after screen
.const max_sprite_memory = 128          // after this comes the bitmap

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
    multicolor_mode(0)
    set_vic_bank(vic_bank)

    set_screen_memory(screen_memory)
    .segment Screen
    .import binary "bg.scr"
    .segment Code

    set_bitmap_memory(bitmap_memory)
    .segment Bitmap
    .import binary "bg.map"
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
