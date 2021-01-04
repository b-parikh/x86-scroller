; #########################################################################
;
;   stars.asm - Assembly file for CompEng205 Assignment 1
;
;
; #########################################################################

      .586
      .MODEL FLAT,STDCALL
      .STACK 4096
      option casemap :none  ; case sensitive


include stars.inc

.DATA

	;; If you need to, you can place global variables here

.CODE

DrawStarField proc
	;; Screen is 640 by 480 (origin at top left corner)
    ;; Draw stars from left to right as you go down the screen
    mov eax, 10  ; x coordinate
    mov ebx, 10  ; y coordinate

    draw_at_current_position:
    invoke DrawStar, eax, ebx
    add eax, 75  ; move x coordinate forward
    cmp eax, 630  ; if x coordinate >= 630, move down a row
    jge move_to_next_row
    jmp draw_at_current_position 

    move_to_next_row:
    mov eax, 10  ; restart x at 10
    add ebx, 50  ; move y down to the next row
    cmp ebx, 470  ; if y coordinate < 470, continue drawing
    jl draw_at_current_position

    finish_art:
	ret
DrawStarField endp



END
