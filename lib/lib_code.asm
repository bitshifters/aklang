; ============================================================================
; Library code routines.
; ============================================================================

.include "lib/maths.h.asm"

.macro LIB_PROGRESS
.if LibConfig_ShowInitProgress
swi OS_WriteI+'_'               ; TODO: Define progress to app_config.h
.endif
.endm

; ============================================================================

lib_code_gen_base_p:
    .long lib_code_gen_base_no_adr

; ============================================================================

lib_init:
    str lr, [sp, #-4]!

    ; --------------------------------------------------
    ; Table generation (table space preallocated in BSS)
    ; --------------------------------------------------

    bl MakeSinus
    LIB_PROGRESS

    ; ------------------------------------------------
    ; Code generation (size not known at compile time)
    ; ------------------------------------------------

    ldr r12, lib_code_gen_base_p

    bl line_segments_init
    LIB_PROGRESS

    ; R12 returns top of RAM.
    ldr pc, [sp], #4

; ============================================================================

.include "lib/mem.asm"

.include "lib/sine.asm"
.include "lib/math-var.asm"
.include "lib/line-segments.asm"

; ============================================================================
