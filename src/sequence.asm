; ============================================================================
; The actual sequence for the demo.
; ============================================================================


seq_main_program:

	; Setup layers of FX.
    call_3 fx_set_layer_fns, 0, 0,                      clear_left_screen       ; bottom layer
    call_3 fx_set_layer_fns, 1, update_columns,         plot_columns            ; columns
                                                                                ; (cube here)
    call_3 fx_set_layer_fns, 3, 0,                      plot_logo               ; moving logo
    call_3 fx_set_layer_fns, 4, scroller_update_new,    scroller_draw_new       ; scroller on top

    ; Wait for 250 frames
    wait 250

    ; Fork a new script
    fork seq_change_column_0_colour

    ; Wait for 250 frames
    wait 250

    ; Call a fn with 3 params
    call_3 fx_set_layer_fns, 2, update_3d_scene,        draw_3d_scene           ; add cube.

    ; THE END.
    end_script

    ; TODO: End demo or loop etc.


seq_change_column_0_colour:
    write_addr column_colours+0, 0xcccccccc
    wait 1
    write_addr column_colours+0, 0xdddddddd
    wait 1
    write_addr column_colours+0, 0xeeeeeeee
    wait 1
    write_addr column_colours+0, 0xffffffff
    end_script
