; #########################################################################
;
;   blit.asm - Assembly file for CompEng205 Assignment 3
;   Biraj Parikh
;   Comp_Eng 205 - Winter 2020
; #########################################################################

      .586
      .MODEL FLAT,STDCALL
      .STACK 4096
      option casemap :none  ; case sensitive

include stars.inc
include lines.inc
include trig.inc
include blit.inc


.DATA
      SCREEN_WIDTH = 640
      SCREEN_HEIGHT = 480
	;; If you need to, you can place global variables here
	
.CODE

DrawPixel PROC USES edi esi ecx edx x:DWORD, y:DWORD, color:DWORD
      mov edi, x                                ;; x is in edi
      mov esi, y                                ;; y is in esi
      mov ecx, color                            ;; this is only a byte
      
      cmp edi, SCREEN_WIDTH                     ;; x out of bounds (0 <= x < 640)
      jge fin
      cmp edi, 0
      jl fin
      
      cmp esi, SCREEN_HEIGHT                    ;; y out of bounds (0 <= y < 480)
      jge fin
      cmp esi, 0
      jl fin
      
      mov eax, SCREEN_WIDTH                     ;; 640*y will give the row
      mul esi
      add eax, edi                              ;; offset into the row
      add eax, ScreenBitsPtr                    ;; the start of the screen
      mov BYTE PTR [eax], cl                    ;; move the color (one byte) into the appropriate location
fin:
	ret

DrawPixel ENDP

BasicBlit PROC USES esi edi ebx ecx edx ptrBitmap:PTR EECS205BITMAP , xcenter:DWORD, ycenter:DWORD
      LOCAL col_start:DWORD, col_end:DWORD, row_start:DWORD, row_end:DWORD, dwWidth:DWORD, dwHeight:DWORD, transparent:BYTE

      mov ebx, ptrBitmap
      mov ecx, (EECS205BITMAP PTR [ebx]).dwWidth
      mov dwWidth, ecx                          ;; once x_start is found, add it to this to get the ending x position
      mov edx, (EECS205BITMAP PTR [ebx]).dwHeight
      mov dwHeight, edx                         ;; once y_start is found, add it to this to get the ending y position

      ;; calculate the top left starting position to draw bitmap (esi, edi)
      ;; position is at (ecx, edx), these registers will be incremented as we draw
      mov esi, xcenter
      shr ecx, 1                                ;; divide the width in half
      sub esi, ecx                              ;; find col where to start bitmap (col_start)
      mov col_start, esi                        ;; save starting column for later
      mov edi, ycenter
      shr edx, 1                                ;; divide height in half
      sub edi, edx                              ;; find row where to start bitmap drawing (row_start)
      mov row_start, edi

      ;; find where to stop drawing, see lines 56 and 58 for reasoning behind the add
      add esi, dwWidth                          ;; find the ending column
      mov col_end, esi
      add edi, dwHeight                         ;; find the ending row
      mov row_end, edi
  
      mov cl, (EECS205BITMAP PTR[ebx]).bTransparent
      mov transparent, cl                       ;; use lowest byte of ecx to save transparent value
      mov ebx, (EECS205BITMAP PTR[ebx]).lpBytes ;; point to the colors
      mov esi, col_start                        ;; start the col counter
      mov edi, row_start                        ;; start the row counter

check_row:                                      ;; 0 <= row < SCREEN_HEIGHT
      cmp edi, row_end                          ;; finished drawing last row of bitmap
      jge fin
      cmp edi, 0                                ;; bitmap is above top of screen
      jl incr_row
      cmp edi, SCREEN_HEIGHT                    ;; bitmap is below bottom of screen
      jge fin

check_col:                                      ;; 0 <= col < SCREEN_WIDTH 
      cmp esi, col_end
      jge reset_col
      cmp esi, 0                                ;; bitmap is before the left side of the screen
      jl incr_col
      cmp esi, SCREEN_WIDTH                     ;; bitmap is after the right side of the screen
      jge reset_col

      ;; find idx within the bitmap (y*dwWidth) + x; if the pixel isn't transparent, draw it
      ;; need to convert y and x from global screen positions to local bitmap positions to idx into the color array
      ;; therefore, (edi*dwWidth) + esi -> ((edi - row_start) * dwWidth) + (esi - col_start)
      mov eax, edi
      sub eax, row_start                        ;; convert the global row pos to local (bitmap) row pos
      imul eax, dwWidth
      add eax, esi                              ;; eax holds the offset corresponding to (esi, edi)
      sub eax, col_start                        ;; convert the global col pos to local (bitmap) col pos
      mov al, BYTE PTR[ebx + eax]               ;; index into the color array to find the color of (esi, edi)
      cmp al, transparent
      je incr_col
      movzx eax, al                             ;; pixel isn't transparent, draw it
      INVOKE DrawPixel, esi, edi, eax           ;; esi holds the col idx, edi hold the row idx

incr_col:
      add esi, 1
      jmp check_col

reset_col:                                      ;; reset col counter then incr to next row
      mov esi, col_start

incr_row:
      add edi, 1
      jmp check_row

fin:
	ret	

BasicBlit ENDP


RotateBlit PROC USES ebx ecx edx esi lpBmp:PTR EECS205BITMAP, xcenter:DWORD, ycenter:DWORD, angle:FXPT
      LOCAL cosA:FXPT, sinA:FXPT, shiftX:DWORD, shiftY:DWORD, fxpt_width:FXPT, fxpt_height:FXPT, dstWidth:DWORD
      LOCAL dstHeight:DWORD, dwWidth:DWORD, dwHeight:DWORD, srcX:DWORD, srcY:DWORD, offset_x:DWORD, offset_y:DWORD
	
      mov esi, lpBmp
      mov eax, (EECS205BITMAP PTR[esi]).dwWidth
      mov dwWidth, eax
      sal eax, 16                               ;; convert dwWidth to fixed point format (16:16)
      mov fxpt_width, eax                       ;; save it for later use
      mov eax, (EECS205BITMAP PTR[esi]).dwHeight
      mov dwHeight, eax
      sal eax, 16                               ;; convert dwHeight to fixed point format (16:16)
      mov fxpt_height, eax                      ;; save it for later use

      INVOKE FixedCos, angle
      mov ebx, eax
      mov cosA, eax
      
      INVOKE FixedSin, angle
      mov ecx, eax
      mov sinA, eax


      sar ebx, 1                                ;; cosA/2
      sar ecx, 1                                ;; sinA/2
      ;; shiftX = (bitmap_width) * cosA/2 - (bitmap_height) * sinA/2
      mov eax, fxpt_width
      imul ebx                                  ;; Left hand multiplication
      mov shiftX, edx
      mov eax, fxpt_height
      imul ecx                                  ;; Right hand multiplication
      sub shiftX, edx

      ;; shiftY = (bitmap_height) * cosA/2 + (bitmap_width) * sinA/2
      mov eax, fxpt_height
      imul ebx
      mov shiftY, edx
      mov eax, fxpt_width
      imul ebx
      mov shiftY, edx                           ;; Left hand multiplication
      mov eax, fxpt_width
      imul ecx                                  ;; Right hand multiplication
      add shiftY, edx

      ;; dstWidth = bitmap_width + bitmap_height
      ;; dstHeight = dstWidth
      mov eax, dwWidth
      add eax, dwHeight
      mov dstWidth, eax
      mov dstHeight, eax

      mov ebx, dstWidth                         ;; ebx is dstX
      neg ebx
      jmp check_outer
outer_body:
      mov ecx, dstHeight                        ;; reset dstY, which is in ecx
      neg ecx
      jmp check_inner

inner_body:
      ;; srcX = dstX*cosA + dstY*sinA
      mov eax, ebx                              ;; eax <- dstX
      sal eax, 16                               ;; convert dstX to fixed point
      imul cosA
      mov srcX, edx                             ;; save left hand multiplication
      mov eax, ecx                              ;; eax <- dstY
      sal eax, 16                               ;; convert dstY to FXPT
      imul sinA
      add srcX, edx

      ;; srcY = dstY*cosA - disX*sinA
      mov eax, ecx                              ;; eax <- dstY
      sal eax, 16                               ;; convert to FXPT
      imul cosA
      mov srcY, edx
      mov eax, ebx                              ;; eax <- dstX
      sal eax, 16                               ;; convert to FXPT
      imul sinA
      sub srcY, edx

      ;; srcX >= 0
      cmp srcX, 0
      jl incr_inner

      ;; srcX < dwWidth (not fxpt comparison)
      mov eax, dwWidth
      cmp srcX, eax
      jge incr_inner

      ;; srcY >= 0
      cmp srcY, 0
      jl incr_inner

      ;; srcY < dwHeight (not fxpt comparison)
      mov eax, dwHeight
      cmp srcY, eax
      jge incr_inner

      ;; (xcenter + dstX - shiftX) >= 0
      mov eax, xcenter
      add eax, ebx                              ;; dstX is added into the sum
      sub eax, shiftX
      cmp eax, 0
      jl incr_inner
      ;; (xcenter+dstX​-shiftX) < 640
      cmp eax, SCREEN_WIDTH
      jge incr_inner
      mov offset_x, eax                         ;; save to use in transparency check

      ;; (ycenter + dstY - shiftY) >= 0
      mov eax, ycenter
      add eax, ecx                              ;; dstY is added in
      sub eax, shiftY
      cmp eax, 0
      jl incr_inner
      ;; (ycenter + dstY - shiftY) < 480
      cmp eax, SCREEN_HEIGHT
      jge incr_inner
      mov offset_y, eax                         ;; save to use in transparency check

      ;; make sure pixel isn't transparent
      ;; (y*dwWidth) + x should give idx into lpBytes
      mov eax, srcY
      imul dwWidth
      add eax, srcX
      add eax, (EECS205BITMAP PTR[esi]).lpBytes ;; start of colors in bitmap
      mov al, BYTE PTR [eax]                    ;; color is byte
      cmp al, (EECS205BITMAP PTR[esi]).bTransparent
      je incr_inner
      movzx eax, al
      INVOKE DrawPixel, offset_x, offset_y, eax

incr_inner:
      add ecx, 1
check_inner:
      cmp ecx, dstHeight
      jl inner_body
      add ebx, 1                                ;; increment outer

check_outer:
      cmp ebx, dstWidth
      jl outer_body

      ret
RotateBlit ENDP


END