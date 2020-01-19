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

.const middle_cannon = 7
.const max_ball_x = $ea
.const min_ball_x = $72
.const min_ball_y = 4 + std.TOP_SCREEN_RASTER_POS

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
    beq go_on
    jmp return_from_irq
go_on:
    configureMemory(std.RAM_IO_RAM)

    // when the ball is flying, we don't handle input
    lda ball_is_flying
    beq handle_input
    get_sprite_x(1)
    clc
    adc ball_speed_x
    set_sprite_x_from_a(1)
    bcc positive_x
    // we had an overflow, so we're really subtracting X position
    sec
    sbc #min_ball_x
    bcs move_ball_y                     // we didn't go left of the border
    lda #min_ball_x                     // stick to the border
    set_sprite_x_from_a(1)
    jmp invert_ball_x
positive_x:
    sec
    sbc #max_ball_x
    bcc move_ball_y                     // if we didn't go right of the border
    lda #max_ball_x
    set_sprite_x_from_a(1)
invert_ball_x:
    lda ball_speed_x
    eor #$ff
    clc
    adc #1
    sta ball_speed_x

move_ball_y:
    get_sprite_y(1)
    sec
    sbc ball_speed_y
    set_sprite_y_from_a(1)
    sec
    sbc #min_ball_y
    bcs return                          // y still larger than min
stick_ball:
    lda #min_ball_y
    set_sprite_y_from_a(1)
    lda #0
    sta ball_is_flying                  // stop flying, we now stick
    jmp return

handle_input:
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

    txa
    and #std.JOY_FIRE
    bne !not+
    lda #1
    sta ball_is_flying
    lda get_sprite_pointer(vic_bank, screen_memory, 0)
    sec
    sbc #[min_sprite_memory + middle_cannon]
    sta ball_speed_x
    lda get_sprite_pointer(vic_bank, screen_memory, 0)
    sec
    sbc #[min_sprite_memory + middle_cannon]
    bcc already_negative
    // make absolute
    eor #$ff
    clc
    adc #1
already_negative:
    adc #8
    sta ball_speed_y
    jmp return
!not:

return:
    configureMemory(std.RAM_IO_KERNAL)
return_from_irq:
    jmp std.IRQ_DEFAULT_HANDLER

delay:.byte 0
ball_is_flying:.byte 0
ball_speed_x:.byte 0
ball_speed_y:.byte 0
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
