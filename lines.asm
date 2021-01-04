; #########################################################################
;
;   lines.asm - Assembly file for Assignment 2
;   Biraj Parikh
;   Comp_Eng 205 - Winter 2020
; #########################################################################

      .586
      .MODEL FLAT,STDCALL
      .STACK 4096
      option casemap :none  ; case sensitive

include stars.inc
include lines.inc

.DATA

    ;; If you need to, you can place global variables here
    LINE_COLOR DWORD 227
    
.CODE

;; Don't forget to add the USES the directive here
;;   Place any registers that you modify (either explicitly or implicitly)
;;   into the USES list so that caller's values can be preserved
    
;;   For example, if your procedure uses only the eax and ebx registers
;;      DrawLine PROC USES eax ebx x0:DWORD, y0:DWORD, x1:DWORD, y1:DWORD, color:DWORD
DrawLine PROC USES ebx ecx edx esi edi x0:DWORD, y0:DWORD, x1:DWORD, y1:DWORD, color:DWORD
    LOCAL inc_x:DWORD, inc_y:DWORD, del_x:DWORD, del_y:DWORD
    
;; calculate abs value of x1-x0
    mov ebx, x1
    sub ebx, x0
    cmp ebx, 0
    jl less_than_x_abs
    mov del_x, ebx
    jmp calc_abs_x2

less_than_x_abs:
    neg ebx
    mov del_x, ebx

;; calculate abs value of y1-y0
calc_abs_x2:
    mov ebx, y1
    sub ebx, y0
    cmp ebx, 0
    jl less_than_y_abs
    mov del_y, ebx
    jmp calc_inc_x

less_than_y_abs:
    neg ebx
    mov del_y, ebx

;; check if the line is moving +x/-x
calc_inc_x:
    mov ebx, x1
    cmp x0, ebx
    jl x_going_up
    mov inc_x, -1
    jmp calc_inc_y
x_going_up:
    mov inc_x, 1

;; check if the line is moving +y/-y
calc_inc_y:
    mov ebx, y1
    cmp y0, ebx
    jl y_going_up
    mov inc_y, -1
    jmp calc_error
y_going_up:
    mov inc_y, 1

;; error = del_x/2 if del_x > del_y, else error = -del_x/2
calc_error:
    mov ecx, del_x  ;; calculate del_x/2
    shr ecx, 1
    mov ebx, del_x  ;; if del_x <= del_y, error = -del_x/2, else error = del_x/2
    cmp ebx, del_y
    jle del_x_leq_del_y
    mov edi, ecx  ;; edi will be used to hold error
    jmp while_setup
del_x_leq_del_y:  ;;  do the negation part of error = -del_x/2
    neg ecx
    mov edi, ecx  ;; edi will be used to hold error
    jmp while_setup

while_setup:
    mov ecx, x0  ;; ecx = curr_x
    mov edx, y0  ;; edx = curr_y
    mov esi, 0  ;; esi = prev_error
    ; mov edi, error  ;; edi = error
    INVOKE DrawPixel, ecx, edx, LINE_COLOR  ;; draw initial pixel at starting location
    jmp check_while_cond

while_body:
    INVOKE DrawPixel, ecx, edx, LINE_COLOR
    mov esi, edi  ;; prev_error <- error (update prev_error)
    ;; if(prev_err > -del_x)
    mov ebx, del_x
    neg ebx
    cmp esi, ebx
    jle check_if_2
    ;; if_1 body
    sub edi, del_y  ;; error -= del_y
    add ecx, inc_x

check_if_2:
    ;; if(prev_error < del_y)
    mov ebx, del_y
    cmp esi, ebx
    jge check_while_cond  ;; false condition
    ;; if_2 body
    add edi, del_x  ;; error += del_x
    add edx, inc_y

check_while_cond:  ;; while(curr_x != x1 OR curr_y != y1)
    cmp ecx, x1
    jne while_body
    cmp edx, y1
    jne while_body

    ret

DrawLine ENDP

END