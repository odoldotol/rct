
;***********************
;   RF MODULE CONTROL  /TMX 729 
;***********************

	lcall	CH_ID_INPUT
	mov	channel_base,channel_0

scan_set_1:
	setb	vcosw		;729  1=RX
	setb	pwsw		;729  1=RX
              setb   	rst
              setb    cps
              setb    RF_SI


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


;--------------------------------------------------------
	jb	scan_22,TX_DATA_SEND	;2nd Channel data
;--------------------------------------------------------




RX_SET_CHANNEL:				; RX 주파수 설정
;===============================
;	Reference Frequency Set
;===============================

               setb    cps			; set complement of CPS high  
	clr	rst			; set RST low

	mov	r5,#2			; 4 us delay
	lcall	delay2

	mov	a,#11110000b		; reference (00110000b)
	mov	r0,#8			; 12.5 kHz
	lcall	set_channel_sub

	mov	a,#00000011b
	mov	r0,#8
	lcall	set_channel_sub

	mov	a,#01010100b
	mov	r0,#6                   ; 5+1
	lcall	set_channel_sub

	mov	r5,#4
	lcall 	delay2			; 2.5 uS delay
        setb    rst
	mov	r5,#100		        ; 20mS delay
	lcall	delay2

;===============================
;	RX Frequency Set
;===============================
	clr	rst			; RX requency setting
	mov	r5,#2			; 4 uS delay
	lcall	delay2

	mov	a,#10100100b		; RX TURN ON			
	mov	r0,#8
	lcall	set_channel_sub

	mov	a,#00101000b		;001010 6bit send
	mov	r0,#6
	lcall	set_channel_sub

	mov	a,ch_dip_sw
	inc	a
	rl	a		
	orl	a,#00000001b
	mov	r0,#8
	lcall	set_channel_sub

	mov	r5,#4
	lcall 	delay2			; 8 uS delay
	setb	rst
	mov	r5,#2		        ; 40mS delay
	lcall	delay1


	ljmp	RECEIVER



;-TX-------------------------------
TX_DATA_S:
	clr	Power_Led		;on
	mov	r5,#2
	lcall	delay1

TX_DATA_SEND:
;======================================
;	TMX729 Reference Frequency Set
;======================================
	clr	vcosw			;0=TX
	mov	r5,#1
	lcall	delay1

        setb    cps			; set complement of CPS high  
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
	mov	r0,#6                   ; 5+1
	lcall	set_channel_sub

	mov	r5,#2
	lcall 	delay2		        ; 2.5 uS delay
        setb    rst
	mov	r5,#2		        ; 20mS delay
	lcall	delay2

;=====================================
;	TMX729 TX Frequency Set
;=====================================
	
	clr	rst			; 

	mov	r5,#2			; 4 uS delay
	lcall	delay2

	mov	a,#01010100b		; 729 TX TURN ON			
	mov	r0,#8
	lcall	set_channel_sub

	mov	a,CHBUF1
	mov	r0,#8
	lcall	set_channel_sub

	mov	a,CHBUF2		; channel DIP S/W setting
	mov	r0,#6			;21bit + 1bit
	lcall	set_channel_sub

	mov	r5,#2			;4
	lcall 	delay2			; 2.5 uS delay

        setb    rst

	mov	r5,#100			; 20mS delay
	lcall	delay2

lock_out_chk:
	jb	lock_out,lock_out_chk	;check lock up
	mov	r5,#2			; 50uS delay
	lcall	delay2
	clr	pwsw			; TX PW SW ON
	mov	r5,#08h 		; 160mS delay
	lcall	delay1

	
	setb	power_led		;OFF
	
;---------------------------------
