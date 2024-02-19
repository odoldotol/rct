; 헤트로닉스 조이스틱 PROGRAM

SYNC_data:

; I/O_X1Y1_ ADDRESS
	mov	IO_PORT,#01110111b		;YE8(U01)/LEFT_RIGHT

	mov	r5,#1
	lcall	delay2
	mov	a,Read_Port
	cpl	a

;--HT_TRANS					;LSB 4bit
	cjne	a,#00010000b,ht11	;L
	mov	a,#00000010b
	sjmp	ht11go
ht11:
	cjne	a,#00010010b,ht12
	mov	a,#00000110b
	sjmp	ht11go
ht12:
	cjne	a,#00010110b,ht13
	mov	a,#00001110b
	sjmp	ht11go

ht13:	cjne	a,#00010111b,ht14
	mov	a,#00001010b
	sjmp	ht11go

ht14:
	cjne	a,#00001000b,ht15	;R
	mov	a,#00000001b
	sjmp	ht11go

ht15:
	cjne	a,#00001010b,ht16
	mov	a,#00000101b
	sjmp	ht11go

ht16:
	cjne	a,#00001110b,ht17
	mov	a,#00001101b
	sjmp	ht11go

ht17:
	cjne	a,#00001111b,ht18
	mov	a,#00001001b
	sjmp	ht11go

ht18:
	mov	a,#00h

ht11go:
	mov	r1,a

	mov	IO_PORT,#01111111b
;--------------------------------------
;	jz	jl_off				;JOYSTICK LED ON/OFF
;	clr	JL_LED
;--------------------------------------
; jl_off:

	mov	xy_pstv_count,x1_pstv_buffer
	mov	xy_ngtv_count,x1_ngtv_buffer

 	lcall	opto_joystick
	mov	x1_data,r1

	mov	x1_pstv_buffer,xy_pstv_count
	mov	x1_ngtv_buffer,xy_ngtv_count

	cjne	r1,#010h,check_x1
	clr	xx1_nondata
	ajmp	check_a
check_x1:
	setb	xx1_nondata

check_a:
	mov	a,#00000001b		 	;8bit  start bits
	mov	r0,#8
	lcall	send_bits

;--------------------------------------		;JOY NOTCH IND
	mov	a,JOY_NOTCH
	jz	x1_zero
	jnb	JL_MARK,x1_dec
	mov	JL_NOTCH,JOY_NOTCH
	clr	JL_MARK
x1_dec:
	djnz	JL_NOTCH,x1_zero
	clr	JL_LED				;LED ON
	setb	JL_MARK
;-------------------------------------
x1_zero:
	 
; I/O_X1Y1_ ADDRESS
	mov	IO_PORT,#01110111b		:TE8

	mov	r5,#1
	lcall	delay2
	mov	a,Read_Port
	cpl	a

;--HT_TRANS					;MSB 4bit
	cjne	a,#00100000b,ht21	;F
	mov	a,#00010000b
	sjmp	ht22go
ht21:
	cjne	a,#00100010b,ht22
	mov	a,#01010000b
	sjmp	ht22go
ht22:
	cjne	a,#00100110b,ht23
	mov	a,#11010110b
	sjmp	ht22go

ht23:	cjne	a,#00100111b,ht24
	mov	a,#10010000b
	sjmp	ht22go

ht24:
	cjne	a,#01000000b,ht25	;B
	mov	a,#00100000b
	sjmp	ht22go

ht25:
	cjne	a,#01000010b,ht26
	mov	a,#01100000b
	sjmp	ht22go

ht26:
	cjne	a,#01000110b,ht27
	mov	a,#11100000b
	sjmp	ht22go

ht27:
	cjne	a,#01000111b,ht28
	mov	a,#10100000b
	sjmp	ht22go

ht28:
	mov	a,#00h

ht22go:

;	anl	a,#11110000b
	swap	a
	mov	r1,a

	mov	IO_PORT,#01111111b

	mov	xy_pstv_count,y1_pstv_buffer
	mov	xy_ngtv_count,y1_ngtv_buffer

	lcall	opto_joystick
	mov	y1_data,r1

	mov	y1_pstv_buffer,xy_pstv_count
	mov	y1_ngtv_buffer,xy_ngtv_count

	cjne	r1,#010h,check_y1
	clr	yy1_nondata
	ajmp	check_b
check_y1:
	setb	yy1_nondata

check_b:
	mov	a,#00000000b			;8bit
	mov	r0,#8
	lcall	send_bits

;--------------------------------------		;JOY NOTCH IND
	mov	a,JOY_NOTCH
	jz	y1_zero
	jnb	JL_MARK,y1_dec
	mov	JL_NOTCH,JOY_NOTCH
	clr	JL_MARK
y1_dec:
	djnz	JL_NOTCH,y1_zero
	clr	JL_LED				;LED ON
	setb	JL_MARK
;-------------------------------------
y1_zero:

; I/O_x2y2_ ADDRESS
	mov	IO_PORT,#01111000b		;YE9(U02) AU/AD

	mov	r5,#1
	lcall	delay2
	mov	a,Read_Port
	cpl	a


;--HT_TRANS					;LSB 4bit
	cjne	a,#00001000b,ht31	;AU
	mov	a,#00000001b
	sjmp	ht33go
ht31:
	cjne	a,#00011000b,ht32
	mov	a,#00000101b
	sjmp	ht33go
ht32:
	cjne	a,#00111000b,ht33
	mov	a,#00001101b
	sjmp	ht33go

ht33:	cjne	a,#01111000b,ht34
	mov	a,#00001001b
	sjmp	ht33go

ht34:
	cjne	a,#00000100b,ht35	;AD
	mov	a,#00000010b
	sjmp	ht33go

ht35:
	cjne	a,#00010100b,ht36
	mov	a,#00000110b
	sjmp	ht33go

ht36:
	cjne	a,#00110100b,ht37
	mov	a,#00001110b
	sjmp	ht33go

ht37:
	cjne	a,#01110100b,ht38
	mov	a,#00001010b
	sjmp	ht33go

ht38:
	mov	a,#00h

ht33go:
	mov	r1,a

	mov	IO_PORT,#01111111b
;--------------------------------------
;	jz	jr_off				;JOYSTICK LED ON/OFF
;	clr	JR_LED
;--------------------------------------
; jr_off:

	mov	xy_pstv_count,x2_pstv_buffer
	mov	xy_ngtv_count,x2_ngtv_buffer

	lcall	opto_joystick
	mov	x2_data,r1

	mov	x2_pstv_buffer,xy_pstv_count
	mov	x2_ngtv_buffer,xy_ngtv_count

	cjne	r1,#010h,check_x2
	clr	xx2_nondata
	ajmp	check_c
check_x2:
	setb	xx2_nondata

check_c:
	mov	a,#00000000b			;8bit
	mov	r0,#8
	lcall	send_bits

;--------------------------------------		;JOY NOTCH IND
	mov	a,JOY_NOTCH
	jz	x2_zero
	jnb	JR_MARK,x2_dec
	mov	JR_NOTCH,JOY_NOTCH
	clr	JR_MARK
x2_dec:
	djnz	JR_NOTCH,x2_zero
	clr	JR_LED				;LED ON
	setb	JR_MARK
;-------------------------------------
x2_zero:

; I/O_x2y2_ ADDRESS
	mov	IO_PORT,#01111000b		;YE9(U02) MU/MD

	mov	r5,#2
	lcall	delay2
	mov	a,Read_Port
	cpl	a


;--HT_TRANS					;MSB 4bit
	cjne	a,#00000001b,ht41		;MD
	mov	a,#00100000b
	sjmp	ht44go
ht41:
	cjne	a,#00010001b,ht42
	mov	a,#01100000b
	sjmp	ht44go
ht42:
	cjne	a,#00110001b,ht43
	mov	a,#11100000b
	sjmp	ht44go

ht43:	cjne	a,#01110001b,ht44
	mov	a,#10100000b
	sjmp	ht44go

ht44:
	cjne	a,#00000010b,ht45	;MU
	mov	a,#00010000b
	sjmp	ht44go

ht45:
	cjne	a,#00010010b,ht46
	mov	a,#01010000b
	sjmp	ht44go

ht46:
	cjne	a,#00110010b,ht47
	mov	a,#11010000b
	sjmp	ht44go

ht47:
	cjne	a,#01110010b,ht48
	mov	a,#10010000b
	sjmp	ht44go

ht48:
	mov	a,#00h

ht44go:
;	anl	a,#11110000b
	swap	a
	mov	r1,a

	mov	IO_PORT,#01111111b