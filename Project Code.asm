;--------------------------------------------------------------------------------------------------------------
;Initiation
.Include "M328pdef.inc"

.Cseg
.Org 0x0000
    jmp main
.Org 0x0002
    jmp INTERRUPT  ; Interrupt for pedestrian button
;--------------------------------------------------------------------------------------------------------------
main:
    ; Initialize stack pointer
    Ldi R20, High(RAMEND)
    Out SPH, R20
    Ldi R20, Low(RAMEND)
    Out SPL, R20

    ; Configure INT0 for falling edge
    Ldi R20, 0b00000011  ; ISC01 = 1, ISC00 = 1 for rising edge
    Sts EICRA, R20

    ; Enable INT0 interrupt
    Ldi R20, 0b00000001
    Out EIMSK, R20

    ; Enable global interrupts
    Sei

	;Input 
	;4 Ports for sound sensors
	cbi DDRB, 0 
	cbi DDRB, 1
	cbi DDRB, 2
	cbi DDRB, 3
	sbi PORTB,0
	sbi PORTB,1
	sbi PORTB,2
	sbi PORTB,3
	
	;Pir sensors via OR gate
	cbi DDRD, 2
	sbi PORTB,2

	;Output 
	;LED/ Sound
	sbi DDRD, 3

;--------------------------------------------------------------------------------------------------------------
;running loop while an interrupt occurs
loop:
    rjmp loop

;--------------------------------------------------------------------------------------------------------------
;Interrupt
INTERRUPT:
	;Check for few iterations
    LDI R16, 180          ; Load delay outer (R16)
    LDI R17, 180          ; Load delay middle (R17)
    LDI R18, 180          ; Load delay inner (R18)

	delay_out:
		rcall checkLoop		  ; get input from sound sensors
		DEC R16               ; Decrement outer loop counter
		BRNE delay_mid		  ; Jump to middle loop if R16 != 0
		reti                   ; Return to main loop R16 == 0

	delay_mid:
		rcall checkLoop		  ; get input from sound sensors
		DEC R17               ; Decrement middle loop counter
		BRNE delay_in         ; Jump to inner loop if R17 != 0
		LDI R17, 180          ; Reload middle loop counter
		RJMP delay_out        ; Return to outer loop

	delay_in:
		rcall checkLoop		  ; get input from sound sensors
		DEC R18				  ; Decrement inner loop counter       
		BRNE delay_in         ; Repeat inner loop until R18 == 0
		LDI R18, 180          ; Reload inner loop counter
		RJMP delay_mid        ; Return to middle loop	

	checkLoop:
		in R21, PINB			;getting the PORT B input byte
		andi R21, 0b00001111	;AND operation with 1111 
		brne warning			;IF R21 is not zero (At least one sound detectors sound level is exceeded)	
		ret

;--------------------------------------------------------------------------------------------------------------
;If sound level exceeded
warning:

	sbi PORTD, 3
	rcall myDelay_1sec
	rcall myDelay_1sec
	rcall myDelay_1sec
	cbi PORTD, 3

	reti
;--------------------------------------------------------------------------------------------------------------
;1 sec Delay
myDelay_1sec:
    LDI R16, 180          ; Load delay outer (R16)
    LDI R17, 180          ; Load delay middle (R17)
    LDI R18, 180          ; Load delay inner (R18)

delay_outer:
    DEC R16               ; Decrement outer loop counter
    BRNE delay_middle     ; Jump to middle loop if R16 != 0
    RET                   ; Return when R16 == 0

delay_middle:
    DEC R17               ; Decrement middle loop counter
    BRNE delay_inner      ; Jump to inner loop if R17 != 0
    LDI R17, 180          ; Reload middle loop counter
    RJMP delay_outer      ; Return to outer loop

delay_inner:
    DEC R18               ; Decrement inner loop counter
    BRNE delay_inner      ; Repeat inner loop until R18 == 0
    LDI R18, 180          ; Reload inner loop counter
    RJMP delay_middle     ; Return to middle loop