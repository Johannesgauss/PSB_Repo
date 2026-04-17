 .nolist
.include "m328Pdef.inc"
.list

.ORG 0x0000
START:
	LDI R16, 0xFF
	OUT DDRB, R16
	LDI R16, 0x00
	JMP LOOP
LOOP:
	INC R16
	OUT PORTB, R16
	JMP DELAY
DELAY:
    LDI R17, 82 
    L17:
        LDI R18, 255
    L18:
        LDI R19, 255
    L19:
	DEC R19
        BRNE L19
        DEC R18
        BRNE L18
        DEC R17
        BRNE L17
	JMP LOOP
