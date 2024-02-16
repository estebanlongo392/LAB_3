//***************************************************
// Universidad del Valle de Guatemala
// IE2023: Programación de Microcontroladores 
// Autor: Esteban Longo Marroquin
// Proyecto: Laboratorio 3
// Descripción: Contador con interrupciones
// Hardware: ATMEGA328P
// Created: 08/02/2024 23:41:30
//****************************************************
// Encabezado 
//****************************************************
.include "M328PDEF.inc"

.cseg
.org 0x00
	JMP MAIN   //se corre el bucle main con el setup 
.org 0x0006
	JMP INT_PC  //se axtiva la interrupción de pines 
.org 0x0020
	JMP INT_TIMER0  //interrupccion de timer
//****************************************************
//Configuración de la Pila
//****************************************************
Main: 
LDI R16, LOW(RAMEND)
OUT SPL, R16
LDI R17, HIGH(RAMEND)
OUT SPH, R17

//****************************************************

//****************************************************
//Configuración MCU
//****************************************************
SETUP:
	LDI R16, 0b1000_0000     //el timer se establece a 8MHz
	LDI R16, (1 << CLKPCE)
	STS CLKPR, R16

	LDI R16, 0b0000_0001
	STS CLKPR, R16
		
	LDI R16, 0b0000_0011 //Configuramos al pueto B como entradas y salidas
	OUT	PORTB, R16

	LDI R16, 0b0000_1100 //Configuración al puerto B como pull ups
	OUT DDRB, R16
	
	LDI R16, 0b1011_1111	//Configuramos el puerto C como salidas
	OUT DDRC, R16

	LDI R16, 0b1111_1111	//Configuramos el puerto D como salidas
	OUT DDRD, R16

	LDI R16, (1<<PCINT1) | (1<<PCINT0)    //se establecen los pines 0 y 1 del puerto b como interrupciones
	STS PCMSK0, R16

	LDI R16, (1<<PCIE0)
	STS PCICR, R16

	SEI

	LDI R20, 0x00
	LDI R21, 0x00    //Estos registros se establecen en cero para ser usados dentro del código
	LDI R22, 0x00
	LDI R23, 0x00

	
	CALL INT_T0  //llamamos la inicializacion del timer0
	SBI PINB, 3  //encendemos el PB3 para la multiplexación 
	
//****************************************************
//Configuración LOOP
//****************************************************

LOOP:
	CPI R22, 10
	BREQ DECE      //analizamos si las unidades llegan a 10, para aumentar las decenas 
	CPI R23, 50
	BREQ UNI      //se analiza si las centenas estan en 50 para asi reiniciar las unidades y las decenas 
	
	CALL DELAY
	SBI PINB, 2    //en esta parte ocurre la multiplexación 
	SBI PINB, 3

	LDI ZH, HIGH(TABLA7SEG << 1)  //se va a buscar detro de la tabla el valor que se desplegara en las decenas 
	LDI ZL, LOW(TABLA7SEG << 1)
	ADD ZL, R21
	LPM R25, Z
	OUT PORTD, R25     //se envia el valor al puerto para verlo en los displays 
	CALL DELAY
	
	SBI PINB, 2
	SBI PINB, 3   //ocurre nuevamente la multiplexacion para ver en el otro display

	LDI ZH, HIGH(TABLA7SEG << 1)
	LDI ZL, LOW(TABLA7SEG << 1)   //se va a buscar detro de la tabla el valor que se desplegara en las unidades
	ADD ZL, R22
	LPM R25, Z
	OUT PORTD, R25       //se envia el valor al puerto para verlo en los displays 
	CALL DELAY

	CPI R21, 6
	BREQ REST     //se analiza el desbordamiento de las decenas para que cuando llegue a 60 se reinicie el contador

	OUT PORTC, R20    //visualizamos el contador en los leds a manos de los botones 
	RJMP LOOP   

DELAY:              //delay que hace posible la multiplexación de los displays 
	LDI R19, 255
DELAY1:
	DEC R19
	BRNE DELAY1 
	LDI R19, 255
DELAY2:
	DEC R19
	BRNE DELAY2
	LDI R19, 255
DELAY3:
	DEC R19
	BRNE DELAY3
	LDI R19, 255
DELAY4:
	DEC R19
	BRNE DELAY4

	RET

DECE:            //en esta parte se ven las decenas y su incremento en función de las unidades 
	LDI R22, 0
	INC R21
	JMP LOOP
UNI:
	INC R22     //en esta parte se ven las unidades y su incremento
	LDI R23, 0
	JMP LOOP 

REST:
	CALL DELAY   //cuando el contador de los displays llega a 59 aca es donde sucede el receteo de las unidades y decenas 
	LDI R21, 0
	LDI R22, 0
	JMP LOOP

//****************************************************
//Subrutina 
//****************************************************
INT_PC:
	PUSH R16		//guardamos el valor de R16
	IN R16, SREG
	PUSH R16

	IN R18, PINB     //los valores del puerto B los almacenamos en R18

	SBRC R18, PB0		//analisis de los botones para aumentar conteo de leds
	JMP BTTON1

	INC R20
	CPI R20, 16   //si el contador llega a 16 se resetea a 0
	BRNE SALIR
	LDI R20, 0
	JMP SALIR

BTTON1:
	SBRC R18, PB1   //analisis de los botones para decrementar el conteo de leds
	JMP SALIR

	DEC R20
	BRNE SALIR
	LDI R20, 15    //si el contador llega a -1 se resetea a 15

SALIR:
	SBI PINB, PB5
	SBI PCIFR, PCIF0

	POP R16
	OUT SREG, R16
	POP R16          //Devolvemos el valor antes guardado
	RETI            //retorno de interrupcion 

INT_T0:
	LDI R26, 0
	OUT TCCR0A, R26      //inicializacion de timer 0 como contador 
	
	LDI R26, (1<<CS02) | (1<<CS00)     //seleccion de prescaler de 1024 
	OUT TCCR0B, R26       
	
	LDI R26, 100           //valor de conteo inicial 
	OUT TCNT0, R26

	LDI R26, (1<<TOIE0)   
	STS TIMSK0, R26

	RET


INT_TIMER0:
	PUSH R16        //guardamos el valor de R16
 	IN R16, SREG
	PUSH R16

	LDI R16, 100
	OUT TCNT0, R16      
	SBI TIFR0, TOV0
	
	INC R23           //realizamos el incremento en las unidades en cada interrupcion del timer0

	POP R16
	OUT SREG, R16  
	POP R16         //Devolvemos el valor antes guardado

	RETI		   //retorno de interrupcion 

TABLA7SEG: .DB 0x7E, 0x0C, 0xB6, 0x9E, 0xCC, 0xDA, 0xFA, 0x0E, 0xFE, 0xDE
//****************************************************