; ============================================================================
; Library module BSS.
; ============================================================================

.p2align 6

; ============================================================================

.if _DEBUG
debug_font_mode9_no_adr:
    .skip Debug_MaxGlyphs * 4*8
.endif

; ============================================================================

sinus_table_no_adr:
    .skip LibSine_TableSize*4

; ============================================================================

math_var_buffer_no_adr:
    .skip MathVar_SIZE * MathVars_MAX
math_var_buffer_end_no_adr:

; ============================================================================

.if LineSegments_UseYBuffer
line_segments_y_buffer_no_adr:
    .skip Screen_Stride
.endif

line_segments_ptrs_no_adr:
	.skip 4*LineSegments_Total_dy

; ============================================================================
; NB. Gen Code must be last!!
; ============================================================================

lib_code_gen_base_no_adr:
