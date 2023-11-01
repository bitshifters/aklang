; ============================================================================
; BSS Segment (Uninitialised data, not stored in the exe.)
; ============================================================================

.bss
.p2align 6

; ============================================================================

stack_no_adr:
    .skip AppConfig_StackSize
stack_base_no_adr:

; ============================================================================
; Per FX BSS.
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

.if 0
starfield_x_no_adr:
    .skip Starfield_Total * 4

starfield_y_no_adr:
    .skip Starfield_Total * 4
.endif

; ============================================================================

transformed_verts_no_adr:
    .skip OBJ_MAX_VERTS * VECTOR3_SIZE

; !VERTEX AND NORMAL ARRAYS MUST BE CONSECUTIVE!

;transformed_normals:       ; this is dynamic depending on num_verts.
    .skip OBJ_MAX_FACES * VECTOR3_SIZE

; !VERTEX AND NORMAL ARRAYS MUST BE CONSECUTIVE!

projected_verts_no_adr:
    .skip OBJ_MAX_VERTS * VECTOR2_SIZE

; ============================================================================

; All objects transformed to world space.
scene2d_object_buffer_no_adr:
    .skip Scene2D_ObjectBuffer_Size

scene2d_verts_buffer_no_adr:
    .skip Scene2D_MaxVerts * VECTOR2_SIZE

; ============================================================================

particles_array_no_adr:
    .skip Particle_SIZE * Particles_Max

; ============================================================================

balls_array_no_adr:
    .skip Ball_SIZE * Balls_Max

; ============================================================================

temp_sprite_data_buffer_no_adr:
    .skip 8*8*8 ; width_in_bytes * rows * 8 pixel shifts

temp_sprite_mask_buffer_no_adr:
    .skip 8*8*8 ; width_in_bytes * rows * 8 pixel shifts

temp_sprite_ptrs_no_adr:
    .skip 4*8   ; sizeof(ptr) * 8 pixel shifts

temp_mask_ptrs_no_adr:
    .skip 4*8   ; sizeof(ptr) * 8 pixel shifts

; ============================================================================
; Library BSS.
; ============================================================================

.include "lib/lib_bss.asm"

; ============================================================================
