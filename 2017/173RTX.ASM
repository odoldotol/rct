;--------------------------------------------------
;	173_TX RF TEST  PROGAM
;--------------------------------------------------
DSEG

       ORG     30H

CHANNEL_DATA1:  DS      1               ;47H
CHANNEL_DATA2:  DS      1               ;48H

READ_DATA:	DS	1		;5AH

        ORG     0060H
STACK_POINT:    DS      1

READ_PORT      EQU	80H

BSEG
;------------------------------------------------------------------------
RST             BIT     P1.0		;PLL_CE
CPS             BIT     P1.1		;PLL_CLK
RF_SI           BIT     P1.2		;PLL_DATA
LOCK_OUT        BIT     P1.3		;LOCK
TXSW		BIT	P1.4		;TX_EN
RXSW      	BIT     P1.5		;RX_EN
SQ_OUT		BIT	P1.6		;SQ_DET

CSEG

;***********************************
;*	Interrupt Vector
;***********************************
        ORG     0000H
        LJMP    INIT            ; Reset

        ORG     0003H           ; External 0
        RETI

        ORG     000BH           ; Timer/Counter 0
        RETI

        ORG     0013H           ; External 1
        RETI

        ORG     001BH           ; Timer/Counter 1
        RETI

        ORG     0023H           ; Serial Port
        RETI

        ORG     0026H           ; Just for debugging
        LJMP    INIT
;********************************************************************
;*	Initialize	H/W	
;********************************************************************
	
INIT:
    
        SETB    RST                     
        SETB    RF_SI
        SETB    CPS					

TX_173:		;173.6250 - 173.7875Mhz  14ch		
	MOV     CHANNEL_DATA1,#36h		;3642h=173.6250Mhz(ch_1)    
	MOV     CHANNEL_DATA2,#42h		;3642h+01h(dip sw)=ch+12.5khz

;	mov	a,dip_sw			;ch data
;	add	a,#42h
;	mov	channel_data2,a

	AJMP	TX_SETING

RX_173:		;173.6250 - 173.7875Mhz  14ch		
        MOV     CHANNEL_DATA1,#2fh		;2f7ah=173.6250Mhz(ch_1)
        MOV     CHANNEL_DATA2,#7ah 		;2f7ah+01h(dip sw)=ch+12.5khz

;	mov	a,dip_sw			;ch data
;	add	a,#7ah
;	mov	channel_data2,a

	AJMP	RX_SETING


TX_SETING:
        SETB    RXSW
	CLR	TXSW				;TX MODE

	MOV	R5,#5
	LCALL	DELAY1

	ACALL	TX_SET_RF_MODULE
	JNB	LOCK_OUT,TX_SETING

	AJMP	TX_START			;TRANSMITTER START
		
TX_SET_RF_MODULE:

	MOV	R5,#2
	LCALL	DELAY1

        CLR     RST					
        MOV     R5,#5           
        LCALL   DELAY2

        SETB     RST				
        MOV     R5,#5           
        LCALL   DELAY2

        CLR     RST					
        MOV     R5,#5           
        LCALL   DELAY2

        SETB     RST					
        MOV     R5,#5           
        LCALL   DELAY2

        CLR     RST					
        MOV     R5,#5           
        LCALL   DELAY2

        SETB     RST					
        MOV     R5,#5           
        LCALL   DELAY2

        ACALL   SET_173TX				
        MOV     R5,#2                     
        LCALL   DELAY1

        JNB     LOCK_OUT,RF_REPET   
        RET

RF_REPET:								

        SETB    RST                   
        SETB    RF_SI
        SETB    CPS					
	RET


;********************************************************************
;	 R counter setup
;--------------------------------------------------------------------
SET_173TX:
        CLR     RST				

TX_173_CHANNEL:
        MOV     A,#0B6H			
        MOV     R0,#8                                       
        ACALL   SET_CHANNEL_SUB

        MOV     A,#0A4H				
        MOV     R0,#8
        ACALL   SET_CHANNEL_SUB
        
        MOV     A,#00h				; CTL[1:0] = 0,0
        MOV     R0,#2					
        ACALL   SET_CHANNEL_SUB

	SETB    RST					
        MOV     R5,#2                   
        LCALL   DELAY2
;--------------------------------------------------------------------
;	TX / RX Actual PLL setup					
;--------------------------------------------------------------------
        CLR     RST				

        MOV     A,CHANNEL_DATA1
        MOV     R0,#8
        ACALL   SET_CHANNEL_SUB

        MOV     A,CHANNEL_DATA2
        MOV     R0,#8
        ACALL   SET_CHANNEL_SUB


        MOV     A,#40H                   ;CTL[1:0] = 0,1
        MOV     R0,#2
        ACALL   SET_CHANNEL_SUB


	SETB    RST				
        MOV     R5,#2                   
        LCALL   DELAY2
;--------------------------------------------------------------------
;	Lock Detect setup
;--------------------------------------------------------------------
	CLR     RST						

        MOV     A,#56H					
        MOV     R0,#8                   
        ACALL   SET_CHANNEL_SUB

        MOV     A,#0A4H				
        MOV     R0,#8
        ACALL   SET_CHANNEL_SUB


        MOV     A,#00H					; CTL[1:0] = 0,0
        MOV     R0,#2					
        ACALL   SET_CHANNEL_SUB			

        SETB    RST

        mov     r5,#50                          
        lcall   delay1                        
        SETB	RF_SI
        SETB	CPS
        
        MOV     R5,#100					; 20mS delay
        LCALL   DELAY2
	RET



RX_SETING:
        CLR   	RXSW				;RX MODE
	SETB	TXSW				

	MOV	R5,#5
	LCALL	DELAY1
	ACALL	SET_173RX

	AJMP	RX_START			;RECEIVER START

;==============================================================
;	Reference Frequency Set
;==============================================================
SET_173RX:
		
        CLR	RST
        MOV     R5,#5
        ACALL   DELAY2

        MOV     A,#0F6H		          
        MOV     R0,#8
        LCALL   SET_CHANNEL_SUB

        MOV     A,#0A4H
        MOV     R0,#8
        LCALL   SET_CHANNEL_SUB

        MOV     A,#80H				 ; CTL[1:0] = 1,0
        MOV     R0,#2
	LCALL   SET_CHANNEL_SUB

        SETB	RST
        MOV     R5,#5
        ACALL   DELAY2
;==============================================================
;       RX Frequency Set
;==============================================================
RX_FREQUENCY_SET:
	SETB	CPS
        CLR	RST

        MOV     R5,#5
        ACALL   DELAY2

        MOV     A,CHANNEL_DATA1
        MOV     R0,#8
        LCALL   SET_CHANNEL_SUB

        MOV     A,CHANNEL_DATA2
        MOV     R0,#8
        LCALL   SET_CHANNEL_SUB

        MOV     A,#0C0H	                 ; CTL[1:0] = 1,1
        MOV     R0,#2
        LCALL   SET_CHANNEL_SUB

        SETB	RST
        MOV     R5,#5
        ACALL   DELAY2
;************************************************************
;       LOCK DETECT SETUP
;************************************************************
        CLR	RST
        MOV     R5,#5
        ACALL   DELAY2

        MOV     A,#56H					; PLL LOCK + reference frequency setting(RX)
        MOV     R0,#8					; 12.5 kHz
        LCALL   SET_CHANNEL_SUB

        MOV     A,#0A4H
        MOV     R0,#8
        LCALL   SET_CHANNEL_SUB

        MOV     A,#80H                 ; CTL[1:0] = 1,0
        MOV     R0,#2					
        LCALL   SET_CHANNEL_SUB
        
        SETB    RST
	SETB	RF_SI
	SETB	CPS
		
        MOV     R5,#100
        ACALL   DELAY2 
        RET


;*************************************************************
SET_CHANNEL_SUB:
	MOV	R5,#5
        LCALL   DELAY2

        RLC     A
        JNC     SET_CH_1
        SETB    RF_SI
        AJMP    SET_CH_2
SET_CH_1:
        CLR     RF_SI
SET_CH_2:
	MOV	R5,#10
        LCALL   DELAY2 
	SETB    CPS

	MOV	R5,#5
        LCALL   DELAY2
	CLR     CPS

        DJNZ    R0,SET_CHANNEL_SUB
        RET



DELAY1:				; R5 * 20mS
        
        MOV	R6,#40
DEL:    MOV     R7,#249
S1:     DJNZ    R7,S1
        DJNZ    R6,DEL
        DJNZ    R5,DELAY1
        RET
;*************************************************************
DELAY2: 
	DJNZ    R5,DELAY2
        RET

TX_START:
RX_START:

END


