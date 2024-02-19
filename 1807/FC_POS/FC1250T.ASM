;TMX 759A (447.6625 -->447.9875 /  12.5Khz
;FILE  NAME : FC1250T.ASM  
;FC120T --> FC550RX
;RCTECH CO,.
;
;	E D I T     B Y  : KIM	SEONG  WEON
;	OFFICE TELEPHONE :(02)2639 - 8310

;*** TX DATA COUNT	--- R0	    send bit count
;*** TIME DELAY--- R5,R6,R7
;interlock , bit add 02bh,02ch
;key data conversion , bit add  02dh,02eh
;word_find 24h,
;WORD ADD/ no1- 101b/ mca-010b/ no2- 110b/ no3-011b/ no4-100b/ no5-001b



;------------------------------------------------------------------------
;
;	data definition
;
;------------------------------------------------------------------------


DSEG
SIR_count	data	30h
low_p_s_count	data	31h	; battery low power siren count
channel_0	data	32h	;send channel
channel_1	data	33h	;seting	channel
CHBUF1		data	34h
chBUF2		data	35h
ERR_BIT_COUNT	data	36h
SYNC_CNT0	data	37h
SYNC_CNT1	data	38h
PATTERN1	data	39h
PATTERN2	data	3ah
PATTERN3	data	3bh
PATTERN4	data	3ch
BIT_CONT_32	data	3dh
ADDRESS1	data	3eh
ADDRESS2	data	3fh
PARITY_BYTE	data	40h

Parity_Count	data	44h
TX_SEND_1	data	45h	;send data memory
TX_SEND_2	data	46h
TX_SEND_3	data	47h
TX_SEND_4	data	48h

Power_status	data	49h	;low power LED on/off
auto_timer_0	data	4ah	;non data check count_1
auto_timer_1	data	4bh	;non data check count_2
keyincount	data	4ch	;3-input clear
SQ_L_CNT	data	4dh
channel_base	data	4eh
MCA_DW_L	data	4fh
ch_dip_sw	data	50h

Read_Port	data	080h	; Port 0
Key_in		data	0a0h	; Port 2(LSB 4bit)

WORD_FIND	data	24h
ENDS


BSEG

Power_Check	bit	p2.7	;/LBO
modem_st	bit	p3.4
modem_sd	bit	P3.1
modem_rt	bit	p3.3
modem_rd	bit	p3.0
modem_me	bit	p3.2
Power_LED	bit	p1.7


;## RF module pin description ##

rst		bit	p1.0
cps		bit	p1.1
rf_si		bit	p1.2
;vcosw		bit	p1.3		;NC
pwsw		bit	p1.4		;759 L-->TX / H-->RX
lock_out	bit	p1.5
sq_out		bit	p1.6

;---KEY IN
scan_y1		bit	p2.4
scan_y2		bit	p2.5
scan_y3		bit	p2.6

power_off	bit	p3.7		;tx power off port

low_p_siren	bit	00h		;20h
sir_status	bit	01h
TX_on_siren	bit	02h
set_status	bit	03h
READ_BIT	bit	04h
PARITY_ERR	bit	05h
base_ch_no	bit	06h
;scan_mark	bit	07h		;scan mode
scan_11		bit	08h		;21h
scan_22		bit	09h
;outfrq_ck	bit	0ah
MAIN_H		bit	0bh
SUB_H		bit	0ch


sync_bit	bit	20h		;WORD_FIND 24H
no1_word_bit	bit	21h
mca_word_bit	bit	22h	
;--23h,24h,25h,26h,27h,NO-----

ENDS

;********************************************************************
;*	Interrupt Vector
;********************************************************************

	org	0000h
	ajmp	init		; Reset

	org	0003h		; External 0
	ajmp	init

	org	000bh		; Timer/Counter 0
	ajmp	init

	org	0013h		; External 1
	ljmp	int_1

	org	001bh		; Timer/Counter 1
	ajmp	init

	org	0023h		; Serial Port
	ajmp	init

	org	0026h		; Just for debugging
	ajmp	init

;********************************************************************
;*	Initialize	H/W
;********************************************************************


INIT:
	mov	sp,#60h
	mov	psw,#00h
	mov	pcon,#00h
	mov	power_status,#4
	mov	p2,#11111111b
	mov	auto_timer_0,#00h
	mov	auto_timer_1,#00h

	clr	low_p_siren		;battery low power siren
	clr	TX_on_siren
;	clr	outfrq_ck
;	clr	scan_mark

	setb	MAIN_H			;init  MAIN HOIST SETTING
	clr	SUB_H

	setb	rst			;RF control initialize
	setb	si
	setb	cps

	setb	modem_sd
	setb	modem_rd
	setb	sir_status		;Auto siren control

;---------------------------------
;INT KEY CHECK
;key input(y1,y2_8bit)
	mov	a,#11111111b
	mov	p2,a
	clr	scan_y1
	mov	r5,#2
	lcall	delay2
	mov	a,Key_in
	cpl	a
	anl	a,#00001111b
	mov	r1,a			;LSB 4bit
	setb	scan_y1

	mov	a,#11111111b
	mov	p2,a
	clr	scan_y2
	mov	r5,#2
	lcall	delay2
	mov	a,Key_in
	cpl	a
	swap	a			;MSB 4bit
	anl	a,#11110000b
	orl	a,r1
	setb	scan_y2
	mov	02bh,a			;58h---5fh(2bh)
;-------------------end

;key input(y3 2bit)
	mov	a,#11111111b
	mov	p2,a	
	clr	scan_y3
	mov	r5,#2
	lcall	delay2
	mov	a,Key_in
	cpl	a
	anl	a,#00001111b
	setb	scan_y3
	mov	02ch,a	
;------------------end

	mov	a,02bh
	jnz	DANGER
	mov	a,02ch
	jnz	DANGER
	ajmp	start_120t

DANGER:
	clr	Power_Led		;LED ON
	mov	r5,#1
	lcall	delay1

	setb	Power_Led		;LED OFF
	mov	r5,#20
	lcall	delay1

	jb	p3.7,DANGER		

	clr	p3.7			;TX POWER(VDD) OFF		

	mov	r5,#200
	lcall	delay1


start_120t:
	clr	Power_Led		; Power Ind \ LED ON

;----------------------------------------------------------------
;POWER_ON
;TRANSMITTER(TX)  POWER  ON    SIREN ( time = 0.10 sec * #data )
;----------------------------------------------------------------
	mov	02eh,#00000010b			; POWER ON BIT
	setb	TX_on_siren			; control on siren 
	clr	sir_status			;
	mov	sir_count,#30			; (( 0.10 sec * #data ))

RF_ON:
	lcall	CH_ID_INPUT
	mov	channel_base,channel_0

scan_set_1:
	mov	a,channel_0
	rl	a
	mov	channel_1,a
	mov	dptr,#CH_Data_447
	movc	a,@a+dptr		; channel data byte #1
	mov	CHBUF1,a

	mov	a,channel_1
	inc	a
	movc	a,@a+dptr		; channel data byte #2
	mov	CHBUF2,a

	setb	p3.6			; RF Channel Port Disable


;=================================================
;	Reference Frequency Set
;=================================================
	setb	sq_out			;SQ INIT L
	setb	cps			; set complement of CPS high
	clr	rst			; set RST low
	mov	r5,#1			; 4 us delay
	lcall	delay2
	mov	a,#11111111b		;<-----D21
	mov	r0,#8			; 12.5 kHz
	acall	set_channel_sub
	mov	a,#00010000b
	mov	r0,#8
	acall	set_channel_sub
	mov	a,#00000100b
	mov	r0,#6			;<---D1, 5+1(NC)
	acall	set_channel_sub
	mov	r5,#1
	lcall	delay2			; 4 uS delay
	setb	rst
	mov	r5,#1 			;20, 20mS delay
	lcall	delay2

;=======================================
;	TX/RX Frequency Set
;=======================================
	clr	rst			; TX requency setting
	mov	r5,#1			; 4 uS delay
	lcall	delay2
	mov	a,#10100100b		; TX TURN ON
	mov	r0,#8
	acall	set_channel_sub

	mov	a,CHBUF1		
	mov	r0,#8
	acall	set_channel_sub

	mov	a,CHBUF2		; Channel setting
	mov	r0,#6
	acall	set_channel_sub
	
	mov	r5,#1
	lcall	delay2			; 4uS delay
	setb	rst
	mov	r5,#2	 		; 4mS delay
	lcall	delay2

;-RX-----------------------------
	jb	scan_22,TX_DATA_SEND	;1st Channel data
	setb	pwsw			;rx
	clr	modem_me
	ljmp	RECEIVER

;-TX-----------------------------
TX_DATA_S:
	clr	Power_Led		;on
	mov	r5,#2
	lcall	delay1

TX_DATA_SEND:
	clr	pwsw			;tx
	setb	Power_Led		;off
	setb	modem_me
;---------------------------------


SYNC_WORD:
;	lcall	CH_ID_INPUT

;0-------------------------->32 BIT<---------------------------31
;1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 1
;start-------------------------------------------------------stop
	jb	TX_on_siren,siren_non
	clr	sir_status
	mov	sir_count,#30

siren_non:
	jnb	power_check,power_L
	ajmp	sync_data

power_L:
	jb	power_check,SYNC_data		
;----------------------------------------------------------------
;	POWER LOW -auto siren/power lamp on,off 
; siren on time [ low_P_S_count (0.10sec) * #data	
;----------------------------------------------------------------
	jb	low_P_siren,lowpowersiren
	setb	low_P_siren			;1 loop start
	mov	low_P_S_count,#50
	
lowpowersiren:
	djnz	power_status,led_off
	clr	Power_Led			;led  on
	mov	power_status,#5
	ajmp	sync_data

led_off:
	setb	Power_Led			;led  off
;================================================================


SYNC_data:
	mov	a,#00000001b		;8bit  start bits(1---8)
	mov	r0,#8
	lcall	send_bits

;key input(y1,y2_8bit)
	mov	a,#11111111b
	mov	p2,a
	clr	scan_y1
	mov	r5,#2
	lcall	delay2
	mov	a,Key_in
	cpl	a
	anl	a,#00001111b
	mov	r1,a			;LSB 4bit
	setb	scan_y1

	mov	a,#11111111b
	mov	p2,a
	clr	scan_y2
	mov	r5,#2
	lcall	delay2
	mov	a,Key_in
	cpl	a
	swap	a			;MSB 4bit
	anl	a,#11110000b
	orl	a,r1
	setb	scan_y2
	mov	02bh,a			;58h---5fh(2bh)
;-------------------end

;------- DATA  CONVERSION ---------------------------------
;-----02eh------     ----------02dh----------
;  73   72  71  70   6F 6E   6D  6C   6B  6A  69  68 -- bit add
;  3    2   1   0    7   6   5   4    3   2   1   0 --->bit addess
; 12   11  10   9    8   7   6   5    4   3   2   1 --->12bit send 
; LIG, SIR, PW, EM,  MU, MD, AU, AD,  B,  R,  L,  F  --->12bit send data
;                                     W,  N,  S,  E
;----------------------------------------------------------
;POWER DET
	jb	p3.7,control_on		
	mov	02eh,#00000001b		;RX CONTROL ON RELAY OFF
	clr	p3.7			;TX POWER(VDD) OFF		


control_on:
	mov	02dh,#00000000b		;1--8 	(02dh)-8bit send data
					;	68h---6fh(2dh)
	mov	a,02bh			;	70h---77h(2eh)
	rrc 	a
	mov	6fh,c
	rrc	a
	mov	68h,c
	rrc	a
	mov	69h,c		;
	rrc	a
	mov	73h,c
	rrc	a
	mov	72h,c
	rrc	a
	mov	6eh,c		;
	rrc	a
	mov	6bh,c
	rrc	a
	mov	6ah,c

	mov	a,#00000000b		;8bit (9---16)
	mov	r0,#8
	lcall	send_bits

;key input(y3 2bit)
	mov	a,#11111111b
	mov	p2,a	
	clr	scan_y3
	mov	r5,#2
	lcall	delay2
	mov	a,Key_in
	cpl	a
	setb	scan_y3
	mov	02ch,a	
;------------------end


	jb	6fh,NOT_SEL	;MU DET
	jb	6eh,NOT_SEL	;MD DET
	ajmp	MASU_SEL
NOT_SEL:
	ajmp	SEL_EXIT


MASU_SEL:
	rrc	a
	mov	6dh,c		;AU

MA_H:
	jnc	AD_ADC
	setb	MAIN_H		; MAIN HOIST SET
	clr	SUB_H
	setb	Power_Led

AD_ADC:
	rrc	a
	mov	6ch,c		;AD

	jnc	SEL_EXIT	
	setb	SUB_H		; SUB HOIST SET
	clr	MAIN_H
	setb	Power_Led
SEL_EXIT:

;****  5ah --  S11
;****  5bh --  S12	 



;-----------------------------------------------------------

	mov	a,#00000000b		;8bit (17---24)
	mov	r0,#8
	lcall	send_bits

;---------------------
;  3-INPUT CLEAR
;---------------------
	clr	c
	mov	keyincount,#00000000b
	mov	r0,#8
	mov	a,02dh

key_count:
	rlc	a
	jc	carryset
	djnz	r0,key_count
	ajmp	inputcheck

carryset:
	inc	keyincount
	djnz	r0,key_count

inputcheck:
	jnb	072h,siren_check	;siren bit
	inc	keyincount

siren_check:
	jnb	073h,light_check	;light bit
	inc	keyincount

light_check:
	mov	a,keyincount		;3-key in check
	cjne	a,#3,check_1

check_1:
	jc	sync_32end		;c-0 if clear	
	mov	02dh,#00000000b
	clr	072h			;siren clear
	clr	073h			;light clear

sync_32end:
	mov	a,#11000000b		;8bit  (25---32) stop bits
	mov	r0,#8
	lcall	send_bits
	

;INTERLOCK--------------------------------------------------
	mov	a,02dh

	rrc	a
	anl	c,6bh		;F/B	interlock
	jnc	next_1
	clr	68h
	clr	6bh
	
next_1:
	rrc	a
	anl	c,6ah		;L/R	interlock
	jnc	next_2
	clr	69h
	clr	6ah

next_2:
	rrc	a
	rrc	a
	rrc	a
	anl	c,6dh		;AU/AD	interlock
	jnc	next_3
	clr	6ch
	clr	6dh

	clr	MAIN_H		;MAIN/ SUB HOIST  CLEAR
	clr	SUB_H
next_3:
	rrc	a
	rrc	a
	anl	c,6fh		;MU/MD	interlock
	jnc	no1_data_word
	clr	6eh
	clr	6fh

;-------------------------------------------------------
;OPA, OPB, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1     12bit send
;-------------------------------------------------------

NO1_DATA_WORD:				;M-ADDESS / OPA,OPB   SEND	

	mov	Parity_Count,#00h
	mov	a,#000000101b		; NO1 ADD  " 101 "
	mov	TX_SEND_1,a
	mov	r0,#3			; 3 Bit
	lcall	send_bits

	clr	p3.5
	mov	r5,#2
	lcall	delay2
	mov	a,Read_Port
	cpl	a
	mov	TX_SEND_2,a

	setb	p3.5

	mov	r0,#8			; 8 Bit
	lcall	send_bits
	
	clr	p3.6
	mov	r5,#2
	lcall	delay2
	mov	a,Read_Port
	cpl	a
	anl	a,#00000011b		;opA/opB=L   /H=> orl=#00001100b
	setb	p3.6

	mov	TX_SEND_3,a		; opA/opB = L
	mov	r0,#4			; 4 Bit
	lcall	send_bits
	
	lcall	Parity_Bit		; 1 Bit

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
;P, 0, 6, 5, 4, 3, 2, 1, 0, 1, 1, 0, 0, (010)   16bit send
;-------------------------------------------------------

MCA_DATA_WORD:			

	jnb	power_check,MCA_DW
	clr	power_led

MCA_DW:
	mov	Parity_Count,#00h
;	mov	a,#01100010b		; base code  "01100010b "
	mov	a,MCA_DW_L

	mov	TX_SEND_1,a
	mov	r0,#8			; 8 Bit
	lcall	send_bits

	mov	a,channel_0
	mov	TX_SEND_2,a		; 6bit MCA ID
	mov	r0,#7			; 7 Bit
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
	mov	r0,#7				; 7 Bit
	lcall	send_bits

	lcall	Parity_Bit			; 1 Bit

;-------------------------------------------------------------------------
NO2_DATA_WORD:		;BUTTON 12 CHANNEL  SEND 

	mov	Parity_Count,#00h
	mov	a,#000000110b		; NO2 ADD  "011"
	mov	TX_SEND_1,a
	mov	r0,#3			; 3 bit
	lcall	send_bits

;- POWER ON SIREN DATA DELETE ----------

	jnb	sir_status,data_delete
	mov	a,02dh			;bit add(key data)
	ajmp	non_data_check

data_delete:
	mov	a,#00000000b
	mov	02dh,a
non_data_check:
	jnz	set_data
	clr	set_status	
	ajmp	zero_data
set_data:	
	setb	set_status
zero_data:

;--F B CHECK      E/W
	mov	a,02dh
	anl	a,#00000001b		;F DET / E
	cjne	a,#00000001b,B_check
	mov	a,#00000001b
	mov	TX_SEND_2,a
	ajmp	FB_send
B_check:
	mov	a,02dh
	anl	a,#00001000b		;B DET / W
	cjne	a,#00001000b,FB_not
	mov	a,#00000010b
	mov	TX_SEND_2,a
	ajmp	FB_send
FB_not:
	mov	a,#00000000b
	mov	TX_SEND_2,a	
FB_send:
	mov	r0,#4			;FB 4 bit
	lcall	send_bits

;--R L CHECK        N/S  
	mov	a,02dh
	anl	a,#00000100b		;R DET / N
	cjne	a,#00000100b,L_check
	mov	a,#00000001b
	mov	TX_SEND_3,a
	ajmp	RL_send
L_check:
	mov	a,02dh
	anl	a,#00000010b		;L DET / S
	cjne	a,#00000010b,RL_not
	mov	a,#000000010b
	mov	TX_SEND_3,a
	ajmp	RL_send
RL_not:
	mov	a,#00000000b
	mov	TX_SEND_3,a	
RL_send:
	mov	r0,#4			;RL 4 bit
	lcall	send_bits


	mov	a,02eh			;4 bit

;--------------------------------------------------------------------
; LOW POWER SIREN
;--------------------------------------------------------------------
	jnb	low_P_siren,low_siren
	mov	r5,low_P_S_count
	cjne	r5,#00h,A_siren
	sjmp	sir_off
A_siren:
	djnz	low_P_S_count,sir_on
	sjmp	sir_off
low_siren:
	jnb	sir_status,low_siren_on
	sjmp	sir_off
low_siren_on:
	djnz	sir_count,sir_on
	setb	sir_status
	sjmp	sir_off
sir_on:
	orl	a,#00000100b		
sir_off:
	mov	TX_SEND_4,a		
	mov	r0,#4			; 4 bit
	lcall	send_bits

	lcall	Parity_Bit		; 1 bit



;!@!@!@! ---NO2 TX DATA REVERSED ---!@!@!@!

	mov	Parity_Count,#01h
	mov	a,TX_SEND_1
	cpl	a
	mov	r0,#3				; 3 Bit
	lcall	send_bits

	mov	a,TX_SEND_2
	cpl	a
	mov	r0,#4				; 4 Bit
	lcall	send_bits


	mov	a,TX_SEND_3
	cpl	a
	mov	r0,#4				; 4 Bit
	lcall	send_bits

	mov	a,TX_SEND_4
	cpl	a
	mov	r0,#4				; 4 Bit
	lcall	send_bits

	lcall	Parity_Bit			; 1 Bit


;-------------------------------------------------------------------------
NO3_DATA_WORD:		;MU MD AU AD  AUX4   12 CHANNEL  SEND 

	mov	Parity_Count,#00h
	mov	a,#000000011b		; NO3 ADD  "011"
	mov	TX_SEND_1,a
	mov	r0,#3
	lcall	send_bits

	jnb	MAIN_H,MUMD_not		;MAIN_H = 0, MU,MD CLEAR

;--MU MD CHECK      
	mov	a,02dh
	anl	a,#10000000b		;MU  DET
	cjne	a,#10000000b,MD_check
	mov	a,#00000001b
	mov	TX_SEND_2,a
	ajmp	MUMD_send
MD_check:
	mov	a,02dh
	anl	a,#01000000b		;MD  DET
	cjne	a,#01000000b,MUMD_not
	mov	a,#00000010b
	mov	TX_SEND_2,a
	ajmp	MUMD_send
MUMD_not:
	mov	a,#00000000b
	mov	TX_SEND_2,a	
MUMD_send:
	mov	r0,#4			;MUMD 4 bit
	lcall	send_bits

	jnb	SUB_H,AUAD_not		;SUB_H=0, AU,AD CLEAR

;--AUAD CHECK         
	mov	a,02dh
;	anl	a,#00100000b		;AU DET
	anl	a,#10000000b		;MU DET

	cjne	a,#10000000b,AD_check
	mov	a,#00000001b
	mov	TX_SEND_3,a
	ajmp	AUAD_send
AD_check:
	mov	a,02dh
;	anl	a,#00010000b		;AD  DET
	anl	a,#01000000b		;MD  DET

	cjne	a,#01000000b,AUAD_not
	mov	a,#000000010b
	mov	TX_SEND_3,a
	ajmp	AUAD_send
AUAD_not:
	mov	a,#00000000b
	mov	TX_SEND_3,a	
AUAD_send:
	mov	r0,#4			;AUAD 4 bit
	lcall	send_bits

; AUX 4bit send
	mov	a,#00000000b
	mov	TX_SEND_4,a		
	mov	r0,#4			; 4 bit
	lcall	send_bits

	lcall	Parity_Bit

;!@!@!@! ---NO3 TX DATA REVERSED ---!@!@!@!

	mov	Parity_Count,#01h
	mov	a,TX_SEND_1
	cpl	a
	mov	r0,#3				; 3 Bit
	lcall	send_bits

	mov	a,TX_SEND_2
	cpl	a
	mov	r0,#4				; 4 Bit
	lcall	send_bits

	mov	a,TX_SEND_3
	cpl	a
	mov	r0,#4				; 4 Bit
	lcall	send_bits

	mov	a,TX_SEND_4
	cpl	a
	mov	r0,#4				; 4 Bit
	lcall	send_bits

	lcall	Parity_Bit			; 1 Bit

;------------------------------------------------------------------
power_down:
	clr	Power_Led

	jb	set_status,loop_stat		;auto timer = 0  
	inc	auto_timer_0
	mov	a,auto_timer_0
	cjne	a,#0ffh,loop_end
;	jnb	scan_mark,tx_go2		;1=scan mode

;-------------------------
;OUT TRANSMITTER Frq CHECK
;-------------------------
;	jb	outfrq_ck,tx_go2
;	setb	pwsw			;RX
;	clr	modem_me
;	mov	r5,#12
;	lcall	delay1

;	jnb	SQ_OUT,tx_go1

;	clr	scan_11
;	clr	scan_22
;	clr	base_ch_no

;	ljmp	RECEIVER

;tx_go1:
;	setb	outfrq_ck
;	clr	pwsw
;	setb 	modem_me

;tx_go2:
	mov	auto_timer_0,#00h
	inc	auto_timer_1
	mov	a,auto_timer_1
;--------------------------------------------
;CRANE REMOCON TX POWER OFF/CONTROL POWER OFF
;     NON DATA TIMER (#DATA * 40.96 sec)
;--------------------------------------------
		
	cjne	a,#030h,loop_end	;1bh->5min,1fh->15min,30h->20min
	clr	p3.7			;power off

loop_stat:
;	clr	outfrq_ck
	mov	auto_timer_0,#00h
	mov	auto_timer_1,#00h

loop_end:
	ljmp	sync_word


;---------------------------------------------
SET_CHANNEL_SUB:
	mov	r5,#2		;2
	lcall	delay2		; 2.5 uS delay
	rlc	a		; rotate A
	jnc	set_ch_1	; check the lowest bit
	setb	rf_si		; set SI high
	ajmp	set_ch_2
SET_CH_1:
	clr	rf_si		; set SI low
SET_CH_2:
	mov	r5,#1		;1
	lcall	delay2		; 2.5 uS delay
	clr	cps
	mov	r5,#1		;1
	lcall	delay2		; 2.5 uS delay
	setb	cps
	djnz	r0,set_channel_sub
	ret
;-----------------------------------------------





;WORD ADDRESS / no1- 101b/mca-010b/no2- 110b/no3-011b/( no4-100b,/ no5-001b)
;BIT ADDRESS 20,21,22,24,2d,2f

;********************************************************************
;*	Initialize	H/W
;********************************************************************

RECEIVER:
;	jnb	Power_Check,GOTOTX	;INIT PAT LOW CK

	mov	ERR_BIT_COUNT,#00h
	mov	SYNC_CNT0,#00h
	mov	SYNC_CNT1,#00h
	mov	WORD_FIND,#00h		;SYNC,NO1,MCA_BIT 
	mov	SQ_L_CNT,#00h
	
	setb	it1			;TCON
	setb	ex1			;IE.2
	setb	ea			;IE.7


MAIN:
	mov	a,SQ_L_CNT
	cjne	a,#224,SYNCCHECK	;192
	jb	scan_11,RFCH_SUB
	setb	base_ch_no
	ajmp	RFCH_SUB

SYNCCHECK:
	mov	a,SYNC_CNT1
	cjne	a,#7,ERR_CHECK		;5  128*#
	mov	SYNC_CNT1,#00h
	ajmp	RFCH_SUB

ERR_CHECK:
	mov	a,ERR_BIT_COUNT		;sync no count
	cjne	a,#7,MAINSTART		;5
	ajmp	RFCH_SUB

MAINSTART:
	mov	a,WORD_FIND		; pattern flag
	cjne	a,#00000111b,MAIN
	mov	WORD_FIND,#00h
	mov	ERR_BIT_COUNT,#00h


	clr	ea		;IE.7
;------------------------------------------------
DISPLAY_ADD:

	setb	power_led		;off
	mov	r5,#5
	lcall	delay1
	jb	p3.7,disp_go
	clr	p3.7			;tx power off
disp_go:	
	mov	r5,#5
	lcall	delay1

lamp_on:
	clr	power_led		;on
	mov	r5,#1
	lcall	delay1

	setb	power_led		;off
	mov	r5,#1
	lcall	delay1
	
	clr	power_led		;on
	mov	r5,#1
	lcall	delay1

	setb	power_led		;off
	mov	r5,#1
	lcall	delay1
	
	clr	power_led		;on
	mov	r5,#1
	lcall	delay1

	sjmp	DISPLAY_ADD
;-------------------------------------------
RFCH_SUB:
	clr	ea
	jb	scan_11,again_end
	mov	a,ch_dip_sw
	anl	a,#01000000b			;7 dip none
	jz	MANU_TXD
	mov	a,ch_dip_sw
	anl	a,#00110000b			;f code 5.6 dip
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
	ljmp	init			;fc error

MANU_TXD:				;MANUAL MODE
	clr	pwsw			;tx mode
	ljmp	TX_DATA_SEND

again_ch:
	setb	scan_11
	ljmp	scan_set_1

again_end:
	jnb	base_ch_no,again_2sd
	mov	channel_0,channel_base		;base ch data send
	setb	Power_Led
	setb	scan_22
	ljmp	scan_set_1

again_2sd:
	setb	Power_Led			;2nd ch data / off
	mov	r5,#1
	lcall	delay1
	ljmp	TX_DATA_S			;LED 2 ON/OFF



;---------------------------------
;	External Interrupt 1
;---------------------------------
int_1:
	push	acc

	jb	SQ_OUT,action_data		;H-> action

	inc	SQ_L_CNT

;--------------------------------------------
action_data:
	mov	c,MODEM_RD
	mov	READ_BIT,c

	mov	a,WORD_FIND			; pattern flag
	cjne	a,#00000000b,address_data	; check pattern flag
	acall	SYNC_W
	ajmp	int_1_ret

address_data:
	cjne	a,#00000001b,mca_data		; check pattern flag
	acall	NO1_DATA_W
	ajmp	int_1_ret

mca_data:
	cjne	a,#00000011b,int_1_ret		; check pattern flag
	acall	MCA_DATA_W

int_1_ret:
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

	setb	SYNC_BIT			;bit add 18b
	mov	SYNC_CNT0,#00h
	mov	SYNC_CNT1,#00h
	mov	SQ_L_CNT,#00h

	lcall	M_ADDRESS_INPUT

	ajmp	SYNC_RET

sync_error:
	inc 	SYNC_CNT0
	mov	a,SYNC_CNT0			;non data check / data delete
	cjne	a,#128,sync_ret
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
;------------------------------------
	mov	a,PATTERN1			
	cjne	a,address1,no1_add_err		; ID CHECK
	mov	a,PATTERN2			; ID CHECK

	anl	a,#00011111b			;bit8-patity,opa,opb clear 

	cjne	a,address2,no1_add_err
	mov	a,PATTERN3
	cpl	a
	cjne	a,address1,no1_add_err
	mov	a,PATTERN4
	cpl	a

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



;--------------------------------
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
	
	mov	a,PATTERN1			;PATTERN1=MCA WORD ADD
	cjne	a,MCA_DW_L,ch_data_err
;	cjne	a,#01100010b,ch_data_err	;base code

	mov	a,PATTERN2
	anl	a,#00111111b			;MCA ID 6bit
	cjne	a,channel_0,ch_data_err		;ID P(0),(7),6,5,4,3,2,1b

	setb	mca_word_bit
	ajmp	ch_ret1
;-----------------------------------

ch_data_err:
	inc	ERR_BIT_COUNT
	mov	WORD_FIND,#00h

ch_ret1:
	mov	BIT_CONT_32,#00h

ch_ret:
	ret

;------------------------------------
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
	mov	PARITY_BYTE,#01h	; Even Parity
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
;-------------------------------------
CAL_PARITY:
        clr     C
	mov	r7,#8
CAL_0:
	rrc	a
	jnc	CAL_1
	inc	PARITY_BYTE
CAL_1:
	djnz	r7,CAL_0
	ret

;---------------------------------------
M_ADDRESS_INPUT:

	clr	p3.5
	mov	r5,#2
	lcall	delay2
	mov	a,Read_Port
	cpl	a
	rl	a
	rl	a
	rl	a
	anl	a,#11111000b
	orl	a,#00000101b
	mov	address1,a

	mov	a,Read_Port
	swap	a
	cpl	a
	rr	a
	anl	a,#00000111b
	mov	r7,a
	setb	p3.5
	
	clr	p3.6
	mov	r5,#2
	lcall	delay2
	mov	a,Read_Port
	cpl	a
	anl	a,#00000011b		;opA/opB=L   /H=> orl=#00001111b
	swap	a
	rr	a
	orl	a,r7
	mov	address2,a
	setb	p3.6
;--------------------------------------
CH_ID_INPUT:
	mov	MCA_DW_L,#00h
	clr	p3.6
	mov	r5,#2
	lcall	delay2
	mov	a,Read_Port
	cpl	a
	rr	a
	rr	a
	anl	a,#00111111b
	orl	a,#01000000b			;scan mode/7dip sw on
	mov	ch_dip_sw,a			;7 dip none
	anl	a,#00111111b
	mov	channel_0,a
	setb	p3.6
	mov	a,ch_dip_sw
	anl	a,#01000000b
	jnz	scan_mode
	mov	MCA_DW_L,#01100010b		;base code
	ret

scan_mode:
	setb	p3.6				;ch ic enable

;	setb	scan_mark			;scan mode mark
	mov	a,ch_dip_sw
	anl	a,#00110000b

	cjne	a,#00000000b,spco_1		;sc00
	mov	MCA_DW_L,#11100010b
	ajmp	spco_4
spco_1:
	cjne	a,#00010000b,spco_2		;sc01
	mov	MCA_DW_L,#11101010b
	ajmp	spco_4
spco_2:
	cjne	a,#00100000b,spco_3		;sc10
	mov	MCA_DW_L,#11110010b
	ajmp	spco_4
spco_3:
	cjne	a,#00110000b,spco_4		;sc11
	mov	MCA_DW_L,#11111010b
	ajmp	spco_4
spco_4:
	mov	a,ch_dip_sw
	anl	a,#00001111b
	cjne	a,#00h,frq_1
	mov	channel_0,#00110000b		;447.8625
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
frq_end:
	mov	channel_0,#11000000b		;11ch over/error
	ret



;------------------------------
;    SEND DATA / SHIFT CLOCK
;------------------------------

send_bits:
send_0:
	jnb	modem_st,send_0
send_1:
	jb	modem_st,send_1
	mov	r5,#10h
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

;---------------------------------------

Parity_Bit:

PP_0:
	jnb	modem_st,PP_0
PP_1:
	jb	modem_st,PP_1
	mov	r5,#10h
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


;------------------
;12Mhz 1s=1usec
;------------------
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
; RF MODUEL MODEL TX / TMX 759A TOKO
; TX FREQUENCY	     / 447.2625Mhz -- 447.9875Mhz (59 Channel)
;*****************************************************************

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
	DB	10011000B
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