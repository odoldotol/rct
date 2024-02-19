
;FILE  NAME :  MR_4500K.ASM  /TMS 613
;CKT   NAME :TCU50,60K
;The LATEST : 1998 / 05 / 30 /
;
;SEONG WEON  ELECTRONICS CO,.LTD
;
;	E D I T     B Y  : KIM	SEONG  WEON
;	OFFICE TELEPHONE :( 032) 652 - 9825
;	HOM    TELEPHONE :(0343)  47 - 1629

;*** TX DATA COUNT	--- R0	    send bit count
;*** opto joystick memo --- R1
;*** function joystick	--- R2,R3,R4
;*** TIME DELAY--- R5,R6,R7
;*** PCB ERROR CONVERSION --- 2DH(BIT ADDRESS)

;WORD ADDRESS / no1- 101b,/ no2- 110b,/ no3-011b,/ no4-010b,/ no5-001b

;OPTION
;p2.4( )=SPA  /  p2.5( )= SPB
;p3.3(Z)=universal / p3.4(W)=auto time delete /
;p1.7(X)=no4,no5 / p3.2(Y)=??????
;------------------------------------------------------------------------
;
;	data definition
;
;------------------------------------------------------------------------


DSEG
Read_Data	data	30h	; Read Data Bank
Address1	data	31h	;
Address2	data	32h


X1_Data 	data	33h	; ADC of IN0
X2_Data 	data	34h	; ADC of IN2
Y1_Data 	data	35h	; ADC of IN1
Y2_Data 	data	36h	; ADC of IN3

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

X1_DATA_OLD	data	47h	;old send data memory
Y1_DATA_OLD	data	48h
X2_DATA_OLD	data	49h
Y2_DATA_OLD	data	4ah

JOY_function	data	4bh
Power_status	data	4ch
auto_timer_0	data	4dh

X1_NOTCH_D	data	50h	;notch display memory
Y1_NOTCH_D	data	51h	;	=
X2_NOTCH_D	data	52h	;	=
Y2_NOTCH_D	data	53h	;	=

wire_mode	data	54h	;wire remocon mode

Read_Port	data	080H	; Port 0
IO_PORT		data	0a0h	; port 2

auto_status	data	20h	;(bit address) nondata check

ENDS

BSEG

Power_Check	bit	p2.6
modem_st	bit	p3.0
modem_sd	bit	P3.1
Power_Led	bit	p3.5
Joy_Butt_X1Y1	bit	p3.6
Joy_Butt_X2Y2	bit	p3.7


;## RF module pin description ##

rst		bit	p1.0
cps		bit	p1.1
rf_si		bit	p1.2
vcosw		bit	p1.3
pwsw		bit	p1.4
lock_out	bit	p1.5

non_data_0	bit	00h		; bit address 20h
non_data_1	bit	01h
non_data_3	bit	02h
non_data_4	bit	03h


siren_2		bit	08h
JOY_test	bit	0ah		; H" joystick test mode
SIR_status	bit	0bh

;JOY_n_test	bit	0ch		; opto type joystick neutral test
low_p_siren	bit	0dh		; battery low power siren
poweronsiren	bit	0eh

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
	sjmp	INIT

	org	0013h		; External 1
	sjmp	init

	org	001bh		; Timer/Counter 1
	sjmp	INIT

	org	0023h		; Serial Port
	sjmp	init

	org	0026h		; Just for debugging
	sjmp	init

;********************************************************************
;*	Initialize	H/W
;********************************************************************


INIT:
	mov	sp,#60h
	mov	psw,#00h
	mov	pcon,#00000000b

	clr	p2.7
	clr	low_p_siren		;battery low power siren
	clr	joy_test
	clr	poweronsiren

	mov	x1_notch_d,#11111111b	;notch data initialize
	mov	x2_notch_d,#11111111b
	mov	y1_notch_d,#11111111b
	mov	y2_notch_d,#11111111b
	mov	Power_status,#4 	; Battery voltage check



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
	setb	siren_2

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

	mov	x1_data_old,#00000000b
	mov	y1_data_old,#00000000b
	mov	x2_data_old,#00000000b
	mov	y2_data_old,#00000000b

	clr	Power_Led		; Power Ind \ LED ON



;-------------------------------------------------------------------------
;  JOYSTICK TEST MODE
;
;initialize joystick start button check to JTM loop again
;initilalize switch ON check to SW_CHECK loop again
;-------------------------------------------------------------------------

JTM:					;start button check
	jnb	joy_butt_x1y1,JTM	; start button on / off status to
	jnb	joy_butt_x2y2,JTM	; RF control


	clr	P1.6			;BUTTON LSB 4BIT CHECK

	mov	r5,#2
	lcall	delay2
	mov	a,Read_Port
	cpl	a

	setb	P1.6

	anl	a,#00001111b

	cjne	a,#00000000b,JTM

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

	mov	wire_mode,a		;wire remocon

	rl	a			; channel data address = a * 2
	mov	Read_Data,a
	mov	dptr,#CH_Data_250
	movc	a,@a+dptr		; channel data byte #1
	mov	RF_SI_Buf_0,a
	mov	a,Read_Data
	inc	a
	movc	a,@a+dptr		; channel data byte #2
	mov	RF_SI_Buf_1,a

; RF Channel Port Disable
	mov	IO_PORT,#01111111b

;--------------------------------------------------------------------------
	mov	a,wire_mode			;wire remocon
	cjne	a,#01111111b,start_rf_module	;RF/CH DIP S/W all ON check
	ajmp	neutral_test
;---------------------------------------------------------------------------

START_RF_MODULE:				; start the RF module
	clr	vcosw				; (1) VCC TX VCO SW ON
	mov	r5,#1				; 20ms delay
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
;	NAME:
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
;=======================================
	setb	cps			; set complement of CPS high
	clr	rst			; set RST low
	mov	r5,#2			; 4 us delay
	lcall	delay2
	mov	a,#00110000b		; reference frequency setting
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

;=======================================
;	RX Frequency Set
;=======================================
	clr	rst			; RX requency setting
	mov	r5,#2			; 4 uS delay
	lcall	delay2
	mov	a,#01100010b		; TX TURN ON
	mov	r0,#8
	lcall	set_channel_sub
	mov	a,#10110000b
	mov	r0,#5
	lcall	set_channel_sub
	mov	a,#00011010b		; channel DIP S/W setting
	mov	r0,#8
	lcall	set_channel_sub
	mov	a,#10000000b		 ;21+1
	mov	r0,#1
	lcall	set_channel_sub
	mov	r5,#4
	lcall	delay2			; 2.5 uS delay
	setb	rst
	mov	r5,#100 		; 20mS delay
	lcall	delay2
	ret

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
	mov	r5,#1
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
	cpl	a
	mov	r1,a

	lcall	opto_joystick
	mov	x1_data,r1		;X1-DATA

	mov	a,Read_Port		; Y1
	cpl	a
	anl	a,#11110000b
	swap	a
	mov	r1,a

	mov	IO_PORT,#01111111b

	lcall	opto_joystick
	mov	y1_data,r1		;Y1-DATA

; I/O_X2Y2_ ADDRESS
	mov	IO_PORT,#01111000b


	mov	r5,#2
	lcall	delay2
	mov	a,Read_Port
	cpl	a
	mov	r1,a

	lcall	opto_joystick
	mov	x2_data,r1		;X2-DATA

	mov	a,Read_Port
	cpl	a
	anl	a,#11110000b
	swap	a
	mov	r1,a

	mov	IO_PORT,#01111111b


	lcall	opto_joystick
	mov	y2_data,r1		;Y2-DATA
;------------------------------------------------------------------------

	mov	2fh,#0ffh
	mov	a,x1_data
	cjne	a,#010h,error_x1
error_1:
	mov	a,y1_data
	cjne	a,#010h,error_y1
error_2:
	mov	a,x2_data
	cjne	a,#010h,error_x2
error_3:
	mov	a,y2_data
	cjne	a,#010h,error_y2

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

	jz	Notch_Disp		; Netural  Status  = ( acc zero )
 
	cpl	a
	mov	read_port,a		; bit address 2Fh
	mov	r5,#2
	lcall	delay2

	setb	p2.7			;  1 notch display  ON

;------------------------------------
	mov	r5,#4
	lcall	delay1

	clr	p2.7
	nop
	nop
	mov	read_port,#0ffh
	nop
	nop
	setb	p2.7			;  1 notch display  OFF

	mov	r5,#6
	lcall	delay1
;----------------------------------------------
	clr	p2.7

	ajmp	Neutral_Test

;----------------------------------------------------------------------
;####  NOTCH DISPPLAY LAMP TEST  ####
;----------------------------------------------------------------------

Notch_Disp:

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

; I/O_RFCH_ ADDRESS
	mov	IO_PORT,#01110000b
	mov	r5,#1
	lcall	delay2

	jb	poweronsiren,SIREN_NON	;

	jb	P0.7,sir_no		; P0.7(L) /74HC240 output/  ASIREN ON

	clr	sir_status		; SIREN_STATUS	" L "
	setb	poweronsiren
	mov	sir_count,#25		; (( 0.10 sec * #data ))
	sjmp	sir_no

SIREN_NON:
	jb	P0.7,sir_no
	clr	siren_2
	mov	sir_count,#25

sir_no:
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
	mov	r1,a

	mov	IO_PORT,#01111111b

 	lcall	opto_joystick
	mov	x1_data,r1

	mov	a,#00000001b		;8bit  start bits
	mov	r0,#8
	lcall	send_bits

; I/O_X1Y1_ADDRESS
	mov	IO_PORT,#01110111b

	mov	r5,#1
	lcall	delay2
	mov	a,Read_Port
	cpl	a
	anl	a,#11110000b
	swap	a
	mov	r1,a

	mov	IO_PORT,#01111111b

	lcall	opto_joystick
	mov	y1_data,r1

	mov	a,#00000000b		;8bit
	mov	r0,#8
	lcall	send_bits

; I/O_x2y2_ ADDRESS
	mov	IO_PORT,#01111000b

	mov	r5,#1
	lcall	delay2
	mov	a,Read_Port
	cpl	a
	mov	r1,a

	mov	IO_PORT,#01111111b

	lcall	opto_joystick
	mov	x2_data,r1

	mov	a,#00000000b		;8bit
	mov	r0,#8
	lcall	send_bits

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

	lcall	opto_joystick
	mov	y2_data,r1

	mov	a,#11000000b		;8bit	 stop bits
	mov	r0,#8
	lcall	send_bits


;--------------------------------------------------------------------------
;UNIVERSAL TYPE SELECTION
	jnb	p3.3,no1_data_word
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
;
;
;--------------------------------------------------------------------------

NO1_DATA_WORD:

	mov	Parity_Count,#00h
	mov	a,#000000101b		; NO1 ADD  " 101 "
	mov	TX_SEND_1,a
	mov	r0,#3
	lcall	send_bits

;I/O_M-ADD_ADDRESS
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

	mov	IO_PORT,#01111111b

	cpl	a
	anl	a,#00000011b		;opa,opb clear
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


;---------------------MCA ID----------------------------
;P, 7, 6, 5, 4, 3, 2, 1, 0, 1, 1, 0, 0, (010)   16bit send
;-------------------------------------------------------

MCA_DATA_WORD:			
	jnb	power_check,MCA_DW	
	clr	power_led		;init led short on

MCA_DW:
	mov	Parity_Count,#00h
	mov	a,#01100010b		; ADD  "01100010b "
	mov	TX_SEND_1,a
	mov	r0,#8			; 8 Bit
	lcall	send_bits

	mov	a,wire_mode
	mov	TX_SEND_2,a
	mov	r0,#7			; 7 bit
	lcall	send_bits
	
	lcall	Parity_Bit		; 1 Bit

;!@!@!@! ---MCA TX DATA REVERSED ---!@!@!@!

	mov	Parity_Count,#01h
	mov	a,TX_SEND_1
	cpl	a
	mov	r0,#8				; 8 Bit
	lcall	send_bits

	mov	a,TX_SEND_2
	cpl	a
	mov	r0,#7				; 5 Bit
	lcall	send_bits

	lcall	Parity_Bit			; 1 Bit

;-------------------------------------------------------------
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
;~~~~~~~~~~~~~~~~~~~~~~~	      / ex)	 ?????000
; address    left	     right	   Y1		   Y2
;	     X	Y	     X	Y	    |		    |
; ?????110 - X1 Y1	     X2 Y2	    |		    |
; ?????001 - Y1 X1	     X2 Y2     <---------> X1  <---------> X2
; ?????010 - X1 X2	     Y1 Y2	    |		    |
; ?????011 - Y1 X2	     X1 Y2	    |		    |
; ?????100 - X1 Y2	     X2 Y1
; ?????101 - Y1 Y2	     X1 X2	  left		  right
; ?????000 - Y1 X1	     Y2 X2
; ?????111 - X2 Y2	     X1 Y1
; ????1000 - X1 Y2	     Y1 X2
;------------------------------------------------------------------------

	mov	r2,joy_function
	cjne	r2,#00000110b,function_y1_0		; Y1
	jb	Joy_Butt_x1y1,y1_butt_off
	jnb	sir_status,y1_butt_off
	mov	r3,y1_data
	lcall	y1_display
	ajmp	no2_y1_data

function_y1_0:
	cjne	r2,#00000001b,function_y1_1		; X1
	jb	Joy_Butt_x1y1,y1_butt_off
	jnb	sir_status,y1_butt_off
	mov	r3,y1_data
	mov	y1_data,x1_data 			; data exchange
	lcall	x1_display
	ajmp	no2_y1_data

function_y1_1:
	cjne	r2,#00000010b,function_y1_2		; X2
	jb	Joy_Butt_x2y2,y1_butt_off
	jnb	sir_status,y1_butt_off
	mov	r3,y1_data
	mov	y1_data,x2_data 			; data exchange
	lcall	x2_display
	ajmp	no2_y1_data

function_y1_2:
	cjne	r2,#00000011b,function_y1_3		; X2
	jb	Joy_Butt_x2y2,y1_butt_off
	jnb	sir_status,y1_butt_off
	mov	r3,y1_data
	mov	y1_data,x2_data 			; data exchange
	lcall	x2_display
	ajmp	no2_y1_data

function_y1_3:
	cjne	r2,#00000100b,function_y1_4		; Y2
	jb	Joy_Butt_x2y2,y1_butt_off
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
	jb	Joy_Butt_x2y2,y1_butt_off
	jnb	sir_status,y1_butt_off
	mov	r3,y1_data
	mov	y1_data,y2_data 			; data exchange
	lcall	y2_display
	ajmp	no2_y1_data

function_y1_5:
	cjne	r2,#00000000b,function_y1_6		; X1
	jb	Joy_Butt_x1y1,y1_butt_off
	jnb	sir_status,y1_butt_off
	mov	r3,y1_data
	mov	y1_data,x1_data 			; data exchange
	lcall	x1_display
	ajmp	no2_y1_data

function_y1_6:
	cjne	r2,#00000111b,function_y1_7		; Y2
	jb	Joy_Butt_x2y2,y1_butt_off
	jnb	sir_status,y1_butt_off
	mov	r3,y1_data
	mov	y1_data,y2_data 			; data exchange
	lcall	y2_display
	ajmp	no2_y1_data

function_y1_7:
	cjne	r2,#00001000b,function_y1_8		; Y2
	jb	Joy_Butt_x2y2,y1_butt_off
	jnb	sir_status,y1_butt_off
	mov	r3,y1_data
	mov	y1_data,y2_data 			; data exchange
	lcall	y2_display
	ajmp	no2_y1_data

function_y1_8:
	ajmp	sync_word				; function error


;-----------------------------------------------------------------------

NO2_Y1_DATA:					;send data

	setb	non_data_0

	mov	a,y1_data
	mov	dptr,#Notch_x1y1
	movc	a,@a+dptr
	mov	TX_SEND_2,a

	mov	y1_data_old,a			;????????????????

	mov	r0,#4				; NO2 X1 DATA  4 BIT
	lcall	send_bits			; ~~~~~~~~~~~~~~~~~~

;-----------------------------------------------------------------------
	mov	y1_data,r3			; reduction y1_data
;----------------------------------------------------------------------

;--------------------------------------------------------------------
; power on siren of non data   ( sir_status    = L )
;--------------------------------------------------------------------

NO2_X1:


;----------------------------------------------------------------------
; FUNCTION  JOYSTCK  X1
;~~~~~~~~~~~~~~~~~~~~~~~	      / ex)	 ?????000
; address    left	     right	   Y1		   Y2
;	     X	Y	     X	Y	    |		    |
; ?????110 - X1 Y1	     X2 Y2	    |		    |
; ?????001 - Y1 X1	     X2 Y2     <---------> X1  <---------> X2
; ?????010 - X1 X2	     Y1 Y2	    |		    |
; ?????011 - Y1 X2	     X1 Y2	    |		    |
; ?????100 - X1 Y2	     X2 Y1
; ?????101 - Y1 Y2	     X1 X2	  left		  right
; ?????000 - Y1 X1	     Y2 X2
; ?????111 - X2 Y2	     X1 Y1
; ????1000 - X1 Y2	     Y1 X2
;------------------------------------------------------------------------

	mov	r2,joy_function
	cjne	r2,#00000110b,function_x1_0		; X1
	jb	Joy_Butt_x1y1,x1_butt_off
	jnb	sir_status,x1_butt_off
	mov	r4,x1_data
	lcall	x1_display
	ajmp	no2_x1_data

function_x1_0:
	cjne	r2,#00000001b,function_x1_1		; Y1
	jb	Joy_Butt_x1y1,x1_butt_off
	jnb	sir_status,x1_butt_off
	mov	r4,x1_data
	mov	x1_data,y1_data 			; data exchange
	lcall	y1_display
	ajmp	no2_x1_data

function_x1_1:
	cjne	r2,#00000010b,function_x1_2		; X1
	jb	Joy_Butt_x1y1,x1_butt_off
	jnb	sir_status,x1_butt_off
	mov	r4,x1_data
	lcall	x1_display
	ajmp	no2_x1_data

function_x1_2:
	cjne	r2,#00000011b,function_x1_3		; Y1
	jb	Joy_Butt_x1y1,x1_butt_off
	jnb	sir_status,x1_butt_off
	mov	r4,x1_data
	mov	x1_data,y1_data 			; data exchange
	lcall	y1_display
	ajmp	no2_x1_data

function_x1_3:
	cjne	r2,#00000100b,function_x1_4		; X1
	jb	Joy_Butt_x1y1,x1_butt_off
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
	jb	Joy_Butt_x1y1,x1_butt_off
	jnb	sir_status,x1_butt_off
	mov	r4,x1_data
	mov	x1_data,y1_data 			; data exchange
	lcall	y1_display
	ajmp	no2_x1_data


function_x1_5:
	cjne	r2,#00000000b,function_x1_6		; Y1
	jb	Joy_Butt_x1y1,x1_butt_off
	jnb	sir_status,x1_butt_off
	mov	r4,x1_data
	mov	x1_data,y1_data 			; data exchange
	lcall	y1_display
	ajmp	no2_x1_data


function_x1_6:
	cjne	r2,#00000111b,function_x1_7		; X2
	jb	Joy_Butt_x2y2,x1_butt_off
	jnb	sir_status,x1_butt_off
	mov	r4,x1_data
	mov	x1_data,x2_data 			; data exchange
	lcall	x2_display
	ajmp	no2_x1_data

function_x1_7:
	cjne	r2,#00001000b,function_x1_8		; X1
	jb	Joy_Butt_x1y1,x1_butt_off
	jnb	sir_status,x1_butt_off
	mov	r4,x1_data
	lcall	x1_display
	ajmp	no2_x1_data

function_x1_8:
	ljmp	sync_word				; function error

;-----------------------------------------------------------------------

NO2_X1_DATA:					; send data

	setb	non_data_1

	mov	a,X1_data
	mov	dptr,#Notch_x1y1
	movc	a,@a+dptr
	mov	TX_SEND_3,a

	mov	x1_data_old,a			;*********

	mov	r0,#4				; NO2 X1 DATA  4 BIT
	lcall	send_bits			; ~~~~~~~~~~~~~~~~~~

;-----------------------------------------------------------------------
	mov	x1_data,r4			; reduction x1_data
;-----------------------------------------------------------------------
;	clr	p2.3
	clr	p1.6

	mov	r5,#2
	lcall	delay2
	mov	a,Read_Port
	cpl	a

	setb	p1.6

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
	jnb	siren_2,SIREN_ON_on

	jnb	sir_status,siren_ON_on		;from joystick ON
	sjmp	sir_OFF_on

SIREN_ON_on:
	djnz	sir_count,sir_ON_on
;	setb	sir_status
	setb	siren_2
;	sjmp	sir_OFF_on
	
SIR_ON_on:
	orl	a,#00000100b

SIR_OFF_on:
	mov	TX_SEND_4,a
	mov	r0,#4
	lcall	send_bits

	lcall	parity_bit

	ljmp	NO2_REVERSED

;-------------------------------------------------------------------------

NO2_BUT_OFF_Y1:

;""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
	clr	non_data_0			; auto_timer  set

;""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
	mov	a,TX_SEND_2
	mov	r0,#4
	lcall	send_bits
	ljmp	NO2_X1

NO2_BUT_OFF_X1:

;"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
	clr	non_data_1			; auto_timer  set

;""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
	mov	a,TX_SEND_3
	mov	r0,#4
	lcall	send_bits

	clr	p1.6

	mov	r5,#2
	lcall	delay2
	mov	a,Read_Port
	cpl	a

	setb	p1.6

	anl	a,#00001111b


;------------------------------------------------------------------
; LOW POWER  AUTO SIREN     |||||||||||||||||||||||
;-------------------------------------------------------------------
	jnb	low_p_siren,low_siren_22

	mov	r5,low_p_s_count
	cjne	r5,#00h,A_siren_22
	sjmp	SIR_OFF_off

A_siren_22:
	djnz	low_p_s_count,SIR_ON_off
	sjmp	SIR_OFF_off

low_siren_22:
	jnb	siren_2,siren_ON_off
	jnb	sir_status,siren_ON_off 	;from joystick OFF
	sjmp	sir_OFF_off

SIREN_ON_off:
	djnz	sir_count,sir_ON_off
;	setb	sir_status
	setb	siren_2
;	sjmp	sir_OFF_off

SIR_ON_off:
	orl	a,#00000100b

SIR_OFF_off:
	mov	TX_SEND_4,a


;""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
;    NO2 AUX 4 BIT DATA  AUTOTIMER
;------------------------------------------------------------------
;	jnz	fulldata_xy1
;	ajmp	nondata_xy1
;fulldata_xy1:
;	setb	non_data_2
;nondata_xy1:

;""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""


	mov	r0,#4
	lcall	send_bits

	lcall	parity_bit


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
;-----------------------------------------------------------------------

NO2_Y1_OFF_DATA:

	cjne	r2,#00000000b,y1_disp_a
	mov	y1_notch_d,#0ffh	; START BUTTON OFF DISPLAY
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
	mov	x1_notch_d,#0ffh
	ajmp	y1_disp_end

y1_disp_g:
	cjne	r2,#00000111b,y1_disp_h
	mov	y2_notch_d,#0ffh
	ajmp	y1_disp_end

y1_disp_h:
	cjne	r2,#00001000b,y1_disp_i
	mov	y2_notch_d,#0ffh
	ajmp	y1_disp_end

y1_disp_i:
	ljmp	sync_word			; error

;--------------------------------------------------------------------------
y1_disp_end:

	mov	a,y1_data_old
	jz	y1_nondata
	cjne	a,#11110001b,y1_sung		; F- 1notch data
	mov	tx_send_2,#00000000b

y1_nondata:
	ljmp	no2_but_off_y1

y1_sung:
	cjne	a,#11110010b,y1_weon		;B- 1notch data
	mov	tx_send_2,#00000000b
	ljmp	no2_but_off_y1

y1_weon:
	cjne	a,#11110101b,y1_shift_1		;F-2
	mov	tx_send_2,#11110001b
	mov	y1_data_old,tx_send_2
	ljmp	no2_but_off_y1

y1_shift_1:
	cjne	a,#11111001b,y1_shift_2		;F-3
	mov	tx_send_2,#11110101b
	mov	y1_data_old,tx_send_2
	ljmp	no2_but_off_y1

y1_shift_2:
	cjne	a,#11111101b,y1_shift_3		;F-4
	mov	tx_send_2,#11111001b
	mov	y1_data_old,tx_send_2
	ljmp	no2_but_off_y1

y1_shift_3:
	cjne	a,#11110110b,y1_shift_4		;B-2
	mov	tx_send_2,#11110010b
	mov	y1_data_old,tx_send_2
	ljmp	no2_but_off_y1

y1_shift_4:
	cjne	a,#11111010b,y1_shift_5		;B-3
	mov	tx_send_2,#11110110b
	mov	y1_data_old,tx_send_2
	ljmp	no2_but_off_y1

y1_shift_5:
	cjne	a,#11111110b,y1_shift_err	;B-4
	mov	tx_send_2,#11111010b
	mov	y1_data_old,tx_send_2
	ljmp	no2_but_off_y1

y1_shift_err:
	ljmp	sync_word


;-----------------------------------------------------------------------

NO2_X1_OFF_DATA:

	cjne	r2,#00000000b,x1_disp_a
	mov	x1_notch_d,#0ffh	;     X1 JOYSTICK
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
	mov	y1_notch_d,#0ffh
	ajmp	x1_disp_end

x1_disp_g:
	cjne	r2,#00000111b,x1_disp_h
	mov	x2_notch_d,#0ffh
	ajmp	x1_disp_end

x1_disp_h:
	cjne	r2,#00001000b,x1_disp_i
	mov	x1_notch_d,#0ffh
	ajmp	x1_disp_end

x1_disp_i:
	ljmp	sync_word			; error

;--------------------------------------------------------------------------
x1_disp_end:


	mov	a,x1_data_old
	jz	x1_nondata
	cjne	a,#11110001b,x1_sung		;R-1
	mov	tx_send_3,#00000000b

x1_nondata:
	ljmp	no2_but_off_x1

x1_sung:
	cjne	a,#11110010b,x1_weon		;L-1
	mov	tx_send_3,#00000000b
	ljmp	no2_but_off_x1

x1_weon:
	cjne	a,#11110101b,x1_shift_1		;R-2
	mov	tx_send_3,#11110001b
	mov	x1_data_old,tx_send_3
	ljmp	no2_but_off_x1

x1_shift_1:
	cjne	a,#11111001b,x1_shift_2		;R-3
	mov	tx_send_3,#11110101b
	mov	x1_data_old,tx_send_3
	ljmp	no2_but_off_x1

x1_shift_2:
	cjne	a,#11111101b,x1_shift_3		;R-4
	mov	tx_send_3,#11111001b
	mov	x1_data_old,tx_send_3
	ljmp	no2_but_off_x1

x1_shift_3:
	cjne	a,#11110110b,x1_shift_4		;L-2
	mov	tx_send_3,#11110010b
	mov	x1_data_old,tx_send_3
	ljmp	no2_but_off_x1

x1_shift_4:
	cjne	a,#11111010b,x1_shift_5		;L-3
	mov	tx_send_3,#11110110b
	mov	x1_data_old,tx_send_3
	ljmp	no2_but_off_x1

x1_shift_5:
	cjne	a,#11111110b,x1_shift_err	;L-4
	mov	tx_send_3,#11111010b
	mov	x1_data_old,tx_send_3
	ljmp	no2_but_off_x1

x1_shift_err:
	ljmp	sync_word

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
; FUNCTION  JOYSTCK  X2
;~~~~~~~~~~~~~~~~~~~~~~~	      / ex)	 ?????000
; address    left	     right	   Y1		   Y2
;	     X	Y	     X	Y	    |		    |
; ?????110 - X1 Y1	     X2 Y2	    |		    |
; ?????001 - Y1 X1	     X2 Y2     <---------> X1  <---------> X2
; ?????010 - X1 X2	     Y1 Y2	    |		    |
; ?????011 - Y1 X2	     X1 Y2	    |		    |
; ?????100 - X1 Y2	     X2 Y1
; ?????101 - Y1 Y2	     X1 X2	  left		  right
; ?????000 - Y1 X1	     Y2 X2
; ?????111 - X2 Y2	     X1 X2
; ????1000 - X1 Y2	     Y1 X2
;------------------------------------------------------------------------


	mov	r2,joy_function
	cjne	r2,#00000110b,function_x2_0		; X2
	jb	Joy_Butt_x2y2,x2_butt_off
	jnb	sir_status,x2_butt_off
	mov	r3,x2_data
	lcall	x2_display
	ljmp	no3_x2_data

function_x2_0:
	cjne	r2,#00000001b,function_x2_1		; X2
	jb	Joy_Butt_x2y2,x2_butt_off
	jnb	sir_status,x2_butt_off
	mov	r3,x2_data
	lcall	x2_display
	ljmp	no3_x2_data

function_x2_1:
	cjne	r2,#00000010b,function_x2_2		; Y1
	jb	Joy_Butt_x1y1,x2_butt_off
	jnb	sir_status,x2_butt_off
	mov	r3,x2_data
	mov	x2_data,y1_data 			; data exchange
	lcall	y1_display
	ljmp	no3_x2_data

function_x2_2:
	cjne	r2,#00000011b,function_x2_3		; X1
	jb	Joy_Butt_x1y1,x2_butt_off
	jnb	sir_status,x2_butt_off
	mov	r3,x2_data
	mov	x2_data,x1_data 			; data exchange
	lcall	x1_display
	ljmp	no3_x2_data

function_x2_3:
	cjne	r2,#00000100b,function_x2_4		; X2
	jb	Joy_Butt_x2y2,x2_butt_off
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
	jb	Joy_Butt_x1y1,x2_butt_off
	jnb	sir_status,x2_butt_off
	mov	r3,x2_data
	mov	x2_data,x1_data 			; data exchange
	lcall	x1_display
	ljmp	no3_x2_data


function_x2_5:
	cjne	r2,#00000000b,function_x2_6		; Y2
	jb	Joy_Butt_x2y2,x2_butt_off
	jnb	sir_status,x2_butt_off
	mov	r3,x2_data
	mov	x2_data,y2_data 			; data exchange
	lcall	y2_display
	ljmp	no3_x2_data


function_x2_6:
	cjne	r2,#00000111b,function_x2_7		; X1
	jb	Joy_Butt_x1y1,x2_butt_off
	jnb	sir_status,x2_butt_off
	mov	r3,x2_data
	mov	x2_data,x1_data 			; data exchange
	lcall	x1_display
	ljmp	no3_x2_data


function_x2_7:
	cjne	r2,#00001000b,function_x2_8		; Y1
	jb	Joy_Butt_x1y1,x2_butt_off
	jnb	sir_status,x2_butt_off
	mov	r3,x2_data
	mov	x2_data,y1_data 			; data exchange
	lcall	y1_display
	ljmp	no3_x2_data

function_x2_8:
	ljmp	sync_word				; function error

;-----------------------------------------------------------------------


NO3_X2_DATA:

	setb	non_data_3

	mov	a,x2_data
	mov	dptr,#Notch_x2y2
	movc	a,@a+dptr
	mov	TX_SEND_2,a

	mov	x2_data_old,a

	mov	r0,#4				; NO2 X1 DATA  4 BIT
	lcall	send_bits			; ~~~~~~~~~~~~~~~~~~

;------------------------------------------------------------------
	mov	x2_data,r3			; reduction x2_data
;------------------------------------------------------------------

NO3_Y2:


;----------------------------------------------------------------------
; FUNCTION  JOYSTCK  Y2
;~~~~~~~~~~~~~~~~~~~~~~~	      / ex)	 ?????000
; address    left	     right	   Y1		   Y2
;	     X	Y	     X	Y	    |		    |
; ?????110 - X1 Y1	     X2 Y2	    |		    |
; ?????001 - Y1 X1	     X2 Y2     <---------> X1  <---------> X2
; ?????010 - X1 X2	     Y1 Y2	    |		    |
; ?????011 - Y1 X2	     X1 Y2	    |		    |
; ?????100 - X1 Y2	     X2 Y1
; ?????101 - Y1 Y2	     X1 X2	  left		  right
; ?????000 - Y1 X1	     Y2 X2
; ?????111 - X2 Y2	     X1 Y1
; ????1000 - X1 Y2	     Y1 X2
;------------------------------------------------------------------------

	mov	r2,joy_function
	cjne	r2,#00000110b,function_y2_0		; Y2
	jb	Joy_Butt_x2y2,y2_butt_off
	jnb	sir_status,y2_butt_off
	mov	r4,y2_data
	lcall	y2_display
	ljmp	no3_y2_data

function_y2_0:
	cjne	r2,#00000001b,function_y2_1		; Y2
	jb	Joy_Butt_x2y2,y2_butt_off
	jnb	sir_status,y2_butt_off
	mov	r4,y2_data
	lcall	y2_display
	ljmp	no3_y2_data

function_y2_1:
	cjne	r2,#00000010b,function_y2_2		; Y2
	jb	Joy_Butt_x2y2,y2_butt_off
	jnb	sir_status,y2_butt_off
	mov	r4,y2_data
	lcall	y2_display
	ljmp	no3_y2_data

function_y2_2:
	cjne	r2,#00000011b,function_y2_3		; Y2
	jb	Joy_Butt_x2y2,y2_butt_off
	jnb	sir_status,y2_butt_off
	mov	r4,y2_data
	lcall	y2_display
	ljmp	no3_y2_data

function_y2_3:
	cjne	r2,#00000100b,function_y2_4		; Y1
	jb	Joy_Butt_x1y1,y2_butt_off
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
	jb	Joy_Butt_x2y2,y2_butt_off
	jnb	sir_status,y2_butt_off
	mov	r4,y2_data
	mov	y2_data,x2_data 			; data exchange
	lcall	x2_display
	ljmp	no3_y2_data

function_y2_5:
	cjne	r2,#00000000b,function_y2_6		; X2
	jb	Joy_Butt_x2y2,y2_butt_off
	jnb	sir_status,y2_butt_off
	mov	r4,y2_data
	mov	y2_data,x2_data 			; data exchange
	lcall	x2_display
	ljmp	no3_y2_data


function_y2_6:
	cjne	r2,#00000111b,function_y2_7		; Y1
	jb	Joy_Butt_x1y1,y2_butt_off
	jnb	sir_status,y2_butt_off
	mov	r4,y2_data
	mov	y2_data,y1_data 			; data exchange
	lcall	y1_display
	ljmp	no3_y2_data

function_y2_7:
	cjne	r2,#00001000b,function_y2_8		; X2
	jb	Joy_Butt_x2y2,y2_butt_off
	jnb	sir_status,y2_butt_off
	mov	r4,y2_data
	mov	y2_data,x2_data 			; data exchange
	lcall	x2_display
	ljmp	no3_y2_data

function_y2_8:
	ljmp	sync_word				; function error

;-------------------------------------------------------------------------

NO3_Y2_DATA:						; send data

	setb	non_data_4

	mov	a,Y2_data
	mov	dptr,#Notch_x2y2
	movc	a,@a+dptr
	mov	TX_SEND_3,a

	mov	y2_data_old,a

	mov	r0,#4				; NO3 Y2 DATA  4 BIT
	lcall	send_bits			; ~~~~~~~~~~~~~~~~~~

;-------------------------------------------------------------------
	mov	y2_data,r4			; reduction y2_data
;-------------------------------------------------------------------

	mov	Read_Port,#0ffh

	clr	p1.6

	mov	r5,#2
	lcall	delay2
	mov	a,Read_Port

	setb	p1.6

	cpl	a
	anl	a,#11110000b
	swap	a
	mov	TX_SEND_4,a
	mov	r0,#4
	lcall	send_bits

	lcall	parity_bit

	ljmp	NO3_REVERSED

;--------------------------------------------------------------------------

NO3_BUT_OFF_X2:

;"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
	clr	non_data_3			; auto timer  set

;"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

	mov	a,TX_SEND_2
	mov	r0,#4
	lcall	send_bits
	ljmp	NO3_Y2

NO3_BUT_OFF_Y2:

;""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
	clr	non_data_4			; auto timer  set

;"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
	mov	a,TX_SEND_3
	mov	r0,#4
	lcall	send_bits

	clr	p1.6

	mov	r5,#2
	lcall	delay2
	mov	a,Read_Port

	setb	p1.6

	cpl	a
	anl	a,#11110000b


;"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
;     NO3 AUX 4BIT DATA AUTO TIMER
;------------------------------------------------------------------
;
;	jnz	fulldata_xy2
;	ajmp	nondata_xy2
;fulldata_xy2:
;	setb	non_data_2
;nondata_xy2:
;
;""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""


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

	ljmp	no4_data_word

;--------------------------------------------------------------------

NO3_X2_OFF_DATA:

	cjne	r2,#00000000b,x2_disp_a
	mov	x2_notch_d,#0ffh		; START BUTTON OFF DISPLAY
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
	mov	y2_notch_d,#0ffh
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
	ljmp	sync_word			; error

;-----------------------------------------------------------------------
x2_disp_end:

	mov	a,x2_data_old
	jz	x2_nondata
	cjne	a,#11110001b,x2_sung		;MU-1
	mov	tx_send_2,#00000000b

x2_nondata:
	ljmp	no3_but_off_x2

x2_sung:
	cjne	a,#11110010b,x2_weon		;MD-1
	mov	tx_send_2,#00000000b
	ljmp	no3_but_off_x2

x2_weon:
	cjne	a,#11110101b,x2_shift_1		;MU-2
	mov	tx_send_2,#11110001b
	mov	x2_data_old,tx_send_2
	ljmp	no3_but_off_x2

x2_shift_1:
	cjne	a,#11111001b,x2_shift_2		;MU-3
	mov	tx_send_2,#11110101b
	mov	x2_data_old,tx_send_2
	ljmp	no3_but_off_x2

x2_shift_2:
	cjne	a,#11111101b,x2_shift_3		;MU-4
	mov	tx_send_2,#11111001b
	mov	x2_data_old,tx_send_2
	ljmp	no3_but_off_x2

x2_shift_3:
	cjne	a,#11110110b,x2_shift_4		;MD-2
	mov	tx_send_2,#11110010b
	mov	x2_data_old,tx_send_2
	ljmp	no3_but_off_x2

x2_shift_4:
	cjne	a,#11111010b,x2_shift_5		;MD-3
	mov	tx_send_2,#11110110b
	mov	x2_data_old,tx_send_2
	ljmp	no3_but_off_x2

x2_shift_5:
	cjne	a,#11111110b,x2_shift_err	;MD-4
	mov	tx_send_2,#11111010b
	mov	x2_data_old,tx_send_2
	ljmp	no3_but_off_x2

x2_shift_err:
	ljmp	sync_word


;-----------------------------------------------------------------------

NO3_Y2_OFF_DATA:

	cjne	r2,#00000000b,y2_disp_a
	mov	y2_notch_d,#0ffh		;     Y2 JOYSTICK
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
	ljmp	sync_word			; error

;--------------------------------------------------------------------------
y2_disp_end:


	mov	a,y2_data_old
	jz	y2_nondata
	cjne	a,#11110001b,y2_sung		;AU-1
	mov	tx_send_3,#00000000b

y2_nondata:
	ljmp	no3_but_off_y2

y2_sung:
	cjne	a,#11110010b,y2_weon		;AD-1
	mov	tx_send_3,#00000000b
	ljmp	no3_but_off_y2

y2_weon:
	cjne	a,#11110101b,y2_shift_1		;AU-2
	mov	tx_send_3,#11110001b
	mov	y2_data_old,tx_send_3
	ljmp	no3_but_off_y2

y2_shift_1:
	cjne	a,#11111001b,y2_shift_2		;AU-3
	mov	tx_send_3,#11110101b
	mov	y2_data_old,tx_send_3
	ljmp	no3_but_off_y2

y2_shift_2:
	cjne	a,#11111101b,y2_shift_3		;AU-4
	mov	tx_send_3,#11111001b
	mov	y2_data_old,tx_send_3
	ljmp	no3_but_off_y2

y2_shift_3:
	cjne	a,#11110110b,y2_shift_4		;AD-2
	mov	tx_send_3,#11110010b
	mov	y2_data_old,tx_send_3
	ljmp	no3_but_off_y2

y2_shift_4:
	cjne	a,#11111010b,y2_shift_5		;AD-3
	mov	tx_send_3,#11110110b
	mov	y2_data_old,tx_send_3
	ljmp	no3_but_off_y2

y2_shift_5:
	cjne	a,#11111110b,y2_shift_err	;AD-4
	mov	tx_send_3,#11111010b
	mov	y2_data_old,tx_send_3
	ljmp	no3_but_off_y2

y2_shift_err:
	ljmp	sync_word

;---------------------------------------------------------------------


NO4_DATA_WORD:
;-------------------------------!!
	jnb	p1.7,no4_5_start	;no4/no5 selector(X)
	ajmp	power_down
;-----------------------------------------------------------

NO4_5_START:
	mov	Parity_Count,#00h
	mov	a,#00000010b		;no4 add  " 010 "
	mov	r0,#3
	mov	TX_SEND_1,a
	acall	send_bits

	mov	IO_PORT,#01110011b

	mov	r5,#2
	lcall	delay2
	mov	a,Read_Port
	cpl	a
	mov	TX_SEND_2,a
	mov	r0,#8

	mov	IO_PORT,#01111111b

	acall	send_bits		; 8bits

	mov	IO_PORT,#01110100b

	mov	r5,#2
	lcall	delay2
	mov	a,Read_port

	mov	IO_PORT,#01111111b	

	cpl	a
	anl	a,#00001111b
	mov	TX_SEND_3,a
	mov	r0,#4			; 4bits
	acall	send_bits

	acall	Parity_bit		; 1bits

;  NO4 TX DATA	REVERSED      ********************

	mov	Parity_Count,#01h
	mov	a,TX_SEND_1
	cpl	a
	mov	r0,#3
	acall	send_bits

	mov	a,TX_SEND_2
	cpl	a
	mov	r0,#8
	acall	send_bits

	mov	a,TX_SEND_3
	cpl	a
	mov	r0,#4
	acall	send_bits

	acall	Parity_bit

;;------------------------------------------------------------------------

;NO5_DATA_WORD:
	mov	Parity_Count,#00h
	mov	a,#00000001b		;no5 add  " 100 "
	mov	r0,#3
	mov	TX_SEND_1,a
	acall	send_bits

	mov	IO_PORT,#01110101b

	mov	r5,#2
	lcall	delay2
	mov	a,Read_Port
	cpl	a
	mov	TX_SEND_2,a
	mov	r0,#8

	mov	IO_PORT,#01111111b

	acall	send_bits		; 8bits

	mov	IO_PORT,#01110100b

	mov	r5,#2
	lcall	delay2
	mov	a,Read_port

	mov	IO_PORT,#01111111b	

	cpl	a
	anl	a,#11110000b
	swap	a
	mov	TX_SEND_3,a
	mov	r0,#4			; 4bits
	acall	send_bits

	acall	Parity_bit		; 1bits

;  NO5 TX DATA	REVERSED      ********************

	mov	Parity_Count,#01h
	mov	a,TX_SEND_1
	cpl	a
	mov	r0,#3
	acall	send_bits

	mov	a,TX_SEND_2
	cpl	a
	mov	r0,#8
	acall	send_bits

	mov	a,TX_SEND_3
	cpl	a
	mov	r0,#4
	acall	send_bits

	acall	Parity_bit

;------------------------------------------------

POWER_DOWN:
	mov	a,sir_count
	cjne	a,#00h,power_down1
	setb	sir_status

power_down1:
;----------auto time delete ------------------
	jnb	p3.4,sync_0
;---------------------------------------------
	jb	non_data_0,sync_0		; X1 DATA
	jb	non_data_1,sync_0		; Y1 DATA

	jb	non_data_3,sync_0		; X2 DATA
	jb	non_data_4,sync_0		; Y2 DATA

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

	cjne	a,#1fh,sync_1		;  #DATA * 40.96 sec
					;~~~~~~~~~~~~~~~~~~~~~~
	setb	power_LED
	clr	p2.7

	mov	read_port,#01110111b
	mov	r5,#2
	acall	delay2

	setb	p2.7			;4 notch led on
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
	mov	dptr,#Notch_x1y1
	movc	a,@a+dptr
	mov	x1_notch_d,a

	ret

X2_DISPLAY:					;X2
	mov	a,x2_data
	inc	a				;notch display
	mov	dptr,#Notch_x2y2
	movc	a,@a+dptr
	mov	x2_notch_d,a

	ret

Y1_DISPLAY:					;Y1
	mov	a,Y1_data
	inc	a				;notch display
	mov	dptr,#Notch_x1y1
	movc	a,@a+dptr
	mov	y1_notch_d,a

	ret

Y2_DISPLAY:					;Y2
	mov	a,Y2_data
	inc	a				;notch display
	mov	dptr,#Notch_x2y2
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

	ret

opto_1: 					;back 1
	cjne	a,#00000010b,opto_2
	mov	r1,#08h

	ret

opto_2: 					;back 2
	cjne	a,#00000110b,opto_3
	mov	r1,#0ah

	ret

opto_3: 					;back 3
	cjne	a,#00001110b,opto_4
	mov	r1,#0ch

	ret

opto_4: 					;back 4
	cjne	a,#00001010b,opto_5
	mov	r1,#0eh

	ret

opto_5: 					;for 1
	cjne	a,#00000001b,opto_6
	mov	r1,#06h

	ret

opto_6: 					;for 2
	cjne	a,#00000101b,opto_7
	mov	r1,#04h

       	ret

opto_7: 					;for 3
	cjne	a,#00001101b,opto_8
	mov	r1,#02h

	ret

opto_8: 					;for 4
	cjne	a,#00001001b,opto_9
	mov	r1,#00h

	ret

opto_9: 					;zero
	mov	r1,#010h

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
;     RF CHANNEL DATA

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


;MR-5500 TYPE NOTCH SEND/DISPLAY DATA
;----------------------------------------------------------------------
;Notch_x1y1:			; TRANSMITTER DATA
;
;	db	11111011b	; f-4	0	f
;	db	11110111b	; d-4
;	db	11111010b	; f-3	2	e
;	db	11111011b	; d-3
;	db	11111001b	; f-2	4	d
;	db	11111101b	; d-2
;	db	11111000b	; f-1	6	c
;	db	11111110b	; d-1
;
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

;Notch_x2y2:			; TRANSMITTER DATA

;	db	11111011b	; f-4
;	db	01111111b	; d-4
;	db	11111010b	; f-3
;	db	10111111b	; d-3
;	db	11111001b	; f-2
;	db	11011111b	; d-2
;	db	11111000b	; f-1
;	db	11101111b	; d-1
;
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



;MR-4500 SYSTEM SEND/DISPLAY DATA
;----------------------------------------------------------------------
Notch_x1y1:			; TRANSMITTER DATA

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

Notch_x2y2:			; TRANSMITTER DATA

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

;----------------------------------------------------------

