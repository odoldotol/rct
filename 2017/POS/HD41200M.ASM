

;---------------------------------------------------------------------------
;
;
;	        POLESTAR MAIN BOARD RECEIVER PROGRAM
;
;			DATE: 	2001 . 08 . 23
;			VERSION: 1.0
;		        EDIT BY: KIM SEONG WEON
;
;---------------------------------------------------------------------------
;TMX 729
;WORD ADDRESS NO1-101b/NO2-110b/NO3-011b/NO4-100b/NO5-001b
;---------------------------------------------------------------------------
;
; 	data definition	
;
;---------------------------------------------------------------------------


		ORG	0020H
ERROR_BYTE:	DS	1	;00h~07h(20h)
ERROR_COUNT:	DS	1	;08h~0Fh(21h)
WORD_FIND:      DS      1	;10h ~17h(22h)  bit ADD 10/11/12/13----


		ORG	0030H
CHANNEL:        DS	1
;ADDRESS1:      DS    	1	;MCA ID
;ADDRESS2:	DS  	1
RXBUF2:         DS    	1
RXBUF3:         DS    	1
BIT_CONT_32:	DS	1
PATTERN1:	DS	1
PATTERN2:	DS	1
PATTERN3:	DS	1
PATTERN4:	DS	1
ODD_PARITY:	DS	1
EVEN_PARITY:	DS	1
PARITY_BYTE:	DS	1
SQCOUNT:	DS	1
SQCOUNT1:	DS	1
REC_CNT0:	DS	1
REC_CNT1:	DS	1
MODE_C:		DS	1
RECWAIT_CUT0:	DS	1
RECWAIT_CUT1:   DS	1
ERR_BIT_COUNT:	DS	1	;SYNC,PARITY,ADD,NO2,NO3,

ENDS

BSEG
;---------------------------------------------------------------------------
;
;	modem chip pin description
;
;---------------------------------------------------------------------------
MODEM_RT 	bit 	p3.2		;int0
MODEM_RD 	bit 	p3.0
MODEM_SD	bit	p3.1
MODEM_ST	bit	p3.3
;---------------------------------------------------------------------------
;
;	rf module pin description
;
;---------------------------------------------------------------------------
RST		bit	p1.0
CPS		bit	p1.1
RF_SI		bit	p1.2
VCO		bit	p1.3
PWSW		bit	p1.4
LOCK		bit	p1.5
SQ_OUT		bit	p1.6		; Carrier Sense Output

WATCH_DOG	bit	p1.7
DACO		bit	p3.4		; 
AR20ER		bit	p3.5		;L-system error

READ_BIT	bit	00h
PARITY_ERR      bit     01h


SYNC_BIT	bit	10h		;WORD FIND(bit add 22h)
NO1_WORD_BIT    bit     11h             ;   //
NO2_WORD_BIT	bit	12h		;   // 
NO3_WORD_BIT    bit     13h             ;option
NO4_WORD_BIT	bit	14h
NO5_WORD_BIT	bit	15h

SEND_BIT	bit	20h

ENDS

;---------------------------------------------------------------------------
;
;	NAME:
;	DESCRIPTION: initialize & main program
;	INPUT:	
;	OUTPUT:
;
;---------------------------------------------------------------------------
;---------------------------------------------------------------------------
;
;	START OF PROGRAM
;
;---------------------------------------------------------------------------
;%S
CSEG

        org     0000h
        ljmp    init            ;Reset

        org     0003h		; External interrupt 0
	ljmp	int_0

        org     000bh		; Timer/Counter 0
        reti

        org     0013h		; External interrupt 1
        reti

        org     001bh		; Timer/Counter 1
        reti

        org     0023h		; Serial Interrupt
        reti



;---------------------------------------------------------------------------
INIT:                           ;:H/W Reset
	clr	WATCH_DOG  		;watch dog clock on
        mov     sp,#60h
	setb	VCO		;729RX
	setb	PWSW		;729RX
        setb    RST
        setb    CPS
        setb    RF_SI

        mov     psw,#00h
        mov     ie,#00000000b   ;

; INTERNAL RAM CLEAR

	clr	DACO			;L-->DATA CLEAR
	clr	PARITY_ERR
	clr	SEND_BIT
	mov	a,#00H
	mov	WORD_FIND,a
	mov	SQCOUNT,a
	mov	SQCOUNT1,a
	mov	BIT_CONT_32,a
	mov	ODD_PARITY,a
	mov	EVEN_PARITY,a
	mov	RECWAIT_CUT0,a
	mov	RECWAIT_CUT1,a
	mov	ERR_BIT_COUNT,a

;-----------------------------------------------
;RX CHANNL INPUT
	setb	watch_dog
	mov	a,p2
	nop
	cpl	a
	anl	a,#01111111b
;RF_SET
	rl	a		; channel data = 2*data
	mov	channel,a

	mov     dptr,#RX_CHANNEL_DATA
	movc    a,@a+dptr       ; move channel data byte #1                    
	mov     RXBUF2,a
	mov     a,channel
	inc     a
	movc    a,@a+dptr       ; move channel data byte #2                   
	mov     RXBUF3,a
	clr	watch_dog	;watch dog clock 

	lcall	start_rf_module 



;ON AIR
 
;------------------------------
;	Interrupt Enable
;------------------------------

	setb	it0		;TCON
	setb	ex0		;IE.0
	setb	ea		;IE.7

;------------------------------------------------------------------
; main loop
;-----------

MAIN:
	setb	watch_dog			;watch dog clock --> 

	mov	a,ERR_BIT_COUNT			;16 ERROR BIT CHECK
	cjne	a,#0f0h,MAINSTART
	mov	ERR_BIT_COUNT,#00h
	clr	DACO
	clr	SEND_BIT
	ajmp	main

MAINSTART:
	jb	SEND_BIT,RECEIVE	;receive(H)

	mov	a,SQCOUNT1
	cjne	a,#4,main		;128*8
	mov	SQCOUNT1,#00h	

	clr	DACO

	ajmp	main

;-no123----------------------------------		
RECEIVE:				;no1,2,3
	mov	a,WORD_FIND		; pattern flag
        cjne    a,#00001111b,REC_WAIT
	mov	WORD_FIND,#00000000b
	mov	ERR_BIT_COUNT,#00h
	mov	RECWAIT_CUT0,#00h
	mov	RECWAIT_CUT1,#00h

 	setb	DACO			;DATA PASS
	setb	p2.7			;rx_txd

	jb	AR20ER,main

	ajmp	main

;-no12345--------------------------------
;RECEIVE:
;       cjne    a,#00111111b,REC_WAIT	;no4,5 option
;	mov	WORD_FIND,#00000000b
;	mov	ERR_BIT_COUNT,#00h
;	mov	RECWAIT_CUT0,#00h
;	mov	RECWAIT_CUT1,#00h

;	setb	DACO
;	setb	p2.7			;rx_txd
;	ajmp	main
;----------------------------------------

REC_WAIT:
	inc	RECWAIT_CUT0
	mov	a,RECWAIT_CUT0

	cjne	a,#0ffh,mainjump
	mov	RECWAIT_CUT0,#00h
	inc	RECWAIT_CUT1
	mov	a,RECWAIT_CUT1

	cjne	a,#05fh,mainjump			;256*5f
	mov	word_find,#00h
	clr	SEND_BIT			;NOISE  rx output clear
	clr	DACO

mainjump:

	ajmp	main
	

;---------------------------------------------------------------------------
;	External Interrupt 0
;---------------------------------------------------------------------------
int_0:
	push	acc
	jb	SQ_OUT,action_data		;H-> action
	mov	ERROR_BYTE,#00h
	inc	SQCOUNT

	mov	a,SQCOUNT
	cjne	a,#128,int_00			;128bit
	mov	SQCOUNT,#00

	inc	SQCOUNT1

int_00:	
	ajmp	int_0_ret

;--------------------------------------------
action_data:
	mov	SQCOUNT,#00h
	mov	SQCOUNT1,#00h

;	setb	SEND_BIT			;TX -> ON

	mov	c,MODEM_RD
	mov	READ_BIT,c

	mov	a,WORD_FIND			; pattern flag
	cjne	a,#00000000b,address_data	; check pattern flag
	acall	SYNC_WORD
	ajmp	int_0_ret

address_data:
	cjne	a,#00000001b,r_data1		; check pattern flag
	acall	NO1_DATA_WORD
	ajmp	int_0_ret

r_data1:
	cjne	a,#00000011b,r_data2		; check pattern flag
	acall	NO2_DATA_WORD
	ajmp	int_0_ret

r_data2:
	cjne	a,#00000111b,r_data3		; check pattern flag
	acall	NO3_DATA_WORD			; Null	pattern
	ajmp	int_0_ret

r_data3:
	cjne	a,#00001111b,r_data4		; check pattern flag
	acall	NO4_DATA_WORD
	ajmp	int_0_ret
r_data4:
	cjne	a,#00011111b,int_0_ret		; check pattern flag
	acall	NO5_DATA_WORD

int_0_ret:
	clr	watch_dog
	setb	ea
	pop	acc
        reti


;-------------------------------------
SYNC_WORD:

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
	cjne	a,#00000000b,sync_error		
	mov	a,PATTERN4
	cjne	a,#11000000b,sync_error		;stop 2 bit

	mov	REC_CNT0,#00h
	mov	REC_CNT1,#00h

	setb	SYNC_BIT			;bit add 10b
	setb	SEND_BIT


	ajmp	SYNC_RET

sync_error:
	inc	ERR_BIT_COUNT
	inc 	REC_CNT0
	mov	a,REC_CNT0			;non data check / data delete
	cjne	a,#32,SYNC_RET
	mov	REC_CNT0,#00

	inc	REC_CNT1
	mov	a,REC_CNT1
	cjne	a,#16,SYNC_RET
	clr	DACO
	clr	SYNC_BIT
	clr	SEND_BIT
	mov	REC_CNT1,#00h
	
SYNC_RET:
	mov	BIT_CONT_32,#00h
	ret

;-------------------------------------------
NO1_DATA_WORD:			
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
	jb	PARITY_ERR,no1_err

	mov	a,PATTERN1			;word address check
	anl	a,#00000111b
	cjne	a,#00000101b,no1_err

	mov	r7,PATTERN1
	mov	a,PATTERN3
	cpl	a
	cjne	a,r7,no1_err

	mov	a,PATTERN2
	anl	a,#01111111b
	mov	r7,a
	mov	a,PATTERN4
	cpl	a
	anl	a,#01111111b
	cjne	a,r7,no1_err

	setb	NO1_WORD_BIT
	ajmp	no1_ret1

no1_err:
	inc	ERR_BIT_COUNT
	mov	WORD_FIND,#00h
	clr	send_bit	
no1_ret1:
	mov	BIT_CONT_32,#00h

no1_ret:
	ret


;---------------------------------------------------------------------------
NO2_DATA_WORD:
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
        cjne    a,#32,no2_ret

        lcall   PARITY_CHECK
	jb	PARITY_ERR,no2_err

	mov	a,PATTERN1			;word address check
;-HITEC CLEAR------------------------
	cjne	a,#01100010b,pos_on		;Hitec mca id
	ajmp	no2_err
;------------------------------------

pos_on:
	anl	a,#00000111b
	cjne	a,#00000110b,no2_err

	mov	r7,PATTERN1
	mov	a,PATTERN3
	cpl	a
	cjne	a,r7,no2_err

	mov	a,PATTERN2
	anl	a,#01111111b
	mov	r7,a
	mov	a,PATTERN4
	cpl	a
	anl	a,#01111111b
	cjne	a,r7,no2_err
	setb	NO2_WORD_BIT			;bit add 12b
        ajmp    no2_ret1

no2_err:
	inc	ERR_BIT_COUNT
	clr	SEND_BIT
	mov	WORD_FIND,#00h		; Return Search Pattern
no2_ret1:
	mov	BIT_CONT_32,#00h

no2_ret:
	ret

;--------------------------------------------------------------
NO3_DATA_WORD:
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
	cjne	a,#32,no3_ret

	lcall	PARITY_CHECK
	jb	PARITY_ERR,no3_err

	mov	r7,PATTERN1
	mov	a,PATTERN3
	cpl	a
	cjne	a,r7,no3_err

	mov	a,PATTERN2
	anl	a,#01111111b
	mov	r7,a
	mov	a,PATTERN4
	cpl	a
	anl	a,#01111111b
	cjne	a,r7,no3_err

	mov	a,PATTERN1			
	anl	a,#00000111b
	cjne	a,#00000011b,no3_err		;word address check

        setb    NO3_WORD_BIT
	mov	BIT_CONT_32,#00h
	ajmp	no3_ret1

no3_err:
	inc	ERR_BIT_COUNT
	mov	WORD_FIND,#00h		; Return Search Pattern
	mov	BIT_CONT_32,#00h
	clr	send_bit
no3_ret1:
	mov	BIT_CONT_32,#00h
no3_ret:
	ret

;---------------------------------------------------------------------------
NO4_DATA_WORD:
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
        cjne    a,#32,no2_ret

        lcall   PARITY_CHECK
	jb	PARITY_ERR,no4_err

	mov	a,PATTERN1			;word address check
	anl	a,#00000111b
	cjne	a,#00000100b,no4_err

	mov	r7,PATTERN1
	mov	a,PATTERN3
	cpl	a
	cjne	a,r7,no4_err

	mov	a,PATTERN2
	anl	a,#01111111b
	mov	r7,a
	mov	a,PATTERN4
	cpl	a
	anl	a,#01111111b
	cjne	a,r7,no4_err
	setb	NO4_WORD_BIT			;bit add 14b
        ajmp    no4_ret1

no4_err:
	inc	ERR_BIT_COUNT
	clr	SEND_BIT
	mov	WORD_FIND,#00h		; Return Search Pattern
no4_ret1:
	mov	BIT_CONT_32,#00h

no4_ret:
	ret

;--------------------------------------------------------------
NO5_DATA_WORD:
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
	cjne	a,#32,no5_ret

	lcall	PARITY_CHECK
	jb	PARITY_ERR,no5_err

	mov	r7,PATTERN1
	mov	a,PATTERN3
	cpl	a
	cjne	a,r7,no5_err

	mov	a,PATTERN2
	anl	a,#01111111b
	mov	r7,a
	mov	a,PATTERN4
	cpl	a
	anl	a,#01111111b
	cjne	a,r7,no5_err

	mov	a,PATTERN1			
	anl	a,#00000111b
	cjne	a,#00000001b,no5_err		;word address check

        setb    NO5_WORD_BIT
	mov	BIT_CONT_32,#00h
	ajmp	no5_ret1

no5_err:
	inc	ERR_BIT_COUNT
	mov	WORD_FIND,#00h		; Return Search Pattern
	mov	BIT_CONT_32,#00h
	clr	send_bit
no5_ret1:
	mov	BIT_CONT_32,#00h
no5_ret:
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
;---------------------------------------------------------------------------
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
;---------------------------------------------------------------------------



;---------------------------------------------------------------------------
;
;	NAME: TMX-729
;	DESCRIPTION: start RF module
;		(1) POWER ON
;		(2) CHANNEL FREQUENCY SET
;	INPUT:	
;	OUTPUT:
;
;---------------------------------------------------------------------------
START_RF_MODULE:
	mov	r5,#2		;4		; 20mS delay
	acall	delay1
	acall 	set_channel			; set channel freq.
	mov	r5,#02h		;8		; 80mS delay
	acall	delay1
	ret

;---------------------------------------------------------------------------
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
;---------------------------------------------------------------------------
SET_CHANNEL:
;=======================================
;	Reference Frequency Set
;=======================================
        setb    cps			; set complement of CPS high  
	clr	rst			; set RST low

	mov	r5,#2			; 4 us delay
	acall	delay2

	mov	a,#00110000b		; reference frequency setting
	mov	r0,#8			; 12.5 kHz
	acall	set_channel_sub

	mov	a,#00000011b
	mov	r0,#8
	acall	set_channel_sub

	mov	a,#01010100b
	mov	r0,#6                   ; 5+1
	acall	set_channel_sub

	mov	r5,#4
	acall 	delay2		; 2.5 uS delay
        setb    rst
	mov	r5,#20		;100	  ; 20mS delay
	acall	delay2

;=======================================
;	TX Frequency Set
;=======================================
;	clr	rst			; TX requency setting

;	mov	r5,#2			; 4 uS delay
;	acall	delay2

;	mov	a,#01010011b		; TX TURN ON			
;	mov	r0,#8
;	acall	set_channel_sub

;	mov	a,#10110000b
;	mov	r0,#5
;	acall	set_channel_sub

;	mov	a,#11010001b 		; channel DIP S/W setting
;	mov	r0,#8
;	acall	set_channel_sub

;       mov     a,#10000000b             ;21+1
;	mov	r0,#1
;	acall	set_channel_sub

;	mov	r5,#2		;4
;	acall 	delay2		; 2.5 uS delay
;       setb    rst
;	mov	r5,#20		;100       ; 20mS delay
;	acall	delay2

;=======================================
;	RX Frequency Set
;=======================================
	clr	rst			; RX requency setting
	mov	r5,#2			; 4 uS delay
	acall	delay2

	mov	a,#10100100b		; RX TURN ON			
	mov	r0,#8
	acall	set_channel_sub

	mov     a,rxbuf2
	mov	r0,#8
	acall	set_channel_sub

	mov     a,rxbuf3
	mov	r0,#6
	acall	set_channel_sub

	mov	r5,#2		;4
	acall 	delay2		; 2.5 uS delay
	setb	rst
	mov	r5,#20		;100       ; 20mS delay
	acall	delay2
	ret
	
;---------------------------------------------------------------------------
;
;	NAME: SET_CHANNEL_SUB()
;	DESCRIPTION: Send bits of Accumulator( length: R0 )  to RF MODULE
;	It is assumed that MSB are sent first.
;	
;	INPUT:	R0,A
;	OUTPUT:
;
;---------------------------------------------------------------------------
SET_CHANNEL_SUB:
	clr	watch_dog
	mov	r5,#4		;8
	acall 	delay2		; 2.5 uS delay

	rlc	a		; rotate A 
	jnc	set_ch_1	; check the lowest bit	
	setb	rf_si		; set SI high
	ljmp	set_ch_2
SET_CH_1:
	clr	rf_si		; set SI low
SET_CH_2:

	mov	r5,#4		;8
	acall 	delay2		; 2.5 uS delay
	clr	cps
	mov	r5,#2
	acall 	delay2		; 2.5 uS delay
	setb	cps
	djnz	r0,set_channel_sub
	setb	watch_dog
	ret

	
;---------------------------------------------------------------------------
;
;	NAME:
;	DESCRIPTION: delay time = R5 * (20mS)
;	INPUT:	R5
;	OUTPUT:
;
;---------------------------------------------------------------------------
DELAY1:
	mov	r6,#40
DEL:	mov	r7,#249
$1:	djnz	r7,$1
	djnz	r6,DEL
	djnz	r5,DELAY1
	RET
	
;---------------------------------------------------------------------------
;
;	NAME:
;	DESCRIPTION: delay time = R5 * (2uS)
;	INPUT:	R5
;	OUTPUT:
;
;---------------------------------------------------------------------------
delay2: djnz	r5,delay2	; 2uS instruction
	ret

;-----------------------------------------------------
RX_CHANNEL_DATA:

;A_RF CHANNEL
        db      00101000b        ; CH#1 
        db      00001100b        ; CH#1 447.2625

        db      00101000b        ; CH#2 
        db      00010100b        ; CH#2 447.2750

        db      00101000b        ; CH#3 
        db      00011100b        ; CH#3 447.2875

        db      00101000b        ; CH#4 
        db      00100100b        ; CH#4 447.3000

        db      00101000b        ; CH#5 
        db      00101100b        ; CH#5 447.3125

        db      00101000b        ; CH#6 
        db      00110100b        ; CH#6 447.3250

        db      00101000b        ; CH#7 
        db      00111100b        ; CH#7 447.3375

        db      00101000b        ; CH#8 
        db      01000100b        ; CH#8 447.3500

        db      00101000b        ; CH#9 
        db      01001100b        ; CH#9 447.3625

        db      00101000b        ; CH#10 
        db      01010100b        ; CH#10 447.3750

        db      00101000b        ; CH#11 
        db      01011100b        ; CH#11 447.3875

        db      00101000b        ; CH#12 
        db      01100100b        ; CH#12 447.4000

        db      00101000b        ; CH#13 
        db      01101100b        ; CH#13 447.4125

        db      00101000b        ; CH#14 
        db      01110100b        ; CH#14 447.4250

        db      00101000b        ; CH#15 
        db      01111100b        ; CH#15 447.4375

        db      00101000b        ; CH#16 
        db      10000100b        ; CH#16 447.4500

;-----------------------------------------------------------------------
;B_RF CHANNEL
        db      00101000b        ; CH#17 
        db      10001100b        ; CH#17 447.4625

        db      00101000b        ; CH#18 
        db      10010100b        ; CH#18 447.4750

        db      00101000b        ; CH#19 
        db      10011100b        ; CH#19 447.4875

        db      00101000b        ; CH#20 
        db      10100100b        ; CH#20 447.5000

        db      00101000b        ; CH#21 
        db      10101100b        ; CH#21 447.5125

        db      00101000b        ; CH#22 
        db      10110100b        ; CH#22 447.5250

        db      00101000b        ; CH#23 
        db      10111100b        ; CH#23 447.5375

        db      00101000b        ; CH#24 
        db      11000100b        ; CH#24 447.5500

        db      00101000b        ; CH#25 
        db      11001100b        ; CH#25 447.5625

        db      00101000b        ; CH#26 
        db      11010100b        ; CH#26 447.3750

        db      00101000b        ; CH#27 
        db      11011100b        ; CH#27 447.5875

        db      00101000b        ; CH#28 
        db      11100100b        ; CH#28 447.6000

        db      00101000b        ; CH#29 
        db      11101100b        ; CH#29 447.6125

        db      00101000b        ; CH#30 
        db      11110100b        ; CH#30 447.6250

        db      00101000b        ; CH#31 
        db      11111100b        ; CH#31 447.6375

        db      00101001b        ; CH#32 
        db      00000100b        ; CH#32 447.6500

;-----------------------------------------------------------------------
;C_RF CHANNEL
        db      00101001b        ; CH#33 
        db      00001100b        ; CH#33 447.6625

        db      00101001b        ; CH#34 
        db      00010100b        ; CH#34 447.6750

        db      00101001b        ; CH#35 
        db      00011100b        ; CH#35 447.6875

        db      00101001b        ; CH#36 
        db      00100100b        ; CH#36 447.7000

        db      00101001b        ; CH#37 
        db      00101100b        ; CH#37 447.7125

        db      00101001b        ; CH#38 
        db      00110100b        ; CH#38 447.7250

        db      00101001b        ; CH#39 
        db      00111100b        ; CH#39 447.7375

        db      00101001b        ; CH#40 
        db      01000100b        ; CH#40 447.7500

        db      00101001b        ; CH#41 
        db      01001100b        ; CH#41 447.7625

        db      00101001b        ; CH#42 
        db      01010100b        ; CH#42 447.7750

        db      00101001b        ; CH#43 
        db      01011100b        ; CH#43 447.7875

        db      00101001b        ; CH#44 
        db      01100100b        ; CH#44 447.8000

        db      00101001b        ; CH#45 
        db      01101100b        ; CH#45 447.8125

        db      00101001b        ; CH#46 
        db      01110100b        ; CH#46 447.8250

        db      00101001b        ; CH#47 
        db      01111100b        ; CH#47 447.8375

        db      00101001b        ; CH#48 
        db      10000100b        ; CH#48 447.8500

;-----------------------------------------------------------------------
;D_RF CHANNEL
        db      00101001b        ; CH#49 
        db      10001100b        ; CH#49 447.8625

        db      00101001b        ; CH#50 
        db      10010100b        ; CH#50 447.8750

        db      00101001b        ; CH#51 
        db      10011100b        ; CH#51 447.8875

        db      00101001b        ; CH#52 
        db      10100100b        ; CH#52 447.9000

        db      00101001b        ; CH#53 
        db      10101100b        ; CH#53 447.9125

        db      00101001b        ; CH#54 
        db      10110100b        ; CH#54 447.9250

        db      00101001b        ; CH#55 
        db      10111100b        ; CH#55 447.9375

        db      00101001b        ; CH#56 
        db      11000100b        ; CH#56 447.9500

        db      00101001b        ; CH#57 
        db      11001100b        ; CH#57 447.9625

        db      00101001b        ; CH#58 
        db      11010100b        ; CH#58 447.9750

        db      00101001b        ; CH#59 
        db      11011100b        ; CH#59 447.9875



;%E

end

