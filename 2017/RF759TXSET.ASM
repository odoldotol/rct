
;***********************
;   RF MODULE CONTROL /TMX 759A
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
	jb	scan_22,TX_DATA_SEND	;2nd Channel data
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
