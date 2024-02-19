
;TMX 613 (253.8625 ~ 254.9750Mhz) / MR TYPE Compatible  
;FILE  NAME :  HD25000T.ASM
;CKT   NAME :  POS-5000TPCB
;
;

;WORD ADDRESS / no1- 101b,/ no2- 110b,/ no3-011b,/( no4-100b,/ no5-001b)
                                                 
;OPTION
;P2.4(Z)=MCA SELECTOR  /  P2.5(W)=AUTO TIME DELETE
;P1.7(X)=NO4,NO5  /  P3.2(Y)=MR / RCT SELECTOR(notch data)

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







