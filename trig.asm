; #########################################################################
;
;   trig.asm - Assembly file for Assignment 3
;	Biraj Parikh
;	Comp_Eng 205 - Winter 2020
; #########################################################################

      .586
      .MODEL FLAT,STDCALL
      .STACK 4096
      option casemap :none  ; case sensitive

include trig.inc

.DATA

;;  These are some useful constants (fixed point values that correspond to important angles)
PI_HALF = 102943           	;;  PI / 2
PI =  205887	                ;;  PI 
TWO_PI	= 411774                ;;  2 * PI 
PI_INC_RECIP =  5340353        	;;  Use reciprocal to find the table entry for a given angle
	                        ;;  (It is easier to use than divison would be)
				
;; If you need to, you can place global variables here
	
.CODE

FixedSin PROC USES ebx ecx angle:FXPT
	LOCAL transformed_angle:FXPT
 
	mov ecx, angle
	jmp check_reduce_angle
reduce_angle:  						;; subtract 2*PI from angle (if it's geq 2*PI)
	sub ecx, TWO_PI
check_reduce_angle:
	cmp ecx, TWO_PI
	jge reduce_angle

	jmp check_increase_angle			;; add 2*PI to angle (if it is negative)
increase_angle:
	add ecx, TWO_PI
check_increase_angle:
	cmp ecx, 0
	jl increase_angle

	;; which quadrant? Now the angle is in range [0, 2*pi]
	mov transformed_angle, ecx
	cmp ecx, PI_HALF
	jl q1
	cmp ecx, PI
	jl q2
	sub ecx, PI
	cmp ecx, PI_HALF
	jl q3						;; now we know the angle is in [pi, 3*pi/2)
	jmp q4						;; angle is in [3*pi/2, 2*pi)
q1:
	mov eax, PI_INC_RECIP
	imul ecx  					;; location of angle in table is in edx (top 2 bytes)
	movzx eax, WORD PTR [SINTAB + 2*edx]
	ret

q2:
	mov ebx, PI					;; sin(angle) = sin(PI - angle) for angle in [pi/2, pi)
	sub ebx, ecx
	mov ecx, ebx

	mov eax, PI_INC_RECIP
	imul ecx
	movzx eax, WORD PTR [SINTAB + 2*edx]
	ret

q3:							;; PI subtracted above for angle between [pi, 3*pi/2)
	mov eax, PI_INC_RECIP
	imul ecx 
	movzx eax, WORD PTR [SINTAB + 2*edx]
	neg eax						;; based on identity
	ret

q4:
	mov ebx, TWO_PI
	mov ecx, transformed_angle			;; restore the angle
	sub ebx, ecx					;; 2*PI - angle should give the negative angle in q1
	mov eax, PI_INC_RECIP
	imul ecx 
	movzx eax, WORD PTR [SINTAB + 2*edx]
	neg eax						;; based on identity
	ret

FixedSin ENDP
	
FixedCos PROC USES ecx angle:FXPT

	;; cos(x) = sin(x + PI/2)
	mov ecx, angle
	add ecx, PI_HALF
	INVOKE FixedSin, ecx
	ret
FixedCos ENDP	
END