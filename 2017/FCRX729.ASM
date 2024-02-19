;---------------------------------------------------------------------------
; ***	TMX729
;           59CH  12.5Khz(447.2625 ~ 447.9875)   
;	        POLESTAR MAIN BOARD RECEIVER PROGRAM
;
;			DATE: 	2005 . 01 . 28
;			VERSION: 1.0
;		        EDIT BY: KIM SEONG WEON
;
;---------------------------------------------------------------------------
;
;WORD ADDRESS NO1-101b/MCA-010b/NO2-110b/NO3-011b/NO4-100b/NO5-001b
;---------------------------------------------------------------------------
;
; 	data definition	
;
;---------------------------------------------------------------------------


		ORG	0020H
ERROR_BYTE:	DS	1	;00h~07h(20h)
ERROR_COUNT:	DS	1	;08h~0Fh(21h)
WORD_FIND:      DS      1	;10h~17h(22h)  bit ADD 10/11/12/13----

		ORG	0030H
CHANNEL_0:      DS	1	;CH REC DET
CHANNEL_1:	DS	1	;CH SETING
CHBUF1:	        DS    	1
CHBUF2:		DS	1
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
AR20ER_CNT:	DS	1	;AR20ER check time
mca_dw_l:	DS	1	;MCA WORD LSB 8BIT SEND	
ch_dip_sw:	DS	1
chan_buf:	DS	1
DACO_CNT:	DS	1
AUTO_RESET0:	DS	1	;tx off/cpu reset
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

READ_BIT	bit	00h		;20h
PARITY_ERR      bit     01h
SEND_BIT	bit	02h
Receiver_OK	bit	03h
scan_mode	bit	04h
ch2_set		bit	05h
SWEET_SET	bit	06h

SYNC_BIT	bit	10h		;WORD FIND(bit add 22h)
NO1_WORD_BIT	bit	11h
MCA_WORD_BIT  	bit     12h             ;   //
NO2345_BIT	bit	13h		;   // 
;14h,15h,16h,17h---not
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
	clr	WATCH_DOG  		;watch dog clock on
        mov     sp,#60h
	setb	VCO		;729RX
	setb	PWSW		;729RX
        setb    RST
        setb    CPS
        setb    RF_SI

        mov     psw,#00h
        mov     ie,#00000000b   

; INTERNAL RAM CLEAR

	clr	DACO			;L-->DATA CLEAR

	clr	PARITY_ERR
	clr	SEND_BIT
	clr	ch2_set

	mov	a,#00h
	mov	BIT_CONT_32,a
	mov	PARITY_COUNT,a
	mov	RX_TXD_CNT,a		;RX_ON_SIREN COUNT
	mov	address1,a
	mov	address2,a
	mov	RECWAIT_CUT0,a
	mov	RECWAIT_CUT1,a
	mov	AUTO_RESET0,a	
	mov	AUTO_RESET0,a	
	mov	AUTO_RESET0,a	
;-------------------------------
;CHANNEL/ ID INPUT

	setb	watch_dog
	mov	a,p2
	nop
	cpl	a
	anl	a,#01111111b			;daco control
	mov	ch_dip_sw,a			;.7,sc1,sc2 buffer

	anl	a,#00111111b			;daco,dip.7 clear
	mov	channel_0,a

	mov	a,ch_dip_sw
	anl	a,#01000000b			;scan mode

	cjne	a,#00000000b,frq_scan		
	ajmp	ch59_set			;7-OFF / HITEC MODE

frq_scan:
	setb	scan_mode			;scan mode set
	mov	a,ch_dip_sw
	anl	a,#00110000b			

	cjne	a,#00000000b,spco_1
	mov	mca_dw_l,#11100010b
	ajmp	spco_4
spco_1:
	cjne	a,#00010000b,spco_2
	mov	mca_dw_l,#11101010b
	ajmp	spco_4
spco_2:
	cjne	a,#00100000b,spco_3
	mov	mca_dw_l,#11110010b
	ajmp	spco_4
spco_3:
	cjne	a,#00110000b,spco_4
	mov	mca_dw_l,#11111010b
spco_4:
	mov	a,channel_0			;lsb 4bit mark
	anl	a,#00001111b			;init frq

;---447.8625~~447.9875-------------------
frq_1:
	cjne	a,#00h,frq_2
	mov	channel_0,#00110000b
	mov	chan_buf,channel_0	
	ajmp	rfch_set
frq_2:
	cjne	a,#01h,frq_3
	mov	channel_0,#00110001b
	mov	chan_buf,channel_0	
	ajmp	rfch_set
frq_3:
	cjne	a,#02h,frq_4
	mov	channel_0,#00110010b
	mov	chan_buf,channel_0	
	ajmp	rfch_set
frq_4:
	cjne	a,#03h,frq_5
	mov	channel_0,#00110011b
	mov	chan_buf,channel_0	
	ajmp	rfch_set
frq_5:
	cjne	a,#04h,frq_6
	mov	channel_0,#00110100b
	mov	chan_buf,channel_0	
	ajmp	rfch_set
frq_6:
	cjne	a,#05h,frq_7
	mov	channel_0,#00110101b
	mov	chan_buf,channel_0	
	ajmp	rfch_set
frq_7:
	cjne	a,#06h,frq_8
	mov	channel_0,#00110110b
	mov	chan_buf,channel_0	
	ajmp	rfch_set
frq_8:
	cjne	a,#07h,frq_9
	mov	channel_0,#00110111b
	mov	chan_buf,channel_0	
	ajmp	rfch_set
frq_9:
	cjne	a,#08h,frq_10
	mov	channel_0,#00111000b
	mov	chan_buf,channel_0	
	ajmp	rfch_set
frq_10:
	cjne	a,#09h,frq_11
	mov	channel_0,#00111001b
	mov	chan_buf,channel_0	
	ajmp	rfch_set
frq_11:
	cjne	a,#0ah,frq_end
	mov	channel_0,#00111010b
	mov	chan_buf,channel_0	
	ajmp	rfch_set
frq_end:
	mov	channel_0,#11000000b		;11CH OVER ERROR
	mov	chan_buf,channel_0	
	ajmp	rfch_set


ch59_set:
	clr	scan_mode			;0=manual mode 
	mov	mca_dw_l,#01100010b		;mca base code

;----------------- scan reseting --------------
rfch_set:
	setb	VCO		;729RX
	setb	PWSW		;729RX
        setb    RST
        setb    CPS
        setb    RF_SI

	mov	a,channel_0
	rl	a				; channel data = 2*data
	mov	channel_1,a

	mov     dptr,#CHANNEL_DATA
	movc    a,@a+dptr      			 ; move channel data byte #1 
	mov     CHBUF1,a

	mov     a,channel_1
	inc     a
	movc    a,@a+dptr       ; move channel data byte #2                   
	mov     CHBUF2,a
	clr	watch_dog	;watch dog clock 

;TMX729_SETING:
;=======================================
;	TMX729 Reference Frequency Set
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

	mov	r5,#2
	acall 	delay2		; 2.5 uS delay
        setb    rst
	mov	r5,#2		; 20mS delay
	acall	delay2

;=======================================
;	TMX729 TX Frequency Set
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

;	mov	r5,#2			;4
;	acall 	delay2			; 2.5 uS delay
;       setb    rst
;	mov	r5,#20			;100      20mS delay
;	acall	delay2

;=======================================
;	TMX729 RX Frequency Set
;=======================================
	clr	rst			; RX requency setting
	mov	r5,#2			; 4 uS delay
	acall	delay2

	mov	a,#10100100b		; RX TURN ON			
	mov	r0,#8
	acall	set_channel_sub

	mov     a,CHBUF1
	mov	r0,#8
	acall	set_channel_sub

	mov     a,CHBUF2
	mov	r0,#6			;;;;;;;;555
	acall	set_channel_sub

	mov     a,#10000000b		;21+1
	mov	r0,#1
	acall	set_channel_sub
	
	setb	rst
	mov	r5,#2			;4
	acall 	delay2			 

	setb	sq_out

;- sq_check_time (rxd det delay) ------------

	mov	r5,#32		   	;3.6864
time_1:
	setb	watch_dog	;watch dog clock 
	mov	r6,#0ffh
D1:
	djnz	r6,D1
	clr	watch_dog		;watch dog clock 
	djnz	r5,time_1

	mov	r5,#64
time_2:
	setb	watch_dog		;watch dog clock 
	mov	r6,#0ffh
D2:
	djnz	r6,D2
	clr	watch_dog		;watch dog clock 
	jb	SQ_OUT,ON_AIR		;receiver jmp
	djnz	r5,time_2

	jb	scan_mode,ON_AIR	;manual mode init again seting
	ljmp	INIT

ON_AIR:
 
;------------------------------
;	Interrupt Enable
;------------------------------

	clr	Receiver_OK
	clr	SWEET_SET

	mov	AR20ER_CNT,#00h
	mov	WORD_FIND,#00h
	mov	RX_TXD_CNT,#00h
	mov	MCA_ID_CNT,#00h
	mov	SQ_L_CNT0,#00h
	mov	SQ_L_CNT1,#00h
	mov	SYNC_ERR_CNT0,#00h
	mov	SYNC_ERR_CNT1,#00h
	mov	ERR_BIT_COUNT,#00h
	mov	DACO_CNT,#00h

	setb	RX_TXD			;P2.7 receiver data
	setb	it0		;TCON
	setb	ex0		;IE.0
	setb	ea		;IE.7


;------------------------------------------------------------------
; main loop
;-----------

MAIN:
	setb	watch_dog			;watch dog clock 


;*rf reseting/ CPU=>M-ADD NO CHECK, LOGIC CKT=ERROR(m_add error)
;m_add error=led display

	jnb	Receiver_OK,MAIN_1	;m-add ->no = H

	jb	AR20ER,MAIN_1

	inc	AR20ER_CNT
	mov	a,AR20ER_CNT

	cjne	a,#250,MAIN_1		;250
	mov	AR20ER_CNT,#00h

	jnb	scan_mode,MAIN_0	;manual mode jmp

	clr	watch_dog
	mov	r5,#2
	lcall	delay1

	setb	watch_dog
	mov	r5,#2
	lcall	delay1

	ajmp	scan_action		;

MAIN_0:					;manual mode
;	clr	ea
	clr	DACO
	ljmp	ON_AIR

MAIN_1:
	jb	SWEET_SET,SWEET_ERR
	mov	a,DACO_CNT		;sync word ok -> count
	cjne	a,#20,ERROR_INIT	;20
	setb	SWEET_SET
	ajmp	SWEET_ERR

ERROR_INIT:
	mov	a,SYNC_ERR_CNT1		;(32*4)=128
	cjne	a,#16,MCA_CHECK		;4   128*2=(32*8)
;	clr	DACO
	clr	SEND_BIT
	ajmp	rfch_scan

MCA_CHECK:
	mov	a,MCA_ID_CNT
	cjne	a,#2,ERROR_DET		;2
;	clr	DACO
	clr	SEND_BIT
	ajmp	rfch_scan

ERROR_DET:
	mov	a,ERR_BIT_COUNT	
	cjne	a,#2,MAINSTART		;2
;	clr	DACO
	clr	SEND_BIT
	ajmp	rfch_scan

;-----------------------------------------------
SWEET_ERR:
	mov	a,SYNC_ERR_CNT1			;(32*4)=128
	cjne	a,#2,MCA_CHECK_S		;2   128*2=(32*8)
;	clr	DACO
	clr	SEND_BIT
	ajmp	rfch_scan

MCA_CHECK_S:
	mov	a,MCA_ID_CNT
	cjne	a,#4,ERROR_DET_S		;4
;	clr	DACO
	clr	SEND_BIT
	ajmp	rfch_scan

ERROR_DET_S:
	mov	a,ERR_BIT_COUNT	
	cjne	a,#8,MAINSTART			;8
;	clr	DACO
	clr	SEND_BIT
	ajmp	rfch_scan
;-----------------------------------------------

MAINSTART:
	jb	SQ_OUT,DATA_CHECK		;TX OFF / SQ_OUT=L
	jb	Receiver_OK,DATA_CHECK		;txd ok
	mov	a,SQ_L_CNT1			;128(0.1) * ?
	cjne	a,#16,DATA_CHECK			;4
	clr	ea
;	clr	DACO
	clr	SEND_BIT
	ajmp	rfch_scan

DATA_CHECK:
	jb	SEND_BIT,RECEIVE		;receive(H)
	ajmp	main				
		
RECEIVE:				
	mov	a,WORD_FIND			; pattern flag
	cjne    a,#00001111b,REC_WAIT

	mov	ERR_BIT_COUNT,#00h
	mov	RECWAIT_CUT0,#00h
	mov	RECWAIT_CUT1,#00h
	mov	MCA_ID_CNT,#00h
	mov	SQ_L_CNT0,#00h
	mov	SQ_L_CNT1,#00h
	mov	SYNC_ERR_CNT0,#00h
	mov	SYNC_ERR_CNT1,#00h
	mov	DACO_CNT,#00h
	mov	AUTO_RESET0,#00h
	mov	AUTO_RESET1,#00h
	mov	AUTO_RESET2,#00h
;;;	mov	AR20ER_CNT,#00h

;	jb	p3.7,rxsiren			;jp pin B
	setb	Receiver_OK			;rx siren clear
	nop

;rxsiren:
;	jb	Receiver_OK,SIREN_TXD		;siren_txd 

 	setb	DACO				; DATA PASS

	ajmp	main






;------------------------------
;SIREN_TXD:
;	clr	ea
;	setb	Receiver_OK
	
;	ljmp	RX_ON_SIREN			;receiver siren action

;------------------------------
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
	
;------------------------------------------------------------
rfch_scan:
	jb	scan_mode,scan_go		;1=scan
	clr	DACO
	ljmp	ON_AIR				;error data init

scan_go:
	jnb	Receiver_OK,scan_action
;-------------------------         RF reseting delay timer(scan mode)
	clr	watch_dog
	mov	r5,#2
	lcall	delay1

	setb	watch_dog
	mov	r5,#2
	lcall	delay1

	clr	watch_dog
	mov	r5,#2
	lcall	delay1

	setb	watch_dog
	mov	r5,#2
	lcall	delay1


	clr	watch_dog
	mov	r5,#2
	lcall	delay1

	setb	watch_dog
	mov	r5,#2
	lcall	delay1

	ljmp	ON_AIR

scan_action:
	clr	DACO
	clr	ea
	jnb	ch2_set,abcd_ch			;0=base ch / 1=abcd ch
	mov	channel_0,chan_buf		;base channel
	clr	ch2_set
	ljmp	rfch_set

abcd_ch:
	mov	a,ch_dip_sw
	anl	a,#00110000b
fc_0:
	cjne	a,#00000000b,fc_1
	mov	a,channel_0
	subb	a,#12
	mov	channel_0,a
	setb	ch2_set
	ljmp	rfch_set	
fc_1:
	cjne	a,#00010000b,fc_2
	mov	a,channel_0
	subb	a,#24
	mov	channel_0,a
	setb	ch2_set
	ljmp	rfch_set	
fc_2:
	cjne	a,#00100000b,fc_3
	mov	a,channel_0
	subb	a,#36
	mov	channel_0,a
	setb	ch2_set
	ljmp	rfch_set	
fc_3:
	cjne	a,#00110000b,fc_end
	mov	a,channel_0
	subb	a,#48
	mov	channel_0,a
	setb	ch2_set
	ljmp	rfch_set	
fc_end:
	ljmp	init



;---------------------------------------------------------------------------
;	External Interrupt 0
;---------------------------------------------------------------------------
int_0:
	push	acc
	jb	SQ_OUT,action_data		;H-> action
	
	inc	SQ_L_CNT0
	mov	a,SQ_L_CNT0
	cjne	a,#128,int_00

	clr	SEND_BIT			;TX -> OFF

	mov	SQ_L_CNT0,#00h
	inc	SQ_L_CNT1

int_00:	
;	ajmp	int_0_ret

;--------------------------------------------
action_data:

;----auto reset  -------------
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
;	cjne	a,#2,action_sta		;10sec
;	cjne	a,#12,action_sta	;1min
;	cjne	a,#24,action_sta	;2min
;	cjne	a,#36,action_sta	;3min
;	cjne	a,#48,action_sta	;4min
;	cjne	a,#60,action_sta	;5min
;	cjne	a,#120,action_sta	;10min
;	cjne	a,#180,action_sta	;15min
;	cjne	a,#240,action_sta	;20min
;	cjne	a,#300,action_sta	;25min
	cjne	a,#360,action_sta	;30min
;	cjne	a,#420,action_sta	;35min
;	cjne	a,#480,action_sta	;40min

	mov	AUTO_RESET2,#00h

	mov	r5,#500
cpu_reset:
	mov	r6,#40
DEL_R:	mov	r7,#249
$1_R:	djnz	r7,$1_R
	djnz	r6,DEL_R
	djnz	r5,cpu_reset	
	

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
	acall	MCA_DATA_WORD
	ajmp	int_0_ret

no2345_data2:
	cjne	a,#00000111b,word_clear_1		; check pattern flag
	acall	NO2345_DATA_WORD
	ajmp	int_0_ret

word_clear_1:
	cjne	a,#00001111b,word_clear_2
	acall	NO2345_DATA_WORD
	ajmp	int_0_ret

word_clear_2:
	mov	WORD_FIND,#00h

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

	setb	SYNC_BIT			;bit add 10b
	setb	SEND_BIT
	inc	DACO_CNT

	mov	SYNC_ERR_CNT0,#00h
	mov	SYNC_ERR_CNT1,#00h
	mov	SQ_L_CNT0,#00h
	mov	SQ_L_CNT1,#00h
	ajmp	SYNC_RET

sync_error:

	mov	WORD_FIND,#00h

	inc	SYNC_ERR_CNT0
	mov	a,SYNC_ERR_CNT0
	cjne	a,#128,SYNC_RET
	mov	SYNC_ERR_CNT0,#00h
	mov	SQ_L_CNT1,#00h
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
	anl	a,#01111111b
	mov	r7,a
	mov	a,PATTERN4
	cpl	a
	anl	a,#01111111b
	cjne	a,r7,no1_data_err
;------------------------------------

	mov	ADDRESS1,PATTERN1		;RX SIREN 
	mov	ADDRESS2,PATTERN2		;RX SIREN

	ajmp	no1_ret1
;------------------------------------
no1_data_err:
	inc	ERR_BIT_COUNT
	clr	send_bit

no1_ret1:
	setb	no1_word_bit			
	mov	BIT_CONT_32,#00h		
	ret

no1_ret:
	ret

;--------------------------------------
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

;--CH ID CHECK-----------------------	
	mov	a,PATTERN1			;PATTERN1=MCA WORD ADD

;	cjne	a,#01100010b,mca_id_err		;01100010b
	cjne	a,mca_dw_l,mca_id_err		;?11??010b

	mov	a,PATTERN2			;PATTERN2=MCA ID,CH NO
	anl	a,#00111111b			;p,dip.7  clear
	cjne	a,channel_0,mca_id_err		;ID P(0)7,6,5,4,3,2,1b

	mov	MCA_ID_CNT,#00h
	ajmp	mca_ret1
;------------------------------------
mca_id_err:
	clr	send_bit
	inc	MCA_ID_CNT
	inc	ERR_BIT_COUNT

mca_ret1:
	setb	mca_word_bit		
	mov	BIT_CONT_32,#00h
	ret

mca_ret:
	ret

;-------------------------------------
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

;---WORD ADD DETECTION-------------

	mov	a,PATTERN1
	anl	a,#00000111b

;no2_word:
	cjne	a,#00000110b,no3_word		;110b
	ajmp	no2345_ret1

no3_word:
	cjne	a,#00000011b,no4_word		;011b
	ajmp	no2345_ret1

no4_word:
	cjne	a,#00000100b,no5_word		;100b
	ajmp	no2345_ret1

no5_word:
	cjne	a,#00000001b,no2345_data_err	; 001b 
	ajmp	no2345_ret1

;------------------------------------

no2345_data_err:
;----sync check

	mov	a,PATTERN1
	cjne	a,#00000001b,no2345		;start 1 bit
	mov	a,PATTERN2
	cjne	a,#00000000b,no2345
	mov	a,PATTERN3
	cjne	a,#00000000b,no2345		;SYNC ID CHECK
	mov	a,PATTERN4
	cjne	a,#11000000b,no2345		;stop 2 bit

	setb	SEND_BIT
	inc	DACO_CNT
	mov	WORD_FIND,#00000001b		;sync_bit set

	mov	SYNC_ERR_CNT0,#00h
	mov	SYNC_ERR_CNT1,#00h
	mov	SQ_L_CNT0,#00h
	mov	SQ_L_CNT1,#00h

	mov	BIT_CONT_32,#00h		
	ret


no2345:
	inc	ERR_BIT_COUNT
	clr	send_bit

no2345_ret1:
	setb	no2345_bit
	mov	BIT_CONT_32,#00h		
	ret

no2345_ret:
	ret










;======== RX POWER ON SIREN ==============================
RX_ON_SIREN:
	clr	DACO
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

;SYNC_WORD:
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
	mov	a,ADDRESS1		; 5,4,3,2,1(101)
	mov	TX_SEND_1,a
	mov	r0,#8			; 8 Bit
	lcall	send_bits

	clr	watch_dog
	mov	a,ADDRESS2		; B,A,10,9,8,7,6
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
	mov	r5,#10h
	acall	delay2
	rrc	a
	jnc	send_2
	clr	RX_TXD			;setb	rx_txd
	inc	parity_count
	ajmp	send_3

send_2:
	setb	RX_TXD			;clr	rx_txd

send_3:
	djnz	r0,send_0
	ret

;-------------------------------------------------------------------

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
	clr	RX_TXD			;setb	rx_txd
	ajmp	PP_3
PP_2:
	setb	RX_TXD			;clr	rx_txd
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
	mov	r5,#2		;4
	acall 	delay2		; 2.5 uS delay

	rlc	a		; rotate A 
	jnc	set_ch_1	; check the lowest bit	
	setb	rf_si		; set SI high
	ljmp	set_ch_2
SET_CH_1:
	clr	rf_si		; set SI low
SET_CH_2:

	mov	r5,#2		;4
	acall 	delay2		; 2.5 uS delay
	clr	cps
	mov	r5,#1
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
CHANNEL_DATA:
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