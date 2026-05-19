.nolist
.include "m328Pdef.inc"
.list

.ORG 0x000

; -----------------------------------------------------------------------------
; DATA MATRIX (3x2) STORED IN FLASH
; -----------------------------------------------------------------------------
; Row 0: 0b00111111, 0b00000110
; Row 1: 0b01011011, 0b01001111
; Row 2: 0b01100110, 0b01101101
Tabela: 
    .db 0b00111111, 0b00000110 
    .db 0b01011011, 0b01001111 
    .db 0b01100110, 0b01101101 

; -----------------------------------------------------------------------------
; REGISTER REGISTER CONFIGURATION
; -----------------------------------------------------------------------------
.def AUX = R16      ; Temporary general-purpose register
.def I   = R17      ; Column Index (0 to 1)
.def J   = R18      ; Row Index (0 to 2)
.def VAL = R19      ; Value fetched from Matrix to display

.equ BUTTON_A = PD7 ; Pin for increasing position
.equ BUTTON_B = PD6 ; Pin for decreasing position

; -----------------------------------------------------------------------------
; INITIALIZATION
; -----------------------------------------------------------------------------
INIT:
    ; Initialize Stack Pointer
    LDI AUX, HIGH(RAMEND)
    OUT SPH, AUX
    LDI AUX, LOW(RAMEND)
    OUT SPL, AUX

    ; Configure PORTB (Pins 0-6) as outputs for the 7-Segment Display
    LDI AUX, 0b01111111
    OUT DDRB, AUX
    
    ; Configure PORTD Pins 6 and 7 as inputs (0)
    LDI AUX, 0b00000000
    OUT DDRD, AUX
    ; Enable internal pull-up resistors for the buttons (Pins will read 1 when idle, 0 when pressed)
    LDI AUX, 0b11000000
    OUT PORTD, AUX

    ; Clear matrix indices initially
    LDI J, 0        ; Row = 0
    LDI I, 0        ; Column = 0

    RCALL SHOW      ; Display initial element

; -----------------------------------------------------------------------------
; MAIN OBSERVATOR LOOP
; -----------------------------------------------------------------------------
OBSERVATOR:
    ; Check Button A (Increase) - Active Low
    SBIS PIND, BUTTON_A
    RJMP INCREASING_MODE

    ; Check Button B (Decrease) - Active Low
    SBIS PIND, BUTTON_B
    RJMP DECREASING_MODE

    RJMP OBSERVATOR

; -----------------------------------------------------------------------------
; NAVIGATION MODES (WITH DEBOUNCE / RELEASE CHECK)
; -----------------------------------------------------------------------------
INCREASING_MODE:
    RCALL DELAY             ; Simple debounce
    ; Wait here until Button A is released (returns to 1)
WAIT_RELEASE_A:
    SBIS PIND, BUTTON_A
    RJMP WAIT_RELEASE_A

    RCALL NEXT_ELEMENT      ; Move to the next matrix item
    RCALL SHOW              ; Update display
    RJMP OBSERVATOR

DECREASING_MODE:
    RCALL DELAY             ; Simple debounce
    ; Wait here until Button B is released (returns to 1)
WAIT_RELEASE_B:
    SBIS PIND, BUTTON_B
    RJMP WAIT_RELEASE_B

    RCALL PREV_ELEMENT      ; Move to the previous matrix item
    RCALL SHOW              ; Update display
    RJMP OBSERVATOR

; -----------------------------------------------------------------------------
; MATRIX NAVIGATION LOGIC
; -----------------------------------------------------------------------------
NEXT_ELEMENT:
    INC I                   ; Increment column index
    CPI I, 2                ; Max columns = 2 (0 and 1 are valid)
    BRNE DONE_NEXT
    LDI I, 0                ; Reset column index to 0
    INC J                   ; Move to next row
    CPI J, 3                ; Max rows = 3 (0, 1, and 2 are valid)
    BRNE DONE_NEXT
    LDI J, 0                ; Wrap around: Reset row index to 0
DONE_NEXT:
    RET

PREV_ELEMENT:
    DEC I                   ; Decrement column index
    BRPL DONE_PREV          ; If I >= 0, index transition within row is fine
    LDI I, 1                ; Reset column index to the last column (1)
    DEC J                   ; Move to previous row
    BRPL DONE_PREV          ; If J >= 0, row transition is fine
    LDI J, 2                ; Wrap around: Reset row index to the last row (2)
DONE_PREV:
    RET

; -----------------------------------------------------------------------------
; MATRIX TO 1D CONVERSION AND DISPLAY ROUTINE
; -----------------------------------------------------------------------------
SHOW:
    ; Formula to find 1D index: Offset = (J * 2) + I
    MOV AUX, J
    LSL AUX                 ; Multiply Row (J) by 2
    ADD AUX, I              ; Add Column (I) -> AUX now holds the total offset

    ; Load Z pointer with the Flash base memory address of Tabela
    LDI ZH, HIGH(Tabela << 1)
    LDI ZL, LOW(Tabela << 1)

    ; Add our computed 1D offset to the Z pointer
    ADD ZL, AUX
    CLR AUX
    ADC ZH, AUX             ; Propagate carry flag to High byte of Z

    ; Fetch the byte from Flash memory into VAL register
    LPM VAL, Z
    
    ; Output the byte configuration to Port B
    OUT PORTB, VAL
    RET

; -----------------------------------------------------------------------------
; DELAY SUBROUTINE (Fixed loop counter bug)
; -----------------------------------------------------------------------------
DELAY:
    LDI R22, 50
L3: LDI R20, 255
L2: LDI R21, 255
L1: DEC R21
    BRNE L1
    DEC R20
    BRNE L2
    DEC R22                 ; Fixed: originally your code decremented R21 here by mistake
    BRNE L3
    RET
