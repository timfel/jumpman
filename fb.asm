#import "std.lib"

.const vic_bank = 3                     // last bank, under kernel and io
.const bitmap_memory = 0                // lower half of bank
.const screen_memory = (8192 / 1024)    // after bitmap
.const min_sprite_memory = (8192 / 64) + (1024 / 64) // start after screen and bitmap
.const max_sprite_memory = (pow(2, 14) / 64)

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

.segment Data                           // globals
.const middle_cannon = 7
cannon_angle:.byte middle_cannon        // 0 - 14
.segment Code

main:{
    jsr setup
    jsr gameloop
    jsr highscore
}

setup_background:{
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

    rts
}

setup_irq:{
    sei
    ldx #<handle_joystick
    ldy #>handle_joystick
    stx std.IRQ_HANDLER_ADDRESS
    sty std.IRQ_HANDLER_ADDRESS + 1
    cli
    rts
}

handle_joystick:{
    // should we trigger?
    lda delay
    sbc #1
    sta delay
    bne return_from_irq

    // handle
    configureMemory(std.RAM_IO_RAM)
    ldx std.JOYSTICK_2

    txa
    and #std.JOY_LEFT
    bne !not+
    lda get_sprite_pointer(vic_bank, screen_memory, 0)
    cmp #[min_sprite_memory + 0]
    beq !not+                           // cannot go left if already using sprite 0
    lda get_sprite_pointer(vic_bank, screen_memory, 0)
    sbc #1
    sta get_sprite_pointer(vic_bank, screen_memory, 0)
    jmp return
!not:

    txa
    and #std.JOY_RIGHT
    bne !not+
    lda get_sprite_pointer(vic_bank, screen_memory, 0)
    cmp #[min_sprite_memory + 14]
    beq !not+                           // cannot go right if already using last sprite
    lda get_sprite_pointer(vic_bank, screen_memory, 0)
    adc #1
    sta get_sprite_pointer(vic_bank, screen_memory, 0)
    jmp return
!not:

return:
    configureMemory(std.RAM_IO_KERNAL)
return_from_irq:
    jmp std.IRQ_DEFAULT_HANDLER

delay:.byte 0
}

setup:{
    jsr setup_irq
    jsr setup_background
    jsr setup_sprites
    rts
}

setup_sprites:{
    .var spritepad = LoadSpritepad("sprites.raw")
    .segment Sprites
    .for (var j = 0; j < spritepad.sprites.size(); j++) {
        *=get_sprite_memory(vic_bank, min_sprite_memory + j)
        .fill 64, spritepad.sprites.get(j).raw_bytes.get(i)
    }
    .segment Code

    // cannon sprite
    set_sprite_position(0, $af, $cd)
    enable_sprite(0, true)
    set_sprite_memory(vic_bank, screen_memory, 0, min_sprite_memory + middle_cannon)
    set_sprite_color(0, spritepad.sprites.get(middle_cannon).color)
    set_sprite_multicolor(0, spritepad.sprites.get(middle_cannon).multicolor)

    // ball sprite
    set_sprite_position(1, $af, $e8)
    enable_sprite(1, true)
    .const ball_sprite = 15
    set_sprite_memory(vic_bank, screen_memory, 1, min_sprite_memory + ball_sprite)
    set_sprite_color(1, spritepad.sprites.get(ball_sprite).color)
    set_sprite_multicolor(1, spritepad.sprites.get(ball_sprite).multicolor)

    // common colors
    lda #BLACK
    sta std.sprites.color1
    lda #WHITE
    sta std.sprites.color2

    rts
}

gameloop:{
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
