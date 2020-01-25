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

.const spritepad = LoadSpritepad("sprites.raw")

.namespace cannon {
    .label sprite_index = 1
    .label min_sprite = min_sprite_memory + 0
    .label middle_sprite = min_sprite_memory + 7
    .label max_sprite = min_sprite_memory + 14
    .label current_sprite = cannon_sprite
    .namespace x {
        .label start = $af
    }
    .namespace y {
        .label start = $cd
    }
}

.namespace ball {
    .label is_flying = ball_is_flying
    .label sprite_index = 0
    .label sprite = min_sprite_memory + 25
    .namespace x {
        .label min = $72
        .label max = $ea
        .label start = $b3
        .label speed = ball_speed_x
    }
    .namespace y {
        .label min = 4 + std.TOP_SCREEN_RASTER_POS
        .label start = $ea
        .label speed = ball_speed_y
    }
    .label width = 16
    .label height = std.SPRITE_HEIGHT
    .label color = ball_start_color
}

.namespace playfield {
    .label width = ball.x.max - ball.x.min
    .label columns = playfield.width / ball.width
    .assert columns < 8, true, "cannot do more than 8 columns"
    .label rows = 7
}

.segment Data
ball_grid:.for (var x = 0; x < playfield.columns; x++) {
              .for (var y = 0; y < playfield.rows; y++) {
                  .byte [$f << 4] | GREEN
              }
          }
cannon_sprite:.word cannon.middle_sprite
ball_start_color:.byte GREEN
ball_is_flying:.byte 0
ball_speed_x:.byte 0
ball_speed_y:.byte 0
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

.macro raster_wait(line_number) {
!wait:
    lda #line_number
    cmp std.RASTER
    bne !wait-
    bit std.CONTROL_1
    .if (line_number <= 255) {
        bmi !wait-
    } else {
        bpl !wait-
    }
}

stick_ball_to_background:{
    // get_sprite_y(1)
    // // determine column sprite for this y line
    // sbc ball.y.min

    // lsr; lsr; lsr; lsr                  // divide by 16
    // // now A holds the row

    get_sprite_x(ball.sprite_index)
    sbc #ball.x.min
    lsr; lsr; lsr; lsr                  // divide by 16 == ball.width
    // now A holds the column, and thus which sprite to use

sprite_found:
    txa; tay
    lda #1
bitshift:
    // bitshift a '1' X-times left (X is still the sprite index, we use Y to dec)
    asl
    dey
    bne bitshift
    sta bitPattern
    // transfer things
    lda std.sprites.colors + ball.sprite_index // Transfer ball color
    sta std.sprites.colors,x
    lda #ball.sprite                    // transfer ball
    sta get_screen_memory(vic_bank, screen_memory) + std.sprites.pointers,x

    txa; asl                            // multiply index by 2 to get position offset

    sta positionOffset
    lda std.sprites.positions + 2 * 1   // find column for last x position
    clc
    sbc #ball.x.min
    ldx #0
    clc
!division_loop:
    inx
    sbc #std.SPRITE_WIDTH
    bcs !division_loop-
    // now X holds the column + 1
    lda column_offsets,x                // load pixel offset for this column
    ldx positionOffset:#00
    sta std.sprites.positions,x

    stx positionOffsetA
    ldx lineIdx
    lda row_offsets,x                   // load pixel offset for this row
    ldx positionOffsetA:#00
    sta std.sprites.positions + 1,x

    // set the bit so this sprite is used now
    ldx lineIdx:#00
    lda lines,x
    ora bitPattern:#00
    sta lines,x
    // reset ball
    jsr reset_ball_sprite

    rts
lines:.fill 7,0
colors:.fill 7,0
posx:.fill 7,0
column_offsets:
    .byte 0
    .for(var x = 0; x < 5; x++) {
        .byte (x * 24) + ball.x.min
    }
row_offsets:
    .for(var y = 0; y < 7; y++) {
        .byte (y * 21) + ball.y.min
    }
}

handle_flying_ball:{
    get_sprite_x(ball.sprite_index)
    clc
    adc ball.x.speed
    set_sprite_x_from_a(ball.sprite_index)
    bcc positive_x
    // we had an overflow, so we're moving left
    sec
    sbc #ball.x.min
    bcs move_ball_y
    // we went left of the border
    lda #ball.x.min
    set_sprite_x_from_a(ball.sprite_index)
    jmp invert_ball_x
positive_x:
    // we're moving right
    sec
    sbc #ball.x.max
    bcc move_ball_y
    // we went right of the border
    lda #ball.x.max
    set_sprite_x_from_a(ball.sprite_index)
invert_ball_x:
    lda ball.x.speed
    eor #$ff
    clc
    adc #1
    sta ball.x.speed

move_ball_y:
    get_sprite_y(ball.sprite_index)
    sec
    sbc ball.y.speed
    set_sprite_y_from_a(ball.sprite_index)
    sec
    sbc #ball.y.min
    bcs return                          // y still larger than min
stick_ball:
    lda #ball.y.min
    set_sprite_y_from_a(ball.sprite_index)
    lda #0
    sta ball.is_flying                  // stop flying, we now stick
    jsr stick_ball_to_background
return:
    rts
}

handle_joystick:{
    // should we trigger?
    lda delay
    dec delay
    bne return
    lda #5
    sta delay
    // when the ball is flying, we don't handle input
    lda ball.is_flying
    beq handle_input
    jmp return

handle_input:
    ldx std.JOYSTICK_2

    txa
    and #std.JOY_LEFT
    bne !not+
    lda cannon.current_sprite
    cmp #cannon.min_sprite
    beq return                          // cannot go left if already using sprite 0
    lda cannon.current_sprite
    sbc #1
    sta cannon.current_sprite
    jmp return
!not:

    txa
    and #std.JOY_RIGHT
    bne !not+
    lda cannon.current_sprite
    cmp #cannon.max_sprite
    beq return                          // cannot go right if already using last sprite
    lda cannon.current_sprite
    adc #1
    sta cannon.current_sprite
    jmp return
!not:

    txa
    and #std.JOY_UP
    bne !not+
    lda #1
    sta ball.is_flying
    lda cannon.current_sprite
    sec
    sbc #cannon.middle_sprite
    sta ball.x.speed
    lda cannon.current_sprite
    sec
    sbc #cannon.middle_sprite
    bcc already_negative
    // make absolute
    eor #$ff
    clc
    adc #1
already_negative:
    adc #8
    sta ball.y.speed
    jmp return
!not:

return:
    rts

delay:.byte 0
}

setup:{
    jsr setup_sid
    jsr setup_background
    jsr setup_sprites
    jsr reset_ball_sprite
    rts
}

reset_ball_sprite:{
    enable_sprite(ball.sprite_index, true)
    set_sprite_position(ball.sprite_index, ball.x.start, ball.y.start)
    set_sprite_memory(vic_bank, screen_memory, ball.sprite_index, ball.sprite)
    set_sprite_multicolor(ball.sprite_index, true)

    lda $D41B
    and #%11
    adc #2
    sta std.sprites.colors + ball.sprite_index

    rts
}

setup_sprites:{
    .segment Sprites
    .for (var j = 0; j < spritepad.sprites.size(); j++) {
        *=get_sprite_memory(vic_bank, min_sprite_memory + j)
        .fill 64, spritepad.sprites.get(j).raw_bytes.get(i)
    }
    .segment Code

    // common colors
    lda #BLACK
    sta std.sprites.color1
    lda #WHITE
    sta std.sprites.color2

    rts
}

setup_sid:{
    // some random numbers in lda $D41B
    lda #$FF                            // maximum frequency value
    sta $D40E                           // voice 3 frequency low byte
    sta $D40F                           // voice 3 frequency high byte
    lda #$80                            // noise waveform, gate bit off
    sta $D412                           // voice 3 control register
}

show_cannon:{
    enable_sprite(cannon.sprite_index, true)
    set_sprite_position(cannon.sprite_index, cannon.x.start, cannon.y.start)
    set_sprite_multicolor(cannon.sprite_index, false)
    set_sprite_color(cannon.sprite_index, BROWN)
    lda cannon.current_sprite
    sta get_sprite_pointer(vic_bank, screen_memory, cannon.sprite_index)
    rts
}

show_score:{
    rts
}

set_ball_colors_and_visibility_in_row_X_with_y_position_Y:{
    .for(var i = ball.sprite_index + 1; i < 8; i++) {
        // x is row * 8, so this is really balls[column + (row * 8)]
        lda [ball_grid + i],x
        // the byte holds the color information in the lower half, so just store it
        sta std.sprites.colors + i
        // is it visible?
        and #%10000000
        beq disable
        enable_sprite(i, true)
        // set Y position
        sty std.sprites.positions + 2 * i + 1
        jmp continue
disable:
        enable_sprite(i, false)
continue:
    }
    rts
}

set_all_sprites_to_invisible_multicolor_balls_in_columns:{
    lda #%11111111
    sta std.sprites.multicolor_bits
    .for(var i = ball.sprite_index + 1; i < 8; i++) {
        set_sprite_memory(vic_bank, screen_memory, i, ball.sprite)
        set_sprite_x(i, ball.x.min + i * ball.width)
    }
    enable_sprites(0)
    enable_sprite(ball.sprite_index, true)
    rts
}

gameloop:{
    .for(var row = 0; row < playfield.rows; row++) {
        raster_wait(ball.y.min + row * ball.height - ball.height / 2)
        ldx #[row * 8]
        ldy #[ball.y.min + row * ball.height]
        jsr set_ball_colors_and_visibility_in_row_X_with_y_position_Y
    }
    raster_wait(cannon.y.start - 2)
    jsr show_cannon
    jsr show_score
    raster_wait(ball.y.start + 1)
    jsr set_all_sprites_to_invisible_multicolor_balls_in_columns
    jsr handle_joystick
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
