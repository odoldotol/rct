;---------------------------------------------------------------------------
;
;
;	        POLESTAR MAIN BOARD RECEIVER PROGRAM
;
;			DATE: 	2002 . 09 . 23
;			VERSION: 1.0
;		        EDIT BY: KIM SEONG WEON
;
;---------------------------------------------------------------------------
;TMX 566
;PCB: HD1200M
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
;SQCOUNT:	DS	1
;SQCOUNT1:	DS	1
REC_CNT0:	DS	1
REC_CNT1:	DS	1
MODE_C:		DS	1
RECWAIT_CUT0:	DS	1
RECWAIT_CUT1:   DS	1
ERR_BIT_COUNT:	DS	1	;SYNC,PARITY,ADD,NO2,NO3,
ERR_BIT_COUNT1:	DS	1	;SYNC,PARITY,ADD,NO2,NO3,
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
AR20ER		bit	p3.5		;LOGIC-system error

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

;------------------------
;	START OF PROGRAM
;------------------------
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
INIT:                      	     	;:H/W Reset
	clr	WATCH_DOG  		;watch dog clock on
        mov     sp,#60h
	setb	VCO			;729RX
	setb	PWSW			;729RX
        setb    RST
        setb    CPS
        setb    RF_SI

        mov     psw,#00h
        mov     ie,#00000000b   	;

; INTERNAL RAM CLEAR

	clr	DACO			;L-->DATA CLEAR
	clr	PARITY_ERR
	clr	SEND_BIT
	mov	a,#00h
	mov	WORD_FIND,a
;	mov	SQCOUNT,a
;	mov	SQCOUNT1,a
	mov	BIT_CONT_32,a
	mov	ODD_PARITY,a
	mov	EVEN_PARITY,a
	mov	RECWAIT_CUT0,a
	mov	RECWAIT_CUT1,a
	mov	ERR_BIT_COUNT,a
	mov	ERR_BIT_COUNT1,a
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



;------------------------------
;	Interrupt Enable
;------------------------------

	setb	it0		;TCON
	setb	ex0		;IE.0
	setb	ea		;IE.7
	setb	p2.7		;C/RX_TXD


MAIN:
	setb	watch_dog			;watch dog clock --> 

	mov	a,ERR_BIT_COUNT			;ERROR BIT CHECK
	cjne	a,#192,MAINSTART		;0f0h
	mov	ERR_BIT_COUNT,#00h

	inc	ERR_BIT_COUNT1
	mov	a,ERR_BIT_COUNT1		;ERROR BIT CHECK
	cjne	a,#5,MAINSTART		;0f0h
	mov	ERR_BIT_COUNT1,#00h

;	clr	DACO
;	clr	SEND_BIT
	ajmp	MAIN

MAINSTART:
;	jb	SEND_BIT,RECEIVE	;receive(H)

;	mov	a,SQCOUNT1
;	cjne	a,#8,main		;128*8
;	mov	SQCOUNT1,#00h	

;	clr	DACO

;	ajmp	main

;-notch S123----------------------------------		
;RECEIVE:				;SYNC NO1,2,3 ONLY CHECK
;	mov	a,WORD_FIND		; pattern flag
;       cjne    a,#00001111b,RECEIVE2
;	mov	WORD_FIND,#00000000b
;	mov	ERR_BIT_COUNT,#00h
;	mov	ERR_BIT_COUNT1,#00h
;	mov	RECWAIT_CUT0,#00h
;	mov	RECWAIT_CUT1,#00h
;;	mov	SQCOUNT1,#00h	

; 	setb	DACO			;DATA PASS
;	setb	p2.7			;C / rx_txd



;	ajmp	MAIN

;-notch S12345--------------------------------
RECEIVE:
	mov	a,WORD_FIND
        cjne    a,#00011111b,REC_11	;no4 option CHECK
	ajmp	rec_ok
rec_11:
        cjne    a,#00111111b,REC_WAIT	;no5 option CHECK
rec_ok:
	mov	WORD_FIND,#00000000b
	mov	ERR_BIT_COUNT,#00h
	mov	ERR_BIT_COUNT1,#00h
	mov	RECWAIT_CUT0,#00h
	mov	RECWAIT_CUT1,#00h
;	mov	SQCOUNT1,#00h	

	setb	DACO
	setb	p2.7			;rx_txd

	ajmp	MAIN
;----------------------------------------------

REC_WAIT:
	inc	RECWAIT_CUT0
	mov	a,RECWAIT_CUT0

	cjne	a,#0ffh,mainjump
	mov	RECWAIT_CUT0,#00h
	inc	RECWAIT_CUT1
	mov	a,RECWAIT_CUT1

	cjne	a,#05fh,mainjump			;256*5fh
	mov	RECWAIT_CUT1,#00h
	mov	word_find,#00h

;	clr	SEND_BIT			;NOISE  rx output clear
	clr	DACO

mainjump:

	ajmp	MAIN
	

;---------------------------------------------------------------------------
;	External Interrupt 0
;---------------------------------------------------------------------------
int_0:
	push	acc
	jb	SQ_OUT,action_data		;H-> action
;	mov	ERROR_BYTE,#00h
;	inc	SQCOUNT

;	mov	a,SQCOUNT
;	cjne	a,#128,int_00			;128bit
;	mov	SQCOUNT,#00h

;	inc	SQCOUNT1

	ajmp	action_data

int_00:	
	ajmp	int_0_ret

;--------------------------------------------
action_data:
;	mov	SQCOUNT,#00h
;	mov	SQCOUNT1,#00h

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

;-POS/MR  START BIT --01b,--10b CHECK------
;	mov	a,PATTERN1
	cjne	a,#00000001b,start_bit		;start 1 bit(00000001b)
	ajmp	sync_check

start_bit:
	cjne	a,#00000010b,sync_error		;start 1 bit(00000010b)
;------------------------------------------
sync_check:
	mov	a,PATTERN2
	cjne	a,#00000000b,sync_error
	mov	a,PATTERN3
	cjne	a,#00000000b,sync_error		
	mov	a,PATTERN4
	cjne	a,#11000000b,sync_error		;stop 2 bit

	mov	REC_CNT0,#00h
	mov	REC_CNT1,#00h

	setb	SYNC_BIT			;bit add 10b
;	setb	SEND_BIT


	ajmp	SYNC_RET

sync_error:
	inc	ERR_BIT_COUNT

	inc 	REC_CNT0
	mov	a,REC_CNT0			;non data check / data delete
	cjne	a,#32,SYNC_RET
	mov	REC_CNT0,#00h

	inc	REC_CNT1
	mov	a,REC_CNT1
	cjne	a,#16,SYNC_RET			;16

	clr	SYNC_BIT
;	clr	SEND_BIT

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

;	mov	a,PATTERN1			;word address check
;	anl	a,#00000111b
;	cjne	a,#00000101b,no1_err

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


;-------------------------------------------
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

;	mov	a,PATTERN1			;word address check
;-HITEC SYSTEM CLEAR-----------------
;	cjne	a,#01100010b,pos_on		;Hitec mca id
;	ajmp	no2_err
;------------------------------------

;pos_on:
;	anl	a,#00000111b
;	cjne	a,#00000110b,no2_err

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
;	clr	SEND_BIT
	mov	WORD_FIND,#00h		; Return Search Pattern
no2_ret1:
	mov	BIT_CONT_32,#00h

no2_ret:
	ret

;-------------------------------------------
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

;	mov	a,PATTERN1			
;	anl	a,#00000111b
;	cjne	a,#00000011b,no3_err		;word address check

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

;-------------------------------------------
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
        cjne    a,#32,no4_ret

        lcall   PARITY_CHECK
	jb	PARITY_ERR,no4_err

;	mov	a,PATTERN1			;word address check
;	anl	a,#00000111b
;	cjne	a,#00000100b,no4_err

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
;SYNC_WORD  DETECTOR (POS/MR  START BIT --01b,--10b CHECK)
	mov	a,PATTERN1
	cjne	a,#00000001b,start_1		;start 1 bit(00000001b)
	ajmp	s_check

start_1:
	cjne	a,#00000010b,s_error		;start 1 bit(00000010b)

s_check:
	mov	a,PATTERN2
	cjne	a,#00000000b,s_error
	mov	a,PATTERN3
	cjne	a,#00000000b,s_error		
	mov	a,PATTERN4
	cjne	a,#11000000b,s_error		;stop 2 bit
;----------------------------------------
	mov	a,WORD_FIND			; pattern flag
        cjne    a,#00001111b,s_error
	mov	WORD_FIND,#00000000b
	mov	ERR_BIT_COUNT,#00h
	mov	ERR_BIT_COUNT1,#00h
	mov	RECWAIT_CUT0,#00h
	mov	RECWAIT_CUT1,#00h
;	mov	SQCOUNT1,#00h	

 	setb	DACO				;DATA PASS
	setb	p2.7				;C / rx_txd
	setb	SYNC_BIT
	ret
;-----------------------------------
s_error:
	inc	ERR_BIT_COUNT
;	clr	SEND_BIT
	mov	WORD_FIND,#00h			; Return Search Pattern
no4_ret1:
	mov	BIT_CONT_32,#00h

no4_ret:
	ret

;-------------------------------------------
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

;	mov	a,PATTERN1			
;	anl	a,#00000111b
;	cjne	a,#00000001b,no5_err		;word address check

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



;-------------------------------------------
PARITY_CHECK:
	mov	PARITY_BYTE,#00h	; Odd Parity
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
;---------------------------------------
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
;---------------------------------------



;---------------------------------------------------
;
;	NAME: TMX-566
;	DESCRIPTION: start RF module
;		(1) POWER ON
;		(2) CHANNEL FREQUENCY SET
;	INPUT:	
;	OUTPUT:
;
;---------------------------------------------------
START_RF_MODULE:
	mov	r5,#4		;4		; 20mS delay
	acall	delay1
	acall 	set_channel			; set channel freq.
	mov	r5,#08h		;8		; 80mS delay
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
	clr	rst			; TX requency setting

	mov	r5,#2			; 4 uS delay
	acall	delay2

	mov	a,#01010011b		; TX TURN ON			
	mov	r0,#8
	acall	set_channel_sub

	mov	a,#10110000b
	mov	r0,#5
	acall	set_channel_sub

	mov	a,#11010001b 		; channel DIP S/W setting
	mov	r0,#8
	acall	set_channel_sub

        mov     a,#10000000b             ;21+1
	mov	r0,#1
	acall	set_channel_sub

	mov	r5,#4		;4
	acall 	delay2		; 2.5 uS delay
	setb    rst
	mov	r5,#100		;100       ; 20mS delay
	acall	delay2

;=======================================
;	RX Frequency Set
;=======================================
	clr	rst			; RX requency setting
	mov	r5,#2			; 4 uS delay
	acall	delay2

	mov	a,#10100010b		; RX TURN ON			
	mov	r0,#8
	acall	set_channel_sub

	mov     a,rxbuf2
	mov	r0,#8
	acall	set_channel_sub

	mov     a,rxbuf3
	mov	r0,#6
	acall	set_channel_sub

	mov	r5,#4		;4
	acall 	delay2		; 2.5 uS delay
	setb	rst
	mov	r5,#100		;100       ; 20mS delay
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
	mov	r5,#8		;8
	acall 	delay2		; 2.5 uS delay

	rlc	a		; rotate A 
	jnc	set_ch_1	; check the lowest bit	
	setb	rf_si		; set SI high
	ljmp	set_ch_2
SET_CH_1:
	clr	rf_si		; set SI low
SET_CH_2:

	mov	r5,#8		;8
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

        db      10110000b        ; CH#1 BYTE 1
        db      11001100b        ; CH#1 BYTE 2

        db      10110000b        ; CH#2 BYTE 1
        db      11010100b        ; CH#2 BYTE 2

        db      10110000b        ; CH#3 BYTE 1
        db      11011100b        ; CH#3 BYTE 2

        db      10110000b        ; CH#4 BYTE 1
        db      11100100b        ; CH#4 BYTE 2

        db      10110000b        ; CH#5 BYTE 1
        db      11101100b        ; CH#5 BYTE 2

        db      10110000b        ; CH#6 BYTE 1
        db      11110100b        ; CH#6 BYTE 2

        db      10110000b        ; CH#7 BYTE 1
        db      11111100b        ; CH#7 BYTE 2

        db      10110001b        ; CH#8 BYTE 1
        db      00000100b        ; CH#8 BYTE 2

        db      10110001b        ; CH#9 BYTE 1
        db      00001100b        ; CH#9 BYTE 2

        db      10110001b        ; CH#10 BYTE 1
        db      00010100b        ; CH#10 BYTE 2

        db      10110001b        ; CH#11 BYTE 1
        db      00011100b        ; CH#11 BYTE 2

        db      10110001b        ; CH#12 BYTE 1
        db      00100100b        ; CH#12 BYTE 2

        db      10110001b        ; CH#13 BYTE 1
        db      00101100b        ; CH#13 BYTE 2

        db      10110001b        ; CH#14 BYTE 1
        db      00110100b        ; CH#14 BYTE 2

        db      10110001b        ; CH#15 BYTE 1
        db      00111100b        ; CH#15 BYTE 2

        db      10110001b        ; CH#16 BYTE 1
        db      01000100b        ; CH#16 BYTE 2

        db      10110001b        ; CH#17 BYTE 1
        db      01001100b        ; CH#17 BYTE 2

        db      10110001b        ; CH#18 BYTE 1
        db      01010100b        ; CH#18 BYTE 2

        db      10110001b        ; CH#19 BYTE 1
        db      01011100b        ; CH#19 BYTE 2

        db      10110001b        ; CH#20 BYTE 1
        db      01100100b        ; CH#20 BYTE 2

        db      10110001b        ; CH#21 BYTE 1
        db      01101100b        ; CH#21 BYTE 2

        db      10110001b        ; CH#22 BYTE 1
        db      01110100b        ; CH#22 BYTE 2

        db      10110001b        ; CH#23 BYTE 1
        db      11110100b        ; CH#23 BYTE 2

        db      10110001b        ; CH#24 BYTE 1
        db      10000100b        ; CH#24 BYTE 2

        db      10110001b        ; CH#25 BYTE 1
        db      10001100b        ; CH#25 BYTE 2

        db      10110001b        ; CH#26 BYTE 1
        db      10010100b        ; CH#26 BYTE 2

        db      10110001b        ; CH#27 BYTE 1
        db      10011100b        ; CH#27 BYTE 2

        db      10110001b        ; CH#28 BYTE 1
        db      10100100b        ; CH#28 BYTE 2

        db      10110001b        ; CH#29 BYTE 1
        db      10101100b        ; CH#29 BYTE 2

        db      10110001b        ; CH#30 BYTE 1
        db      10110100b        ; CH#30 BYTE 2

        db      10110001b        ; CH#31 BYTE 1
        db      10111100b        ; CH#31 BYTE 2

        db      10110001b        ; CH#32 BYTE 1
        db      11000100b        ; CH#32 BYTE 2

        db      10110001b        ; CH#33 BYTE 1
        db      11001100b        ; CH#33 BYTE 2

        db      10110001b        ; CH#34 BYTE 1
        db      11010100b        ; CH#34 BYTE 2

        db      10110001b        ; CH#35 BYTE 1
        db      11011100b        ; CH#35 BYTE 2

        db      10110001b        ; CH#36 BYTE 1
        db      11100100b        ; CH#36 BYTE 2

        db      10110001b        ; CH#37 BYTE 1
        db      11101100b        ; CH#37 BYTE 2

        db      10110001b        ; CH#38 BYTE 1
        db      11110100b        ; CH#38 BYTE 2

        db      10110001b        ; CH#39 BYTE 1
        db      11111100b        ; CH#39 BYTE 2

        db      10110010b        ; CH#40 BYTE 1
        db      00000100b        ; CH#40 BYTE 2

        db      10110010b        ; CH#41 BYTE 1
        db      00001100b        ; CH#41 BYTE 2

        db      10110010b        ; CH#42 BYTE 1
        db      00010100b        ; CH#42 BYTE 2

        db      10110010b        ; CH#43 BYTE 1
        db      00011100b        ; CH#43 BYTE 2

        db      10110010b        ; CH#44 BYTE 1
        db      00100100b        ; CH#44 BYTE 2

        db      10110010b        ; CH#45 BYTE 1
        db      00101100b        ; CH#45 BYTE 2

        db      10110010b        ; CH#46 BYTE 1
        db      00110100b        ; CH#46 BYTE 2

        db      10110010b        ; CH#47 BYTE 1
        db      11100100b        ; CH#47 BYTE 2

        db      10110010b        ; CH#48 BYTE 1
        db      01000100b        ; CH#48 BYTE 2

        db      10110010b        ; CH#49 BYTE 1
        db      01001100b        ; CH#49 BYTE 2

        db      10110010b        ; CH#50 BYTE 1
        db      01010100b        ; CH#50 BYTE 2

        db      10110010b        ; CH#51 BYTE 1
        db      01011100b        ; CH#51 BYTE 2

        db      10110010b        ; CH#52 BYTE 1
        db      01100100b        ; CH#52 BYTE 2

        db      10110010b        ; CH#53 BYTE 1
        db      01101100b        ; CH#53 BYTE 2

        db      10110010b        ; CH#54 BYTE 1
        db      01110100b        ; CH#54 BYTE 2

        db      10110010b        ; CH#55 BYTE 1
        db      01111100b        ; CH#55 BYTE 2

        db      10110010b        ; CH#56 BYTE 1
        db      10000100b        ; CH#56 BYTE 2

        db      10110010b        ; CH#57 BYTE 1
        db      10001100b        ; CH#57 BYTE 2

        db      10110010b        ; CH#58 BYTE 1
        db      10010100b        ; CH#58 BYTE 2

        db      10110010b        ; CH#59 BYTE 1
        db      10011100b        ; CH#59 BYTE 2

        db      10110010b        ; CH#60 BYTE 1
        db      10100100b        ; CH#60 BYTE 2

        db      10110010b        ; CH#61 BYTE 1
        db      10101100b        ; CH#61 BYTE 2

        db      10110010b        ; CH#62 BYTE 1
        db      10110100b        ; CH#62 BYTE 2

        db      10110010b        ; CH#63 BYTE 1
        db      10111100b        ; CH#63 BYTE 2

        db      10110010b        ; CH#64 BYTE 1
        db      11000100b        ; CH#64 BYTE 2

        db      10110010b        ; CH#65 BYTE 1
        db      11001100b        ; CH#65 BYTE 2

        db      10110010b        ; CH#66 BYTE 1
        db      11010100b        ; CH#66 BYTE 2

        db      10110010b        ; CH#67 BYTE 1
        db      11011100b        ; CH#67 BYTE 2

        db      10110010b        ; CH#68 BYTE 1
        db      11100100b        ; CH#68 BYTE 2

        db      10110010b        ; CH#69 BYTE 1
        db      11101100b        ; CH#69 BYTE 2

        db      10110010b        ; CH#70 BYTE 1
        db      11110100b        ; CH#70 BYTE 2

        db      10110010b        ; CH#71 BYTE 1
        db      11111100b        ; CH#71 BYTE 2

        db      10110011b        ; CH#72 BYTE 1
        db      00000100b        ; CH#72 BYTE 2

        db      10110011b        ; CH#73 BYTE 1
        db      00001100b        ; CH#73 BYTE 2

        db      10110011b        ; CH#74 BYTE 1
        db      00010100b        ; CH#74 BYTE 2

        db      10110011b        ; CH#75 BYTE 1
        db      00011100b        ; CH#75 BYTE 2

        db      10110011b        ; CH#76 BYTE 1
        db      00100100b        ; CH#76 BYTE 2

        db      10110011b        ; CH#77 BYTE 1
        db      00101100b        ; CH#77 BYTE 2

        db      10110011b        ; CH#78 BYTE 1
        db      00110100b        ; CH#78 BYTE 2

        db      10110011b        ; CH#79 BYTE 1
        db      00111100b        ; CH#79 BYTE 2

        db      10110011b        ; CH#80 BYTE 1
        db      01000100b        ; CH#80 BYTE 2

        db      10110011b        ; CH#81 BYTE 1
        db      01001100b        ; CH#81 BYTE 2

        db      10110011b        ; CH#82 BYTE 1
        db      01010100b        ; CH#82 BYTE 2

        db      10110011b        ; CH#83 BYTE 1
        db      01011100b        ; CH#83 BYTE 2

        db      10110011b        ; CH#84 BYTE 1
        db      01100100b        ; CH#84 BYTE 2

        db      10110011b        ; CH#85 BYTE 1
        db      01101100b        ; CH#85 BYTE 2

        db      10110011b        ; CH#86 BYTE 1
        db      01110100b        ; CH#86 BYTE 2

        db      10110011b        ; CH#87 BYTE 1
        db      11111100b        ; CH#87 BYTE 2

        db      10110011b        ; CH#88 BYTE 1
        db      10000100b        ; CH#88 BYTE 2

        db      10110011b        ; CH#89 BYTE 1
        db      10001100b        ; CH#89 BYTE 2

;%E

end

