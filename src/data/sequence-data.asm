; ============================================================================
; Sequence helper macros.
; ============================================================================

.macro on_pattern pattern_no, do_thing
    fork_and_wait_secs SeqConfig_PatternLength_Secs*\pattern_no, \do_thing
.endm

.macro wait_patterns pats
    wait_secs SeqConfig_PatternLength_Secs*\pats
.endm

.macro palette_lerp_over_secs palette_A, palette_B, secs
    math_make_var seq_palette_blend, 0.0, 1.0, math_clamp, 0.0, 1.0/(\secs*50.0)  ; seconds.
    math_make_palette seq_palette_id, \palette_A, \palette_B, seq_palette_blend, seq_palette_lerped
    write_addr palette_array_p, seq_palette_lerped
    fork_and_wait_secs \secs, seq_unlink_palette_lerp
.endm

.macro rgb_lerp_over_secs rgb_addr, from_rgb, to_rgb, secs
    math_make_var seq_rgb_blend, 0.0, 1.0, math_clamp, 0.0, 1.0/(\secs*50.0)  ; 5 seconds.
    math_make_rgb \rgb_addr, \from_rgb, \to_rgb, seq_rgb_blend
.endm

; ============================================================================
; The actual sequence for the demo.
; ============================================================================

    ; Init FX modules.
    call_0 math_emitter_init
    call_0 the_ball_init
    call_0 particle_grid_init
    gosub seq_make_owl_verts            ; NB. This takes about 10 frames!

    ; Screen setup.

	; Setup layers of FX.
    call_3 fx_set_layer_fns, 0, 0,                          screen_cls
    ;
    call_3 fx_set_layer_fns, 2, the_ball_tick,              the_ball_draw
    call_3 fx_set_layer_fns, 3, 0,                          circles_plot_all_in_order

    write_fp particle_grid_gloop_factor,    0.99            ; 0.0=won't move, 1.0=won't return, higher is slower.
    write_fp particle_grid_collider_radius, 48.0            ;
    write_fp particle_grid_dave_maxpush,    1.21            ; displacement radius multiplier

    ; Call each part in turn.

seq_loop:
    ; Start!
    write_addr palette_array_p, seq_palette_green_white_ramp

    fork seq_init_expand_orb
    wait_patterns 1
    gosub seq_kill_expand_orb

    write_addr palette_array_p, seq_palette_green_white_ramp

    fork seq_init_grid_with_orb_spiral
    wait_patterns 3
    gosub seq_kill_grid_with_orb_spiral

    palette_lerp_over_secs seq_palette_green_white_ramp, seq_palette_red_magenta_ramp, SeqConfig_PatternLength_Secs/2.0

    fork seq_init_orb_straight_lines
    wait_patterns 3.75

    palette_lerp_over_secs seq_palette_red_magenta_ramp, seq_palette_all_black, SeqConfig_PatternLength_Secs*0.25
    rgb_lerp_over_secs seq_palette_lerped+15*4, 0x00ffffff, 0x00000000, SeqConfig_PatternLength_Secs*0.25
    wait_patterns 0.25
    gosub seq_kill_orb_straight_lines
    math_kill_rgb seq_palette_lerped+15*4

    write_addr palette_array_p, seq_palette_blue_cyan_ramp

    fork seq_init_rain
    wait_patterns 3.75

    palette_lerp_over_secs seq_palette_blue_cyan_ramp, seq_palette_all_black, SeqConfig_PatternLength_Secs*0.25
    rgb_lerp_over_secs seq_palette_lerped+15*4, 0x00ffffff, 0x00000000, SeqConfig_PatternLength_Secs*0.25
    wait_patterns 0.25
    gosub seq_kill_rain
    math_kill_rgb seq_palette_lerped+15*4

    write_addr palette_array_p, seq_palette_red_additive

    fork seq_init_fire_spiral
    wait_patterns 4
    gosub seq_kill_fire_spiral

.if 0
    fork seq_init_ball_under_gravity
    wait_patterns 0.75

    palette_lerp_over_secs seq_palette_red_additive, seq_palette_all_black, SeqConfig_PatternLength_Secs*0.25
    rgb_lerp_over_secs seq_palette_lerped+15*4, 0x00ffffff, 0x00000000, SeqConfig_PatternLength_Secs*0.25
    wait_patterns 0.25
    gosub seq_kill_ball_under_gravity
    math_kill_rgb seq_palette_lerped+15*4
.endif

    write_addr palette_array_p, seq_palette_green_white_ramp

    fork seq_init_orb_particle_emitter
    wait_patterns 2
    gosub seq_kill_orb_particle_emitter

    ; END HERE FOR NOW,
    end_script


; Ball appears and expands to starting size.
seq_init_expand_orb:
    ; Make particle grid.
    call_7 particle_grid_make, 26, 20, MATHS_CONST_1*-137.5, MATHS_CONST_1*-104.5, MATHS_CONST_1*11.0, MATHS_CONST_1*11.0, 0

    call_3 fx_set_layer_fns, 1, particle_grid_tick_all_dave_equation,    particle_grid_draw_all_as_2x2_tinted

    ; Static grid to start.
    call_1 particle_grid_set_dave_rotation, 0
    call_1 particle_grid_set_dave_expansion, 13

    ; Setup the ball.
    call_2f the_env_set_constant_force, 0.0, 0.0    ; zero gravity
    call_2f the_ball_set_pos, 0.0, 0.0              ; centre ball
    call_2f the_ball_set_vel, 0.0, 0.0
    call_1f the_ball_set_radiusf 1.0

    ; Collider radius = 3.0 * the ball radius.
    math_link_vars particle_grid_collider_radius, 0.0, 3.0, the_ball_block+TheBall_radius

    ; Make the ball the particle grid collider.
    math_link_vars particle_grid_collider_pos+0, 0.0, 1.0, the_ball_block+TheBall_x
    math_link_vars particle_grid_collider_pos+4, 0.0, 1.0, the_ball_block+TheBall_y

    wait_patterns 0.25

    math_make_var the_ball_block+TheBall_radius, 1.0, TheBall_DefaultRadius-1.0, math_clamp, 0.0, 1.0/(SeqConfig_PatternLength_Frames*0.75)
    
    end_script

seq_kill_expand_orb:
    math_kill_var the_ball_block+TheBall_radius
    math_unlink_vars particle_grid_collider_pos+0
    math_unlink_vars particle_grid_collider_pos+4
    math_unlink_vars particle_grid_collider_radius
    write_fp the_ball_block+TheBall_radius, TheBall_DefaultRadius
    write_fp particle_grid_collider_radius, TheBall_DefaultRadius*3.0
    end_script


; Ball moves in a spiral through the particle grid.
seq_init_grid_with_orb_spiral:

    ; Make particle grid.
    ;call_7 particle_grid_make, 26, 20, MATHS_CONST_1*-137.5, MATHS_CONST_1*-104.5, MATHS_CONST_1*11.0, MATHS_CONST_1*11.0, 0
    ;call_3 particle_grid_add_verts, 520, bits_verts_no_adr, 0

    call_3 fx_set_layer_fns, 1, particle_grid_tick_all_dave_equation,    particle_grid_draw_all_as_2x2_tinted

    ; Setup the ball.
    call_2f the_env_set_constant_force, 0.0, 0.0    ; zero gravity
    call_2f the_ball_set_pos, 0.0, 0.0              ; centre ball
    call_2f the_ball_set_vel, 0.0, 0.0

    ; Make the ball the particle grid collider.
    ; particle_grid_collider_pos.x = the_ball.x
    ; particle_grid_collider_pos.y = the_ball.y
    math_link_vars particle_grid_collider_pos+0, 0.0, 1.0, the_ball_block+TheBall_x
    math_link_vars particle_grid_collider_pos+4, 0.0, 1.0, the_ball_block+TheBall_y

    call_1 particle_grid_set_dave_rotation, 13
    call_1 particle_grid_set_dave_expansion, 13

    wait_patterns 0.25

    ; Equation of the ball.
    ; x=radius * sin(t/speed)
    ; y=128 + radius * cos(t/speed)
    ; Where radius = t/speed as well.
    ; ~20 seconds to get to max radius 100. 1000/speed=100;speed=10.

    ; radius = i/10
    math_make_var seq_path_radius, 0.0, 1.0, math_no_func, 0.0, 1.0/15.0

    ; Want this to be the radius value -----------------------v
    math_make_var2 the_ball_block+TheBall_x,   0.0, seq_path_radius, math_sin, 0.0, 1.0/(MATHS_2PI*40.0)
    math_make_var2 the_ball_block+TheBall_y,   0.0, seq_path_radius, math_cos, 0.0, 1.0/(MATHS_2PI*40.0)

    end_script

seq_kill_grid_with_orb_spiral:
    math_kill_var the_ball_block+TheBall_x
    math_kill_var the_ball_block+TheBall_y
    math_kill_var seq_path_radius
    math_unlink_vars particle_grid_collider_pos+0
    math_unlink_vars particle_grid_collider_pos+4
    end_script


seq_init_fire_spiral:
    ; Nice spiral.
    call_7 particle_grid_make_spiral, 500, MATHS_CONST_1*4.0, MATHS_CONST_1*1.0, MATHS_CONST_1*0.3, MATHS_CONST_1*0.0, MATHS_CONST_1*0.0, 0
    call_3 fx_set_layer_fns, 1, particle_grid_tick_all_dave_equation,    particle_grid_draw_all_as_2x2_tinted

    ; Setup the ball.
    call_2f the_env_set_constant_force, 0.0, 0.0    ; zero gravity
    call_2f the_ball_set_pos, 0.0, 0.0              ; centre ball
    call_2f the_ball_set_vel, 0.0, 0.0

    ; Make the ball the particle grid collider.
    ; particle_grid_collider_pos.x = the_ball.x
    ; particle_grid_collider_pos.y = the_ball.y
    math_link_vars particle_grid_collider_pos+0, 0.0, 1.0, the_ball_block+TheBall_x
    math_link_vars particle_grid_collider_pos+4, 0.0, 1.0, the_ball_block+TheBall_y

    ; Make the ball the particle grid collider but inverted!
    ; particle_grid_collider_pos.x = -the_ball.x
    ; particle_grid_collider_pos.y = -the_ball.y
    ;math_link_vars particle_grid_collider_pos+0,   0.0, -1.0, the_ball_block+TheBall_x
    ;math_link_vars particle_grid_collider_pos+4,   0.0, -1.0, the_ball_block+TheBall_y

    ; radius = i/10
    math_make_var seq_path_radius, 0.0, 1.0, math_no_func, 0.0, 1.0/15.0

    ; Want this to be the radius value -----------------------v
    math_make_var2 the_ball_block+TheBall_x,   0.0, seq_path_radius, math_sin, 0.0, 1.0/(MATHS_2PI*50.0)
    math_make_var2 the_ball_block+TheBall_y,   0.0, seq_path_radius, math_cos, 0.0, 1.0/(MATHS_2PI*50.0)

    call_1 particle_grid_set_dave_rotation, 12
    call_1 particle_grid_set_dave_expansion, 12

    end_script

seq_kill_fire_spiral:
    math_kill_var the_ball_block+TheBall_x
    math_kill_var the_ball_block+TheBall_y
    math_kill_var seq_path_radius
    math_unlink_vars particle_grid_collider_pos+0
    math_unlink_vars particle_grid_collider_pos+4
    end_script


; Ball moves in straight lines through the particle grid.
seq_init_orb_straight_lines:
    ; Make particle grid.
    ; call_7 particle_grid_make, 26, 20, MATHS_CONST_1*-137.5, MATHS_CONST_1*-104.5, MATHS_CONST_1*11.0, MATHS_CONST_1*11.0, 1

    call_3 fx_set_layer_fns, 1, particle_grid_tick_all_dave_equation,    particle_grid_draw_all_as_2x2_tinted

    ; Setup the ball.
    call_2f the_env_set_constant_force, 0.0, 0.0    ; zero gravity
    call_2f the_ball_set_vel,  0.0, 0.0

    ; Connect the ball to the particle grid collider.
    math_link_vars particle_grid_collider_pos+0, 0.0, 1.0, the_ball_block+TheBall_x
    math_link_vars particle_grid_collider_pos+4, 0.0, 1.0, the_ball_block+TheBall_y

    call_1 particle_grid_set_dave_rotation, -12
    call_1 particle_grid_set_dave_expansion, -13

    call_2f the_ball_set_pos, 208.0,-80.0
    wait_secs SeqConfig_PatternLength_Secs*0.25
    ; Start off right side of the screen and move left.
    call_2f the_ball_set_vel,  -3.12, 0.0

    wait_secs SeqConfig_PatternLength_Secs*0.75

    ; Top and move down.
    call_2f the_ball_set_pos, -108.0, 176.0
    call_2f the_ball_set_vel,  0.0, -2.64

    wait_secs SeqConfig_PatternLength_Secs*0.75

    ; Morph to new shape.
;    call_3 particle_grid_add_verts, 520, circ_verts_no_adr, 1
;    call_3 particle_grid_add_verts, 520, bits_owl_vert_array_no_adr, 1
    call_3 particle_grid_add_verts, 520, bits_logo_vert_array_no_adr, 1

    ; Bottom and move up.
    call_2f the_ball_set_pos, 64.0, -176.0
    call_2f the_ball_set_vel,  0.0, 2.64

    wait_secs SeqConfig_PatternLength_Secs*0.75

    ; Right and move left again.
    call_2f the_ball_set_pos, 208.0, 44.0
    call_2f the_ball_set_vel,  -3.12, 0.0

    wait_secs SeqConfig_PatternLength_Secs*0.75

    ; Left and move right again.
    call_2f the_ball_set_pos, -208.0, -80.0
    call_2f the_ball_set_vel,  3.12, 0.0

    wait_secs SeqConfig_PatternLength_Secs*0.75
    call_2f the_ball_set_vel,  0.0, 0.0

.if 0
    ; Bottom and move up.
    call_2f the_ball_set_pos, -48.0, -176.0
    call_2f the_ball_set_vel,  0.0, 2.64

    wait_secs SeqConfig_PatternLength_Secs*0.75

    ; Top and move down.
    call_2f the_ball_set_pos, 64.0, 176.0
    call_2f the_ball_set_vel,  0.0, -2.64
    wait_secs SeqConfig_PatternLength_Secs/2.0

    ; Right and move left again.
    call_2f the_ball_set_pos, 208.0, -32.0
    call_2f the_ball_set_vel,  -3.12, 0.0
.endif

    end_script

seq_kill_orb_straight_lines:
    math_unlink_vars particle_grid_collider_pos+0
    math_unlink_vars particle_grid_collider_pos+4
    end_script


; Ball drops under gravity etc.
seq_init_ball_under_gravity:
    ; Make particle grid.
    ; X [-147, 147] step 14 = 22 total (border 13)
    ; Y [-105, 105] step 14 = 16 total (border 23)
;   call_6 particle_grid_make, 22, 16, MATHS_CONST_1*-147.0, MATHS_CONST_1*-105.0, MATHS_CONST_1*14.0, MATHS_CONST_1*14.0
    call_7 particle_gridlines_make, 8, 6, MATHS_CONST_1*-128.0, MATHS_CONST_1*-96.0, MATHS_CONST_1*8.0, 4, 1

    call_3 fx_set_layer_fns, 1, particle_grid_tick_all_dave_equation,    particle_grid_draw_all_as_2x2_tinted

    ; Environment setup.
    make_and_add_env_plane the_env_floor_plane, 0.0, -128.0, 0.0
;    make_and_add_env_plane the_env_left_plane, -160.0, -128.0, 64.0        ; +90 degrees
;    make_and_add_env_plane the_env_left_slope, -80.0, -128.0, 32.0         ; +45 degrees
;    make_and_add_env_plane the_env_right_plane, 160.0, -128.0, -64.0       ; -90 degrees
;    make_and_add_env_plane the_env_right_slope, 80.0, -128.0, -32.0        ; -45 degrees

    ; Setup the ball.
    call_2f the_env_set_constant_force  0.0, -(2.0/50.0)
;    call_2f the_ball_set_pos, 80.0, 80.0            ; centre ball
;    call_2f the_ball_set_vel,  0.5, 0.0

    ; Make the ball the particle grid collider.
    ; particle_grid_collider_pos.x = the_ball.x
    ; particle_grid_collider_pos.y = the_ball.y
    math_link_vars particle_grid_collider_pos+0, 0.0, 1.0, the_ball_block+TheBall_x
    math_link_vars particle_grid_collider_pos+4, 0.0, 1.0, the_ball_block+TheBall_y

    end_script

seq_kill_ball_under_gravity:
;    call_1 the_env_remove_plane, the_env_left_plane
    ;call_1 the_env_remove_plane, the_env_left_slope
;    call_1 the_env_remove_plane, the_env_right_plane
    ;call_1 the_env_remove_plane, the_env_right_slope
    call_1 the_env_remove_plane, the_env_floor_plane

    math_unlink_vars particle_grid_collider_pos+0
    math_unlink_vars particle_grid_collider_pos+4
    end_script


; Orb emits particles.
seq_init_orb_particle_emitter:
    call_0 particles_init

    ; Set layers.
    call_3 fx_set_layer_fns, 0, math_emitter_tick_all               screen_cls
    call_3 fx_set_layer_fns, 1, particles_tick_all_under_gravity,   particles_draw_all_as_2x2
    
    ; Setup emitter.
    write_addr math_emitter_p, math_emitter_config_3
    write_addr math_emitter_spawn_fn, particle_spawn

    ; Setup the ball. TODO: Merge these? Hmmm!
    call_2f particles_set_constant_force  0.0, 0.0
    call_2f the_env_set_constant_force  0.0, 0.0
    call_2f the_ball_set_pos, 0.0, 0.0
    call_2f the_ball_set_vel, 0.0, 0.0

    call_1f the_ball_set_radiusf, 4.0

    ; Ball motion.
    ; v = a + b * f(c + d * t)
    ; radius = i/10
    math_make_var seq_path_radius, 0.0, 1.0, math_no_func, 0.0, 1.0/10.0

    ; Want this to be the radius value -----------------------v
    math_make_var2 the_ball_block+TheBall_x,   0.0, seq_path_radius, math_sin, 0.0, 1.0/(MATHS_2PI*40.0)
    math_make_var2 the_ball_block+TheBall_y,   0.0, seq_path_radius, math_cos, 0.0, 1.0/(MATHS_2PI*40.0)

    math_make_rgb seq_palette_green_white_ramp+15*4, 0x00ffffff, 0x0000ff00, seq_rgb_blend
    math_make_var seq_rgb_blend, 0.5, 0.5, math_sin, 0.0, 1.0/50.0

    wait_secs SeqConfig_PatternLength_Secs*3

    ; Copy free particles to the particle grid.
    call_1 particles_transfer_to_grid, 0

    call_1f the_ball_set_radiusf, TheBall_DefaultRadius

    ; Then lerp them to become the spiral.
    ;call_7 particle_grid_make_spiral, 500, MATHS_CONST_1*4.0, MATHS_CONST_1*1.0, MATHS_CONST_1*0.3, MATHS_CONST_1*0.0, MATHS_CONST_1*0.0, 1

    ; TODO: Separate tick & draw layers - I shouldn't have to know about CLS here!
    call_3 fx_set_layer_fns, 0, 0               screen_cls
    call_3 fx_set_layer_fns, 1, particle_grid_tick_all_dave_equation,    particle_grid_draw_all_as_2x2_tinted

    math_link_vars particle_grid_collider_pos+0, 0.0, 1.0, the_ball_block+TheBall_x
    math_link_vars particle_grid_collider_pos+4, 0.0, 1.0, the_ball_block+TheBall_y

;    math_make_var the_ball_block+TheBall_x,   0.0, 50.0, math_sin, 0.0, 1.0/(MATHS_2PI*200.0)
;    math_make_var the_ball_block+TheBall_y,   0.0, 50.0, math_cos, 0.0, 1.0/(MATHS_2PI*80.0)

    end_script

seq_kill_orb_particle_emitter:
    math_unlink_vars particle_grid_collider_pos+0
    math_unlink_vars particle_grid_collider_pos+4
    math_kill_var the_ball_block+TheBall_x
    math_kill_var the_ball_block+TheBall_y
    math_kill_var seq_path_radius
    math_kill_rgb seq_palette_green_white_ramp+15*4
    end_script


; Rain down!
seq_init_rain:
    call_0 particle_dave_init

    ; Set layers.
    call_3 fx_set_layer_fns, 0, math_emitter_tick_all               screen_cls
    call_3 fx_set_layer_fns, 1, particle_dave_tick_all,            particle_dave_draw_all_as_2x2
    
    ; Setup emitter.
    write_addr math_emitter_p, math_emitter_config_4
    write_addr math_emitter_spawn_fn, particle_dave_spawn

    ; Setup the ball.
    call_2f the_env_set_constant_force, 0.0, 0.0    ; zero gravity
    call_2f the_ball_set_pos, 0.0, 0.0              ; centre ball
    call_2f the_ball_set_vel, 0.0, 0.0

    ; Make the ball the particle grid collider.
    ; particle_grid_collider_pos.x = the_ball.x
    ; particle_grid_collider_pos.y = the_ball.y
    math_link_vars particle_grid_collider_pos+0, 0.0, 1.0, the_ball_block+TheBall_x
    math_link_vars particle_grid_collider_pos+4, 0.0, 1.0, the_ball_block+TheBall_y

    ; Equation of the ball.
    ; x=radius * sin(t/speed)
    ; y=128 + radius * cos(t/speed)
    ; Where radius = t/speed as well.
    ; ~20 seconds to get to max radius 100. 1000/speed=100;speed=10.

    ; radius = i/10
    math_make_var seq_path_radius, 40.0, -40.0, math_cos, 0.0, 1.0/(4.0*SeqConfig_PatternLength_Frames)

    ; Want this to be the radius value -----------------------v
    math_make_var2 the_ball_block+TheBall_x,   0.0, seq_path_radius, math_sin, 0.0, 1.0/(MATHS_2PI*40.0)
    ;math_make_var2 the_ball_block+TheBall_y,   0.0, seq_path_radius, math_cos, 0.0, 1.0/(MATHS_2PI*50.0)

    call_2f particles_set_constant_force 0.0, -1.0/50.0

    wait_patterns 3.0

    call_2f particles_set_constant_force 0.0, 0.0
    write_addr math_emitter_p, math_emitter_config_5
    end_script

seq_kill_rain:
    math_unlink_vars particle_grid_collider_pos+0
    math_unlink_vars particle_grid_collider_pos+4
    math_kill_var the_ball_block+TheBall_x
    math_kill_var the_ball_block+TheBall_y
    math_kill_var seq_path_radius

    call_3 fx_set_layer_fns, 0, 0               screen_cls
    end_script

; ============================================================================
; Support functions.
; ============================================================================

seq_unlink_palette_lerp:
    math_kill_var seq_palette_blend
    math_kill_var seq_palette_id
    end_script

seq_make_owl_verts:
    ; Convert 1bpp image to 4bpp using colour 7.
    call_5 bits_convert_mode4_to_mode9, bits_owl_no_adr, bits_owl_mode9_no_adr, Bits_Owl_Width_Bytes, Bits_Owl_Height_Rows, 0x7

    ; Random sampling of 4bpp image (marks top bit).
    call_4 bits_logo_select_random, Bits_Owl_Width_Bytes, Bits_Owl_Height_Rows, bits_owl_mode9_no_adr, 520

    ; Create a vertex array (slow) to reduce run-time overhead.
    call_5 bits_create_vert_array_from_image, Bits_Owl_Width_Bytes, Bits_Owl_Height_Rows, bits_owl_mode9_no_adr, bits_owl_vert_array_no_adr, 520*VECTOR2_SIZE

    end_script

; ============================================================================
; Sequence tasks can be forked and self-terminate on completion.
; Rather than have a task management system it just uses the existing script
; system and therefore supports any arbitrary sequence of fn calls.
;
;  Use 'yield <label>' to continue the script on the next from a given label.
;  Use 'end_script_if_zero <var>' to terminate a script conditionally.
;
; (Yes I know this is starting to head into 'real language' territory.)
; ============================================================================

.if 0
seq_test_fade_down:
    call_3 palette_init_fade, 0, 1, seq_palette_red_additive

seq_test_fade_down_loop:
    call_0 palette_update_fade_to_black
    end_script_if_zero palette_interp
    yield seq_test_fade_down_loop

seq_test_fade_up:
    call_3 palette_init_fade, 0, 1, seq_palette_red_additive

seq_test_fade_up_loop:
    call_0 palette_update_fade_from_black
    end_script_if_zero palette_interp
    yield seq_test_fade_up_loop
.endif

; ============================================================================
; Sequence specific data.
; ============================================================================

math_emitter_config_1:
    math_const 50.0/80                                                  ; emission rate=80 particles per second fixed.
    math_func  0.0,    100.0,  math_sin,  0.0,   1.0/(MATHS_2PI*60.0)   ; emitter.pos.x = 100.0 * math.sin(f/60)
    math_func  128.0,  60.0,   math_cos,  0.0,   1.0/(MATHS_2PI*80.0)   ; emitter.pos.y = 128.0 + 60.0 * math.cos(f/80)
    math_func  0.0,    2.0,    math_sin,  0.0,   1.0/(MATHS_2PI*100.0)  ; emitter.dir.x = 2.0 * math.sin(f/100)
    math_func  1.0,    5.0,    math_rand, 0.0,   0.0                    ; emitter.dir.y = 1.0 + 5.0 * math.random()
    math_const 255                                                      ; emitter.life
    math_func  0.0,    1.0,    math_and15,0.0,   1.0                    ; emitter.colour = (emitter.colour + 1) & 15
    math_func  8.0,    6.0,    math_sin,  0.0,   1.0/(MATHS_2PI*10.0)   ; emitter.radius = 8.0 + 6 * math.sin(f/10)

math_emitter_config_2:
    math_const 50.0/80                                                  ; emission rate=80 particles per second fixed.
    math_const 0.0                                                      ; emitter.pos.x = 0
    math_const 0.0                                                      ; emitter.pos.y = 192.0
    math_func -1.0,    2.0,    math_rand,  0.0,  0.0                    ; emitter.dir.x = 4.0 + 3.0 * math.random()
    math_func  1.0,    3.0,    math_rand,  0.0,  0.0                    ; emitter.dir.y = 1.0 + 5.0 * math.random()
    math_const 512                                                      ; emitter.life
    math_func  0.0,    1.0,    math_and15, 0.0,  1.0                    ; emitter.colour = (emitter.colour + 1) & 15
    math_const 8.0                                                      ; emitter.radius = 8.0

math_emitter_config_3:  ; attached to the_ball.
    math_const 50.0/20                                                  ; emission rate=80 particles per second fixed.
    math_func_read_addr 0.0, 1.0, the_ball_block+TheBall_x              ; emitter.x = 0.0 + 1.0 * the_ball_block.x
    math_func_read_addr 0.0, 1.0, the_ball_block+TheBall_y              ; emitter.y = 0.0 + 1.0 * the_ball_block.y
    math_func  0.0,    0.3,    math_sin,  0.0,   1.0/(MATHS_2PI*5.0)  ; emitter.dir.x = 2.0 * math.sin(f/100)
    math_func  0.0,    0.3,    math_cos,  0.0,   1.0/(MATHS_2PI*5.0)  ; emitter.dir.y = 2.0 * math.cos(f/100)
    math_const 32768                                                    ; emitter.life
    math_const 1                                                        ; emitter.colour
    math_const 1                                                        ; emitter.radius

math_emitter_config_4:
    math_const 50.0/120                                                 ; emission rate=120 particles per second fixed.
    math_func  -160.0,  320.0,    math_rand,  0.0,  0.0                 ; emitter.pos.x = 160.0 * math.random()
    math_func  128.0,   32.0,     math_rand,  0.0,  0.0                 ; emitter.pos.y = 128.0 + 32.0 * math.random()
    math_const 0.0                                                      ; emitter.vel.x = 0.0
    math_const 0.0                                                      ; emitter.vel.y = 0.0
    math_const 512                                                      ; emitter.life
    math_const 14                                                       ; emitter.colour
    math_const 8.0                                                      ; emitter.radius = 8.0

math_emitter_config_5:
    math_const 50.0/50                                                  ; emission rate=50 particles per second fixed.
    math_func  -160.0,  320.0,    math_rand,  0.0,  0.0                 ; emitter.pos.x = 160.0 * math.random()
    math_func  128.0,   32.0,     math_rand,  0.0,  0.0                 ; emitter.pos.y = 128.0 + 32.0 * math.random()
    math_const 0.0                                                      ; emitter.vel.x = 0.0
    math_func  0.0,     -0.5,     math_rand,  0.0,  0.0                 ; emitter.vel.y = - 4.0 * math.random()
    math_const 512                                                      ; emitter.life
    math_const 14                                                       ; emitter.colour
    math_const 8.0                                                      ; emitter.radius = 8.0

; ============================================================================

seq_palette_red_additive:
    .long 0x00000000                    ; 00 = 0000 = black
    .long 0x00000020                    ; 01 = 0001 =
    .long 0x00000040                    ; 02 = 0010 =
    .long 0x00000060                    ; 03 = 0011 =
    .long 0x00000080                    ; 04 = 0100 =
    .long 0x000000a0                    ; 05 = 0101 =
    .long 0x000000c0                    ; 06 = 0110 =
    .long 0x000020e0                    ; 07 = 0111 = reds
    .long 0x000040e0                    ; 08 = 1000 =
    .long 0x000060e0                    ; 09 = 1001 =
    .long 0x000080e0                    ; 10 = 1010 =
    .long 0x0000a0e0                    ; 11 = 1011 =
    .long 0x0000c0e0                    ; 12 = 1100 =
    .long 0x0000d0e0                    ; 13 = 1101 =
    .long 0x00e0e0e0                    ; 14 = 1110 = oranges
    .long 0x00f0f0f0                    ; 15 = 1111 = white

seq_palette_green_white_ramp:
    .long 0x00000000                    ; 00 = 0000 = black
    .long 0x00008000                    ; 01 = 0001 =
    .long 0x00108010                    ; 02 = 0010 =
    .long 0x00208020                    ; 03 = 0011 =
    .long 0x00308030                    ; 04 = 0100 =
    .long 0x00408040                    ; 05 = 0101 =
    .long 0x00509050                    ; 06 = 0110 =
    .long 0x0060a060                    ; 07 = 0111 = reds
    .long 0x0070b070                    ; 08 = 1000 =
    .long 0x0080c080                    ; 09 = 1001 =
    .long 0x0090d090                    ; 10 = 1010 =
    .long 0x00a0e0a0                    ; 11 = 1011 =
    .long 0x00b0e0b0                    ; 12 = 1100 =
    .long 0x00c0e0c0                    ; 13 = 1101 =
    .long 0x00d0e0d0                    ; 14 = 1110 = oranges
    .long 0x00f0f0f0                    ; 15 = 1111 = white

seq_palette_red_magenta_ramp:
    .long 0x00000000                    ; 00 = 0000 = black
    .long 0x00000080                    ; 01 = 0001 =
    .long 0x00100080                    ; 02 = 0010 =
    .long 0x00200080                    ; 03 = 0011 =
    .long 0x00300080                    ; 04 = 0100 =
    .long 0x00400080                    ; 05 = 0101 =
    .long 0x00500080                    ; 06 = 0110 =
    .long 0x00600080                    ; 07 = 0111 = reds
    .long 0x00700080                    ; 08 = 1000 =
    .long 0x00800080                    ; 09 = 1001 =
    .long 0x00900090                    ; 10 = 1010 =
    .long 0x008040a0                    ; 11 = 1011 =
    .long 0x007050b0                    ; 12 = 1100 =
    .long 0x006060c0                    ; 13 = 1101 =
    .long 0x005070d0                    ; 14 = 1110 = oranges
    .long 0x004080f0                    ; 15 = 1111 = white

seq_palette_black_on_white:
    .long 0x00f0f0f0                    ; 00 = 0000 = black
    .long 0x00000000                    ; 01 = 0001 =
    .long 0x00101010                    ; 02 = 0010 =
    .long 0x00202020                    ; 03 = 0011 =
    .long 0x00303030                    ; 04 = 0100 =
    .long 0x00404040                    ; 05 = 0101 =
    .long 0x00505050                    ; 06 = 0110 =
    .long 0x00606060                    ; 07 = 0111 = reds
    .long 0x00707070                    ; 08 = 1000 =
    .long 0x00808080                    ; 09 = 1001 =
    .long 0x00909090                    ; 10 = 1010 =
    .long 0x00a0a0a0                    ; 11 = 1011 =
    .long 0x00b0b0b0                    ; 12 = 1100 =
    .long 0x00c0c0c0                    ; 13 = 1101 =
    .long 0x00d0d0d0                    ; 14 = 1110 = oranges
    .long 0x00e0e0e0                    ; 15 = 1111 = white

seq_palette_blue_cyan_ramp:
    .long 0x00000000                    ; 00 = 0000 = black
    .long 0x00a03000                    ; 01 = 0001 =
    .long 0x00a04000                    ; 02 = 0010 =
    .long 0x00a05000                    ; 03 = 0011 =
    .long 0x00a06000                    ; 04 = 0100 =
    .long 0x00b07000                    ; 05 = 0101 =
    .long 0x00b08000                    ; 06 = 0110 =
    .long 0x00c09000                    ; 07 = 0111 = reds
    .long 0x00c0a000                    ; 08 = 1000 =
    .long 0x00d0b020                    ; 09 = 1001 =
    .long 0x00d0c040                    ; 10 = 1010 =
    .long 0x00e0d060                    ; 11 = 1011 =
    .long 0x00e0e080                    ; 12 = 1100 =
    .long 0x00f0f0a0                    ; 13 = 1101 =
    .long 0x00f0f0c0                    ; 14 = 1110 = oranges
    .long 0x00f0f0f0                    ; 15 = 1111 = white

seq_palette_all_black:
    .rept 16
    .long 0x00000000
    .endr

seq_palette_all_white:
    .rept 16
    .long 0x00ffffff
    .endr

seq_palette_lerped:
    .skip 15*4
    .long 0x00ffffff


; ============================================================================
; Sequence specific bss.
; ============================================================================

seq_rgb_blend:
    .long 0

seq_palette_blend:
    .long 0

seq_path_radius:
    .long 0

seq_palette_id:
    .long 0

seq_ball_radius:
    .long 0

the_env_floor_plane:
    .skip EnvPlane_SIZE

the_env_left_plane:
    .skip EnvPlane_SIZE

the_env_left_slope:
    .skip EnvPlane_SIZE

the_env_right_plane:
    .skip EnvPlane_SIZE

the_env_right_slope:
    .skip EnvPlane_SIZE

; ============================================================================
