
;TMX 613 (253.8625 ~ 254.9750Mhz) / MR TYPE Compatible  
;FILE  NAME :  HD25000T.ASM ---> HD253HT.ASM
;CKT   NAME :  POS-5000TPCB	
;The LATEST : 2018 / 09 /28 /
;
;       POLESTAR
;
;       DAE HWA ELECTRONICS CO,.LTD
;
;	E D I T     B Y  : KIM	SEONG  WEON
;	OFFICE TELEPHONE :  (02) 2639 - 8310
;	HOM    TELEPHONE :(0343) 398 - 9588

;*** TX DATA COUNT	--- R0	    send bit count
;*** opto joystick memo --- R1
;*** function joystick	--- R2,R3,R4
;*** TIME DELAY--- R5,R6,R7

;WORD ADDRESS / no1- 101b,/ no2- 110b,/ no3-011b,/( no4-100b,/ no5-001b)
                                                 
;OPTION
;P2.4(Z)=UNIVERSAL  /  P2.5(W)=AUTO TIME DELETE
;P1.7(X)=NO4,NO5  /  P3.2(Y)=POLESTAR 5000/4500 SELECTOR(notch data)

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

X1_Data_Buf	data	38h
Y1_Data_Buf	data	39h
X2_Data_Buf	data	3ah
Y2_Data_Buf	data	3bh
SIR_count	data	3ch
auto_timer_1	data	3dh
low_p_s_count	data	3eh	; battery low power siren count

; -----

Parity_Count	data	40h
RF_SI_Buf_0	data	41h	;TX Data Bank 8bit
RF_SI_Buf_1	data	42h	;TX Data Bank 8bit

TX_SEND_1	data	43h	;send data memory
TX_SEND_2	data	44h
TX_SEND_3	data	45h
TX_SEND_4	data	46h

JOY_function	data	47h
Power_status	data	48h
auto_timer_0	data	49h

X1_NOTCH_D	data	4ah	;notch display memory
Y1_NOTCH_D	data	4bh	;	=
X2_NOTCH_D	data	4ch	;	=
Y2_NOTCH_D	data	4dh	;	=

wire_mode	data	4eh	;wire remocon mode

xy_pstv_count	data	50h
xy_ngtv_count	data	51h

x1_pstv_buffer	data	52h
x1_ngtv_buffer	data	53h
y1_pstv_buffer	data	54h
y1_ngtv_buffer	data	55h
x2_pstv_buffer	data	56h
x2_ngtv_buffer	data	57h
y2_pstv_buffer	data	58h
y2_ngtv_buffer	data	59h

JL_NOTCH	data	5ah
JR_NOTCH	data	5bh
JOY_NOTCH	data	5ch

Read_Port	data	080H	; Port 0
IO_PORT		data	0a0h	; port 2

auto_status	data	20h	;(bit address) nondata timer

ENDS

BSEG

Power_Check	bit	p2.6
modem_st	bit	p3.4
modem_sd	bit	P3.1
modem_rd	bit	p3.0
modem_rt	bit	p3.2		;/INT0

Power_Led	bit	p3.5
;Joy_Butt_X1Y1	bit	p3.6
;Joy_Butt_X2Y2	bit	p3.7

JL_LED		bit	p3.6
JR_LED		bit	p3.7

OPT_W		bit	p2.5		;AUTO TIME DELETE
OPT_X		bit	p1.7		;NO4 NO5
OPT_Y		bit	p3.3		;MR5000 ,POS5000 SELECTOR
OPT_Z		bit	p2.4		;UNIVERSAL

;## RF module pin description ##

rst		bit	p1.0
cps		bit	p1.1
rf_si		bit	p1.2
vcosw		bit	p1.3
pwsw		bit	p1.4
lock_out	bit	p1.5
SQ_OUT		bit	p1.6

xx1_nondata	bit	00h
yy1_nondata	bit	01h
xx2_nondata	bit	02h
yy2_nondata	bit	03h
neutralbit	bit	07h

JOY_test	bit	0ah		; H" joystick test mode
sir_status	bit	0bh

;JOY_n_test	bit	0ch		; opto type joystick neutral test
low_p_siren	bit	0dh		; battery low power siren
poweronsiren	bit	0eh
po5045select	bit	0fh

JL_MARK		bit	10h
JR_MARK		bit	11h

ENDS

;--------------------------------------------------------------------
;%S
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



;********************************************************************
;*	Interrupt Vector
;********************************************************************

	org	0000h
	sjmp	init		; Reset

	org	0003h		; External 0
	sjmp	init

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

;********************************************************************
;*	Initialize	H/W
;********************************************************************


INIT:
	mov	sp,#70h
	mov	psw,#00h
	mov	pcon,#00000000b

INIT_1:
;INIT START_ON SWITCH CHECK
	mov	IO_PORT,#01111001b
	mov	r5,#2
	lcall	delay2
	mov	a,Read_Port
	cpl	a
	mov	IO_PORT,#01111111b

	anl	a,#00000010b
	
	cjne	a,#00000010b,START_TX		;start_on det
	mov	r5,#2
	lcall	delay1
	clr	Power_Led			;ON
	mov	r5,#2
	lcall	delay1
	setb	Power_Led			;OFF

	ljmp	INIT_1

;----------------------------------------
START_TX:
	clr	p2.7			;374CK
	clr	low_p_siren		;battery low power siren
	clr	joy_test
	clr	poweronsiren
;	clr	mcano1end

	setb	JL_MARK
	setb	JR_MARK

	mov	x1_notch_d,#11111111b	;notch data initialize
	mov	x2_notch_d,#11111111b
	mov	y1_notch_d,#11111111b
	mov	y2_notch_d,#11111111b
	mov	Power_status,#4 	; Battery voltage check
;	mov	mca_no1_again,#00000000b
;---------------------------------------------------------------------
; POLESTAR 5000/4500 SELECTOR
;---------------------------------------------------------------------
	mov	r5,#5
	lcall	delay2

	jb	OPT_Y,POS5045SE		;S(L)-->POS5000 SYSTEM
	clr	po5045select		
	nop
	jnb	OPT_Y,FUNCTION
	ajmp	INIT

POS5045SE:				;O(H)MR4500 SYSTEM	
	nop
	jnb	OPT_Y,INIT
	setb	po5045select		
	
FUNCTION:
;----------------------------------------------------------------------
; FUNCTION JOYSTICK SELECTION
;----------------------------------------------------------------------
	mov	IO_PORT,#01110010b

	mov	r5,#2
	lcall	delay2
	mov	a,Read_Port
	cpl	a
	anl	a,#11110000b
	swap	a

;--------------------------------------------------------------------------
	mov	joy_function,a		;  joystick function selection
;--------------------------------------------------------------------------

	mov	IO_PORT,#01111111b

	setb	rst			;RF control initialize
	setb	si
	setb	cps
	setb	pwsw
	setb	vcosw

	setb	modem_sd
	setb	sir_status		;Auto siren control

	mov	auto_timer_0,#00h
	mov	auto_timer_1,#00h

	mov	x1_data,#010h		;zero notch initialize (hex)
	mov	x2_data,#010h		;notch display data table
	mov	y1_data,#010h
	mov	y2_data,#010h

	mov	x1_data_buf,#00h	;zero notch initialize
	mov	x2_data_buf,#00h
	mov	y1_data_buf,#00h
	mov	y2_data_buf,#00h

	mov	x1_pstv_buffer,#00h
	mov	x1_ngtv_buffer,#00h
	mov	y1_pstv_buffer,#00h
	mov	y1_ngtv_buffer,#00h
	mov	x2_pstv_buffer,#00h
	mov	x2_ngtv_buffer,#00h
	mov	y2_pstv_buffer,#00h
	mov	y2_ngtv_buffer,#00h

	clr	Power_Led		; Power Ind \ LED ON



;-------------------------------------------------------------------------
;  JOYSTICK TEST MODE
;
;initialize joystick start button check to JTM loop again
;initilalize switch ON check to SW_CHECK loop again
;-------------------------------------------------------------------------

JTM:					;start button check
;	jnb	joy_butt_x1y1,JTM	; start button on / off status to
;	jnb	joy_butt_x2y2,JTM	; RF control

;- 4bit  check -----------------------

;	mov	IO_PORT,#01111001b

;	mov	r5,#2
;	lcall	delay2
;	mov	a,Read_Port
;	cpl	a

;	mov	IO_PORT,#01111111b

;	anl	a,#00001111b

;	cjne	a,#00000000b,JTM	;4bit(S,L,P_ON,P_OFF) check

;********************************************************************
;*	RF MODULE CONTROL
;********************************************************************

RF_ON:				

; RF Channel Port Enable

	mov	IO_PORT,#01110000b

	mov	r5,#3
	lcall	delay2			; 2.5 uS delay
	mov	a,Read_Port		; Read RF Chennel DIP switch Port

;-------------------------------------------------------------------------
;TRANSMITTER(TX)  POWER  ON    SIREN ( time = 0.10 sec * #data )
;-------------------------------------------------------------------------

	jb	P0.7,SIREN_OFF			; CPU 8 PIN = 0N(L)  SIREN ON
	setb	poweronsiren			; contron on siren disable
	clr	sir_status			;
	mov	sir_count,#25			; (( 0.10 sec * #data ))

SIREN_OFF:
	cpl	a			; H -> L -> H
	anl	a,#01111111b		; MSB.7 =Erase

	mov	wire_mode,a			;wire remocon

	rl	a
	mov	Read_Data,a
;	mov	dptr,#CH_Data_447
	mov	dptr,#CH_Data_250
	movc	a,@a+dptr
	mov	RF_SI_Buf_0,a
	mov	a,Read_Data
	inc	a
	movc	a,@a+dptr
	mov	RF_SI_Buf_1,a

; RF Channel Port Disable
	mov	IO_PORT,#01111111b

;---------------------------------------------------------------------
	mov	a,wire_mode
	cjne	a,#01111111b,start_rf_module
	ajmp	neutral_test
;---------------------------------------------------------------------

START_RF_MODULE:
	clr	vcosw
	mov	r5,#1
	lcall	delay1
	lcall	Set_Channel			; (2) set channel freq.
	mov	r5,#2				; 40mS delay
	lcall	delay1

START_RF_MODULE0:
	jb	lock_out, start_rf_module0	; (3) check lock up
	mov	r5,#2				; 50uS delay
	lcall	delay2
	clr	pwsw				; (4) TX PW SW ON
	mov	r5,#08h 			; 160mS delay
	lcall	delay1


	setb	Power_LED
	mov	r5,#5
	lcall	delay1
	clr	Power_LED


	ajmp	NEUTRAL_Test

;-------------------------------------------------------------------
;
;	NAME: TMX 729
;	DESCRIPTION: Set RF channel frequency
;
;	INPUT:
;	OUTPUT:
;
;	The followings should be executed in order.
;
;	(1) reference frequency setting at 12.5 kHz
;		BIT PATTERN: 111100000000001101010
;			     MSB	       LSB
;	(2) TX frequency setting from DIP switch setting
;		BIT PATTERN: 0101001001111 CHANNEL
;			     MSB	       LSB
;	(3) RX frequency setting from DIP switch setting
;		BIT PATTERN: 1010001001111 CHANNEL
;			     MSB	       LSB
;
;	One setting bits consist of 21 bits.
;
;	D21 D20 ----------------------- D2 D1
;	It is assumed that MSB are sent first.
;
;---------------------------------------------------------------------

SET_CHANNEL:

;=======================================
;	Reference Frequency Set
;	   equ tmx 613
;=======================================
	setb	cps			; set complement of CPS high
	clr	rst			; set RST low
	mov	r5,#2			; 4 us delay
	lcall	delay2
	mov	a,#11110000b		; reference frequency setting
	mov	r0,#8			; 12.5 kHz
	lcall	set_channel_sub
	mov	a,#00000011b
	mov	r0,#8
	lcall	set_channel_sub
	mov	a,#01010100b
	mov	r0,#6			; 5+1
	lcall	set_channel_sub
	mov	r5,#4
	lcall	delay2			; 2.5 uS delay
	setb	rst
	mov	r5,#100 		; 20mS delay
	lcall	delay2

;=======================================
;	TX Frequency Set
;=======================================
	clr	rst			; TX requency setting
	mov	r5,#2			; 4 uS delay
	lcall	delay2
	mov	a,#01010010b		; TX TURN ON
;	mov	a,#01010100b		; 729
	mov	r0,#8
	lcall	set_channel_sub
	mov	a,RF_SI_Buf_0		; Channel DIP S/W setting
	mov	r0,#8
	lcall	set_channel_sub
	mov	a,RF_SI_Buf_1		; Channel DIP S/W setting
	mov	r0,#6
	lcall	set_channel_sub
	mov	r5,#4
	lcall	delay2			; 2.5 uS delay
	setb	rst
	mov	r5,#100 		; 20mS delay
	lcall	delay2
	ret
;=======================================
;	RX Frequency Set
;=======================================
;	clr	rst			; RX requency setting
;	mov	r5,#2			; 4 uS delay
;	lcall	delay2
;	mov	a,#01100010b		; RX TURN ON
;	mov	r0,#8
;	lcall	set_channel_sub
;	mov	a,#10110000b
;	mov	r0,#5
;	lcall	set_channel_sub
;	mov	a,#00011010b		; channel DIP S/W setting
;	mov	r0,#8
;	lcall	set_channel_sub
;	mov	a,#10000000b		 ;21+1
;	mov	r0,#1
;	lcall	set_channel_sub
;	mov	r5,#4
;	lcall	delay2			; 2.5 uS delay
;	setb	rst
;	mov	r5,#100 		; 20mS delay
;	lcall	delay2
;	ret

;---------------------------------------------------------------------
;
;	NAME: SET_CHANNEL_SUB()
;	DESCRIPTION: Send bits of Accumulator( length: R0 )  to RF MODULE
;	It is assumed that MSB are sent first.
;
;	INPUT:	R0,A
;	OUTPUT:
;
;---------------------------------------------------------------------

SET_CHANNEL_SUB:
	mov	r5,#8
	lcall	delay2		; 2.5 uS delay
	rlc	a		; rotate A
	jnc	set_ch_1	; check the lowest bit
	setb	rf_si		; set SI high
	ajmp	set_ch_2
SET_CH_1:
	clr	rf_si		; set SI low
SET_CH_2:
	mov	r5,#8
	lcall	delay2		; 2.5 uS delay
	clr	cps
	mov	r5,#2
	lcall	delay2		; 2.5 uS delay
	setb	cps
	djnz	r0,set_channel_sub
	ret


;-----------------------------------------------------------------------
;	     JOYSTICK	NEUTRAL TESTING
;-----------------------------------------------------------------------

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


;	lcall	opto_joystick
	mov	y2_data,a		;Y2-DATA
;------------------------------------------------------------------------

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
;	clr	7fh			; pcb error    7
	ajmp	error_3

error_y2:
	clr	7ch
;	clr	7fh			; pcb error    7	
Neutral:
	mov	a,02fh			; bit address 2Fh
	cpl	a

	jz	Notch_Disp		; Netural  Status  = ( acc zero )
 
	cpl	a
	mov	read_port,a		; bit address 2Fh
	mov	r5,#2
	lcall	delay2
	
	clr	power_led
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

	setb	power_led
	setb	p2.7			;  1 notch display  OFF

	mov	r5,#2
	lcall	delay1
;----------------------------------------------
	clr	p2.7

	ajmp	Neutral_Test

;----------------------------------------------------------------------
;####  NOTCH DISPPLAY LAMP TEST  ####
;----------------------------------------------------------------------

Notch_Disp:

	clr	power_led
	mov	r4,#9			;loop 9
	clr	a
loop_1:
	mov	Read_Data,a
	clr	p2.7

	mov	dptr,#Lamp_Test_Data
	movc	a,@a+dptr
	mov	read_port,a
	mov	r5,#4			;
	lcall	DELAY2

	setb	p2.7			; NOTCH LED  ON / OFF

	mov	r5,#7			;
	lcall	DELAY1

	mov	a,Read_Data
	inc	a
	djnz	r4,loop_1

	mov	Read_Port,#0ffh




SYNC_WORD:

;0-------------------------->32 BIT<---------------------------31
;1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 1
;start-------------------------------------------------------stop

;---------------------------------------------------------------------
; CONTROLL POWER  MAGNET  ON /	SIREN ( time = 0.10 sec * #data )
;---------------------------------------------------------------------

	jb	poweronsiren,SIREN_NON	;

; I/O_RFCH_ ADDRESS
	mov	IO_PORT,#01110000b

	mov	r5,#1
	lcall	delay2

	jb	neutralbit,SIREN_NON
	jb	P0.7,SIREN_NON		; P0.7(L) /74HC240 output/  ASIREN ON

	clr	sir_status		; SIREN_STATUS	" L "
	setb	poweronsiren		;
	mov	sir_count,#25		; (( 0.10 sec * #data ))

SIREN_NON:
	mov	IO_PORT,#01111111b

	mov	auto_status,#00h	; NON DATA CHECK INITIALIZE

	jnb	power_check,Power_L
	clr	Power_LED
	ajmp	Power_H
Power_L:
	jb	power_check,Power_H	; BATTERY VOLTAGE CHECK

;------------------------------------------------------------------------
;	POWER LOW  _  AUTO SIREN
; siren on time { low_p_s_count (0.10sec) } * #data
;-----------------------------------------------------------------------
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

;-------------------------------------------------------------
SYNC_data:

; I/O_X1Y1_ ADDRESS
	mov	IO_PORT,#01110111b

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
	mov	a,#00000001b		;4bit  start bits     4
	mov	r0,#4
	lcall	send_bits

;-------------------------------------	;JOY NOTCH IND
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
	 
	mov	a,#00000000b		;4bit  		    8
	mov	r0,#4
	lcall	send_bits

; I/O_X1Y1_ ADDRESS
	mov	IO_PORT,#01110111b

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
	mov	a,#00000000b		;4bit		12
	mov	r0,#4
	lcall	send_bits

;-------------------------------------	;JOY NOTCH IND
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
	mov	a,#00000000b		;4bit		16
	mov	r0,#4
	lcall	send_bits

; I/O_x2y2_ ADDRESS
	mov	IO_PORT,#01111000b

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
	mov	a,#00000000b		;4bit		20
	mov	r0,#4
	lcall	send_bits

;-------------------------------------	;JOY NOTCH IND
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
	mov	a,#00000000b		;4bit		24
	mov	r0,#4
	lcall	send_bits

; I/O_x2y2_ ADDRESS
	mov	IO_PORT,#01111000b

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
	mov	a,#00000000b		;4bit		28	 
	mov	r0,#4
	lcall	send_bits

;-------------------------------------	;JOY NOTCH IND
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
	mov	a,#00001100b		;4bit	stop bit	32
	mov	r0,#4
	lcall	send_bits

;---joystick not neutral no power on ----------
	
	mov	a,auto_status
	jnz	powerclear
	clr	neutralbit
	ajmp	pon_clear
powerclear:
	setb	neutralbit
pon_clear:

;-------------------------------------------------
;UNIVERSAL TYPE SELECTION (JB1)
;	jnb	OPT_Z,no1_data_word
;-------------------------------------------------
X1_CLOSE:
	mov	a,x1_data
	cjne	a,#010h,y1_close
	ajmp	x2_close
Y1_CLOSE:
	mov	a,y1_data
	cjne	a,#010h,x1y1_close
	ajmp	x2_close
X1Y1_CLOSE:
	mov	x1_data,#010h
	mov	y1_data,#010h
X2_CLOSE:
	mov	a,x2_data
	cjne	a,#010h,y2_close
	ajmp	no1_data_word
Y2_CLOSE:
	mov	a,y2_data
	cjne	a,#010h,x2y2_close
	ajmp	no1_data_word
X2Y2_CLOSE:
	mov	x2_data,#010h
	mov	y2_data,#010h

;---------------------------------------------------------------------------
;    NO1 DATA WORD
;
; NO1 Address  101 ,  NO2  011 , NO3  110  , N04  010  , NO5   100
;~~~~~~~~~~~~~~~~~    ~~~~~~~~	 ~~~~~~~~    ~~~~~~~~	 ~~~~~~~~~
;--------------------------------------------------------------------------

NO1_DATA_WORD:

	mov	Parity_Count,#00h
	mov	a,#000000101b		; NO1 ADD  " 101 "
	mov	TX_SEND_1,a
	mov	r0,#3
	lcall	send_bits
	
;I\O_M-ADD_ADDRESS
	mov	IO_PORT,#01110001b
	
	mov	r5,#1
	lcall	delay2
	mov	a,Read_Port
	cpl	a
	mov	TX_SEND_2,a

	mov	IO_PORT,#01111111b

	mov	r0,#8			; 8 Bit
	lcall	send_bits

;I/O_9,10,OPA,OPB_ADDRESS
	mov	IO_PORT,#01110010b

	mov	r5,#2
	lcall	delay2
	mov	a,Read_Port
	cpl	a

	mov	IO_PORT,#01111111b

	anl	a,#00001111b

	mov	TX_SEND_3,a
	mov	r0,#4
	lcall	send_bits		;4bit add 9,10.opa.opb

	lcall	Parity_Bit

;!@!@!@! ---NO1 TX DATA REVERSED ---!@!@!@!

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

	setb	JL_LED				;LEFT JOY LED OFF

;-------------------------------------------------------------------------

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
;	     Y	X	     Y	X	    |		    |
; ****0110 - X1 Y1	     X2 Y2	    |		    |
; ?????001 - Y1 X1	     X2 Y2     <---------> X1  <---------> X2
; ?????010 - X1 X2	     Y1 Y2	    |		    |
; ?????011 - Y1 X2	     X1 Y2	    |		    |
; ?????100 - X1 Y2	     X2 Y1
; ?????101 - Y1 Y2	     X1 X2	  left		  right
; ****0000 - Y1 X1	     Y2 X2		5000 mode 
; ****0111 - X2 Y2	     X1 Y1
; ????1000 - Y2 X1	     Y1 X2
; ????1001 - Y2 X2	     Y1 X1
; ????1010 - X2 Y2	     Y1 X1
; ????1011 - Y2 X2	     X1 Y1
; ****1100 - X1 Y1	     Y2 X2      5000 from 4500 mode T/L,T/S CHANGE
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

;-------------------------------------------------------------
y1_butt_off:
	ljmp	no2_y1_off_data
;--------------------------------------------------------------

function_y1_4:
	cjne	r2,#00000101b,function_y1_5		; Y2
;	jb	Joy_Butt_x2y2,y1_butt_off
	jnb	sir_status,y1_butt_off
	mov	r3,y1_data
	mov	y1_data,y2_data 			; data exchange
	lcall	y2_display
	ajmp	no2_y1_data

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
	mov	r2,joy_function
	cjne	r2,#00001100b,function_y1_12		; Y1
;	jb	Joy_Butt_x1y1,y1_butt_off
	jnb	sir_status,y1_butt_off
	mov	r3,y1_data
	lcall	y1_display
	ajmp	no2_y1_data

function_y1_12:
	ajmp	sync_word				; function error


;-----------------------------------------------------------------------

NO2_Y1_DATA:					;send data
	
	jb	po5045select,y1y1_sel
	mov	a,y1_data
	mov	dptr,#Notch_4500_x1y1
	movc	a,@a+dptr
	ajmp	Y1Y1DATASEND
y1y1_sel:
	mov	a,y1_data
	mov	dptr,#Notch_5000_x1y1
	movc	a,@a+dptr

Y1Y1DATASEND:

	mov	TX_SEND_2,a

	mov	r0,#4				; NO2 X1 DATA  4 BIT
	lcall	send_bits			; ~~~~~~~~~~~~~~~~~~

;-----------------------------------------------------------------------
	mov	y1_data,r3			; reduction y1_data
;----------------------------------------------------------------------

;--------------------------------------------------------------------
; power on siren of non data   ( sir_status    = L )
;--------------------------------------------------------------------

NO2_X1:

;------------------------------------------------------------------------
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


;---------------------------------------------------------------
x1_butt_off:
	ljmp	no2_x1_off_data
;---------------------------------------------------------------

function_x1_4:
	cjne	r2,#00000101b,function_x1_5		; Y1
;	jb	Joy_Butt_x1y1,x1_butt_off
	jnb	sir_status,x1_butt_off
	mov	r4,x1_data
	mov	x1_data,y1_data 			; data exchange
	lcall	y1_display
	ajmp	no2_x1_data


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
	mov	r2,joy_function
	cjne	r2,#00001100b,function_x1_12		; X1
;	jb	Joy_Butt_x1y1,x1_butt_off
	jnb	sir_status,x1_butt_off
	mov	r4,x1_data
	lcall	x1_display
	ajmp	no2_x1_data

function_x1_12:
	ljmp	sync_word				; function error

;-----------------------------------------------------------------------

NO2_X1_DATA:					; send data
	
	jb	po5045select,x1x1_sel
	mov	a,x1_data
	mov	dptr,#Notch_4500_x1y1
	movc	a,@a+dptr
	ajmp	X1X1DATASEND
x1x1_sel:
	mov	a,x1_data
	mov	dptr,#Notch_5000_x1y1
	movc	a,@a+dptr

X1X1DATASEND:

	mov	TX_SEND_3,a

	mov	r0,#4				; NO2 X1 DATA  4 BIT
	lcall	send_bits			; ~~~~~~~~~~~~~~~~~~

;-----------------------------------------------------------------------
	mov	x1_data,r4			; reduction x1_data
;-----------------------------------------------------------------------
;	clr	p2.3
;	clr	p1.6
	mov	IO_PORT,#01111001b	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	mov	r5,#2
	lcall	delay2
	mov	a,Read_Port
	cpl	a

;	setb	p1.6
	mov	IO_PORT,#01111111b
	anl	a,#00001111b


;------------------------------------------------------------------
; LOW POWER  AUTO SIREN     |||||||||||||||||||||||
;-------------------------------------------------------------------
	jnb	low_p_siren,low_siren_11

	mov	r5,low_p_s_count
	cjne	r5,#00h,A_siren_11
	sjmp	SIR_OFF_on

A_siren_11:
	djnz	low_p_s_count,SIR_ON_on
	sjmp	SIR_OFF_on

low_siren_11:
	jnb	sir_status,siren_ON_on		;from joystick ON
	sjmp	sir_OFF_on

SIREN_ON_on:
	djnz	sir_count,sir_ON_on
	setb	sir_status
;	setb	poweronsiren

SIR_ON_on:
	orl	a,#00000100b

SIR_OFF_on:
	jnb	neutralbit,ponjmp
	anl	a,#11111101b

PONJMP:
	mov	TX_SEND_4,a
	mov	r0,#4
	lcall	send_bits

	lcall	parity_bit


	setb	JR_LED				;RIGHT JOY LED OFF

;----------------------------------------------------------------
;	   NO2 TX DATA REVERSED
;---------------------------------------------------------------

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


;---------------------------------------------------------------
x2_butt_off:
	ljmp	no3_x2_off_data
;---------------------------------------------------------------

function_x2_4:
	cjne	r2,#00000101b,function_x2_5		; X1
;	jb	Joy_Butt_x1y1,x2_butt_off
	jnb	sir_status,x2_butt_off
	mov	r3,x2_data
	mov	x2_data,x1_data 			; data exchange
	lcall	x1_display
	ljmp	no3_x2_data


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
	ljmp	sync_word				; function error

;-----------------------------------------------------------------------


NO3_X2_DATA:
	
	jb	po5045select,x2x2_sel
	mov	a,x2_data
	mov	dptr,#Notch_4500_x2y2
	movc	a,@a+dptr
	ljmp	X2X2DATASEND
x2x2_sel:
	mov	a,x2_data
	mov	dptr,#Notch_5000_x2y2
	movc	a,@a+dptr

X2X2DATASEND:

	mov	TX_SEND_2,a

	mov	r0,#4				; NO2 X1 DATA  4 BIT
	lcall	send_bits			; ~~~~~~~~~~~~~~~~~~

;------------------------------------------------------------------
	mov	x2_data,r3			; reduction x2_data
;------------------------------------------------------------------

NO3_Y2:

;------------------------------------------------------------------------
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

;---------------------------------------------------------------------
y2_butt_off:
	ljmp	no3_y2_off_data
;---------------------------------------------------------------------

function_y2_4:
	cjne	r2,#00000101b,function_y2_5		; X2
;	jb	Joy_Butt_x2y2,y2_butt_off
	jnb	sir_status,y2_butt_off
	mov	r4,y2_data
	mov	y2_data,x2_data 			; data exchange
	lcall	x2_display
	ljmp	no3_y2_data

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
	ljmp	sync_word				; function error

;-------------------------------------------------------------------------

NO3_Y2_DATA:						; send data
	
	jb	po5045select,y2y2_sel
	mov	a,y2_data
	mov	dptr,#Notch_4500_x2y2
	movc	a,@a+dptr
	ljmp	Y2Y2DATASEND
y2y2_sel:
	mov	a,y2_data
	mov	dptr,#Notch_5000_x2y2
	movc	a,@a+dptr

Y2Y2DATASEND:

	mov	TX_SEND_3,a

	mov	r0,#4				; NO3 Y2 DATA  4 BIT
	lcall	send_bits			; ~~~~~~~~~~~~~~~~~~

;-------------------------------------------------------------------
	mov	y2_data,r4			; reduction y2_data
;-------------------------------------------------------------------

	mov	Read_Port,#0ffh

;	clr	p2.3
;	clr	p1.6
	mov	IO_PORT,#01111001b

	mov	r5,#2
	lcall	delay2
	mov	a,Read_Port

;	setb	p2.3
;	setb	p1.6

	mov	IO_PORT,#01111111b
	cpl	a
	anl	a,#11110000b
	swap	a
	mov	TX_SEND_4,a
	mov	r0,#4
	lcall	send_bits

	lcall	parity_bit

;-----------------------------------------------------------------------
;	   NO3 TX DATA REVERSED
;-----------------------------------------------------------------------

NO3_REVERSED:

;//////////////////////////////////////////////////////////////////

	mov	a,x1_notch_d	;X1 / Y1 / X2 / Y2 joystick  notch
	anl	a,x2_notch_d	; display data	Logical AND
	anl	a,y1_notch_d
	anl	a,y2_notch_d

	notch_display

;//////////////////////////////////////////////////////////////////

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
	ljmp	sync_word			; error

;-----------------------------------------------
y2_disp_end:
	mov	y2_data,#010h
	ljmp	no3_y2_data

;----------------------------------------------
;----------------------------------------------

NO4_DATA_WORD:				;NO4 DATA WORD
	jnb	OPT_X,no45_send	
	ljmp	power_down
no45_send:

	mov	Parity_Count,#00h
	mov	a,#000000100b		; NO1 ADD  " 100b "
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
	lcall	send_bits		;YE4 LSB 4bit send

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
	ljmp	power_down			;no5  delete
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

	mov	r0,#8			;YE5/ 8 Bit send
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

;----------auto time delete ------------------
	jnb	OPT_W,sync_0
;---------------------------------------------
	jb	xx1_nondata,sync_0		; XY- DATA
	jb	yy1_nondata,sync_0		; XY- DATA
	jb	xx2_nondata,sync_0		; XY- DATA
	jb	yy2_nondata,sync_0		; XY- DATA

	inc	auto_timer_0
	mov	a,auto_timer_0

	cjne	a,#0ffh,sync_1
	mov	auto_timer_0,#00h

	inc	auto_timer_1
	mov	a,auto_timer_1

;----------------------------------------------------------------------
;AUTO TX DATA or CRANE CONTROL POWER OFF MODE
;	AUTO TIME ( #DATA * 40.96 sec )
;-----------------------------------------------------------------------

	cjne	a,#02fh,sync_1		;  #DATA * 40.96 sec
					;~~~~~~~~~~~~~~~~~~~~~~
	setb	power_LED
	clr	p2.7

	mov	read_port,#01110111b
	mov	r5,#2
	acall	delay2

	setb	p2.7			;power down mode 4 notch led on
	mov	auto_timer_0,#00h
	mov	auto_timer_1,#00h

	setb	vcosw
	setb	pwsw
	mov	pcon,#00000010b 	; POWER DOWN MODE

;-----------< power down / STOP >--------------------------

sync_0:
	mov	auto_timer_0,#00h
	mov	auto_timer_1,#00h
sync_1:


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
	mov	dptr,#Notch_5000_x1y1
	movc	a,@a+dptr
	mov	x1_notch_d,a

	ret

X2_DISPLAY:					;X2
	mov	a,x2_data
	inc	a				;notch display
	mov	dptr,#Notch_5000_x2y2
	movc	a,@a+dptr
	mov	x2_notch_d,a

	ret

Y1_DISPLAY:					;Y1
	mov	a,Y1_data
	inc	a				;notch display
	mov	dptr,#Notch_5000_x1y1
	movc	a,@a+dptr
	mov	y1_notch_d,a

	ret

Y2_DISPLAY:					;Y2
	mov	a,Y2_data
	inc	a				;notch display
	mov	dptr,#Notch_5000_x2y2
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


;-----------------------------------------------------------------------

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

;*********************************************************************
; RF MODUEL MODEL TX / TMX 613A TOKO
; TX FREQUENCY	     / 253.8625Mhz -- 254.9625Mhz (89 Channel)
;
;	CHANNEL SETTING DATA
;
;		B7	B6	B5	B4	B3	B2	B1	B0
;		---	---	---	---	---	---	---	---
; BYTE#1	D	C	B	A	D17	D16	D15	D14
; BYTE#2	D13	D12	D11	D10	D9	D8	D7	D6
; BYTE#3	D5	D4	D3	D2	D1	1	0	0
;
;*****************************************************************

CH_Data_250:
	DB	01111010B	; CH #1 / 3.8625
	DB	10101100B
	DB	01111010B	; CH #2 / 3.8750
	DB	10110100B
	DB	01111010B	; CH #3 / 3.8875
	DB	10111100B
	DB	01111010B	; CH #4 / 3.9000
	DB	11000100B
	DB	01111010B	; CH #5 / 3.9125
	DB	11001100B
	DB	01111010B	; CH #6 / 3.9250
	DB	11010100B
	DB	01111010B	; CH #7 / 3.9375
	DB	11011100B
	DB	01111010B	; CH #8 / 3.9500
	DB	11100100B
	DB	01111010B	; CH #9 / 3.9625
	DB	11101100B
	DB	01111010B	; CH #10 / 3.9750
	DB	11110100B
	DB	01111010B	; CH #11 / 3.9875
	DB	11111100B
	DB	01111011B	; CH #12 / 4.0000
	DB	00000100B
	DB	01111011B	; CH #13
	DB	00001100B
	DB	01111011B	; CH #14
	DB	00010100B
	DB	01111011B	; CH #15
	DB	00011100B
	DB	01111011B	; CH #16 / 4.0500
	DB	00100100B
	DB	01111011B	;CH  #17
	DB	00101100B
	DB	01111011B	;CH  #18
	DB	00110100B
	DB	01111011B	;CH  #19
	DB	00111100B
	DB	01111011B	;CH  #20 / 4.1000
	DB	01000100B
	DB	01111011B	;CH  #21
	DB	01001100B
	DB	01111011B	;CH  #22
	DB	01010100B
	DB	01111011B	;CH  #23
	DB	01011100B
	DB	01111011B	;CH  #24 / 4.1500
	DB	01100100B
	DB	01111011B	;CH  #25
	DB	01101100B
	DB	01111011B	;CH  #26
	DB	01110100B
	DB	01111011B	;CH  #27
	DB	01111100B
	DB	01111011B	;CH  #28 / 4.2000
	DB	10000100B
	DB	01111011B	;CH  #29
	DB	10001100B
	DB	01111011B	;CH  #30
	DB	10010100B
	DB	01111011B	;CH  #31
	DB	10011100B
	DB	01111011B	;CH  #32 / 4.2500
	DB	10100100B
	DB	01111011B	;CH  #33
	DB	10101100B
	DB	01111011B	;CH  #34
	DB	10110100B
	DB	01111011B	;CH  #35
	DB	10111100B
	DB	01111011B	;CH  #36 / 4.3000
	DB	11000100B
	DB	01111011B	;CH  #37
	DB	11001100B
	DB	01111011B	;CH  #38
	DB	11010100B
	DB	01111011B	;CH  #39
	DB	11011100B
	DB	01111011B	;CH  #40 / 4.3500
	DB	11100100B
	DB	01111011B	;CH  #41
	DB	11101100B
	DB	01111011B	;CH  #42
	DB	11110100B
	DB	01111011B	;CH  #43
	DB	11111100B
	DB	01111100B	;CH  #44 / 4.4000
	DB	00000100B
	DB	01111100B	;CH  #45
	DB	00001100B
	DB	01111100B	;CH  #46
	DB	00010100B
	DB	01111100B	;CH  #47
	DB	00011100B
	DB	01111100B	;CH  #48 / 4.4500
	DB	00100100B
	DB	01111100B	;CH  #49
	DB	00101100B
	DB	01111100B	;CH  #50
	DB	00110100B
	DB	01111100B	;CH  #51
	DB	00111100B
	DB	01111100B	;CH  #52 / 4.5000
	DB	01000100B
	DB	01111100B	;CH  #53
	DB	01001100B
	DB	01111100B	;CH  #54
	DB	01010100B
	DB	01111100B	;CH  #55
	DB	01011100B
	DB	01111100B	;CH  #56 / 4.5500
	DB	01100100B
	DB	01111100B	;CH  #57
	DB	01101100B
	db	01111100b	;CH  #58
	db	01110100b
	DB	01111100B	;CH  #59
	DB	01111100B
	db	01111100b	;CH  #60 / 4.6000
	db	10000100b
	DB	01111100B	;CH  #61
	DB	10001100B
	db	01111100b	;CH  #62
	db	10010100b
	DB	01111100B	;CH  #63
	DB	10011100B
	db	01111100b	;CH  #64 / 4.6500
	db	10100100b
	DB	01111100B	;CH  #65
	DB	10101100B
	db	01111100b	;CH  #66
	db	10110100b
	DB	01111100B	;CH  #67
	DB	10111100B
	db	01111100b	;CH  #68 / 4.7000
	db	11000100b
	DB	01111100B	;CH  #69
	DB	11001100B
	db	01111100b	;CH  #70
	db	11010100b
	DB	01111100B	;CH  #71
	DB	11011100B
	db	01111100b	;CH  #72 / 4.7500
	db	11100100b
	DB	01111100B	;CH  #73
	DB	11101100B
	db	01111100b	;CH  #74
	db	11110100b
	DB	01111100B	;CH  #75
	DB	11111100B
	db	01111101b	;CH  #76 / 4.8000
	db	00000100b
	DB	01111101B	;CH  #77
	DB	00001100B
	db	01111101b	;CH  #78
	db	00010100b
	DB	01111101B	;CH  #79
	DB	00011100B
	db	01111101b	;CH  #80 / 4.8500
	db	00100100b
	DB	01111101B	;CH  #81
	DB	00101100B
	db	01111101b	;CH  #82
	db	00110100b
	DB	01111101B	;CH  #83
	DB	00111100B
	db	01111101b	;CH  #84 / 4.9000
	db	01000100b
	DB	01111101B	;CH  #85
	DB	01001100B
	db	01111101b	;CH  #86
	db	01010100b
	DB	01111101B	;CH  #87
	DB	01011100B
	db	01111101b	;CH  #88 / 4.9500
	db	01100100b
	DB	01111101B	;CH  #89
	DB	01101100B


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

Notch_5000_x1y1:			; TRANSMITTER DATA

	db	11111011b	; f-4	0	f
	db	11110111b	; d-4
	db	11111010b	; f-3	2	e
	db	11111011b	; d-3
	db	11111001b	; f-2	4	d
	db	11111101b	; d-2
	db	11111000b	; f-1	6	c
	db	11111110b	; d-1

	db	11111100b	; b-1	8	8
	db	11111110b
	db	11111101b	; b-2	A	9
	db	11111101b
	db	11111110b	; b-3	C	a
	db	11111011b
	db	11111111b	; b-4	E	b
	db	11110111b
	db	00000000b	; zero
	db	11111111b

Notch_5000_x2y2:			; TRANSMITTER DATA

	db	11111011b	; f-4
	db	01111111b	; d-4
	db	11111010b	; f-3
	db	10111111b	; d-3
	db	11111001b	; f-2
	db	11011111b	; d-2
	db	11111000b	; f-1
	db	11101111b	; d-1

	db	11111100b	; b-1
	db	11101111b
	db	11111101b	; b-2
	db	11011111b
	db	11111110b	; b-3
	db	10111111b
	db	11111111b	; b-4
	db	01111111b
	db	00000000b	; zero notch
	db	11111111b



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


;%E

end







