; ============================================================================
; Bitshifters logo.
; And bits & pieces that don't necessarily have a home or are in prototype.
; ============================================================================

bits_text_curr:
    .long 4                     ; which one to plot.

bits_text_xpos:
    FLOAT_TO_FP 0.0

bits_text_ypos:                 ; Y coordinate for centre of word.
    FLOAT_TO_FP 0.0
; TODO: Could drive address lookup per scanline with an iterator.

bits_text_colour:
    FLOAT_TO_FP 15.0
; TODO: Could drive per scanline colour with an iterator.

bits_text_nums_p:
    .long text_nums_no_adr

.equ Bits_HeaderHeight, 64

; R12=screen adrr.
bits_draw_text:
    str lr, [sp, #-4]!

    ldr r0, bits_text_curr
    cmp r0, #0
    movlt r8, #0
    movlt r9, #1
    blt .5

    ldr r1, bits_text_nums_p
    ldr r0, [r1, r0, lsl #2]
    bl text_pool_get_sprite
    ; Returns:
    ;  R8=width in words.
    ;  R9=height in rows.
    ;  R11=ptr to pixel data.

    ;ldr r10, bits_text_ypos
    ;mov r10, r10, asr #16

.5:
    mov r10, #Bits_HeaderHeight/2
    subs r10, r10, r9, lsr #1          ; y top
    movlt r10, #0
;    add r12, r12, r10, lsl #8
;    add r12, r12, r10, lsl #6       ; y start

    rsb r6, r9, #Bits_HeaderHeight
    sub r6, r6, r10
    str r6, [sp, #-4]!

    ; Blank top.
    adr lr, .3
.3:
    mov r7, #Screen_WidthWords
    subs r10, r10, #1
    bpl bits_blank_words

    mov r6, #Screen_Stride/8        ; words to centre.
    sub r6, r6, r8, lsr #1          ; x left.

    ;ldr r2, bits_text_xpos
    ;mov r2, r2, asr #16
    ;add r12, r12, r2, asr #2        ; convert to words in this MODE

    ldr r5, bits_text_colour
    mov r5, r5, asr #16
    orr r5, r5, r5, lsl #4
    orr r5, r5, r5, lsl #8
    orr r5, r5, r5, lsl #16

.1:
    ; Blanks on LHS.
    mov r7, r6
    bl bits_blank_words

    ; Copy a line to screen.
    mov r7, r8                      ; word count.
.2:
    cmp r7, #4
    blt .21

    ; TODO: Could unroll this and jump.
    ldmia r11!, {r0-r3}
    and r0, r0, r5
    and r1, r1, r5
    and r2, r2, r5
    and r3, r3, r5
    stmia r12!, {r0-r3}
    sub r7, r7, #4
    b .2

.21:
    cmp r7, #2
    blt .22

    ldmia r11!, {r0-r1}
    and r0, r0, r5
    and r1, r1, r5
    stmia r12!, {r0-r1}
    sub r7, r7, #2

.22:
    cmp r7, #1
    blt .23

    ldr r0, [r11], #4
    and r0, r0, r5
    str r0, [r12], #4
    sub r7, r7, #1

.23:
    ; Blanks on RHS.
    rsb r7, r8, #Screen_WidthWords
    sub r7, r7, r6
    bl bits_blank_words

    ; Next line.
    subs r9, r9, #1
    bne .1

    ; Blank bottom lines.
    ldr r10, [sp], #4
    adr lr, .4
.4:
    mov r7, #Screen_WidthWords
    subs r10, r10, #1
    bpl bits_blank_words

    ldr pc, [sp], #4

; R7=word count.
; R12=screen addr.
bits_blank_words:
    mov r0, #0
	mov r1, r0
	mov r2, r0
	mov r3, r0

    bic r4, r7, #3              ; 
    rsb r4, r4, #Screen_WidthWords
    add pc, pc, r4              ; jump!
    mov r0, r0                  ; over
    .rept Screen_WidthWords/4
    stmia r12!, {r0-r3}
    .endr

    tst r7, #2
    stmneia r12!, {r0-r1}
    tst r7, #1
    strne r0, [r12], #4
    mov pc, lr

; ============================================================================
