; ============================================================================
; App standard code.
; Hack as necessary per prod.
; ============================================================================

.equ RasterSplitLine, 56+90			; 56 lines from vsync to screen start


; ============================================================================
; App video code.
; ============================================================================

vdu_screen_disable_cursor:
.byte 22, VideoConfig_VduMode, 23,1,0,0,0,0,0,0,0,0,17,7
.p2align 2

app_init_video:
	; Set screen MODE & disable cursor
	adr r0, vdu_screen_disable_cursor
	mov r1, #14
	swi OS_WriteN

	; Set screen size for number of buffers
	MOV r0, #DynArea_Screen
	SWI OS_ReadDynamicArea
	MOV r0, #DynArea_Screen
	MOV r2, #Mode_Bytes * VideoConfig_ScreenBanks
	SUBS r1, r2, r1
	SWI OS_ChangeDynamicArea
	MOV r0, #DynArea_Screen
	SWI OS_ReadDynamicArea
	CMP r1, r2
	ADRCC r0, error_noscreenmem
	SWICC OS_GenerateError

	; Clear all screen buffers
	mov r1, #1
.1:
	str r1, write_bank

	; CLS bank N
	mov r0, #OSByte_WriteVDUBank
	swi OS_Byte
	SWI OS_WriteI + 12		; cls

	add r1, r1, #1
	cmp r1, #VideoConfig_ScreenBanks
	ble .1
    mov pc, lr

; TODO: Junk this for non_DEBUG?
error_noscreenmem:
	.long 0
	.byte "Cannot allocate screen memory!"
	.p2align 2
	.long 0


; ============================================================================
; App audio code.
; ============================================================================

.if AppConfig_LoadModFromFile
music_filename:
	.byte "<Demo$Dir>.Music",0
	.p2align 2
.else
music_mod_p:
	.long music_mod_no_adr		; 14
.endif

; R12=top of RAM used.
app_init_audio:
.if AppConfig_DynamicSampleSpeed
	; Count how long the init takes as a very rough estimate of CPU speed.
	ldr r1, vsync_count
	cmp r1, #AudioConfig_SampleSpeed_CPUThreshold
	movge r0, #AudioConfig_SampleSpeed_SlowCPU
	movlt r0, #AudioConfig_SampleSpeed_FastCPU
.else
    mov r0, #AudioConfig_SampleSpeed_Default
.endif

	; Setup QTM for our needs.
	swi QTM_SetSampleSpeed

	; Load the music.
    .if AppConfig_LoadModFromFile
    adr r0, music_filename
    mov r1, r12             ; HIMEM.
    .else
	mov r0, #0              ; load from address, don't copy to RMA.
    ldr r1, music_mod_p
    .endif
	swi QTM_Load

    mov pc, lr


; ============================================================================
; Interrupt handling.
; ============================================================================

.if AppConfig_InstallIrqHandler
oldirqhandler:
	.long 0

oldirqjumper:
	.long 0

vsyncstartdelay:
	.long 127*RasterSplitLine  ;2000000/50.08

install_irq_handler:
	mov r1, #0x18					; IRQ vector.
	
	; Remember previous IRQ branch call.
	ldr r0, [r1]					; old IRQ handler.
	str r0, oldirqjumper

	; Calculate old IRQ handler address from branch opcode.
	bic r0, r0, #0xff000000
	mov r0, r0, lsl #2
	add r0, r0, #32
	str r0, oldirqhandler

	; Set Timer 1.
	SWI		OS_EnterOS
	MOV     R12,#0x3200000           ;IOC address

	TEQP    PC,#0b11<<26 | 0b11  ;jam all interrupts!

	LDR     R0,vsyncstartdelay
	STRB    R0,[R12,#0x50]
	MOV     R0,R0,LSR#8
	STRB    R0,[R12,#0x54]           ;prepare timer 1 for waiting until screen start
									;don't start timer1, done on next Vs...
	TEQP    PC,#0
	MOV     R0,R0

	; Install our IRQ handler.
	swi OS_IntOff
	adr r0, irq_handler
	sub r0, r0, #32
	mov r0, r0, lsr #2
	add r0, r0, #0xea000000			; B irq_handler.
	str r0, [r1]
	swi OS_IntOn

	mov pc, lr

uninstall_irq_handler:
	mov r1, #0x18					; IRQ vector.
	
	; Restore previous IRQ branch call.
	ldr r0, oldirqjumper
	str r0, [r1]

	mov pc, lr

irq_handler:
	STMFD   R13!,{R0-R1,R11-R12}
	MOV     R12,#0x3200000           ;IOC address
	LDRB    R0,[R12,#0x14+0]
	TST     R0,#1<<6 | (1<<3)
	BEQ     nottimer1orVs           ;not T1 or Vs, back to RISCOS

	TEQP    PC,#0b11<<26 | 0b11
	MOV     R0,R0

	MOV     R11,#VIDC_Write
	TST     R0,#1<<3
	BNE     handle_vsync                   ;...Vs higher priority than T1

timer1:
	mov r0, #0
	str r0, vsync_bodge

	; WRITE VIDC REGS HERE!

	LDRB    R0,[R12,#0x18]
	BIC     R0,R0,#1<<6
	STRB    R0,[R12,#0x18]           ;stop T1 irq...

exittimer1:
	TEQP    PC,#0b10<<26 | 0b10
	MOV     R0,R0
	LDMFD   R13!,{R0-R1,R11-R12}
	SUBS    PC,R14,#4

handle_vsync:
	ldr r0, vsync_bodge
	cmp r0, #0
	beq .3
	b exitVs
.3:
	mov r0, #1
	str r0, vsync_bodge

	STRB    R0,[R12,#0x58]           ;T1 GO (latch already set up)
	LDRB    R0,[R12,#0x18]
	ORR     R0,R0,#1<<6
	STRB    R0,[R12,#0x18]           ;enable T1 irq...
	MOV     R0,#1<<6
	STRB    R0,[R12,#0x14]           ;clear any pending T1 irq

    b app_vsync_code

exitVs:
	TEQP    PC,#0b10<<26 | 0b10
	MOV     R0,R0

nottimer1orVs:
	LDMFD   R13!,{R0-R1,R11-R12}
	ldr pc, oldirqhandler

vsync_bodge:
	.long 0
.endif

; ============================================================================
; Code run at vsync.
; ============================================================================

app_vsync_code:
    ; TODO: Palette pending.
	; WRITE VIDC REGS HERE!

	; Update the vsync counter.
	ldr r0, vsync_count
	add r0, r0, #1
	str r0, vsync_count

	; Pending bank will now be displayed.
	ldr r1, pending_bank
	cmp r1, #0
	.if _CHECK_FRAME_DROP
	streq r0, last_dropped_frame
	.endif
	beq exitVs

	str r1, displayed_bank

	; Clear pending bank.
	mov r0, #0
	str r0, pending_bank
    b exitVs
