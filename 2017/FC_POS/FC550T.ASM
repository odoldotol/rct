  
;TMX 759A (447.2625 -->447.9875 /59CH  / 12.5Khz 
;FILE  NAME :  FC550T.ASM
;CKT   NAME :  POS-5000TPCB	
;The LATEST : 2004 / 04 /02 /
;
;       POLESTAR
;
;       DAE HWA ELECTRONICS CO,.LTD
;
;	E D I T     B Y  : KIM	SEONG  WEON
;	OFFICE TELEPHONE :  (02) 688 - 9310

;*** TX DATA COUNT	--- R0	    send bit count
;*** opto joystick memo --- R1
;*** function joystick	--- R2,R3,R4
;*** TIME DELAY--- R5,R6,R7

;WORD ADDRESS / no1- 101b,/ no2- 110b,/ no3-011b,/( no4-100b,/ no5-001b)
                                                 
;OPTION
;P2.4(Z)=UNIVERSAL  /  P2.5(W)=AUTO TIME DELETE
;P1.7(X)=NO4,NO5    /  P3.3(Y)= OPTION

;------------------------------------------------------------------------
;
;	data definition
;
;------------------------------------------------------------------------
DSEG
Read_Data	data	30h	; Read Data Bank
Address1	data	31h	;
Address2	data	32h

X1_Data 	data	33h	;
X2_Data 	data	34h	;
Y1_Data 	data	35h	;
Y2_Data 	data	36h	;

XY_Data 	data	37h	; notch data memory

;X1_Data_Buf	data	38h
;Y1_Data_Buf	data	39h
;X2_Data_Buf	data	3ah
;Y2_Data_Buf	data	3bh

SIR_count	data	3ch
auto_timer_1	data	3dh
low_p_s_count	data	3eh	; battery low power siren count
Parity_Count	data	3fh

TX_SEND_1	data	40h	;send data memory
TX_SEND_2	data	41h
TX_SEND_3	data	42h
TX_SEND_4	data	43h

JOY_function	data	44h
Power_status	data	45h
auto_timer_0	data	46h

X1_NOTCH_D	data	47h	;notch display memory
Y1_NOTCH_D	data	48h	;	=
X2_NOTCH_D	data	49h	;	=
Y2_NOTCH_D	data	4ah	;	=

xy_pstv_count	data	4bh
xy_ngtv_count	data	4ch

x1_pstv_buffer	data	4dh
x1_ngtv_buffer	data	4eh
y1_pstv_buffer	data	4fh
y1_ngtv_buffer	data	50h
x2_pstv_buffer	data	51h
x2_ngtv_buffer	data	52h
y2_pstv_buffer	data	53h
y2_ngtv_buffer	data	54h

channel_0	data	55h
channel_1	data	56h
CHBUF1		data	57h
CHBUF2		data	58h
ERR_BIT_COUNT	data	59h
SYNC_CNT0	data	5ah
SYNC_CNT1	data	5bh
PATTERN1	data	5ch
PATTERN2	data	5dh
PATTERN3	data	5eh
PATTERN4	data	5fh
BIT_CONT_32	data	60h
PARITY_BYTE	data	61h
channel_base	data	62h		
MCA_DW_L	data	63h
ch_dip_sw	data	64h
SQ_L_CNT	data	65h
JL_NOTCH	data	66h	;JOY LED IND
JR_NOTCH	data	67h	;JOY LED IND
JOY_NOTCH	data	68h	;JOY LED IND

Read_Port	data	080H	; Port 0
IO_PORT		data	0a0h	; port 2

auto_status	data	20h	;(bit address) nondata check

;-- 20h,21h,22h,23h,24h,25h,26h,27h, no ----- 
WORD_FIND	data	24h

ENDS


BSEG
Power_Check	bit	p2.6
modem_st	bit	p3.4
modem_sd	bit	P3.1
modem_rd	bit	p3.0
modem_rt	bit	p3.2		;/INT0
modem_me	bit	p1.3		;RXD LOW

Power_Led	bit	p3.5
JL_LED		bit	p3.6		;JB1(joy left led)
JR_LED		bit	p3.7		;JB2(joy right led)

OPT_W		bit	p2.5		;AUTO TIME DELETE
OPT_X		bit	p1.7		;NO4 NO5
;OPT_Y		bit	p3.3		;option
OPT_Z		bit	p2.4		;UNIVERSAL

; RF module pin description 

rst		bit	p1.0
cps		bit	p1.1
rf_si		bit	p1.2
;vcosw		bit	modem_me		;759A 
pwsw		bit	p1.4		;R/T change
lock_out	bit	p1.5
SQ_OUT		bit	p1.6

;SEND_BIT	bit	00h		;20H rx
READ_BIT	bit	01h		;
PARITY_ERR	bit	02h		

xx1_nondata	bit	03h		;tx
yy1_nondata	bit	04h
xx2_nondata	bit	05h
yy2_nondata	bit	06h
neutralbit	bit	07h

base_ch_no	bit	08h		;21H
JOY_test	bit	09h		; H" joystick test mode
sir_status	bit	0ah
low_p_siren	bit	0bh		; battery low power siren
poweronsiren	bit	0ch
scan_11		bit	0dh
scan_22		bit	0eh
starton_set	bit	0fh
JL_MARK		bit	10h		;JOY LED IND
JR_MARK		bit	11h		;JOY LED IND
EM_STOP		bit	12h

;outfrq_ck	bit	10h		;22h		
;scan_mark	bit	11h		;FRQ SCAN MODE

;22H(10h~~17h) ?
;25H(18h~~1Fh) chanel_dip_switch/bytes

sync_bit	bit	20h	;24h WORD_FIND 
no1_word_bit	bit	21h
mca_word_bit	bit	22h	
;--23h,24h,25h,26h,27h,~ NO-----
;2Fh(78h~~7Fh) neutral test/ 2dh


ENDS


CSEG

NOTCH_Display		MACRO

		mov	Read_Port,a
		mov	r5,#2
		lcall	delay2
		setb	p2.7
		mov	r5,#200 		;400u S  delay time
		lcall	delay2

		clr	p2.7
		mov	Read_Port,#0ffh 	; ??

		ENDM




;*************************
;*    Interrupt Vector
;*************************

	org	0000h
	sjmp	init		; Reset

	org	0003h		; External 0
	ljmp	int_0

	org	000bh		; Timer/Counter 0
	sjmp	init

	org	0013h		; External 1
	sjmp	init

	org	001bh		; Timer/Counter 1
	sjmp	init

	org	0023h		; Serial Port
	sjmp	init

	org	0026h		; Just for debugging
	sjmp	init

;**********************
;*	Initialize	
;**********************


INIT:
	mov	sp,#70h
	mov	psw,#00h
	mov	pcon,#00000000b

INIT_1:
; INIT POWER ON CHECK
	mov	IO_PORT,#01111001b
	mov	r5,#2
	lcall	delay2
	mov	a,Read_Port
	cpl	a
	mov	IO_PORT,#01111111b

	anl	a,#00000010b

	cjne	a,#00000010b,START_TX		;strt on det
	mov	r5,#2
	lcall	delay1
	clr	power_led		; ON
	mov	r5,#2
	lcall	delay1
	setb	power_led		;OFF

	ljmp	INIT_1

;------------------------------------
START_TX:
	clr	p2.7			;374CK
	clr	low_p_siren		;battery low power siren
	clr	joy_test
	clr	poweronsiren
	clr	starton_set
	clr	scan_11
	clr	scan_22
	clr	base_ch_no
	clr	EM_STOP
;	clr	outfrq_ck
;	clr	scan_mark

	setb	JL_MARK			;JOY LED IND	
	setb	JR_MARK			;JOY LED IND
	setb	JL_LED
	setb	JR_LED

	mov	x1_notch_d,#11111111b	;notch data initialize
	mov	x2_notch_d,#11111111b
	mov	y1_notch_d,#11111111b
	mov	y2_notch_d,#11111111b
	mov	Power_status,#4 	; Battery voltage check

	
FUNCTION:
;--------------------------------
; FUNCTION JOYSTICK SELECTION
;--------------------------------
	mov	IO_PORT,#01110010b
	mov	r5,#4
	lcall	delay2
	mov	a,Read_Port
	cpl	a
	anl	a,#11110000b
	swap	a
;---------------------------------
	mov	joy_function,a		;  joystick function selection
;---------------------------------
	mov	IO_PORT,#01111111b

	setb	sir_status		;Auto siren control/init

	mov	auto_timer_0,#00h
	mov	auto_timer_1,#00h

	mov	x1_data,#010h		;zero notch initialize (hex)
	mov	x2_data,#010h		;notch display data table
	mov	y1_data,#010h
	mov	y2_data,#010h

	mov	x1_pstv_buffer,#00h
	mov	x1_ngtv_buffer,#00h
	mov	y1_pstv_buffer,#00h
	mov	y1_ngtv_buffer,#00h
	mov	x2_pstv_buffer,#00h
	mov	x2_ngtv_buffer,#00h
	mov	y2_pstv_buffer,#00h
	mov	y2_ngtv_buffer,#00h

	clr	Power_Led		; Power Ind  LED ON


;---------------------------------------------------------
;  JOYSTICK TEST MODE
;
;initialize joystick start button check to JTM loop again
;initilalize switch ON check to SW_CHECK loop again
;---------------------------------------------------------

JTM:					;start button check
;	jnb	joy_butt_x1y1,JTM	; start button on / off status to
;	jnb	joy_butt_x2y2,JTM	; RF control



;----------------------------------------------------
;TRANSMITTER POWER ON SIREN (time = 0.10 sec * #data)
;----------------------------------------------------
	mov	IO_PORT,#01110000b

	mov	r5,#2
	lcall	delay2			; 2.5 uS delay
	mov	a,Read_Port		; MCA ID Port

	jb	P0.7,SIREN_OFF		; CPU 8 PIN = 0N(L)  SIREN ON
	setb	poweronsiren		; contron on siren disable
	clr	sir_status		;
	mov	sir_count,#20		; (( 0.10 sec * #data ))

	jb	OPT_X,SIREN_OFF		;no4,5=siren time 
	mov	sir_count,#12

SIREN_OFF:
	mov	IO_PORT,#01111111b




;***********************
;   RF MODULE CONTROL
;***********************

	lcall	CH_ID_INPUT
	mov	channel_base,channel_0

scan_set_1:
	mov	a,channel_0
	rl	a
	mov	channel_1,a
	mov	dptr,#CH_DATA_447
	movc	a,@a+dptr
	mov	CHBUF1,a

	mov	a,channel_1
	inc	a
	movc	a,@a+dptr
	mov	CHBUF2,a

;=================================================
;	Reference Frequency Set
;=================================================
	setb	sq_out			;SQ INIT L
	setb	cps			; set complement of CPS high
	clr	rst			; set RST low
	mov	r5,#2			; 4 us delay
	lcall	delay2
	mov	a,#11111111b		;<-----D21
	mov	r0,#8			; 12.5 kHz
	lcall	set_channel_sub
	mov	a,#00010000b
	mov	r0,#8
	lcall	set_channel_sub
	mov	a,#00000100b
	mov	r0,#6			;<---D1, 5+1(NC)
	lcall	set_channel_sub
	mov	r5,#2
	lcall	delay2			; 4 uS delay
	setb	rst
	mov	r5,#2 			;20, 20mS delay
	lcall	delay2

;=======================================
;	TX/RX Frequency Set
;=======================================
	clr	rst			; TX requency setting
	mov	r5,#2			; 4 uS delay
	lcall	delay2
	mov	a,#10100100b		; TX TURN ON
	mov	r0,#8
	lcall	set_channel_sub

	mov	a,CHBUF1		
	mov	r0,#8
	lcall	set_channel_sub

	mov	a,CHBUF2		; Channel setting
	mov	r0,#6			;5+1
	lcall	set_channel_sub

	mov	r5,#2
	lcall	delay2			; 4uS delay
	setb	rst
	mov	r5,#2	 		; 40ms delay
	lcall	delay1
;-RX-------------------------------
	jb	scan_22,TX_DATA_SEND	;2nd Channel data
	setb	pwsw
	clr	modem_me
	ljmp	RECEIVER

;-TX-------------------------------
TX_DATA_S:
	clr	Power_Led		;on
	mov	r5,#2
	lcall	delay1
TX_DATA_SEND:
	clr	pwsw
	setb	power_led		;OFF
	setb	modem_me
;---------------------------------

NEUTRAL_TEST:

; I/O_ X1Y1_ ADDRESS
	mov	IO_PORT,#01110111b
	mov	r5,#2
	lcall	delay2
	mov	a,Read_Port
	anl	a,#00001111b
	mov	x1_data,a		;X1-DATA
	mov	a,Read_Port		; Y1
	anl	a,#11110000b
	swap	a
	mov	IO_PORT,#01111111b
	mov	y1_data,a		;Y1-DATA

; I/O_X2Y2_ ADDRESS
	mov	IO_PORT,#01111000b
	mov	r5,#2
	lcall	delay2
	mov	a,Read_Port
	anl	a,#00001111b
	mov	x2_data,a		;X2-DATA
	mov	a,Read_Port
	anl	a,#11110000b
	swap	a
	mov	IO_PORT,#01111111b
	mov	y2_data,a		;Y2-DATA
	mov	2fh,#0ffh
	mov	a,x1_data
	cjne	a,#0fh,error_x1
error_1:
	mov	a,y1_data
	cjne	a,#0fh,error_y1
error_2:
	mov	a,x2_data
	cjne	a,#0fh,error_x2
error_3:
	mov	a,y2_data
	cjne	a,#0fh,error_y2

	ajmp	neutral

error_x1:
	clr	78h			; 2Fh  0  bit address
	ajmp	error_1
error_y1:
	clr	78h
	ajmp	error_2
error_x2:
	clr	7ch			; 2Fh 4  bit address
	ajmp	error_3
error_y2:
	clr	7ch
Neutral:
	mov	a,02fh			; bit address 2Fh
	cpl	a
;-----------------------------
	jz	Notch_Disp		; Netural  Status  = ( acc zero )
;----------------------------- 
	cpl	a
	mov	read_port,a		; bit address 2Fh
	mov	r5,#2
	lcall	delay2
	
	clr	power_led		; ON
	setb	p2.7			;  1 notch display  ON

;------------------------------------
	mov	r5,#1
	lcall	delay1

	clr	p2.7
	nop
	nop
	mov	read_port,#0ffh
	nop
	nop

	setb	power_led		;OFF
	setb	p2.7			;  1 notch display  OFF

	mov	r5,#2
	lcall	delay1
;-------------------------------------
	clr	p2.7

	ajmp	Neutral_Test

;-------------------------------------
;####  NOTCH DISPPLAY LAMP TEST  ####
;-------------------------------------

Notch_Disp:

;	clr	power_led
;	mov	r4,#9			;loop 9
;	clr	a
;loop_1:
;	mov	Read_Data,a
;	clr	p2.7

;	mov	dptr,#Lamp_Test_Data
;	movc	a,@a+dptr
;	mov	read_port,a
;	mov	r5,#4			;
;	lcall	DELAY2

;	setb	p2.7			; NOTCH LED  ON / OFF

;	mov	r5,#7			;
;	lcall	DELAY1

;	mov	a,Read_Data
;	inc	a
;	djnz	r4,loop_1

;	mov	Read_Port,#0ffh


SYNC_WORD:

;-----------------------------------------------------
; CONTROLL POWER ON /SIREN ( time = 0.10 sec * #data )
;-----------------------------------------------------



	jb	poweronsiren,SIREN_NON	;

; I/O_RFCH_ ADDRESS
	mov	IO_PORT,#01110000b

	mov	r5,#1
	lcall	delay2

	jb	neutralbit,SIREN_NON
	jb	P0.7,SIREN_NON		; P0.7(L) /74HC240 output/  ASIREN ON
	clr	sir_status		; SIREN_STATUS	" L "
	setb	poweronsiren		;action of siren no
;	setb	starton_set
	mov	sir_count,#20		; (( 0.10 sec * #data ))
	jb	OPT_X,SIREN_NON		;no4,5 siren time
	mov	sir_count,#12

SIREN_NON:
	mov	IO_PORT,#01111111b

	mov	auto_status,#00h	; NON DATA CHECK INITIALIZE

	jnb	power_check,Power_L

;	clr	Power_LED

	ajmp	Power_H
Power_L:
	jb	power_check,Power_H	; BATTERY VOLTAGE CHECK

;------------------------------------------------
;	POWER LOW  _  AUTO SIREN
; siren on time { low_p_s_count (0.10sec) } * #data
;------------------------------------------------
	jb	low_p_siren,lowpowersiren
	setb	low_p_siren
	mov	low_p_s_count,#50

lowpowersiren:
	djnz	power_status,led_off
	clr	Power_LED
	mov	power_status,#4 	; OFF TIME  (power_status) * 0.10 sec
	ajmp	Power_H

led_off:
	setb	Power_LED

Power_H:

;---------------------------------------------
SYNC_data:

; I/O_X1Y1_ ADDRESS
	mov	IO_PORT,#01110111b

	mov	r5,#1
	lcall	delay2
	mov	a,Read_Port
	cpl	a
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
	mov	IO_PORT,#01110111b

	mov	r5,#1
	lcall	delay2
	mov	a,Read_Port
	cpl	a
	anl	a,#11110000b
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
	mov	IO_PORT,#01111000b

	mov	r5,#1
	lcall	delay2
	mov	a,Read_Port
	cpl	a
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
	mov	IO_PORT,#01111000b

	mov	r5,#2
	lcall	delay2
	mov	a,Read_Port
	cpl	a
	anl	a,#11110000b
	swap	a
	mov	r1,a

	mov	IO_PORT,#01111111b

	mov	xy_pstv_count,y2_pstv_buffer
	mov	xy_ngtv_count,y2_ngtv_buffer

	lcall	opto_joystick
	mov	y2_data,r1

	mov	y2_pstv_buffer,xy_pstv_count
	mov	y2_ngtv_buffer,xy_ngtv_count

	cjne	r1,#010h,check_y2
	clr	yy2_nondata
	ajmp	check_d
check_y2:
	setb	yy2_nondata

check_d:
	mov	a,#11000000b		;8bit	 stop bits
	mov	r0,#8
	lcall	send_bits

;--------------------------------------		;JOY NOTCH IND
	mov	a,JOY_NOTCH
	jz	y2_zero
	jnb	JR_MARK,y2_dec
	mov	JR_NOTCH,JOY_NOTCH
	clr	JR_MARK
y2_dec:
	djnz	JR_NOTCH,y2_zero
	clr	JR_LED				;LED ON
	setb	JR_MARK
;-------------------------------------
y2_zero:

;---JOYSTICK NO NEUTRAL NO POWER ON ----------

	mov	a,auto_status		;JOY DATA CHECK
	jnz	powerclear
	clr	neutralbit		;0=power on
	ajmp	pon_clear
powerclear:
	setb	neutralbit		;1=no power on
pon_clear:

;------------------------------------
;UNIVERSAL TYPE SELECTION (JB1)
;	jnb	OPT_Z,no1_data_word
;------------------------------------
x1_ck:
	mov	a,x1_data
	cjne	a,#010h,y1_ck
	ajmp	x2_ck
y1_ck:
	mov	a,y1_data
	cjne	a,#010h,x1y1_close
	ajmp	x2_ck
x1y1_close:
	mov	x1_data,#010h
	mov	y1_data,#010h
x2_ck:
	mov	a,x2_data
	cjne	a,#010h,y2_ck
	ajmp	no1_data_word
y2_ck:
	mov	a,y2_data
	cjne	a,#010h,x2y2_close
	ajmp	no1_data_word
x2y2_close:
	mov	x2_data,#010h
	mov	y2_data,#010h

;--------------------------------------------------
; NO1-101b/ NO2-011b/ NO3-110b/ N04-100b/ NO5-001b
;--------------------------------------------------

NO1_DATA_WORD:
;------------------------------------
;	setb	JL_LED				;JOY LED OFF
;	setb	JR_LED				;JOY LED OFF
;------------------------------------
	mov	Parity_Count,#00h
	mov	a,#000000101b		; NO1 ADD  " 101 "
	mov	TX_SEND_1,a
	mov	r0,#3
	lcall	send_bits

	lcall	M_ADDRESS_INPUT

	mov	a,Address1
	rr	a
	rr	a
	rr	a
	mov	TX_SEND_2,a
	mov	r0,#5
	lcall	send_bits

	mov	a,Address2
	mov	TX_SEND_3,a
	mov	r0,#7
	lcall	send_bits

	lcall	Parity_Bit

;!@!@!@! ---NO1 TX DATA REVERSED ---!@!@!@!

	mov	Parity_Count,#01h
	mov	a,TX_SEND_1
	cpl	a
	mov	r0,#3				; 3 Bit
	lcall	send_bits

	mov	a,TX_SEND_2
	cpl	a
	mov	r0,#5				; 8 Bit
	lcall	send_bits

	mov	a,TX_SEND_3
	cpl	a
	mov	r0,#7				; 4 Bit
	lcall	send_bits

	lcall	Parity_Bit			; 1 Bit

;---------------------MCA ID----------------------------
;P, 7, 6, 5, 4, 3, 2, 1, dip7, 1, 1,sc2, sc1, (010)   16bit send
;-------------------------------------------------------

MCA_DATA_WORD:			
	jnb	power_check,MCA_DW	
	clr	power_led		;init led short on

MCA_DW:
	mov	Parity_Count,#00h
	mov	a,MCA_DW_L		; ADD  "?11??(010)b "
	mov	TX_SEND_1,a
	mov	r0,#8			; 8 Bit
	lcall	send_bits

	mov	a,channel_0
	mov	TX_SEND_2,a
	mov	r0,#7			; 7 bit
	lcall	send_bits
	
	lcall	Parity_Bit		; 1 Bit

;------------------------------------
	setb	JL_LED				;LEFT JOY LED OFF
;------------------------------------

;!@!@!@! ---MCA TX DATA REVERSED ---!@!@!@!

	mov	Parity_Count,#01h
	mov	a,TX_SEND_1
	cpl	a
	mov	r0,#8				; 3 Bit
	lcall	send_bits

	mov	a,TX_SEND_2
	cpl	a
	mov	r0,#7				; 5 Bit
	lcall	send_bits

	lcall	Parity_Bit			; 1 Bit

;------------------------------------
	setb	JR_LED				;RIGHT JOY LED OFF
;------------------------------------

;----------------------------------------------------------
NO2_DATA_WORD:

	mov	tx_send_2,#00000000b
	mov	tx_send_3,#00000000b

	mov	parity_count,#00h
	mov	a,#00000110b			; ADD NO2 " 0 1 1 "
	mov	r0,#3				; NO2 ADD  3 BIT
	mov	TX_SEND_1,a			; ~~~~~~~~~~~~~~
	lcall	send_bits



NO2_Y1:

;----------------------------------------------------------------------
; FUNCTION  JOYSTCK  XY
;~~~~~~~~~~~~~~~~~~~~~~~	      / ex)	 ????0000
; address    left	     right	   Y1		   Y2
;	     Y1	X1	     Y2	X2	    |		    |
; ????0110 - X1 Y1	     X2 Y2	    |		    |
; ?????001 - Y1 X1	     X2 Y2     <---------> X1  <---------> X2
; ?????010 - X1 X2	     Y1 Y2	    |		    |
; ?????011 - Y1 X2	     X1 Y2	    |		    |
; ?????100 - X1 Y2	     X2 Y1
; ?????101 - Y1 Y2	     X1 X2	  left		  right
; ****0000 - TL TS	     MH AH		MR mode 
; ????0111 - X2 Y2	     X1 Y1
; ????1000 - Y2 X1	     Y1 X2
; ????1001 - Y2 X2	     Y1 X1
; ????1010 - X2 Y2	     Y1 X1
; ????1011 - Y2 X2	     X1 Y1
; ****1100 - TS TL	     MH AH      MR from POS mode T/L,T/S CHANGE
; ****1101 - MH TS           AH TL
;------------------------------------------------------------------------
	mov	r2,joy_function
	cjne	r2,#00000000b,function_y1_0		; X1
;	jb	Joy_Butt_x1y1,y1_butt_off
	jnb	sir_status,y1_butt_off
	mov	r3,y1_data
	mov	y1_data,x1_data 			; data exchange
	lcall	x1_display
	ajmp	no2_y1_data

function_y1_0:
	cjne	r2,#00000001b,function_y1_1		; X1
;	jb	Joy_Butt_x1y1,y1_butt_off
	jnb	sir_status,y1_butt_off
	mov	r3,y1_data
	mov	y1_data,x1_data 			; data exchange
	lcall	x1_display
	ajmp	no2_y1_data

function_y1_1:
	cjne	r2,#00000010b,function_y1_2		; X2
;	jb	Joy_Butt_x2y2,y1_butt_off
	jnb	sir_status,y1_butt_off
	mov	r3,y1_data
	mov	y1_data,x2_data 			; data exchange
	lcall	x2_display
	ajmp	no2_y1_data

function_y1_2:
	cjne	r2,#00000011b,function_y1_3		; X2
;	jb	Joy_Butt_x2y2,y1_butt_off
	jnb	sir_status,y1_butt_off
	mov	r3,y1_data
	mov	y1_data,x2_data 			; data exchange
	lcall	x2_display
	ajmp	no2_y1_data

function_y1_3:
	cjne	r2,#00000100b,function_y1_4		; Y2
;	jb	Joy_Butt_x2y2,y1_butt_off
	jnb	sir_status,y1_butt_off
	mov	r3,y1_data
	mov	y1_data,y2_data 			; data exchange
	lcall	y2_display
	ajmp	no2_y1_data

function_y1_4:
	cjne	r2,#00000101b,function_y1_5		; Y2
;	jb	Joy_Butt_x2y2,y1_butt_off
	jnb	sir_status,y1_butt_off
	mov	r3,y1_data
	mov	y1_data,y2_data 			; data exchange
	lcall	y2_display
	ajmp	no2_y1_data

;-------------------------------------------------------------
y1_butt_off:
	ljmp	no2_y1_off_data
;--------------------------------------------------------------
function_y1_5:
	cjne	r2,#00000110b,function_y1_6		; Y1
;	jb	Joy_Butt_x1y1,y1_butt_off
	jnb	sir_status,y1_butt_off
	mov	r3,y1_data
	lcall	y1_display
	ajmp	no2_y1_data

function_y1_6:
	cjne	r2,#00000111b,function_y1_7		; Y2
;	jb	Joy_Butt_x2y2,y1_butt_off
	jnb	sir_status,y1_butt_off
	mov	r3,y1_data
	mov	y1_data,y2_data 			; data exchange
	lcall	y2_display
	ajmp	no2_y1_data

function_y1_7:
	cjne	r2,#00001000b,function_y1_8		; X1
;	jb	Joy_Butt_x2y2,y1_butt_off
	jnb	sir_status,y1_butt_off
	mov	r3,y1_data
	mov	y1_data,x1_data	 			; data exchange
	lcall	x1_display
	ajmp	no2_y1_data

function_y1_8:
	cjne	r2,#00001001b,function_y1_9		; X2
;	jb	Joy_Butt_x2y2,y1_butt_off
	jnb	sir_status,y1_butt_off
	mov	r3,y1_data
	mov	y1_data,x2_data 			; data exchange
	lcall	x2_display
	ajmp	no2_y1_data


function_y1_9:
	cjne	r2,#00001010b,function_y1_10		; Y2
;	jb	Joy_Butt_x2y2,y1_butt_off
	jnb	sir_status,y1_butt_off
	mov	r3,y1_data
	mov	y1_data,y2_data 			; data exchange
	lcall	y2_display
	ajmp	no2_y1_data

function_y1_10:
	cjne	r2,#00001011b,function_y1_11		; X2
;	jb	Joy_Butt_x2y2,y1_butt_off
	jnb	sir_status,y1_butt_off
	mov	r3,y1_data
	mov	y1_data,x2_data 			; data exchange
	lcall	x2_display
	ajmp	no2_y1_data

function_y1_11:
	cjne	r2,#00001100b,function_y1_12		; Y1
;	jb	Joy_Butt_x1y1,y1_butt_off
	jnb	sir_status,y1_butt_off
	mov	r3,y1_data
	lcall	y1_display
	ajmp	no2_y1_data

function_y1_12:
	cjne	r2,#00001101b,function_y1_13		; X1
;	jb	Joy_Butt_x2y2,y1_butt_off
	jnb	sir_status,y1_butt_off
	mov	r3,y1_data
	mov	y1_data,x1_data 			; data exchange
	lcall	x1_display
	ajmp	no2_y1_data

function_y1_13:
	ajmp	sync_word				; function error


;-----------------------------------------------------------------------

NO2_Y1_DATA:					;send data
	
	mov	a,y1_data
	mov	dptr,#Notch_4500_x1y1
	movc	a,@a+dptr

	mov	TX_SEND_2,a

	mov	r0,#4				; NO2 X1 DATA  4 BIT
	lcall	send_bits			; ~~~~~~~~~~~~~~~~~~

;------------------------------
	mov	y1_data,r3			; reduction y1_data
;------------------------------

;------------------------------
; power on siren of non data   ( sir_status    = L )
;------------------------------

NO2_X1:

;------------------------------------------------
	mov	r2,joy_function
	cjne	r2,#00000000b,function_x1_0		; Y1
;	jb	Joy_Butt_x1y1,x1_butt_off
	jnb	sir_status,x1_butt_off
	mov	r4,x1_data
	mov	x1_data,y1_data 			; data exchange
	lcall	y1_display
	ajmp	no2_x1_data

function_x1_0:
	cjne	r2,#00000001b,function_x1_1		; Y1
;	jb	Joy_Butt_x1y1,x1_butt_off
	jnb	sir_status,x1_butt_off
	mov	r4,x1_data
	mov	x1_data,y1_data 			; data exchange
	lcall	y1_display
	ajmp	no2_x1_data

function_x1_1:
	cjne	r2,#00000010b,function_x1_2		; X1
;	jb	Joy_Butt_x1y1,x1_butt_off
	jnb	sir_status,x1_butt_off
	mov	r4,x1_data
	lcall	x1_display
	ajmp	no2_x1_data

function_x1_2:
	cjne	r2,#00000011b,function_x1_3		; Y1
;	jb	Joy_Butt_x1y1,x1_butt_off
	jnb	sir_status,x1_butt_off
	mov	r4,x1_data
	mov	x1_data,y1_data 			; data exchange
	lcall	y1_display
	ajmp	no2_x1_data

function_x1_3:
	cjne	r2,#00000100b,function_x1_4		; X1
;	jb	Joy_Butt_x1y1,x1_butt_off
	jnb	sir_status,x1_butt_off
	mov	r4,x1_data
	lcall	x1_display
	ajmp	no2_x1_data

function_x1_4:
	cjne	r2,#00000101b,function_x1_5		; Y1
;	jb	Joy_Butt_x1y1,x1_butt_off
	jnb	sir_status,x1_butt_off
	mov	r4,x1_data
	mov	x1_data,y1_data 			; data exchange
	lcall	y1_display
	ajmp	no2_x1_data

;-------------------------------------------
x1_butt_off:
	ljmp	no2_x1_off_data
;-------------------------------------------

function_x1_5:
	cjne	r2,#00000110b,function_x1_6		; X1
;	jb	Joy_Butt_x1y1,x1_butt_off
	jnb	sir_status,x1_butt_off
	mov	r4,x1_data
	lcall	x1_display
	ajmp	no2_x1_data


function_x1_6:
	cjne	r2,#00000111b,function_x1_7		; X2
;	jb	Joy_Butt_x2y2,x1_butt_off
	jnb	sir_status,x1_butt_off
	mov	r4,x1_data
	mov	x1_data,x2_data 			; data exchange
	lcall	x2_display
	ajmp	no2_x1_data

function_x1_7:
	cjne	r2,#00001000b,function_x1_8		; Y2
;	jb	Joy_Butt_x1y1,x1_butt_off
	jnb	sir_status,x1_butt_off
	mov	r4,x1_data
	mov	x1_data,y2_data
	lcall	y2_display
	ajmp	no2_x1_data


function_x1_8:
	cjne	r2,#00001001b,function_x1_9		; Y2
;	jb	Joy_Butt_x1y1,x1_butt_off
	jnb	sir_status,x1_butt_off
	mov	r4,x1_data
	mov	x1_data,y2_data
	lcall	y2_display
	ajmp	no2_x1_data

function_x1_9:
	cjne	r2,#00001010b,function_x1_10		; X2
;	jb	Joy_Butt_x1y1,x1_butt_off
	jnb	sir_status,x1_butt_off
	mov	r4,x1_data
	mov	x1_data,x2_data
	lcall	x2_display
	ajmp	no2_x1_data

function_x1_10:
	cjne	r2,#00001011b,function_x1_11		; Y2
;	jb	Joy_Butt_x1y1,x1_butt_off
	jnb	sir_status,x1_butt_off
	mov	r4,x1_data
	mov	x1_data,y2_data
	lcall	y2_display
	ajmp	no2_x1_data

function_x1_11:
	cjne	r2,#00001100b,function_x1_12		; X1
;	jb	Joy_Butt_x1y1,x1_butt_off
	jnb	sir_status,x1_butt_off
	mov	r4,x1_data
	lcall	x1_display
	ajmp	no2_x1_data

function_x1_12:
	cjne	r2,#00001101b,function_x1_13		; X2
;	jb	Joy_Butt_x1y1,x1_butt_off
	jnb	sir_status,x1_butt_off
	mov	r4,x1_data
	mov	x1_data,x2_data
	lcall	x2_display
	ajmp	no2_x1_data

function_x1_13:
	ljmp	sync_word				; function error

;----------------------------------------------

NO2_X1_DATA:					; send data
	
	mov	a,x1_data
	mov	dptr,#Notch_4500_x1y1
	movc	a,@a+dptr

	mov	TX_SEND_3,a

	mov	r0,#4				; NO2 X1 DATA  4 BIT
	lcall	send_bits			; ~~~~~~~~~~~~~~~~~~

;-----------------------------------------------------------------------
	mov	x1_data,r4			; reduction x1_data
;-----------------------------------------------------------------------
	mov	IO_PORT,#01111001b		;no2 button 4bit input
	mov	r5,#2
	lcall	delay2
	mov	a,Read_Port
	cpl	a
	mov	IO_PORT,#01111111b

	anl	a,#00001111b
	mov	r5,a
;-------------------------------------
;  power on/off bit  0011b det
;  0011b =>  0001b (only power off send)
;-------------------------------------
	anl  	a,#00000011b			;on/off  mark
	cjne	a,#00000011b,jmp_one
	mov	a,r5
	anl	a,#00001101b			;power on bit clear
	mov	r5,a
	setb	EM_STOP
	ajmp	jmp_start
;--------------------------------------
jmp_one:
	cjne	a,#00000001b,aa_jmp		;on=>init, off=>send
	clr	EM_STOP
	ajmp	jmp_start
aa_jmp:
	jnb	EM_STOP,jmp_start
	ljmp 	init				;start init
;--------------------------------------
jmp_start:
	mov	a,r5
	anl	a,#00001101b			;power on bit clear
	mov	TX_SEND_4,a
	mov	a,r5				;on off det
	anl	a,#00000011b


	jb	starton_set,start_off
	jb	neutralbit,start_off

	cjne	a,#00000010b,start_off		;strt on det
	setb	starton_set
	ajmp	start_1

start_off:
	cjne	a,#00000001b,start_1		;strt off det	
	clr	starton_set
	nop
	
start_1:	
	jnb	starton_set,start_2
	mov	a,TX_SEND_4
	orl	a,#00000010b			;1=control power on
	ajmp	start_send

start_2:
	mov	a,TX_SEND_4

start_send:
;-------------------------------
;     LOW POWER  AUTO SIREN     
;-------------------------------

	jnb	low_p_siren,low_siren_11

	mov	r5,low_p_s_count
	cjne	r5,#00h,A_siren_11
	sjmp	SIR_OFF_on

A_siren_11:
	djnz	low_p_s_count,SIR_ON_on
	sjmp	SIR_OFF_on

low_siren_11:
	jnb	sir_status,SIREN_ON_on		;from joystick ON
	sjmp	sir_OFF_on

SIREN_ON_on:
	djnz	sir_count,SIR_ON_on
;	setb	sir_status
;	setb	poweronsiren

SIR_ON_on:
	orl	a,#00000100b

SIR_OFF_on:
;	jnb	neutralbit,PONJMP		
;	anl	a,#11111101b			;1=p_on X

;PONJMP:
	mov	TX_SEND_4,a
	mov	r0,#4
	lcall	send_bits

	lcall	parity_bit


;------------------------------------
;	   NO2 TX DATA REVERSED
;------------------------------------

NO2_REVERSED:
	mov	Parity_Count,#01h
	mov	a,TX_SEND_1
	cpl	a
	mov	r0,#3
	lcall	send_bits

	mov	a,TX_SEND_2
	cpl	a
	mov	r0,#4
	lcall	send_bits

	mov	a,TX_SEND_3
	cpl	a
	mov	r0,#4
	lcall	send_bits


	mov	a,TX_SEND_4
	cpl	a
	mov	r0,#4
	lcall	send_bits

	lcall	Parity_Bit

	ljmp   	NO3_DATA_WORD
;-----------------------------------------------------
; power on siren to display off and output data delete
;-----------------------------------------------------
NO2_Y1_OFF_DATA:			;notch display off

	cjne	r2,#00000000b,y1_disp_a
	mov	x1_notch_d,#0ffh	; 
	ljmp	y1_disp_end

y1_disp_a:
	cjne	r2,#00000001b,y1_disp_b
	mov	x1_notch_d,#0ffh
	ljmp	y1_disp_end

y1_disp_b:
	cjne	r2,#00000010b,y1_disp_c
	mov	x2_notch_d,#0ffh
	ljmp	y1_disp_end

y1_disp_c:
	cjne	r2,#00000011b,y1_disp_d
	mov	x2_notch_d,#0ffh
	ljmp	y1_disp_end

y1_disp_d:
	cjne	r2,#00000100b,y1_disp_e
	mov	y2_notch_d,#0ffh
	ljmp	y1_disp_end

y1_disp_e:
	cjne	r2,#00000101b,y1_disp_f
	mov	y2_notch_d,#0ffh
	ajmp	y1_disp_end

y1_disp_f:
	cjne	r2,#00000110b,y1_disp_g
	mov	y1_notch_d,#0ffh
	ajmp	y1_disp_end

y1_disp_g:
	cjne	r2,#00000111b,y1_disp_h
	mov	y2_notch_d,#0ffh
	ajmp	y1_disp_end

y1_disp_h:
	cjne	r2,#00001000b,y1_disp_i
	mov	x1_notch_d,#0ffh
	ajmp	y1_disp_end

y1_disp_i:
	cjne	r2,#00001001b,y1_disp_j
	mov	x2_notch_d,#0ffh
	ajmp	y1_disp_end

y1_disp_j:
	cjne	r2,#00001010b,y1_disp_k
	mov	y2_notch_d,#0ffh
	ajmp	y1_disp_end

y1_disp_k:
	cjne	r2,#00001011b,y1_disp_l
	mov	x2_notch_d,#0ffh
	ajmp	y1_disp_end

y1_disp_l:
	cjne	r2,#00001100b,y1_disp_m
	mov	y1_notch_d,#0ffh	; START BUTTON OFF DISPLAY
	ljmp	y1_disp_end

y1_disp_m:
	cjne	r2,#00001101b,y1_disp_n
	mov	x1_notch_d,#0ffh	; START BUTTON OFF DISPLAY
	ljmp	y1_disp_end

y1_disp_n:
	ljmp	sync_word			; error

;--------------------------------------------------------------------------
y1_disp_end:
	mov	y1_data,#010h
	ljmp	no2_y1_data

;-----------------------------------------------------------------------

NO2_X1_OFF_DATA:

	cjne	r2,#00000000b,x1_disp_a
	mov	y1_notch_d,#0ffh	;     X1 JOYSTICK
	ljmp	x1_disp_end

x1_disp_a:
	cjne	r2,#00000001b,x1_disp_b
	mov	y1_notch_d,#0ffh
	ljmp	x1_disp_end

x1_disp_b:
	cjne	r2,#00000010b,x1_disp_c
	mov	x1_notch_d,#0ffh
	ljmp	x1_disp_end

x1_disp_c:
	cjne	r2,#00000011b,x1_disp_d
	mov	y1_notch_d,#0ffh
	ljmp	x1_disp_end

x1_disp_d:
	cjne	r2,#00000100b,x1_disp_e
	mov	x1_notch_d,#0ffh
	ljmp	x1_disp_end

x1_disp_e:
	cjne	r2,#00000101b,x1_disp_f
	mov	y1_notch_d,#0ffh
	ajmp	x1_disp_end

x1_disp_f:
	cjne	r2,#00000110b,x1_disp_g
	mov	x1_notch_d,#0ffh
	ajmp	x1_disp_end

x1_disp_g:
	cjne	r2,#00000111b,x1_disp_h
	mov	x2_notch_d,#0ffh
	ajmp	x1_disp_end

x1_disp_h:
	cjne	r2,#00001000b,x1_disp_i
	mov	y2_notch_d,#0ffh
	ajmp	x1_disp_end


x1_disp_i:
	cjne	r2,#00001001b,x1_disp_j
	mov	y2_notch_d,#0ffh
	ajmp	x1_disp_end

x1_disp_j:
	cjne	r2,#00001010b,x1_disp_k
	mov	y2_notch_d,#0ffh
	ajmp	x1_disp_end

x1_disp_k:
	cjne	r2,#00001011b,x1_disp_l
	mov	x2_notch_d,#0ffh
	ajmp	x1_disp_end

x1_disp_l:
	cjne	r2,#00001100b,x1_disp_m
	mov	x1_notch_d,#0ffh	;     X1 JOYSTICK
	ljmp	x1_disp_end

x1_disp_m:
	cjne	r2,#00001101b,x1_disp_n
	mov	x2_notch_d,#0ffh	
	ljmp	x1_disp_end

x1_disp_n:
	ljmp	sync_word			; error

;--------------------------------------------------------------------------
x1_disp_end:
	mov	x1_data,#010h			;zero notch
	ljmp	no2_x1_data

;------------------------------------------------------------------------


NO3_DATA_WORD:

	mov	tx_send_2,#00000000b
	mov	tx_send_3,#00000000b

	mov	parity_count,#00h
	mov	a,#00000011b			; ADD NO3 " 1 1 0 "
	mov	r0,#3				; NO3 ADD  3 BIT
	mov	TX_SEND_1,a			;~~~~~~~~~~~~~~~
	lcall	send_bits

NO3_X2:

;----------------------------------------------------------------------
	mov	r2,joy_function
	cjne	r2,#00000000b,function_x2_0		; Y2
;	jb	Joy_Butt_x2y2,x2_butt_off
	jnb	sir_status,x2_butt_off
	mov	r3,x2_data
	mov	x2_data,y2_data 			; data exchange
	lcall	y2_display
	ljmp	no3_x2_data


function_x2_0:
	cjne	r2,#00000001b,function_x2_1		; X2
;	jb	Joy_Butt_x2y2,x2_butt_off
	jnb	sir_status,x2_butt_off
	mov	r3,x2_data
	lcall	x2_display
	ljmp	no3_x2_data

function_x2_1:
	cjne	r2,#00000010b,function_x2_2		; Y1
;	jb	Joy_Butt_x1y1,x2_butt_off
	jnb	sir_status,x2_butt_off
	mov	r3,x2_data
	mov	x2_data,y1_data 			; data exchange
	lcall	y1_display
	ljmp	no3_x2_data

function_x2_2:
	cjne	r2,#00000011b,function_x2_3		; X1
;	jb	Joy_Butt_x1y1,x2_butt_off
	jnb	sir_status,x2_butt_off
	mov	r3,x2_data
	mov	x2_data,x1_data 			; data exchange
	lcall	x1_display
	ljmp	no3_x2_data

function_x2_3:
	cjne	r2,#00000100b,function_x2_4		; X2
;	jb	Joy_Butt_x2y2,x2_butt_off
	jnb	sir_status,x2_butt_off
	mov	r3,x2_data
	lcall	x2_display
	ljmp	no3_x2_data

function_x2_4:
	cjne	r2,#00000101b,function_x2_5		; X1
;	jb	Joy_Butt_x1y1,x2_butt_off
	jnb	sir_status,x2_butt_off
	mov	r3,x2_data
	mov	x2_data,x1_data 			; data exchange
	lcall	x1_display
	ljmp	no3_x2_data

;---------------------------------------------------------------
x2_butt_off:
	ljmp	no3_x2_off_data
;---------------------------------------------------------------

function_x2_5:
	cjne	r2,#00000110b,function_x2_6		; X2
;	jb	Joy_Butt_x2y2,x2_butt_off
	jnb	sir_status,x2_butt_off
	mov	r3,x2_data
	lcall	x2_display
	ljmp	no3_x2_data


function_x2_6:
	cjne	r2,#00000111b,function_x2_7		; X1
;	jb	Joy_Butt_x1y1,x2_butt_off
	jnb	sir_status,x2_butt_off
	mov	r3,x2_data
	mov	x2_data,x1_data 			; data exchange
	lcall	x1_display
	ljmp	no3_x2_data


function_x2_7:
	cjne	r2,#00001000b,function_x2_8		; Y1
;	jb	Joy_Butt_x1y1,x2_butt_off
	jnb	sir_status,x2_butt_off
	mov	r3,x2_data
	mov	x2_data,y1_data 			; data exchange
	lcall	y1_display
	ljmp	no3_x2_data

function_x2_8:
	cjne	r2,#00001001b,function_x2_9		; Y1
;	jb	Joy_Butt_x1y1,x2_butt_off
	jnb	sir_status,x2_butt_off
	mov	r3,x2_data
	mov	x2_data,y1_data 			; data exchange
	lcall	y1_display
	ljmp	no3_x2_data

function_x2_9:
	cjne	r2,#00001010b,function_x2_10		; Y1
;	jb	Joy_Butt_x1y1,x2_butt_off
	jnb	sir_status,x2_butt_off
	mov	r3,x2_data
	mov	x2_data,y1_data 			; data exchange
	lcall	y1_display
	ljmp	no3_x2_data

function_x2_10:
	cjne	r2,#00001011b,function_x2_11		; X1
;	jb	Joy_Butt_x1y1,x2_butt_off
	jnb	sir_status,x2_butt_off
	mov	r3,x2_data
	mov	x2_data,x1_data 			; data exchange
	lcall	x1_display
	ljmp	no3_x2_data

function_x2_11:
	cjne	r2,#00001100b,function_x2_12		; Y2
;	jb	Joy_Butt_x2y2,x2_butt_off
	jnb	sir_status,x2_butt_off
	mov	r3,x2_data
	mov	x2_data,y2_data 			; data exchange
	lcall	y2_display
	ljmp	no3_x2_data

function_x2_12:
	cjne	r2,#00001101b,function_x2_13		; Y1
;	jb	Joy_Butt_x1y1,x2_butt_off
	jnb	sir_status,x2_butt_off
	mov	r3,x2_data
	mov	x2_data,y1_data 			; data exchange
	lcall	y1_display
	ljmp	no3_x2_data

function_x2_13:
	ljmp	sync_word				; function error

;------------------------------------------


NO3_X2_DATA:					;send data
	
	mov	a,x2_data
	mov	dptr,#Notch_4500_x2y2
	movc	a,@a+dptr

	mov	TX_SEND_2,a

	mov	r0,#4				; NO2 X1 DATA  4 BIT
	lcall	send_bits			; ~~~~~~~~~~~~~~~~~~

;-----------------------------
	mov	x2_data,r3			; reduction x2_data
;-----------------------------

NO3_Y2:

;-------------------------------------------------------
	mov	r2,joy_function
	cjne	r2,#00000000b,function_y2_0		; X2
;	jb	Joy_Butt_x2y2,y2_butt_off
	jnb	sir_status,y2_butt_off
	mov	r4,y2_data
	mov	y2_data,x2_data 			; data exchange
	lcall	x2_display
	ljmp	no3_y2_data

function_y2_0:
	cjne	r2,#00000001b,function_y2_1		; Y2
;	jb	Joy_Butt_x2y2,y2_butt_off
	jnb	sir_status,y2_butt_off
	mov	r4,y2_data
	lcall	y2_display
	ljmp	no3_y2_data

function_y2_1:
	cjne	r2,#00000010b,function_y2_2		; Y2
;	jb	Joy_Butt_x2y2,y2_butt_off
	jnb	sir_status,y2_butt_off
	mov	r4,y2_data
	lcall	y2_display
	ljmp	no3_y2_data

function_y2_2:
	cjne	r2,#00000011b,function_y2_3		; Y2
;	jb	Joy_Butt_x2y2,y2_butt_off
	jnb	sir_status,y2_butt_off
	mov	r4,y2_data
	lcall	y2_display
	ljmp	no3_y2_data

function_y2_3:
	cjne	r2,#00000100b,function_y2_4		; Y1
;	jb	Joy_Butt_x1y1,y2_butt_off
	jnb	sir_status,y2_butt_off
	mov	r4,y2_data
	mov	y2_data,y1_data 			; data exchange
	lcall	y1_display
	ljmp	no3_y2_data

function_y2_4:
	cjne	r2,#00000101b,function_y2_5		; X2
;	jb	Joy_Butt_x2y2,y2_butt_off
	jnb	sir_status,y2_butt_off
	mov	r4,y2_data
	mov	y2_data,x2_data 			; data exchange
	lcall	x2_display
	ljmp	no3_y2_data

;---------------------------------------------------------------------
y2_butt_off:
	ljmp	no3_y2_off_data
;---------------------------------------------------------------------

function_y2_5:
	cjne	r2,#00000110b,function_y2_6		; Y2
;	jb	Joy_Butt_x2y2,y2_butt_off
	jnb	sir_status,y2_butt_off
	mov	r4,y2_data
	lcall	y2_display
	ljmp	no3_y2_data

function_y2_6:
	cjne	r2,#00000111b,function_y2_7		; Y1
;	jb	Joy_Butt_x1y1,y2_butt_off
	jnb	sir_status,y2_butt_off
	mov	r4,y2_data
	mov	y2_data,y1_data 			; data exchange
	lcall	y1_display
	ljmp	no3_y2_data

function_y2_7:
	cjne	r2,#00001000b,function_y2_8		; X2
;	jb	Joy_Butt_x2y2,y2_butt_off
	jnb	sir_status,y2_butt_off
	mov	r4,y2_data
	mov	y2_data,x2_data 			; data exchange
	lcall	x2_display
	ljmp	no3_y2_data


function_y2_8:
	cjne	r2,#00001001b,function_y2_9		; X1
;	jb	Joy_Butt_x2y2,y2_butt_off
	jnb	sir_status,y2_butt_off
	mov	r4,y2_data
	mov	y2_data,x1_data 			; data exchange
	lcall	x1_display
	ljmp	no3_y2_data

function_y2_9:
	cjne	r2,#00001010b,function_y2_10		; X1
;	jb	Joy_Butt_x2y2,y2_butt_off
	jnb	sir_status,y2_butt_off
	mov	r4,y2_data
	mov	y2_data,x1_data 			; data exchange
	lcall	x1_display
	ljmp	no3_y2_data

function_y2_10:
	cjne	r2,#00001011b,function_y2_11		; Y1
;	jb	Joy_Butt_x2y2,y2_butt_off
	jnb	sir_status,y2_butt_off
	mov	r4,y2_data
	mov	y2_data,y1_data 			; data exchange
	lcall	y1_display
	ljmp	no3_y2_data

function_y2_11:
	cjne	r2,#00001100b,function_y2_12		; X2
;	jb	Joy_Butt_x2y2,y2_butt_off
	jnb	sir_status,y2_butt_off
	mov	r4,y2_data
	mov	y2_data,x2_data 			; data exchange
	lcall	x2_display
	ljmp	no3_y2_data

function_y2_12:
	cjne	r2,#00001101b,function_y2_13		; Y2
;	jb	Joy_Butt_x2y2,y2_butt_off
	jnb	sir_status,y2_butt_off
	mov	r4,y2_data
	lcall	y2_display
	ljmp	no3_y2_data

function_y2_13:
	ljmp	sync_word				; function error

;----------------------------------------------

NO3_Y2_DATA:						; send data
	
	mov	a,y2_data
	mov	dptr,#Notch_4500_x2y2
	movc	a,@a+dptr

	mov	TX_SEND_3,a

	mov	r0,#4				; NO3 Y2 DATA  4 BIT
	lcall	send_bits			; ~~~~~~~~~~~~~~~~~~

;----------------------------------
	mov	y2_data,r4			; reduction y2_data
;----------------------------------

	mov	Read_Port,#0ffh

	mov	IO_PORT,#01111001b

	mov	r5,#2
	lcall	delay2
	mov	a,Read_Port

	mov	IO_PORT,#01111111b
	cpl	a
	anl	a,#11110000b
	swap	a
	mov	TX_SEND_4,a
	mov	r0,#4
	lcall	send_bits

	lcall	parity_bit


NO3_REVERSED:

;/////////////////////////////////////////

	mov	a,x1_notch_d	;X1 / Y1 / X2 / Y2 joystick  notch
	anl	a,x2_notch_d	; display data	Logical AND
	anl	a,y1_notch_d
	anl	a,y2_notch_d

	notch_display		;MACRO

;/////////////////////////////////////////

	mov	Parity_Count,#01h
	mov	a,TX_SEND_1
	cpl	a
	mov	r0,#3
	lcall	send_bits

	mov	a,TX_SEND_2
	cpl	a
	mov	r0,#4
	lcall	send_bits

	mov	a,TX_SEND_3
	cpl	a
	mov	r0,#4
	lcall	send_bits


	mov	a,TX_SEND_4
	cpl	a
	mov	r0,#4
	lcall	send_bits

	lcall	Parity_Bit

	ljmp	no4_data_word			;NO4 JMP

;--------------------------------------------------------------------

NO3_X2_OFF_DATA:

	cjne	r2,#00000000b,x2_disp_a
	mov	y2_notch_d,#0ffh		; START BUTTON OFF DISPLAY
	ljmp	x2_disp_end

x2_disp_a:
	cjne	r2,#00000001b,x2_disp_b
	mov	x2_notch_d,#0ffh
	ljmp	x2_disp_end

x2_disp_b:
	cjne	r2,#00000010b,x2_disp_c
	mov	y1_notch_d,#0ffh
	ljmp	x2_disp_end

x2_disp_c:
	cjne	r2,#00000011b,x2_disp_d
	mov	x1_notch_d,#0ffh
	ljmp	x2_disp_end

x2_disp_d:
	cjne	r2,#00000100b,x2_disp_e
	mov	x2_notch_d,#0ffh
	ajmp	x2_disp_end

x2_disp_e:
	cjne	r2,#00000101b,x2_disp_f
	mov	x1_notch_d,#0ffh
	ajmp	x2_disp_end

x2_disp_f:
	cjne	r2,#00000110b,x2_disp_g
	mov	x2_notch_d,#0ffh
	ajmp	x2_disp_end

x2_disp_g:
	cjne	r2,#00000111b,x2_disp_h
	mov	x1_notch_d,#0ffh
	ajmp	x2_disp_end

x2_disp_h:
	cjne	r2,#00001000b,x2_disp_i
	mov	y1_notch_d,#0ffh
	ajmp	x2_disp_end


x2_disp_i:
	cjne	r2,#00001001b,x2_disp_j
	mov	y1_notch_d,#0ffh
	ajmp	x2_disp_end

x2_disp_j:
	cjne	r2,#00001010b,x2_disp_k
	mov	y1_notch_d,#0ffh
	ajmp	x2_disp_end

x2_disp_k:
	cjne	r2,#00001011b,x2_disp_l
	mov	x1_notch_d,#0ffh
	ajmp	x2_disp_end

x2_disp_l:
	cjne	r2,#00001100b,x2_disp_m
	mov	y2_notch_d,#0ffh		; START BUTTON OFF DISPLAY
	ljmp	x2_disp_end

x2_disp_m:
	cjne	r2,#00001101b,x2_disp_n
	mov	y1_notch_d,#0ffh
	ajmp	x2_disp_end

x2_disp_n:
	ljmp	sync_word			; error

;-----------------------------------------------------------------------
x2_disp_end:
	mov	x2_data,#010h
	ljmp	no3_x2_data

;-----------------------------------------------------------------------

NO3_Y2_OFF_DATA:

	cjne	r2,#00000000b,y2_disp_a
	mov	x2_notch_d,#0ffh		;     Y2 JOYSTICK
	ljmp	y2_disp_end

y2_disp_a:
	cjne	r2,#00000001b,y2_disp_b
	mov	y2_notch_d,#0ffh
	ljmp	y2_disp_end

y2_disp_b:
	cjne	r2,#00000010b,y2_disp_c
	mov	y2_notch_d,#0ffh
	ljmp	y2_disp_end

y2_disp_c:
	cjne	r2,#00000011b,y2_disp_d
	mov	y2_notch_d,#0ffh
	ljmp	y2_disp_end

y2_disp_d:
	cjne	r2,#00000100b,y2_disp_e
	mov	y1_notch_d,#0ffh
	ajmp	y2_disp_end

y2_disp_e:
	cjne	r2,#00000101b,y2_disp_f
	mov	x2_notch_d,#0ffh
	ajmp	y2_disp_end

y2_disp_f:
	cjne	r2,#00000110b,y2_disp_g
	mov	x2_notch_d,#0ffh
	ajmp	y2_disp_end

y2_disp_g:
	cjne	r2,#00000111b,y2_disp_h
	mov	y1_notch_d,#0ffh
	ajmp	y2_disp_end

y2_disp_h:
	cjne	r2,#00001000b,y2_disp_i
	mov	x2_notch_d,#0ffh
	ajmp	y2_disp_end


y2_disp_i:
	cjne	r2,#00001001b,y2_disp_j
	mov	x1_notch_d,#0ffh
	ajmp	y2_disp_end

y2_disp_j:
	cjne	r2,#00001010b,y2_disp_k
	mov	x1_notch_d,#0ffh
	ajmp	y2_disp_end

y2_disp_k:
	cjne	r2,#00001011b,y2_disp_l
	mov	y1_notch_d,#0ffh
	ajmp	y2_disp_end

y2_disp_l:
	cjne	r2,#00001100b,y2_disp_m
	mov	x2_notch_d,#0ffh		;     Y2 JOYSTICK
	ljmp	y2_disp_end

y2_disp_m:
	cjne	r2,#00001101b,y2_disp_n
	mov	y2_notch_d,#0ffh		;     Y2 JOYSTICK
	ljmp	y2_disp_end

y2_disp_n:
	ljmp	sync_word			; error

;-----------------------------
y2_disp_end:
	mov	y2_data,#010h
	ljmp	no3_y2_data



;--------------------
;-- NO4/NO5 OPTION ----------------------------
;--------------------

NO4_DATA_WORD:				;NO4 DATA WORD

	jnb	OPT_X,no45_send	
	ljmp	power_down

no45_send:

	mov	Parity_Count,#00h
	mov	a,#00000100b		; NO1 ADD  " 100b "
	mov	TX_SEND_1,a
	mov	r0,#3
	lcall	send_bits

	mov	IO_PORT,#01110011b

	mov	r5,#2
	lcall	delay2
	mov	a,Read_Port
	cpl	a
	mov	TX_SEND_2,a

	mov	IO_PORT,#01111111b

	mov	r0,#8			;YE4/ 8 Bit send
	lcall	send_bits

	mov	IO_PORT,#01110100b

	mov	r5,#2
	lcall	delay2
	mov	a,Read_Port

	mov	IO_PORT,#01111111b


	anl	a,#00001111b
	cpl	a
	mov	TX_SEND_3,a
	mov	r0,#4
	lcall	send_bits		;YE5 LSB 4bit send

	lcall	Parity_Bit

;!@!@!@! ---NO4 TX DATA REVERSED ---!@!@!@!

	mov	Parity_Count,#01h
	mov	a,TX_SEND_1
	cpl	a
	mov	r0,#3				; 3 Bit
	lcall	send_bits

	mov	a,TX_SEND_2
	cpl	a
	mov	r0,#8				; 8 Bit
	lcall	send_bits

	mov	a,TX_SEND_3
	cpl	a
	mov	r0,#4				; 4 Bit
	lcall	send_bits

	lcall	Parity_Bit			; 1 Bit
;------------------------------------------------------------------------
;	ljmp	power_down			;no5  delete
;-------------------------------------------------------------------------


NO5_DATA_WORD:				;NO5 DATA WORD

	mov	Parity_Count,#00h
	mov	a,#00000001b		; NO5 ADD  " 001b "
	mov	TX_SEND_1,a
	mov	r0,#3
	lcall	send_bits

	mov	IO_PORT,#01110101b

	mov	r5,#2
	lcall	delay2
	mov	a,Read_Port
	cpl	a
	mov	TX_SEND_2,a

	mov	IO_PORT,#01111111b

	mov	r0,#8			;YE6/ 8 Bit send
	lcall	send_bits

	mov	IO_PORT,#01110100b

	mov	r5,#2
	lcall	delay2
	mov	a,Read_Port

	mov	IO_PORT,#01111111b


	anl	a,#11110000b
	swap	a
	cpl	a
	mov	TX_SEND_3,a
	mov	r0,#4
	lcall	send_bits		;YE5 MSB 4bit send

	lcall	Parity_Bit

;!@!@!@! ---NO5 TX DATA REVERSED ---!@!@!@!

	mov	Parity_Count,#01h
	mov	a,TX_SEND_1
	cpl	a
	mov	r0,#3				; 3 Bit
	lcall	send_bits

	mov	a,TX_SEND_2
	cpl	a
	mov	r0,#8				; 8 Bit
	lcall	send_bits

	mov	a,TX_SEND_3
	cpl	a
	mov	r0,#4				; 4 Bit
	lcall	send_bits

	lcall	Parity_Bit			; 1 Bit


;------------------------------------------------

POWER_DOWN:
	mov	a,sir_count
	cjne	a,#00h,power_down1
	setb	sir_status

power_down1:
	jb	xx1_nondata,sync_0		; XY- DATA
	jb	yy1_nondata,sync_0		; XY- DATA
	jb	xx2_nondata,sync_0		; XY- DATA
	jb	yy2_nondata,sync_0		; XY- DATA

;----L,S,ON,OFFb  no2 4bit/START ON SW CHECK 			

;	mov	IO_PORT,#01111001b
;	mov	r5,#2
;	lcall	delay2
;	mov	a,Read_Port
;	mov	IO_PORT,#01111111b
;	cpl	a
;	anl	a,#00000010b		;----ON bit check
;	jnz	sync_0

	inc	auto_timer_0
	mov	a,auto_timer_0

	cjne	a,#128,sync_1		;0ffh
	mov	auto_timer_0,#00h
;	jnb	scan_mark,tx_go2		;1=scan mode

;-------------------------
;OUT TRANSMITTER Frq CHECK
;-------------------------
;	jb	outfrq_ck,tx_go2
;	setb	pwsw			;RX
;	clr	modem_me
;	mov	r5,#15
;	lcall	delay1

;	jnb	SQ_OUT,tx_go1

;	clr	scan_11
;	clr	scan_22
;	clr	base_ch_no

;	ljmp	RECEIVER	

;tx_go1:
;	setb	outfrq_ck
;	clr	pwsw			;TX
;	setb	modem_me

;tx_go2:
;---------------------------------------------
;AUTO TX DATA or CRANE CONTROL POWER OFF MODE

;----------auto time delete ------------------
	jnb	OPT_W,sync_0
;---------------------------------------------


	inc	auto_timer_1

	mov	a,auto_timer_1
	cjne	a,#72,sync_1		;#36 * 34sec(128bit)

	setb	power_LED
	mov	auto_timer_0,#00h
	mov	auto_timer_1,#00h

	mov	IO_PORT,#01111001b
	setb	pwsw			;rx mode
	clr	modem_me

POW_SW_H:
	mov	IO_PORT,#01111001b
	mov	r5,#2
	lcall	delay2
	mov	a,Read_Port
	mov	IO_PORT,#01111111b

	cpl	a
	anl	a,#00000010b		;(L,S,P-ON,P-OFF) P-ON check
	jnz	POW_SW_H		;a=1,jump 
	mov	r5,#5			;sw noise
	lcall	delay1

POW_SW_CK:
	mov	IO_PORT,#01111001b
	mov	r5,#2
	lcall	delay2
	mov	a,Read_Port
	mov	IO_PORT,#01111111b

	cpl	a
	anl	a,#00000010b		;(L,S,P-ON,P-OFF) P-ON check
	jz	POW_SW_CK		;a=1,jump 

	ljmp	START_TX

;	clr	p2.7
;	mov	read_port,#01110111b
;	mov	r5,#2
;	acall	delay2
;	setb	p2.7			;power down mode 4 notch led on
;	setb	vcosw
;	setb	pwsw
;	mov	pcon,#00000010b 	; POWER DOWN MODE



;-----------< power down / STOP >--------------------------

sync_0:
;	clr	outfrq_ck					;
	mov	auto_timer_0,#00h
	mov	auto_timer_1,#00h

sync_1:					; non data

	ljmp	SYNC_WORD






;---------------------------------------------------------------------
;    SEND DATA / SHIFT CLOCK
;---------------------------------------------------------------------

send_bits:
send_0:
	jnb	modem_st,send_0
send_1:
	jb	modem_st,send_1
	mov	r5,#20h
	acall	delay2
	rrc	a
	jnc	send_2
	setb	modem_sd
	inc	parity_count
	ajmp	send_3

send_2:
	clr	modem_sd

send_3:
	djnz	r0,send_0
	ret

;-------------------------------------------------------------------

Parity_Bit:

PP_0:
	jnb	modem_st,PP_0
PP_1:
	jb	modem_st,PP_1
	mov	r5,#20h
	acall	delay2
	mov	a,parity_Count
	anl	a,#00000001b
	jz	PP_2
	setb	modem_sd
	ajmp	PP_3
PP_2:
	clr	modem_sd
PP_3:
	ret
;________________________________________________________________________

X1_DISPLAY:					;X1
	mov	a,x1_data
	inc	a				;notch display
	mov	dptr,#Notch_4500_x1y1
	movc	a,@a+dptr
	mov	x1_notch_d,a

	ret

X2_DISPLAY:					;X2
	mov	a,x2_data
	inc	a				;notch display
	mov	dptr,#Notch_4500_x2y2
	movc	a,@a+dptr
	mov	x2_notch_d,a

	ret

Y1_DISPLAY:					;Y1
	mov	a,Y1_data
	inc	a				;notch display
	mov	dptr,#Notch_4500_x1y1
	movc	a,@a+dptr
	mov	y1_notch_d,a

	ret

Y2_DISPLAY:					;Y2
	mov	a,Y2_data
	inc	a				;notch display
	mov	dptr,#Notch_4500_x2y2
	movc	a,@a+dptr
	mov	y2_notch_d,a

	ret

;------------------------------------------------------
;OPTO  JOYSTICK  NOTCH DATA
;------------------------------------------------------

OPTO_JOYSTICK:

	mov	a,r1
	anl	a,#00001111b
	cjne	a,#00000000b,opto_1		;zero
	mov	r1,#010h
	mov	JOY_NOTCH,#00h			;joy notch ind
	clr	a
	cjne	a,xy_pstv_count,aaa
	cjne	a,xy_ngtv_count,bbb
	ret
aaa:
	dec	xy_pstv_count
	cjne	a,xy_ngtv_count,bbb
	ret
bbb:
	dec	xy_ngtv_count
	ret
;-------------------------
opto_1: 					;back 1
	cjne	a,#00000010b,opto_2
	clr	a
	cjne	a,xy_pstv_count,back_1
	mov	r1,#08h
	mov	JOY_NOTCH,#04h			;joy notch ind
	mov	xy_ngtv_count,#03h		;0.3sec
	ret
back_1:
	dec	xy_pstv_count
	mov	r1,#010h
	mov	xy_ngtv_count,#03h		;0.3sec
	ret
;------------------------
opto_2: 					;back 2
	cjne	a,#00000110b,opto_3
	clr	a
	cjne	a,xy_pstv_count,back_2
	mov	r1,#0ah
	mov	JOY_NOTCH,#03h			;joy notch ind
	mov	xy_ngtv_count,#03h		;0.3sec
	ret
back_2:
	dec	xy_pstv_count
	mov	r1,#010h
	mov	xy_ngtv_count,#03h		;0.3sec
	ret
;-------------------------
opto_3: 					;back 3
	cjne	a,#00001110b,opto_4
	clr	a
	cjne	a,xy_pstv_count,back_3
	mov	r1,#0ch
	mov	JOY_NOTCH,#02h			;joy notch ind
	mov	xy_ngtv_count,#04h		;0.4sec
	ret
back_3:
	dec	xy_pstv_count
	mov	r1,#010h
	mov	xy_ngtv_count,#04h		;0.4sec
	ret
;-------------------------
opto_4: 					;back 4
	cjne	a,#00001010b,opto_5
	clr	a
	cjne	a,xy_pstv_count,back_4
	mov	r1,#0eh
	mov	JOY_NOTCH,#01h			;joy notch ind
	mov	xy_ngtv_count,#05h		;0.5sec
	ret
back_4:
	dec	xy_pstv_count
	mov	r1,#010h
	mov	xy_ngtv_count,#05h		;0.5sec
	ret
;-------------------------
opto_5: 					;for 1
	cjne	a,#00000001b,opto_6
	clr	a
	cjne	a,xy_ngtv_count,for_1
	mov	r1,#06h
	mov	JOY_NOTCH,#04h			;joy notch ind
	mov	xy_pstv_count,#03h		;0.3sec
	ret
for_1:
	dec	xy_ngtv_count
	mov	r1,#010h
	mov	xy_pstv_count,#03h		;0.3sec
	ret
;--------------------------
opto_6: 					;for 2
	cjne	a,#00000101b,opto_7
	clr	a
	cjne	a,xy_ngtv_count,for_2
	mov	r1,#04h
	mov	JOY_NOTCH,#03h			;joy notch ind
	mov	xy_pstv_count,#03h		;0.3sec
       	ret
for_2:
	dec	xy_ngtv_count
	mov	r1,#010h
	mov	xy_pstv_count,#03h		;0.3sec
	ret
;---------------------------
opto_7: 					;for 3
	cjne	a,#00001101b,opto_8
	clr	a
	cjne	a,xy_ngtv_count,for_3
	mov	r1,#02h
	mov	JOY_NOTCH,#02h			;joy notch ind
	mov	xy_pstv_count,#04h		;0.4sec
	ret
for_3:
	dec	xy_ngtv_count
	mov	r1,#010h
	mov	xy_pstv_count,#04h		;0.4sec
	ret
;----------------------------
opto_8: 					;for 4
	cjne	a,#00001001b,opto_9
	clr	a
	cjne	a,xy_ngtv_count,for_4
	mov	r1,#00h
	mov	JOY_NOTCH,#01h			;joy notch ind
	mov	xy_pstv_count,#05h		;0.5sec
	ret
for_4:
	dec	xy_ngtv_count
	mov	r1,#010h
	mov	xy_pstv_count,#05h		;0.5sec
	ret

;-----------------------------
opto_9: 					;zero
	mov	r1,#010h
	mov	JOY_NOTCH,#00h			;joy notch ind
	ret


;---------------------------------------------------------------------
SET_CHANNEL_SUB:
	mov	r5,#4		;8
	lcall	delay2		; 2.5 uS delay
	rlc	a		; rotate A
	jnc	set_ch_1	; check the lowest bit
	setb	rf_si		; set SI high
	ajmp	set_ch_2
SET_CH_1:
	clr	rf_si		; set SI low
SET_CH_2:
	mov	r5,#2		;4
	lcall	delay2		; 2.5 uS delay
	clr	cps
	mov	r5,#2		;4
	lcall	delay2		; 2.5 uS delay
	setb	cps
	djnz	r0,set_channel_sub
	ret

;----------------------------------------------------------

DELAY1: 			;Delay Time (r5*20mS)
	mov	r6,#40
DEL:	mov	r7,#249
$1:	djnz	r7,$1
	djnz	r6,DEL
	djnz	r5,DELAY1
	ret


DELAY2: 			;r5 * (2uS)
	djnz	r5,delay2
        ret

;--------------------------------------------------------------------
Lamp_Test_Data:
	db	11101110b
	db	11011101b
	db	10111011b
	db	01110111b

	db	11111111b
	db	00000000b
	db	11111111b
	db	00000000b
	db	11111111b

;---------------------------------------------------
;POLESTAR 5000 NOTCH DATA/DISPPLAY DATA
;---------------------------------------------------

;Notch_5000_x1y1:			; TRANSMITTER DATA

;	db	11111011b	; f-4	0	f
;	db	11110111b	; d-4
;	db	11111010b	; f-3	2	e
;	db	11111011b	; d-3
;	db	11111001b	; f-2	4	d
;	db	11111101b	; d-2
;	db	11111000b	; f-1	6	c
;	db	11111110b	; d-1

;	db	11111100b	; b-1	8	8
;	db	11111110b
;	db	11111101b	; b-2	A	9
;	db	11111101b
;	db	11111110b	; b-3	C	a
;	db	11111011b
;	db	11111111b	; b-4	E	b
;	db	11110111b
;	db	00000000b	; zero
;	db	11111111b

;Notch_5000_x2y2:			; TRANSMITTER DATA

;	db	11111011b	; f-4
;	db	01111111b	; d-4
;	db	11111010b	; f-3
;	db	10111111b	; d-3
;	db	11111001b	; f-2
;	db	11011111b	; d-2
;	db	11111000b	; f-1
;	db	11101111b	; d-1

;	db	11111100b	; b-1
;	db	11101111b
;	db	11111101b	; b-2
;	db	11011111b
;	db	11111110b	; b-3
;	db	10111111b
;	db	11111111b	; b-4
;	db	01111111b
;	db	00000000b	; zero notch
;	db	11111111b



;POLESTAR 4500 SYSTEM SEND/DISPLAY DATA
;----------------------------------------------------------------------
Notch_4500_x1y1:			; TRANSMITTER DATA

	db	11111101b	; f-4	0	f
	db	11110111b	; d-4
	db	11111001b	; f-3	2	e
	db	11111011b	; d-3
	db	11110101b	; f-2	4	d
	db	11111101b	; d-2
	db	11110001b	; f-1	6	c
	db	11111110b	; d-1

	db	11110010b	; b-1	8	8
	db	11111110b
	db	11110110b	; b-2	A	9
	db	11111101b
	db	11111010b	; b-3	C	a
	db	11111011b
	db	11111110b	; b-4	E	b
	db	11110111b
	db	00000000b	; zero
	db	11111111b

Notch_4500_x2y2:			; TRANSMITTER DATA

	db	11111101b	; f-4
	db	01111111b	; d-4
	db	11111001b	; f-3
	db	10111111b	; d-3
	db	11110101b	; f-2
	db	11011111b	; d-2
	db	11110001b	; f-1
	db	11101111b	; d-1

	db	11110010b	; b-1
	db	11101111b
	db	11110110b	; b-2
	db	11011111b
	db	11111010b	; b-3
	db	10111111b
	db	11111110b	; b-4
	db	01111111b
	db	00000000b	; zero notch
	db	11111111b







;________________________________________________________________________
;------------------------------------------------------------------------
;WORD ADDRESS / no1- 101b,/ no2- 110b,/ no3-011b,/( no4-100b,/ no5-001b)
;BIT ADDRESS 20,21,22,24,2d,2f

;********************************************************************
;*	Initialize	H/W
;********************************************************************

RECEIVER:

	mov	ERR_BIT_COUNT,#00h
	mov	SYNC_CNT0,#00h
	mov	SYNC_CNT1,#00h
	mov	WORD_FIND,#00h		;SYNC,NO1,MCA_BIT 
	mov	SQ_L_CNT,#00h

	setb	it0			;TCON
	setb	ex0			;IE.0
	setb	ea			;IE.7



MAIN:
	mov	a,SQ_L_CNT
	cjne	a,#220,SYNCCHECK		;192
	jb	scan_11,RFCH_SUB
	setb	base_ch_no
	ajmp	RFCH_SUB

SYNCCHECK:
	mov	a,SYNC_CNT1
	cjne	a,#15,ERR_CHECK			;5  128 * #?
	mov	SYNC_CNT1,#00h
	ajmp	RFCH_SUB
	
ERR_CHECK:
	mov	a,ERR_BIT_COUNT			;sync no count	
	cjne	a,#8,MAINSTART			;5
	ajmp	RFCH_SUB

MAINSTART:
	mov	a,WORD_FIND			; pattern flag
	cjne	a,#00000111b,MAIN
	mov	WORD_FIND,#00h
	mov	ERR_BIT_COUNT,#00h

	clr	ea				;IE.7
;------------------------------------------------
DISPLAY_ADD:					;tx check led on off

	setb	power_led		;off
	mov	r5,#40
	lcall	delay1

lamp_on:
	clr	power_led		;on
	mov	r5,#1
	lcall	delay1

	setb	power_led		;off
	mov	r5,#3
	lcall	delay1
	
	clr	power_led		;on
	mov	r5,#1
	lcall	delay1

	setb	power_led		;off
	mov	r5,#3
	lcall	delay1
	
	clr	power_led		;on
	mov	r5,#1
	lcall	delay1

	sjmp	DISPLAY_ADD


;--------------------------------	
RFCH_SUB:
	clr	ea
	jb	scan_11,again_end
	mov	a,ch_dip_sw
	anl	a,#01000000b
	jz	MANU_TXD			;manual mode
	mov	a,ch_dip_sw
	anl	a,#00110000b
fc_1:
	cjne	a,#00000000b,fc_2
	mov	a,channel_0
	subb	a,#12
	mov	channel_0,a
	ajmp	again_ch
fc_2:

	cjne	a,#00010000b,fc_3
	mov	a,channel_0
	subb	a,#24
	mov	channel_0,a
	ajmp	again_ch
fc_3:
	cjne	a,#00100000b,fc_4
	mov	a,channel_0
	subb	a,#36
	mov	channel_0,a
	ajmp	again_ch
fc_4:
	cjne	a,#00110000b,fc_e
	mov	a,channel_0
	subb	a,#48
	mov	channel_0,a
	ajmp	again_ch
fc_e:
	ljmp	init			;fc   error

MANU_TXD:				;MANUAL MODE
	clr	pwsw			;rf tx mode change(0)  1=rx
	ljmp	TX_DATA_SEND

again_ch:
	setb	scan_11			;base ch scan end
	ljmp	scan_set_1

again_end:
	jnb	base_ch_no,again_2sd
	mov	channel_0,channel_base	;base ch data send
	setb	Power_Led
	setb	scan_22
	ljmp	scan_set_1

again_2sd:
	setb	Power_Led		;2nd Channel data/ OFF
	mov	r5,#3
	lcall	delay1
	ljmp	TX_DATA_S		;LED 2 ON/OFF




;----------------------------------
;	External Interrupt 0
;----------------------------------
int_0:
	push	acc

	jb	SQ_OUT,action_data		;H-> action

	inc	SQ_L_CNT

;----------------------------------
action_data:
	mov	c,MODEM_RD
	mov	READ_BIT,c

	mov	a,WORD_FIND			; pattern flag
	cjne	a,#00000000b,address_data	; check pattern flag
	acall	SYNC_W
	ajmp	int_0_ret

address_data:
	cjne	a,#00000001b,mca_data		; check pattern flag
	acall	NO1_DATA_W
	ajmp	int_0_ret

mca_data:
	cjne	a,#00000011b,int_0_ret		; check pattern flag
	acall	MCA_DATA_W

int_0_ret:
	setb	ea
	pop	acc
        reti

;---------------------------------------------------------------------------
SYNC_W:
	mov	c,READ_BIT
	mov	a,PATTERN4
	rrc	a
	mov	PATTERN4,a
	mov	a,PATTERN3
	rrc	a
	mov	PATTERN3,a
	mov	a,PATTERN2
	rrc	a
	mov	PATTERN2,a
	mov	a,PATTERN1
	rrc	a
	mov	PATTERN1,a
	mov	a,PATTERN1
	cjne	a,#00000001b,sync_error		;start 1 bit
	mov	a,PATTERN2
	cjne	a,#00000000b,sync_error
	mov	a,PATTERN3
	cjne	a,#00000000b,sync_error		;
	mov	a,PATTERN4
	cjne	a,#11000000b,sync_error		;stop 2 bit

	setb	SYNC_BIT			;bit add 20h
	mov	SYNC_CNT0,#00h
	mov	SYNC_CNT1,#00h
	mov	SQ_L_CNT,#00h

	lcall	M_ADDRESS_INPUT

	ajmp	SYNC_RET

sync_error:
	inc 	SYNC_CNT0
	mov	a,SYNC_CNT0			;non data check / data delete
	cjne	a,#128,SYNC_RET
	mov	SYNC_CNT0,#00h
	inc	SYNC_CNT1

sync_ret:
	mov	BIT_CONT_32,#00h
	ret

;---------------------------------------------------------------------------
NO1_DATA_W:			
	inc	BIT_CONT_32
	mov	c,READ_BIT
	mov	a,PATTERN4
	rrc	a
	mov	PATTERN4,a
	mov	a,PATTERN3
	rrc	a
	mov	PATTERN3,a
	mov	a,PATTERN2
	rrc	a
	mov	PATTERN2,a
	mov	a,PATTERN1
	rrc	a
	mov	PATTERN1,a

	mov	a,BIT_CONT_32
	cjne	a,#32,no1_ret

	lcall	PARITY_CHECK
	jb	PARITY_ERR,no1_add_err

	mov	r7,PATTERN1			;PATTERN1=PATTERN3
	mov	a,PATTERN3
	cpl	a
	cjne	a,r7,no1_add_err
	mov	a,PATTERN2			;PATTERN2=PATTERN4
	anl	a,#01111111b			
	mov	r7,a
	mov	a,PATTERN4
	cpl	a
	anl	a,#01111111b
	cjne	a,r7,no1_add_err
;-------------------------------------
	mov	a,PATTERN1			
	cjne	a,Address1,no1_add_err		; ID CHECK
	mov	a,PATTERN2			; ID CHECK

;	anl	a,#01111111b			;bit8-patity, clear 
	anl	a,#00011111b			;p,opa,opb clear

	cjne	a,Address2,no1_add_err
	mov	a,PATTERN3
	cpl	a
	cjne	a,address1,no1_add_err
	mov	a,PATTERN4
	cpl	a

;	anl	a,#01111111b			;p clear
	anl	a,#00011111b			;p,opa,opb clear

	cjne	a,address2,no1_add_err
	setb	NO1_WORD_BIT

	ajmp	no1_ret1

no1_add_err:
	mov	WORD_FIND,#00h
	inc	ERR_BIT_COUNT

	lcall	M_ADDRESS_INPUT
		
no1_ret1:
	mov	BIT_CONT_32,#00h

no1_ret:
	ret

;---------------------------------------------------------------------------
MCA_DATA_W:			
	inc	BIT_CONT_32
	mov	c,READ_BIT
	mov	a,PATTERN4
	rrc	a
	mov	PATTERN4,a
	mov	a,PATTERN3
	rrc	a
	mov	PATTERN3,a
	mov	a,PATTERN2
	rrc	a
	mov	PATTERN2,a
	mov	a,PATTERN1
	rrc	a
	mov	PATTERN1,a

	mov	a,BIT_CONT_32
	cjne	a,#32,ch_ret

	lcall	PARITY_CHECK
	jb	PARITY_ERR,ch_data_err

	mov	r7,PATTERN1			;PATTERN1=PATTERN3
	mov	a,PATTERN3
	cpl	a
	cjne	a,r7,ch_data_err
	mov	a,PATTERN2			;PATTERN2=PATTERN4
	anl	a,#01111111b			
	mov	r7,a
	mov	a,PATTERN4
	cpl	a
	anl	a,#01111111b
	cjne	a,r7,ch_data_err

;--MCA ID CHECK---------------------	
;------.7,1,1,sc2,sc1,0,1,0b
	mov	a,PATTERN1			;PATTERN1=WORD ADD
	cjne	a,MCA_DW_L,ch_data_err		;lsb 8bit
;	cjne	a,#01100010b,ch_data_err	;WORD DATA 8bit

	mov	a,PATTERN2			;channel dip 7bit
	anl	a,#00111111b			;p,dip.7 clear
	cjne	a,channel_0,ch_data_err		;ID/ P,7,6,5,4,3,2,1b

	setb	mca_word_bit
	ajmp	ch_ret1
;------------------------------------

ch_data_err:
	inc	ERR_BIT_COUNT
	mov	WORD_FIND,#00h

ch_ret1:
	mov	BIT_CONT_32,#00h

ch_ret:
	ret


;---------------------------------------------------------------------------
PARITY_CHECK:
	mov	PARITY_BYTE,#00H	; Odd Parity
	mov	a,PATTERN1
	lcall	CAL_PARITY

	mov	a,PATTERN2
	lcall	CAL_PARITY

	mov	B,#2
	mov	A,PARITY_BYTE
	div	AB
	mov	A,B
        jz     EVEN_P

	SJMP	PCHECK_ERR	
		
EVEN_P:
	mov	PARITY_BYTE,#01H	; Even Parity
	mov	a,PATTERN3
	lcall	CAL_PARITY

	mov	a,PATTERN4
	lcall	CAL_PARITY

        mov     B,#2
        mov     A,PARITY_BYTE
        div     AB
	mov	A,B
        jz     EVEN_P1

	SJMP	PCHECK_ERR	

EVEN_P1:
	CLR	PARITY_ERR
	SJMP	PCHECK_RET


PCHECK_ERR:
	setb	PARITY_ERR		; SET PARITY ERR FLAG
PCHECK_RET:
	ret
;----------------------------------------------------
CAL_PARITY:
        CLR     C
	mov	r7,#8
CAL_0:
	rrc	a
	jnc	CAL_1
	inc	PARITY_BYTE
CAL_1:
	djnz	r7,CAL_0
	ret

;----------------------------------------------------
M_ADDRESS_INPUT:

	mov	IO_PORT,#01110001b
	mov	r5,#2
	lcall	delay2
	mov	a,Read_Port
	cpl	a
	mov	r4,a
	rl	a
	rl	a
	rl	a
	anl	a,#11111000b
	orl	a,#00000101b		;5,4,3,2,1,H,L,Hb
	mov	Address1,a		; 8 bit
	mov	IO_PORT,#01111111b
	mov 	a,r4
	swap	a
	rr	a
	anl	a,#00000111b
	mov	r4,a
	
	mov	IO_PORT,#01110010b
	mov	r5,#2
	lcall	delay2
	mov	a,Read_Port
	cpl	a
	swap	a
	rr	a
	mov	r0,a

;----dip sw .7(CH ADD) check
	mov	IO_PORT,#01110000b
	mov	r5,#2
	lcall	delay2
	mov	a,Read_Port
	cpl	a
	anl	a,#01000000b
	jnz	mca_opab		;7dip=1(ON) jmp/ mca mode
	mov	a,r0
	anl	a,#01111000b		;opa opb txd
	ajmp	opaopb
mca_opab:
	mov	a,r0
	anl	a,#00011000b		;p,opa,opb clear
opaopb:
	mov	IO_PORT,#01111111b

	orl	a,r4
	mov	Address2,a		; P,OPA,OPB,10,9,8,7,6b
	mov	IO_PORT,#01111111b
	ret

;--------------------------------------
CH_ID_INPUT:
	mov	MCA_DW_L,#00h
	mov	IO_PORT,#01110000b
	mov	r5,#2
	lcall	delay2
	mov	a,Read_Port
	cpl	a
	anl	a,#01111111b
	mov	ch_dip_sw,a			;.7 check
	anl	a,#00111111b
	mov	channel_0,a			;p,.7 clear

	mov	a,ch_dip_sw
	anl	a,#01000000b
	jnz	scan_mode			;7dip=1(ON) jmp

	mov	IO_PORT,#01111111b

	mov	MCA_DW_L,#01100010b		;base code
	ret

scan_mode:					;dip.7 on
	mov	IO_PORT,#01111111b
	
;	setb	scan_mark			;scan mode mark
	mov	a,ch_dip_sw
	anl	a,#00110000b			

	cjne	a,#00000000b,spco_1		;sc00
	mov	MCA_DW_L,#11100010b
	ajmp	spco_4
spco_1:
	cjne	a,#00010000b,spco_2		;sc1
	mov	MCA_DW_L,#11101010b
	ajmp	spco_4
spco_2:
	cjne	a,#00100000b,spco_3		;sc2
	mov	MCA_DW_L,#11110010b
	ajmp	spco_4
spco_3:
	cjne	a,#00110000b,spco_4		;sc1,2
	mov	MCA_DW_L,#11111010b

spco_4:
	mov	a,ch_dip_sw
	anl	a,#00001111b
	cjne	a,#00h,frq_1
	mov	channel_0,#00110000b		;4447.8625
	ret		

frq_1:		
	cjne	a,#01h,frq_2
	mov	channel_0,#00110001b		;447.8750
	ret

frq_2:		
	cjne	a,#02h,frq_3
	mov	channel_0,#00110010b		;447.8875
	ret
frq_3:		
	cjne	a,#03h,frq_4
	mov	channel_0,#00110011b		;447.9000
	ret
frq_4:		
	cjne	a,#04h,frq_5
	mov	channel_0,#00110100b		;447.9125
	ret
frq_5:		
	cjne	a,#05h,frq_6
	mov	channel_0,#00110101b		;447.9250
	ret
frq_6:		
	cjne	a,#06h,frq_7
	mov	channel_0,#00110110b		;447.9375
	ret
frq_7:		
	cjne	a,#07h,frq_8
	mov	channel_0,#00110111b		;447.9500
	ret
frq_8:		
	cjne	a,#08h,frq_9
	mov	channel_0,#00111000b		;447.9625
	ret
frq_9:		
	cjne	a,#09h,frq_10
	mov	channel_0,#00111001b		;447.9750
	ret
frq_10:		
	cjne	a,#0ah,frq_end
	mov	channel_0,#00111010b		;447.9875
	ret
frq_end:					;11ch over		
	mov	channel_0,#11000000b		;error
	ret

;**********************************************

CH_Data_447:
	DB	00011101B	; CH #1 / 7.2625
	DB	00001100B
	DB	00011101B	; CH #2 / 7.2750
	DB	00010100B
	DB	00011101B	; CH #3 / 7.2875
	DB	00011100B
	DB	00011101B	; CH #4 / 7.3000
	DB	00100100B
	DB	00011101B	; CH #5 / 7.3125
	DB	00101100B
	DB	00011101B	; CH #6 / 7.3250
	DB	00110100B
	DB	00011101B	; CH #7 / 7.3375
	DB	00111100B
	DB	00011101B	; CH #8 / 7.3500
	DB	01000100B
	DB	00011101B	; CH #9 / 7.3625
	DB	01001100B
	DB	00011101B	; CH #10 / 7.3750
	DB	01010100B
	DB	00011101B	; CH #11 / 7.3875
	DB	01011100B
	DB	00011101B	; CH #12 / 7.4000
	DB	01100100B
	DB	00011101B	; CH #13
	DB	01101100B
	DB	00011101B	; CH #14
	DB	01110100B
	DB	00011101B	; CH #15
	DB	01111100B
	DB	00011101B	; CH #16 / 7.4500
	DB	10000100B
	DB	00011101B	;CH  #17
	DB	10001100B
	DB	00011101B	;CH  #18
	DB	10010100B
	DB	00011101B	;CH  #19
	DB	10011100B
	DB	00011101B	;CH  #20 / 7.5000
	DB	10100100B
	DB	00011101B	;CH  #21
	DB	10101100B
	DB	00011101B	;CH  #22
	DB	10110100B
	DB	00011101B	;CH  #23
	DB	10111100B
	DB	00011101B	;CH  #24 / 7.5500
	DB	11000100B
	DB	00011101B	;CH  #25
	DB	11001100B
	DB	00011101B	;CH  #26
	DB	11010100B
	DB	00011101B	;CH  #27
	DB	11011100B
	DB	00011101B	;CH  #28 / 7.6000
	DB	11100100B
	DB	00011101B	;CH  #29
	DB	11101100B
	DB	00011101B	;CH  #30
	DB	11110100B
	DB	00011101B	;CH  #31
	DB	11111100B
	DB	00011110B	;CH  #32 / 7.6500
	DB	00000100B
	DB	00011110B	;CH  #33
	DB	00001100B
	DB	00011110B	;CH  #34
	DB	00010100B
	DB	00011110B	;CH  #35
	DB	00011100B
	DB	00011110B	;CH  #36 / 7.7000
	DB	00100100B
	DB	00011110B	;CH  #37
	DB	00101100B
	DB	00011110B	;CH  #38
	DB	00110100B
	DB	00011110B	;CH  #39
	DB	00111100B
	DB	00011110B	;CH  #40 / 7.7500
	DB	01000100B
	DB	00011110B	;CH  #41
	DB	01001100B
	DB	00011110B	;CH  #42
	DB	01010100B
	DB	00011110B	;CH  #43
	DB	01011100B
	DB	00011110B	;CH  #44 / 7.8000
	DB	01100100B
	DB	00011110B	;CH  #45
	DB	01101100B
	DB	00011110B	;CH  #46
	DB	01110100B
	DB	00011110B	;CH  #47
	DB	01111100B
	DB	00011110B	;CH  #48 / 7.8500
	DB	10000100B
	DB	00011110B	;CH  #49
	DB	10001100B
	DB	00011110B	;CH  #50
	DB	10010100B
	DB	00011110B	;CH  #51
	DB	10011100B
	DB	00011110B	;CH  #52 / 7.9000
	DB	10100100B
	DB	00011110B	;CH  #53
	DB	10101100B
	DB	00011110B	;CH  #54
	DB	10110100B
	DB	00011110B	;CH  #55
	DB	10111100B
	DB	00011110B	;CH  #56 / 7.9500
	DB	11000100B
	DB	00011110B	;CH  #57
	DB	11001100B
	DB	00011110B	;CH  #58
	DB	11010100B
	DB	00011110B	;CH  #59 / 7.9875
	DB	11011100B
;-----------------------------------------------------

;%E

end





