  
;TMX 759A (447.2625 -->447.9875 /59CH  / 12.5Khz 
;FILE  NAME :  FCJBDT.ASM
;CKT   NAME :  POS-5000TPCB	
;The LATEST : 2004 / 10 /04 /
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

NO2_8BIT_BUF	data	33h
NO2_4BIT_BUF	data	34h
NO3_8BIT_BUF	data	35h
NO3_4BIT_BUF	data	36h

sir_count	data	3ch
auto_timer_1	data	3dh
low_p_s_count	data	3eh	; battery low power siren count
Parity_Count	data	3fh

TX_SEND_1	data	40h	;send data memory
TX_SEND_2	data	41h
TX_SEND_3	data	42h
TX_SEND_4	data	43h

power_status	data	45h
auto_timer_0	data	46h

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

Read_Port	data	080H	; Port 0
IO_PORT		data	0a0h	; port 2

;-- 20h,21h,22h,23h,24h,25h,26h,27h, DANGER  ----- 
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
;Joy_Butt_X1Y1	bit	p3.6		;JB1
;Joy_Butt_X2Y2	bit	p3.7		;JB2

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

;SEND_BIT	bit	00h		; rx
READ_BIT	bit	01h		;
PARITY_ERR	bit	02h		
crane_tong	bit	03h
neutralbit	bit	04h

base_ch_no	bit	08h		;21H
JOY_test	bit	09h		; H" joystick test mode
sir_status	bit	0ah
low_p_siren	bit	0bh		; battery low power siren
poweronsiren	bit	0ch
scan_11		bit	0dh
scan_22		bit	0eh
starton_set	bit	0fh

;22H(10h~~17h) ?
;25H(18h~~1Fh) chanel_dip_switch/bytes

sync_bit	bit	20h	;24h WORD_FIND 
no1_word_bit	bit	21h
mca_word_bit	bit	22h	
;--23h,24h,25h,26h,27h,~ NO-----
;2Fh(78h~~7Fh) neutral test/ 2dh

ENDS



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
	mov	sir_count,#00h
	mov	pcon,#00000000b
	
	clr	p2.7			;374CK
	clr	low_p_siren		;battery low power siren
	clr	joy_test
	clr	poweronsiren
	clr  	neutralbit
	clr	starton_set
	clr	scan_11
	clr	scan_22
	clr	base_ch_no

	setb	sir_status
	mov	power_status,#4 	; Battery voltage check
	mov	auto_timer_0,#00h
	mov	auto_timer_1,#00h
	mov	NO2_8BIT_BUF,#00h
	mov	NO3_8BIT_BUF,#00h

	clr 	Power_Led

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
	jb	scan_22,TX_DATA_SEND	;1nd Channel data
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
; I/O_ 8bit_ ADDRESS
	mov	IO_PORT,#01110100b	; YE5
	mov	r5,#2
	lcall	delay2
	mov	a,Read_Port
	cpl	a
	mov	IO_PORT,#01111111b

	jnz	neutral_dsp		

; I/O_4bit_ADDRESS  (LIG, SIR, POW, OFF)	;pow det
	mov	IO_PORT,#01111001b
	mov	r5,#2
	lcall	delay2
	mov	a,Read_Port
	cpl	a
	anl	a,#00000010b
	mov	IO_PORT,#01111111b

	jz	SYNC_WORD

neutral_dsp:
	mov	r5,#2
	lcall	delay2
	
	clr	power_led		; ON
	mov	r5,#1
	lcall	delay1

	setb	power_led		;OFF
	mov	r5,#2
	lcall	delay1

	ajmp	Neutral_Test


SYNC_WORD:

;-----------------------------------------------------
; CONTROLL POWER ON /SIREN ( time = 0.10 sec * #data )
;-----------------------------------------------------

	jb	poweronsiren,SIREN_NON	;

; I/O_RFCH_ ADDRESS
	mov	IO_PORT,#01110000b	;auto siren bit det

	mov	r5,#1
	lcall	delay2

	jb	neutralbit,SIREN_NON
	jb	P0.7,SIREN_NON		; P0.7(L)   ASIREN ON
	clr	sir_status		; SIREN_STATUS	" L "
	setb	poweronsiren		;action of siren no
	setb	starton_set
	mov	sir_count,#13		; (( 0.10 sec * #data ))

SIREN_NON:
	mov	IO_PORT,#01111111b

	jnb	Power_Check,Power_L

	ajmp	Power_H
Power_L:
	jb	Power_Check,Power_H	; BATTERY VOLTAGE CHECK

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
	mov	a,#00000001b		;8bit  start bits
	mov	r0,#8
	lcall	send_bits

; I/O_ 8bit_ ADDRESS
	mov	IO_PORT,#01110100b	;YE5
	mov	r5,#2
	lcall	delay2
	mov	a,Read_Port
	cpl	a
	mov	NO2_8BIT_BUF,a		;8bit data bank
	mov	IO_PORT,#01111111b

	mov	a,#00000000b		;8bit
	mov	r0,#8
	lcall	send_bits


; I/O_ OPA/OPB_ ADDRESS
	mov	IO_PORT,#01110010b	;YE3
	mov	r5,#2
	lcall	delay2
	mov	a,Read_Port
	cpl	a
	anl	a,#00001100b
	mov	IO_PORT,#01111111b
	cjne	a,#00001100b,crane_mode
	setb	crane_tong		;crane=0 / tong=1
	ajmp	sync_go
crane_mode:
	clr	crane_tong
sync_go:
	mov	a,#00000000b		;8bit
	mov	r0,#8
	lcall	send_bits


	mov	a,#11000000b		;8bit	 stop bits
	mov	r0,#8
	lcall	send_bits


;---JOYSTICK NO NEUTRAL NO POWER ON ----------

	mov	a,NO2_8BIT_BUF		;8bit data
	jnz	powerclear		;a=1 jmp
	clr	neutralbit
	ajmp	NO1_DATA_WORD
powerclear:
	setb	neutralbit


;-----------------------------------------------------------
; NO1-101b/ MCA-010b/ NO2-011b/ NO3-110b/ N04-100b/ NO5-001b
;-----------------------------------------------------------

NO1_DATA_WORD:
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
;P, 7, 6, 5, 4, 3, 2, 1, dip7, 1, 1,sc2, sc1, (010)   16bit send / FC
;P, 7, 6, 5, 4, 3, 2, 1,    0, 1, 1,  0,   0, (010)              / HITEC
;-------------------------------------------------------

MCA_DATA_WORD:			
	jnb	Power_Check,MCA_DW	
	clr	power_led		;init led short on

MCA_DW:
	mov	Parity_Count,#00h
;-------------------------------------------
;	mov	a,MCA_DW_L		; ADD  "?11??(010)b "  FC TYPE
	mov	a,#01100010b		; HITEC TYPE
;-------------------------------------------	
	mov	TX_SEND_1,a
	mov	r0,#8			; 8 Bit
	lcall	send_bits

	mov	a,channel_0		;FC TYPE/HITEC TYPE
	mov	TX_SEND_2,a
	mov	r0,#7			; 7 bit
	lcall	send_bits
	
	lcall	Parity_Bit		; 1 Bit

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


;----------------------------------------------------------
NO2_DATA_WORD:

	mov	parity_count,#00h
	mov	a,#00000110b			; ADD NO2 " 0 1 1 "
	mov	r0,#3				; NO2 ADD  3 BIT
	mov	TX_SEND_1,a			; ~~~~~~~~~~~~~~
	lcall	send_bits

;--------------------------------------
;12  ----------------------------     1
;LIG,SIR,PW,EM(OFF),MU,MD,AU,AD,B,R,L,F b
;--------------------------------------
; I/O_ 8bit_ ADDRESS (T/L, T/S, M/H, A/U)
;	mov	IO_PORT,#01110100b		;YE5
;	mov	r5,#2
;	lcall	delay2
;	mov	a,Read_Port
;	cpl	a
;	mov	IO_PORT,#01111111b

;-CRANE/TONG INTERLOCK------------------
	jnb	crane_tong,FB_LOCK
	mov	NO2_8BIT_BUF,#00h	

;--------INTERLOCK-------------------------
FB_LOCK:
	mov	a,NO2_8BIT_BUF
	anl	a,#00001001b
	cjne	a,#00001001b,LR_LOCK
	mov	a,NO2_8BIT_BUF
	anl	a,#11110110b
	mov	NO2_8BIT_BUF,a	

LR_LOCK:
	mov	a,NO2_8BIT_BUF
	anl	a,#00000110b
	cjne	a,#00000110b,AUD_LOCK
	mov	a,NO2_8BIT_BUF
	anl	a,#11111001b
	mov	NO2_8BIT_BUF,a	

AUD_LOCK:
	mov	a,NO2_8BIT_BUF
	anl	a,#00110000b
	cjne	a,#00110000b,MUD_LOCK
	mov	a,NO2_8BIT_BUF
	anl	a,#11001111b
	mov	NO2_8BIT_BUF,a	

MUD_LOCK:
	mov	a,NO2_8BIT_BUF
	anl	a,#11000000b
	cjne	a,#11000000b,NO2_8BIT_SEND
	mov	a,NO2_8BIT_BUF
	anl	a,#00111111b
	mov	NO2_8BIT_BUF,a	

NO2_8BIT_SEND:
	mov	a,NO2_8BIT_BUF	
	mov	TX_SEND_2,a
	mov	r0,#8				
	lcall	send_bits			


; I/O_4bit_ADDRESS  (LIG, SIR, POW, OFF)
	mov	IO_PORT,#01111001b
	mov	r5,#2
	lcall	delay2
	mov	a,Read_Port
	cpl	a
	mov	IO_PORT,#01111111b

	anl	a,#00001111b
	mov	NO2_4BIT_BUF,a

	mov	TX_SEND_4,a
	anl	a,#00000011b

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
	orl	a,#00000010b
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

SIR_ON_on:
	orl	a,#00000100b

SIR_OFF_on:
	jnb	neutralbit,PONJMP		
	anl	a,#11111101b			;p_on X

PONJMP:
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
	mov	r0,#8
	lcall	send_bits

	mov	a,TX_SEND_4
	cpl	a
	mov	r0,#4
	lcall	send_bits

	lcall	Parity_Bit


NO3_DATA_WORD:

	mov	parity_count,#00h
;-------------------------------------------------------------------
;	mov	a,#00000011b			; NO3 ADD  " 110b "
	mov	a,#00000100b			; NO4 ADD  " 100b "
;	mov	a,#00000001b			; NO5 ADD  " 001b "
;-------------------------------------------------------------------

	mov	r0,#3				
	mov	TX_SEND_1,a			
	lcall	send_bits

;I/O_8bit_ADDRESS
	mov	IO_PORT,#01110101b	;YE6
	mov	r5,#2
	lcall	delay2
	mov	a,Read_Port
	cpl	a
	mov	IO_PORT,#01111111b


;-CRANE/TONG INTERLOCK------------------
	jb	crane_tong,NO3_SEND
	mov	a,#00h	

NO3_SEND:
	mov	NO3_8BIT_BUF,a
	mov	TX_SEND_2,a
	mov	r0,#8			;YE4/ 8 Bit send
	lcall	send_bits

;-----------------------------------------------------------------
; I/O_4bit_ADDRESS  (LIG, SIR, POW, OFF)
;	mov	IO_PORT,#01111001b
;	mov	r5,#2
;	lcall	delay2
;	mov	a,Read_Port
;	cpl	a
;	mov	IO_PORT,#01111111b

;	anl	a,#00001111b
;	mov	TX_SEND_4,a
;	anl	a,#00000011b

;	cjne	a,#00000010b,start_off3		;strt on det
;	setb	starton_set
;	ajmp	start_13

;start_off3:
;	cjne	a,#00000001b,start_13		;strt off det	
;	clr	starton_set
;	nop
	
;start_13:	
;	jnb	starton_set,start_23
;	mov	a,TX_SEND_4
;	orl	a,#00000010b
;	ajmp	start_send3

;start_23:
;	mov	a,TX_SEND_4

;start_send3:
;-------------------------------
;     LOW POWER  AUTO SIREN     
;-------------------------------

;	jnb	low_p_siren,low_siren_113

;	mov	r5,low_p_s_count
;	cjne	r5,#00h,A_siren_113
;	sjmp	SIR_OFF_on3

;A_siren_113:
;	djnz	low_p_s_count,SIR_ON_on3
;	sjmp	SIR_OFF_on3

;low_siren_113:
;	jnb	sir_status,SIREN_ON_on3		;from joystick ON
;	sjmp	sir_OFF_on3

;SIREN_ON_on3:
;	djnz	sir_count,SIR_ON_on3

;SIR_ON_on3:
;	orl	a,#00000100b

;SIR_OFF_on3:
;	jnb	neutralbit,PONJMP3		
;	anl	a,#11111101b			;p_on X

;PONJMP3:
;	mov	TX_SEND_4,a
;	mov	r0,#4
;	lcall	send_bits
;-----------------------------------------------------------------


;I/O_4bit_ADDRESS
	mov	IO_PORT,#01111001b	;YE8
	mov	r5,#2
	lcall	delay2
	mov	a,Read_Port
	cpl	a
	anl	a,#11110000b
	swap	a
	mov	IO_PORT,#01111111b


;-CRANE/TONG INTERLOCK------------------
	jb	crane_tong,NO3_4B_SEND
	anl	a,#00000010b		;0,0,0,0,L,S,ON,OFFb	

NO3_4B_SEND:
	mov	NO3_4BIT_BUF,a
	mov	TX_SEND_4,a
	mov	r0,#4			;YE4/ 8 Bit send
	lcall	send_bits


	lcall	parity_bit

NO3_REVERSED:

	mov	Parity_Count,#01h
	mov	a,TX_SEND_1
	cpl	a
	mov	r0,#3
	lcall	send_bits

	mov	a,TX_SEND_2
	cpl	a
	mov	r0,#8
	lcall	send_bits
;
;	mov	a,TX_SEND_3
;	cpl	a
;	mov	r0,#4
;	lcall	send_bits


	mov	a,TX_SEND_4
	cpl	a
	mov	r0,#4
	lcall	send_bits

	lcall	Parity_Bit

;------------------------------------------------

POWER_DOWN:
	mov	a,sir_count
	cjne	a,#00h,power_down1
	setb	sir_status

power_down1:
;----------auto time delete ------------------
	jnb	OPT_W,sync_0
;---------------------------------------------
	mov	a,NO2_8BIT_BUF
	jnz	sync_0
;	mov	a,NO2_4BIT_BUF
;	jnz	sync_0
	mov	a,NO3_8BIT_BUF
	jnz	sync_0
;	mov	a,NO3_4BIT_BUF
;	jnz	sync_0


;----L,S,ON,OFFb  no2 4bit/START ON SW CHECK(non data timer delety)	

	mov	IO_PORT,#01111001b
	mov	r5,#2
	lcall	delay2
	mov	a,Read_Port
	mov	IO_PORT,#01111111b
	cpl	a
	anl	a,#00000010b		;----ON bit check
	jnz	sync_0

	inc	auto_timer_0
	mov	a,auto_timer_0

	cjne	a,#0ffh,sync_1
	mov	auto_timer_0,#00h

	inc	auto_timer_1
	mov	a,auto_timer_1

;---------------------------------------------
;AUTO TX DATA or CRANE CONTROL POWER OFF MODE
;---------------------------------------------

	cjne	a,#36,sync_1		;#36 * 34sec(128bit)

	setb	power_LED
	mov	auto_timer_0,#00h
	mov	auto_timer_1,#00h

	mov	IO_PORT,#01111001b
	setb	pwsw			;rx mode
	clr	modem_me

ON_SW_CK:
	mov	r5,#2
	lcall	delay2
	mov	a,Read_Port
	cpl	a
	anl	a,#00000110b		;S,ON,check
	jz	ON_SW_CK

	mov	IO_PORT,#01111111b
	ljmp	INIT


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
	cjne	a,#192,SYNCCHECK		;192
	jb	scan_11,RFCH_SUB
	setb	base_ch_no
	ajmp	RFCH_SUB

SYNCCHECK:
	mov	a,SYNC_CNT1
	cjne	a,#5,ERR_CHECK			;5  128 * #?
	mov	SYNC_CNT1,#00h
	ajmp	RFCH_SUB
	
ERR_CHECK:
	mov	a,ERR_BIT_COUNT			;sync no count	
	cjne	a,#5,MAINSTART			;5
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

;	anl	a,#01111000b
	anl	a,#00011000b		;p,opa,opb clear

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
	jnz	scan_mode			;7dip=1 jmp

	mov	IO_PORT,#01111111b

	mov	MCA_DW_L,#01100010b		;base code
	ret

scan_mode:					;dip.7 on
	mov	IO_PORT,#01111111b

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