; ============================================================================
; BSS.
; ============================================================================

.bss

.p2align 6

; ============================================================================

stack_no_adr:
    .skip 1024
stack_base_no_adr:

; ============================================================================

.if 0
scroller_font_data_shifted_no_adr:
	.skip Scroller_Max_Glyphs * Scroller_Glyph_Height * 12 * 8
.endif

; ============================================================================

.if 0
logo_data_shifted_no_adr:
	.skip Logo_Bytes * 7

logo_mask_shifted_no_adr:
	.skip Logo_Bytes * 7
.endif

; ============================================================================

.include "lib/lib_bss.asm"

; ============================================================================
