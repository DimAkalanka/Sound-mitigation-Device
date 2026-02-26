.include "m328pdef.inc"

.equ SAMPLE_WINDOW = 50
.equ THRESHOLD_DB = 50
.equ SOUND_SENSORS = 4

.dseg
motion_detected: .byte 1
sound_max: .byte SOUND_SENSORS
sound_min: .byte SOUND_SENSORS

.cseg
.org 0x00
    rjmp RESET
.org INT0addr
    rjmp PIR_ISR


RESET:
    ldi r16, high(RAMEND)
    out SPH, r16
    ldi r16, low(RAMEND)
    out SPL, r16

    ldi r16, 0x00
    sts motion_detected, r16

    ldi r16, (1<<PD3)|(1<<PD4)|(1<<PD6)
    out DDRD, r16

    ldi r16, (1<<ADEN)|(1<<ADPS2)|(1<<ADPS1)|(1<<ADPS0)
    sts ADCSRA, r16

    ldi r16, (1<<REFS0)
    sts ADMUX, r16

    ldi r16, (1<<INT0)
    out EIMSK, r16
    ldi r16, (1<<ISC01)|(1<<ISC00)
    sts EICRA, r16

    ldi r16, 0x00
    out PORTD, r16

    sei

MAIN_LOOP:
    lds r20, motion_detected
    cpi r20, 0x01
    brne MAIN_LOOP

    ldi r20, 0x00
    sts motion_detected, r20

    in r21, PIND
    sbrs r21, PD5
    rjmp SOUND_ANALYSIS

    rcall INTRUDER_SYSTEM
    rjmp MAIN_LOOP

PIR_ISR:
    ldi r16, 0x01
    sts motion_detected, r16
    reti

SOUND_ANALYSIS:
    in r16, PORTD
    ori r16, (1<<PD6)
    out PORTD, r16

    rcall DELAY_100MS

    ldi r24, 60

SOUND_ANALYSIS_LOOP:
    ldi r22, 0

SENSOR_LOOP:
    lds r16, ADMUX
    andi r16, 0xF0
    or r16, r22
    sts ADMUX, r16

    rcall READ_SOUND_SENSOR

    cpi r23, THRESHOLD_DB
    brlo NO_ALERT

    rcall TRIGGER_ALERT
    rjmp SOUND_ANALYSIS_END

NO_ALERT:
    inc r22
    cpi r22, SOUND_SENSORS
    brlo SENSOR_LOOP

    rcall DELAY_10MS

    dec r24
    brne SOUND_ANALYSIS_LOOP

SOUND_ANALYSIS_END:
    in r16, PORTD
    andi r16, ~(1<<PD6)
    out PORTD, r16
    ret

READ_SOUND_SENSOR:
    ldi r17, 0x00 ; min
    ldi r18, 0xFF ; max
    ldi r19, SAMPLE_WINDOW

READ_SOUND_LOOP:
    lds r16, ADCSRA
    ori r16, (1<<ADSC)
    sts ADCSRA, r16

ADC_WAIT:
    lds r16, ADCSRA
    sbrc r16, ADSC
    rjmp ADC_WAIT

    lds r26, ADCL
    lds r27, ADCH

    ; Combine to 10-bit result
    mov r20, r27

    cp r20, r17
    brlo UPDATE_MAX
    rjmp SKIP_MAX
UPDATE_MAX:
    mov r17, r20
SKIP_MAX:

    cp r20, r18
    brsh UPDATE_MIN
    rjmp SKIP_MIN
UPDATE_MIN:
    mov r18, r20
SKIP_MIN:

    rcall DELAY_1MS
    dec r19
    brne READ_SOUND_LOOP

    sub r17, r18
    mov r23, r17
    ret

TRIGGER_ALERT:
    in r16, PORTD
    ori r16, (1<<PD3)
    out PORTD, r16

    ldi r24, 50
    rcall DELAY_MS_LOOP

    in r16, PORTD
    andi r16, ~(1<<PD3)
    out PORTD, r16
    ret

INTRUDER_SYSTEM:
    in r16, PORTD
    ori r16, (1<<PD4)
    out PORTD, r16

    ldi r24, 40
    rcall DELAY_MS_LOOP

    in r16, PORTD
    andi r16, ~(1<<PD4)
    out PORTD, r16

    rcall DELAY_20MS
    ret

DELAY_MS_LOOP:
    rcall DELAY_100MS
    dec r24
    brne DELAY_MS_LOOP
    ret

DELAY_1MS:
    ldi r16, 230
DELAY_1MS_LOOP:
    nop
    dec r16
    brne DELAY_1MS_LOOP
    ret

DELAY_10MS:
    ldi r16, 10
DELAY_10MS_LOOP:
    rcall DELAY_1MS
    dec r16
    brne DELAY_10MS_LOOP
    ret

DELAY_20MS:
    ldi r16, 20
DELAY_20MS_LOOP:
    rcall DELAY_1MS
    dec r16
    brne DELAY_20MS_LOOP
    ret

DELAY_100MS:
    ldi r16, 10
DELAY_100MS_LOOP:
    rcall DELAY_10MS
    dec r16
    brne DELAY_100MS_LOOP
    ret
