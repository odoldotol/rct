;---------------------------------------------------------------------------
; DAE HWA ENT VERSION ( DHE TX  -----> RCT RX) 
;  MCA DATA WORD DEL

; ***	173Mhz
;  BAND A    14CH  12.5Khz(173.6250 ~ 173.7875)  DIP SW  1.2.3.4 
;  BAND B    21CH  12.5Khz(173.0250 ~ 173.2750)  DIP SW  1.2.3.4 (7)
;
;      POLESTAR MAIN BOARD RECEIVER PROGRAM
;
;			DATE: 	2005 . 06 . 10
;			VERSION: 1.0
;		        EDIT BY: KIM SEONG WEON
;
;---------------------------------------------------------------------------
;
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
rx_channel:     DS	1	
tx_channel:	DS	1	
channel_id:	DS	1
;CHBUF1:	        DS    	1
;CHBUF2:		DS	1
BIT_CONT_32:	DS	1
PATTERN1:	DS	1
PATTERN2:	DS	1
PATTERN3:	DS	1
PATTERN4:	DS	1
SQ_L_CNT0:	DS	1
SQ_L_CNT1:	DS	1
PARITY_BYTE:	DS	1
SYNC_ERR_CNT0:	DS	1
SYNC_ERR_CNT1:	DS	1
RECWAIT_CUT0:	DS	1
RECWAIT_CUT1:   DS	1
ERR_BIT_COUNT:	DS	1	
MCA_ID_CNT:	DS	1	
TX_SEND_1:	DS	1	;send data memory
TX_SEND_2:	DS	1
TX_SEND_3:	DS	1
TX_SEND_4:	DS	1
PARITY_COUNT:	DS	1
ADDRESS1:	DS	1
ADDRESS2:	DS	1
RX_TXD_CNT:	DS	1
AR20ER_1:	DS	1	;AR20ER check time
AR20ER_2:	DS	1
AUTO_RESET0:	DS	1
AUTO_RESET1:	DS	1
AUTO_RESET2:	DS	1
ENDS

BSEG


;------------------------------------
;	modem chip pin description
;------------------------------------
MODEM_RT 	bit 	p3.2		;int0
MODEM_RD 	bit 	p3.0
MODEM_SD	bit	p3.1
MODEM_ST	bit	p3.3
RX_TXD		bit	p2.7



;------------------------------------------------------------------------
RST             BIT     P1.2		;PLL_CE
CPS             BIT     P1.0		;PLL_CLK
RF_SI           BIT     P1.1		;PLL_DATA
TXSW		BIT	P1.4		;TX_EN/vco
RXSW      	BIT     P1.5		;RX_EN/pwsw
LOCK_OUT        BIT     P1.6		;LOCK
SQ_OUT		BIT	P1.3		;SQ_DET

WATCH_DOG	bit	p1.7
DACO		bit	p3.4		; 
AR20ER		bit	p3.5		;L-system error

READ_BIT	bit	00h
PARITY_ERR      bit     01h
SEND_BIT	bit	02h
RECEIVER_OK	bit	03h

SYNC_BIT	bit	10h		;WORD FIND(bit add 22h)
NO1_WORD_BIT	bit	11h
MCA_WORD_BIT  	bit     12h             ;   //
NO2345_BIT	bit	13h		;   // 
ENDS


;------------------------------
;	START OF PROGRAM
;------------------------------

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
	clr	watch_dog  		;watch dog clock on
        mov     sp,#60h
	setb	TXSW		
	setb	RXSW		
        setb    RST
        setb    CPS
        setb    RF_SI

        mov     psw,#00h
        mov     ie,#00000000b   

; INTERNAL RAM CLEAR

	clr	DACO			;L-->DATA CLEAR
	clr	RX_TXD
	clr	PARITY_ERR
	clr	SEND_BIT
	mov	a,#00h
	mov	BIT_CONT_32,a
	mov	PARITY_COUNT,a
	mov	RX_TXD_CNT,a		;RX_ON_SIREN COUNT
	mov	address1,a
	mov	address2,a
	mov	RECWAIT_CUT0,a
	mov	RECWAIT_CUT1,a


			;CHANNEL/ ID INPUT
				;// 173.6250 - 173.7875Mhz  14ch	
	setb	watch_dog
;------------------------------------------------------------------
	mov	a,p2			;ch data
	nop
	cpl	a
	anl	a,#01111111b
	mov	channel_id,a		;channel_id
	anl	a,#01000000b
	jnz	band_B

band_A:				;173.6250 ~ 173.7875Mhz(14 ch)
	mov	a,channel_id		;channel_id
	anl	a,#00001111b		;00001110b ch over
	cjne	a,#00001110b,choga_A	;a>#, c=0
choga_a:
	jnc	INIT			;c=0, ch over
	add	a,#7ah			;RX CH/ (7ah)+dip 4bit
	mov	rx_channel,a
	nop
	mov	a,channel_id		;channel_id
	anl	a,#00001111b
	add	a,#42h			;TX CH/ (42h)+dip 4bit
	mov	tx_channel,a
	ajmp	RTX_173SET

band_B:				;173.0250 ~ 173.2750Mhz(21 ch)
	mov	a,channel_id		;channel_id
	anl	a,#00011111b		;00010101b ch over
	cjne	a,#00010101b,choga_B	;a>#, c=0
choga_B:
	jnc	INIT			;c=0, ch over

	add	a,#4ah			;RX CH/ (4ah)+dip 5bit
	mov	rx_channel,a
	nop
	mov	a,channel_id		;channel_id
	anl	a,#00011111b
	add	a,#12h			;TX CH/ (12h)+dip 5bit
	mov	tx_channel,a

RTX_173SET:
;==============================================================
;	MAIN R CNTR / RX Reference Frequency Set
;==============================================================
SET_173RX:
        clr	RST
        mov     r5,#5
        lcall   delay2

        mov     a,#0f6h		          
        mov     r0,#8
        lcall   SET_CHANNEL_SUB

        mov     a,#0a4h
        mov     r0,#8
        lcall   SET_CHANNEL_SUB

        mov     a,#80h				 ; CTL[1:0] = 1,0
        mov     r0,#2
	lcall   SET_CHANNEL_SUB

        mov	r5,#2                   
        lcall   delay2

        setb	RST
        mov     R5,#5
        lcall   delay2

;==============================================================
;       MAIN N CNTR / RX Frequency Set
;==============================================================
RX_FREQUENCY_SET:
        clr	RST

        mov     r5,#5
        lcall   delay2

        mov     a,#2fh			;RX MSB 8bit(2fh)
        mov     r0,#8
        lcall   SET_CHANNEL_SUB

        mov     a,rx_channel
        mov     r0,#8
        lcall   SET_CHANNEL_SUB

        mov     a,#0c0h	                 ; CTL[1:0] = 1,1
        mov     r0,#2
        lcall   SET_CHANNEL_SUB

        mov	r5,#2                   
        lcall   delay2

        setb	RST
        mov     r5,#5
        lcall   delay2
;************************************************************
;       LOCK DETECT SETUP
;************************************************************
;       clr	RST
;       mov     r5,#5
;       lcall   delay2

;       mov     a,#36h		; PLL LOCK + reference frequency setting(RX)
;       mov     r0,#8		; 12.5 kHz
;       lcall   SET_CHANNEL_SUB

;       mov     a,#0a4h
;       mov     r0,#8
;       lcall   SET_CHANNEL_SUB

;       mov     a,#00h                 ; CTL[1:0] = 1,0
;       mov     r0,#2					
;       lcall   SET_CHANNEL_SUB
		
;       mov     r5,#5
;       lcall   delay2 
        
;       setb    RST

;********************************************************************
;	AUX R CNTR / TX Reference Frequency Set
;--------------------------------------------------------------------

       	clr     RST				
        mov	r5,#2                   
        lcall   delay2

TX_173_CHANNEL:
        mov     a,#0b6h				;0B6h			
        mov     r0,#8                                       
        lcall   SET_CHANNEL_SUB

        mov     a,#0a4h				
        mov     r0,#8
        lcall   SET_CHANNEL_SUB
        
        mov     a,#00h				; CTL[1:0] = 0,0
        mov     r0,#2					
        lcall   SET_CHANNEL_SUB

        mov	r5,#2                   
        lcall   delay2

	setb    RST					
        mov	r5,#2                   
        lcall   delay2

;-------------------------------------------
;       AUX N CNTR / TX Frequency Set					
;-------------------------------------------
        clr     RST				
        mov	r5,#2                   
        lcall   delay2

        mov     a,#36h			;TX MSB 8bit(36h)
        mov     r0,#8
        lcall   SET_CHANNEL_SUB

        mov     a,tx_channel
        mov     r0,#8
        lcall   SET_CHANNEL_SUB

        mov     a,#40h                   ;CTL[1:0] = 0,1
        mov     r0,#2
        lcall   SET_CHANNEL_SUB

        mov	r5,#2                   
        lcall   delay2

	setb    RST				

        mov     r5,#2                   
        lcall   delay2

;--------------------------------------------------------------------
;	Lock Detect setup
;--------------------------------------------------------------------
	clr     RST						
        mov	r5,#2                   
        lcall   delay2
 
        mov     a,#56h			;RX L=36h,TX L=56h,
        mov     r0,#8                   
        lcall   SET_CHANNEL_SUB

        mov     a,#0a4h				
        mov     r0,#8
        lcall   SET_CHANNEL_SUB


        mov     a,#00h					; CTL[1:0] = 0,0
        mov     r0,#2					
        lcall   SET_CHANNEL_SUB			

        mov	r5,#5                   
        lcall   delay2
	
	setb	RST
	setb	RF_SI
	setb	CPS

	clr	TXSW				;************
	clr	RXSW			;LOCK DET=>TXSW and RXSW=L
        mov	r5,#5                   
        lcall   delay1

;LOCK BIT CHECK----------------------------

	jnb	LOCK_OUT,LO_DEL_1
	ajmp	ON_AIR			
LO_DEL_1:					;lock det time delay
	mov	r5,#2
	lcall	delay1
	jnb	LOCK_OUT,LO_DEL_2
	ajmp	ON_AIR			
LO_DEL_2:					;lock det time delay
	mov	r5,#4
	lcall	delay1
	jnb	LOCK_OUT,LO_DEL_3
	ajmp	ON_AIR			
LO_DEL_3:					;lock det time delay
	mov	r5,#8
	lcall	delay1
	jnb	LOCK_OUT,LO_DEL_4
	ajmp	ON_AIR			
LO_DEL_4:					;lock det time delay
	mov	r5,#16
	lcall	delay1
	jb	LOCK_OUT,ON_AIR

;-----rf modul init---------------------
        clr     RST				
        mov	r5,#2                   
        lcall   delay2

        mov     a,#00h			;TX MSB 8bit(36h)
        mov     r0,#8
        lcall   SET_CHANNEL_SUB

        mov     a,00h
        mov     r0,#8
        lcall   SET_CHANNEL_SUB

        mov     a,#00h                   ;CTL[1:0] = 0,0
        mov     r0,#2
        lcall   SET_CHANNEL_SUB

        mov	r5,#2                   
        lcall   delay2
	setb    RST				
	ajmp	RTX_173SET		;RF RESETING



ON_AIR:
 
;------------------------------
;	Interrupt Enable
;------------------------------
	setb	TXSW
	clr	RXSW			;RECEIVER MODE
aa:
	mov	r5,#5
	lcall	delay1

	setb	DACO
	setb	RX_TXD	

	clr 	watch_dog
	mov	r5,#20
	lcall 	delay1
	setb	watch_dog
	mov	r5,#20

	ajmp	aa




	clr	Receiver_OK
	mov	AR20ER_1,#00h
	mov	AR20ER_2,#00h
	mov	WORD_FIND,#00h
	mov	RX_TXD_CNT,#00h
	mov	MCA_ID_CNT,#00h
	mov	SQ_L_CNT0,#00h
	mov	SQ_L_CNT1,#00h
	mov	SYNC_ERR_CNT0,#00h
	mov	SYNC_ERR_CNT1,#00h
	mov	ERR_BIT_COUNT,#00h
	mov	AUTO_RESET0,#00h
	mov	AUTO_RESET1,#00h
	mov	AUTO_RESET2,#00h
	setb	it0		;TCON
	setb	ex0		;IE.0
	setb	ea		;IE.7


;------------------------------------------------------------------
; main loop
;-----------

MAIN:
	setb	watch_dog			;watch dog clock 

	jnb	Receiver_OK,MAIN_1
;-------------------------------------------
;  error check=fr reseting or init
;  TX ON--OFF = CPU reset
;-------------------------------------------	
	jb	AR20ER,MAIN_1
	inc	AR20ER_1
	mov	a,AR20ER_1
	cjne	a,#128,MAIN_1
	mov	AR20ER_1,#00h
	inc	AR20ER_2
	mov	a,AR20ER_2
	cjne	a,#25,MAIN_1
	clr	ea
	clr	Receiver_OK

;	ljmp	RTX_173SET			;rf reseting	

;-------------------------------------------
	mov	r5,#256				;CPU	reset
	lcall	delay3		
;-------------------------------------------
MAIN_1:


;;	mov	a,SYNC_ERR_CNT1
;;	cjne	a,#5,MCA_CHECK		;0.1sec(160) * 5 ?
;;	clr	DACO
;;	clr	SEND_BIT

MCA_CHECK:
;;	mov	a,MCA_ID_CNT
;;	cjne	a,#4,ERROR_DET		;10
;;	clr	DACO
;;	clr	SEND_BIT

ERROR_DET:
	mov	a,ERR_BIT_COUNT	
	cjne	a,#8,MAINSTART		;10
	clr	DACO
	clr	SEND_BIT

MAINSTART:
;	jb	SQ_OUT,DATA_CHECK		;TX OFF / SQ_OUT=L
;	mov	a,SQ_L_CNT1			;128(0.1) * ?
;	cjne	a,#4,DATA_CHECK
;	clr	DACO
;	clr	SEND_BIT
;	clr	ea	

;	ajmp	ON_AIR

DATA_CHECK:
	jb	SEND_BIT,RECEIVE		;receive(H)
	ajmp	main
		
RECEIVE:				
	mov	a,WORD_FIND			; pattern flag
	cjne    a,#00001111b,REC_WAIT
	mov	WORD_FIND,#00h	
	mov	ERR_BIT_COUNT,#00h
	mov	RECWAIT_CUT0,#00h
	mov	RECWAIT_CUT1,#00h
	mov	MCA_ID_CNT,#00h
	mov	SQ_L_CNT0,#00h
	mov	SQ_L_CNT1,#00h
	mov	SYNC_ERR_CNT0,#00h
	mov	SYNC_ERR_CNT1,#00h
	
;	jb	p3.7,rxsiren			;jp pin B
	setb	Receiver_OK			;rx siren clean
	mov	AR20ER_2,#00h
	nop

;rxsiren:
;	jnb	Receiver_OK,SIREN_TXD

 	setb	DACO				; DATA PASS
	setb	RX_TXD				; p2.7 (SIR)

	ajmp	main


REC_WAIT:
	inc	RECWAIT_CUT0
	mov	a,RECWAIT_CUT0

	cjne	a,#0ffh,mainjump
	mov	RECWAIT_CUT0,#00h
	inc	RECWAIT_CUT1
	mov	a,RECWAIT_CUT1
	cjne	a,#05fh,mainjump		;05fh/ 04h-no3ok,no4,5no
	mov	RECWAIT_CUT1,#00h
	mov	WORD_FIND,#00h
	clr	SEND_BIT			;NOISE  rx output clear
;	clr	DACO

mainjump:
	ajmp	main
	

;------------------------------
;SIREN_TXD:
;	clr	ea
;	setb	Receiver_OK
	
;	ljmp	RX_ON_SIREN




;---------------------------------------------------------------------------
;	External Interrupt 0
;---------------------------------------------------------------------------
int_0:
	push	acc


;	jb	SQ_OUT,action_data		;H-> action
;	clr	SEND_BIT			;TX -> OFF
;	clr	DACO
;	inc	SQ_L_CNT0
;	mov	a,SQ_L_CNT0
;	cjne	a,#128,int_00
;	mov	SQ_L_CNT0,#00h
;	inc	SQ_L_CNT1
;int_00:	
;	ajmp	int_0_ret

;--------------------------------------------
action_data:

;-----auto cpu reset--------------
	jb	Receiver_OK,action_sta
	inc	AUTO_RESET0
	mov	a,AUTO_RESET0
	cjne	a,#400,action_sta		;0.276msec
	mov	AUTO_RESET0,#00h

	inc	AUTO_RESET1
	mov	a,AUTO_RESET1
	cjne	a,#300,action_sta		;83msec
	mov	AUTO_RESET1,#00h

	inc	AUTO_RESET2
	mov	a,AUTO_RESET2
;	cjne	a,#2,action_sta			;10sec
;	cjne	a,#12,action_sta		;1min
;	cjne	a,#24,action_sta		;2min
;	cjne	a,#36,action_sta		;3min
;	cjne	a,#48,action_sta		;4min
;	cjne	a,#60,action_sta		;50min
;	cjne	a,#120,action_sta		;10min
;	cjne	a,#180,action_sta		;15min
;	cjne	a,#240,action_sta		;20min
;	cjne	a,#300,action_sta		;25min
	cjne	a,#360,action_sta		;30min
;	cjne	a,#420,action_sta		;35min
;	cjne	a,#480,action_sta		;40min

	mov	AUTO_RESET1,#00h

;----cpu reset--------------
	mov	r5,#256				;CPU	reset
	lcall	delay3				;watch dog		
;---------------------------

action_sta:
	mov	c,MODEM_RD
	mov	READ_BIT,c

	mov	a,WORD_FIND			; pattern flag
	cjne	a,#00000000b,no1_check		; check pattern flag
	acall	SYNC_WORD
	ajmp	int_0_ret

no1_check:
	cjne	a,#00000001b,mca_data1		; check pattern flag
	acall	NO1_DATA_WORD
	ajmp	int_0_ret

mca_data1:
	cjne	a,#00000011b,no2345_data2		; check pattern flag

	setb	mca_word_bit
;;	acall	MCA_DATA_WORD
;;	ajmp	int_0_ret

no2345_data2:
	cjne	a,#00000111b,word_clear_1		; check pattern flag
	acall	NO2345_DATA_WORD
	ajmp	int_0_ret

word_clear_1:
	cjne	a,#00001111b,word_clear_2
	ajmp	int_0_ret

word_clear_2:
	clr	ea
	ljmp	ON_AIR

int_0_ret:
	clr	watch_dog
	setb	ea
	pop	acc
        reti


;---------------------------------------------------------------------------
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
	cjne	a,#00000000b,sync_error		;SYNC ID CHECK
	mov	a,PATTERN4
	cjne	a,#11000000b,sync_error		;stop 2 bit

	mov	WORD_FIND,#00000001b		;sync_bit set
;	setb	SYNC_BIT			;bit add 10b
	setb	SEND_BIT
	mov	SYNC_ERR_CNT0,#00h
	mov	SYNC_ERR_CNT1,#00h

	ajmp	SYNC_RET

sync_error:

	mov	WORD_FIND,#00h

	inc	SYNC_ERR_CNT0
	mov	a,SYNC_ERR_CNT0
	cjne	a,#160,SYNC_RET
	mov	SYNC_ERR_CNT0,#00h
	inc	SYNC_ERR_CNT1

SYNC_RET:
	mov	BIT_CONT_32,#00h
	ret

;---------------------------------------------------------------------------
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
	jb	PARITY_ERR,no1_data_err

	mov	a,PATTERN1
	anl	a,#00000111b
	cjne	a,#00000101b,no1_data_err

	mov	r7,PATTERN1			;PATTERN1=PATTERN3
	mov	a,PATTERN3
	cpl	a
	cjne	a,r7,no1_data_err

	mov	a,PATTERN2			;PATTERN2=PATTERN4
	anl	a,#01111111b			;parity clear
	mov	r7,a
	mov	a,PATTERN4
	cpl	a
	anl	a,#01111111b
	cjne	a,r7,no1_data_err

	anl	a,#01100000b			;opa,opb det
	jnz	no1_data_err
;------------------------------------

	mov	address1,PATTERN1
	mov	address2,PATTERN2
	setb	no1_word_bit
	setb	send_bit

	ajmp	no1_ret1
;------------------------------------
no1_data_err:
	inc	ERR_BIT_COUNT
	mov	WORD_FIND,#00h
	clr	send_bit

no1_ret1:
	mov	BIT_CONT_32,#00h		;RF SETING
	ret

no1_ret:
	ret

;---------------------------------------------------------------------------
MCA_DATA_WORD:		
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
	cjne	a,#32,mca_ret

	lcall	PARITY_CHECK
	jb	PARITY_ERR,mca_id_err

	mov	r7,PATTERN1			;PATTERN1=PATTERN3
	mov	a,PATTERN3
	cpl	a
	cjne	a,r7,mca_id_err

	mov	a,PATTERN2			;PATTERN2=PATTERN4
	anl	a,#01111111b
	mov	r7,a
	mov	a,PATTERN4
	cpl	a
	anl	a,#01111111b
	cjne	a,r7,mca_id_err

;--CH ID CHECK---------------------	
	mov	a,PATTERN1			;PATTERN1=MCA WORD ADD
	cjne	a,#01100010b,mca_id_err		;01100010b

	mov	a,PATTERN2			;PATTERN2=MCA ID
	anl	a,#01111111b
	cjne	a,channel_id,mca_id_err		;ID P(0)7,6,5,4,3,2,1b

	setb	mca_word_bit
	mov	MCA_ID_CNT,#00h
	ajmp	mca_ret1
;------------------------------------
mca_id_err:
	mov	WORD_FIND,#00h
	clr	send_bit
	inc	MCA_ID_CNT
	inc	ERR_BIT_COUNT

mca_ret1:
	mov	BIT_CONT_32,#00h
	ret

mca_ret:
	ret

;---------------------------------------------------------------------------
NO2345_DATA_WORD:			
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
	cjne	a,#32,no2345_ret

	lcall	PARITY_CHECK
	jb	PARITY_ERR,no2345_data_err

	mov	r7,PATTERN1			;PATTERN1=PATTERN3
	mov	a,PATTERN3
	cpl	a
	cjne	a,r7,no2345_data_err

	mov	a,PATTERN2			;PATTERN2=PATTERN4
	anl	a,#01111111b
	mov	r7,a
	mov	a,PATTERN4
	cpl	a
	anl	a,#01111111b
	cjne	a,r7,no2345_data_err
	setb	no2345_bit
	setb	send_bit

	ajmp	no2345_ret1
;------------------------------------

no2345_data_err:
	inc	ERR_BIT_COUNT
	mov	WORD_FIND,#00h
	clr	send_bit

no2345_ret1:
	mov	BIT_CONT_32,#00h		;RF SETING
	ret

no2345_ret:
	ret










;======== RX POWER ON SIREN ==============================
RX_ON_SIREN:
	mov	a,RX_TXD_CNT
;---------------------------------
	cjne	a,#20,siren_send		;0.1sec * ? RX SIREN TIME
;---------------------------------
	setb	DACO
	setb	RX_TXD
	setb	ea

	ljmp	MAIN

siren_send:
	jc	start_siren		;a>#20 => c=0
	ljmp	ON_AIR	

start_siren:
	setb	watch_dog
	inc	RX_TXD_CNT

	mov	a,#00000001b	
	mov	r0,#8
	lcall	send_bits

	clr	watch_dog
	mov	a,#00000000b	
	mov	r0,#8
	lcall	send_bits

	setb	watch_dog
	mov	a,#00000000b
	mov	r0,#8
	lcall	send_bits

	clr	watch_dog
	mov	a,#11000000b
	mov	r0,#8
	lcall	send_bits
	
;NO1_DATA_WORD:		;M-ADDESS / OPA,OPB   SEND	

	setb	watch_dog
	mov	Parity_Count,#00h
	mov	a,address1		; 5,4,3,2,1(101)
	mov	TX_SEND_1,a
	mov	r0,#8			; 8 Bit
	lcall	send_bits

	clr	watch_dog
	mov	a,address2		; B,A,10,9,8,7,6
	mov	TX_SEND_2,a
	mov	r0,#7			; 7 Bit
	lcall	send_bits

	lcall	Parity_Bit		; 1 Bit


;!@!@!@! ---NO1 TX DATA REVERSED ---!@!@!@!
	setb	watch_dog
	mov	Parity_Count,#01h
	mov	a,TX_SEND_1
	cpl	a
	mov	r0,#8				; 8 Bit
	lcall	send_bits

	clr	watch_dog
	mov	a,TX_SEND_2
	cpl	a
	mov	r0,#7				; 7 Bit
	lcall	send_bits

	lcall	Parity_Bit			; 1 Bit

;-------------------------------------------------------------------------
;NO2_DATA_WORD:	 

	setb	watch_dog
	mov	Parity_Count,#00h
	mov	a,#000000110b		; NO2 ADD  "011"
	mov	TX_SEND_1,a
	mov	r0,#3
	lcall	send_bits

	clr	watch_dog
	mov	a,#00000000b		
	mov	TX_SEND_2,a
	mov	r0,#8			; 8 bit
	lcall	send_bits

	setb	watch_dog
	mov	a,#00000100b		;siren bit
	mov	TX_SEND_3,a
	mov	r0,#4			; 4 bit
	lcall	send_bits

	lcall	Parity_Bit

;!@!@!@! ---NO2 TX DATA REVERSED ---!@!@!@!
	clr	watch_dog
	mov	Parity_Count,#01h
	mov	a,TX_SEND_1
	cpl	a
	mov	r0,#3				; 3 Bit
	lcall	send_bits

	setb	watch_dog
	mov	a,TX_SEND_2
	cpl	a
	mov	r0,#8				; 8 Bit
	lcall	send_bits

	clr	watch_dog
	mov	a,TX_SEND_3
	cpl	a
	mov	r0,#4				; 4 Bit
	lcall	send_bits

	lcall	Parity_Bit			; 1 Bit

;-------------------------------------------------------------------------
;NO3_DATA_WORD:		 
	setb	watch_dog
	mov	Parity_Count,#00h
	mov	a,#000000011b		; NO3 ADD  "011"
	mov	TX_SEND_1,a
	mov	r0,#3
	lcall	send_bits

	clr	watch_dog
	mov	a,#00000000b
	mov	TX_SEND_2,a
	mov	r0,#8			; 8 Bit
	lcall	send_bits

	setb	watch_dog
	mov	a,#00000000b
	mov	TX_SEND_3,a		
	mov	r0,#4			; 4 bit
	lcall	send_bits

	lcall	Parity_Bit

;!@!@!@! ---NO3 TX DATA REVERSED ---!@!@!@!
	clr	watch_dog
	mov	Parity_Count,#01h
	mov	a,TX_SEND_1
	cpl	a
	mov	r0,#3				; 3 Bit
	lcall	send_bits

	setb	watch_dog
	mov	a,TX_SEND_2
	cpl	a
	mov	r0,#8				; 8 Bit
	lcall	send_bits

	clr	watch_dog
	mov	a,TX_SEND_3
	cpl	a
	mov	r0,#4				; 4 Bit
	lcall	send_bits

	lcall	Parity_Bit			; 1 Bit

	ljmp	RX_ON_SIREN



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
	clr	rx_txd			;setb	rx_txd
	inc	parity_count
	ajmp	send_3

send_2:
	setb	rx_txd			;clr	rx_txd

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
	clr	rx_txd			;setb	rx_txd
	ajmp	PP_3
PP_2:
	setb	rx_txd			;clr	rx_txd
PP_3:
	ret
;----------------------------------------------------------------


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

;-----------------------------------
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
	mov	r5,#1		;2
	acall 	delay2		; 2.5 uS delay

	rlc	a		; rotate A 
	jnc	set_ch_1	; check the lowest bit	
	setb	rf_si		; set SI high
	ajmp	set_ch_2
SET_CH_1:
	clr	rf_si		; set SI low
SET_CH_2:

	mov	r5,#2		;5
	acall 	delay2		; 2.5 uS delay
	clr	cps
	mov	r5,#1		;2
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
	setb	watch_dog
	mov	r6,#40
DEL:	mov	r7,#249
$1:	djnz	r7,$1
	djnz	r6,DEL
	clr	watch_dog
	djnz	r5,DELAY1
	ret
	
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

;---- non watch_dog --------------
DELAY3:
	mov	r6,#40
DEL1:	mov	r7,#249
$11:	djnz	r7,$11
	djnz	r6,DEL1
	djnz	r5,DELAY3
	ret
;----------------------------------

;%E

end
