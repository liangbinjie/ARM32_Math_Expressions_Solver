.section .data
	inputMsg: .asciz "Ingrese una operacion matematica: "
	inputMsgLen = .-inputMsg
	operacion: .space 1025
	reversePolishNotation: .space 1025
	variables: .space 11
	enter0ah: .asciz "\n"
	inputVariable: .asciz " > Ingrese su valor: "
	inputVariableLen = .-inputVariable
	char: .space 1
	num: .space 11
	new_operacion: .space 1025
	result: .space 11

.section .text
.global _start

_start:

@ IMPRIMIMOS EL MENSAJE PARA QUE INGRESE UN INPUT
	ldr r1,=inputMsg
	ldr r2,=inputMsgLen
	bl writeString
	
@ LLAMAMOS LA FUNCION LEER INPUT
	ldr r1,=operacion
	mov r2,#1025									// tiene un limite de 100 caracteres
	bl readInput
	
@ ELIMINAMOS AL ENTER DEL FINAL DEL INPUT
	ldr r0,=operacion
	bl delReturn
	
@ CONVERTIMOS DE INFIJO -> RPN
	// si es un operando (un numero o letra, va directo al string)
	// si es un operador (+-/*^) va al stack basado en su prioridad
	// orden de prioridad: PEMDSR
	// si un operador tiene una prioridad menor o igual al operador tope del stack, se saca ese operador del stack y se pone en el string, mientras que el nuevo, se pone en el stack
	// si el operador tiene una mayor prioridad al tope del stack, simplemente se hace push, no hay pop
	
	mov r12,#0								// indice del rpn
	ldr r11,=reversePolishNotation			// puntero de rpn
	mov r10,#0								// indice infix
	ldr r0,=operacion						// puntero de input
	ldr r8,=variables						// puntero de variables
	mov r9,#0				 				// indice de variables
	
	@ leemos el byte
InfixToRPN:
	ldrb r1,[r0, r10]						// r1 recibiria el byte
	
	cmp r1, #0								// llegamos al fin del input?
	beq endRPNConvertion					
	@ VERIFICAR SI ES PARENTESIS )
	cmp r1,#')'
	beq popPila

	cmp r1,#'('
	beq pushParenthesis	

	bl isNumber
	cmp r2,#1								// es numero?
	beq storeNumber
	bl isOperator							// es operador?
	cmp r2,#0
	beq storeVariable						// no? guarde variable
	

	
	
	@ aqui tenemos que ver el operador actual y de la pila
	@ r1 contiene el operador actual del input
	@ r3 contiene la prioridad del operador actual
	@ tenemos que saber si la pila esta vacia
	@ por lo tanto, utilizando el stack pointer
	@ obtenemos el tope de la pila
	@ verificamos que sea un operador, si no, hacemos push
	@ si es un operador, comparamos prioridades
	@ si los operadores actuales son parentesis
	@ la posicion de r12 no aumenta
	
	ldr r2, [sp]							// r2 lee el tope de la pila
	cmp r2,#'('
	beq pushParenthesis
	push {r1, r3} 							// guardamos el operador actual con su respectiva prioridad
	mov r1,r2								// r1 recibe el tope de la pila
	bl isOperator							// para saber si la pila esta vacia
	cmp r2,#0								// la pila esta vacia?
	beq pushPila							// PUSH
	
	@ aqui la pila no esta vacia, por lo tanto
	@ r1 contiene actualmente el operador del tope
	@ r3 contiene la prioridad del tope
	@ en la pila habiamos metido anteriormente el operador y su prioridad actual
	@ entonces tenemos que hacerles pop en algun lado para ver quien entra o sale
	@ entonces, r2 recibiria el operador actual, mientras que r4, recibe la prioridad
	add r10,#1

compareStack:	
	pop {r2,r4}								// POP (operadorActual, prioridad)
	cmp r4,r3								// CMP (prioridadActual - prioridadTope)								
	bgt pushPila2							// si el operador actual tiene mayor prioridad, PUSH, fin

	@ R1: OPERADOR TOPE
	@ R2: OPERADOR ACTUAL
	@ R3: PRIORIDAD TOPE
	@ R4: PRIORIDAD ACTUAL
	@ el stack todavia tiene el operador tope, no se le ha hecho pop	
	
	pop {r1}								// POP al tope
	strb r1,[r11,r12]						// lo guardamos al output						
	add r12,#1			
	mov r7,#' '
	strb r7, [r11,r12]
	add r12,#1
	@ con el tope guardado, tenemos que evaluar al siguiente tope
	@ r2 y r4 aun tienen informacion
	ldr r1,[sp]
	push {r2,r4}							// push operadorActual, prioridadActual

	bl isOperator
	cmp r2,#0
	beq InfixToRPN
	
	@ ahora r1 vuelve a tener el operador tope
	@ y r3 tiene la prioridad tope
	
	//add r10,#1
	b compareStack

pushParenthesis:
	push {r1}
	add r10,#1
	b InfixToRPN
	
pushPila2:
	push {r2}								// metemos solo el operador a la pila
	//add r10,#1								// aumentamos el indice del 
	b InfixToRPN							// nos devolvemos al ciclo

pushPila:
	pop {r1,r3}								// sacamos la prioridad y el operador actual que habiamos hecho PUSH anteriormente
	push {r1}								// metemos solo el operador a la pila
	add r10,#1								// aumentamos el indice del 
	b InfixToRPN							// nos devolvemos al ciclo
	
popPila:
	@ actualmente la pila no esta modificado, por lo tanto, hay que llegar hasta ( o fin de la pila
	pop {r1}
	cmp r1,#'('
	beq popPila.end
	strb r1,[r11,r12]
	add r12,#1

	b popPila
	
popPila.end:
	add r10,#1
	b InfixToRPN
	
storeNumber:
	strb r1,[r11,r12]						// store number in rpn[i]
	add r12,#1								// pasamos al siguiente indice del rpn
	add r10,#1								// pasamos al siguiente caracter del input 
	b InfixToRPN							// nos devolvemos al loop
	
storeVariable:
	strb r1,[r11,r12]						// store number in rpn[i]
	add r12,#1								// pasamos al siguiente indice del rpn
	add r10,#1
	cmp r1,#0x20
	beq noGuardeEspacio						// pasamos al siguiente caracter del input 
	strb r1,[r8,r9]							// guardamos la variable en variables
	add r9,#1
	noGuardeEspacio:						// aumentamos el indice de variables
	b InfixToRPN							// nos devolvemos al loop
	
endRPNConvertion:
	@ SACAMOS LO QUE QUEDA DE OPERADORES
	pop {r1}
	bl isOperator
	cmp r2,#0
	beq endRPN
	strb r1,[r11,r12]
	add r12,#1
	mov r7,#0x20
	strb r7, [r11,r12]
	add r12,#1
	
	b endRPNConvertion
	
endRPN:

	ldr r0,=reversePolishNotation
	bl cleanDoubleSpace
	bl cleaningExpression
	
	ldr r4,=variables
	ldr r3,=char

askInput:
	ldrb r1,[r4]
	cmp r1,#0
	beq askInput.end
	
	strb r1,[r3]
	ldr r1,=char
	mov r2,#1
	bl writeString
	
	ldr r1,=inputVariable
	ldr r2,=inputVariableLen
	bl writeString
	mov r7,#3
	mov r0,#1
	ldr r1,=num
	mov r2,#10
	swi 0
	
	
	add r4,#1
	b askInput
askInput.end:
	ldr r1,=new_operacion
	mov r2,#1025
	bl writeString
	bl printEnter
	
	ldr r0,=new_operacion
	push {r0}
evaluate:
	pop {r0}				// OBTENER PUNTERO 
	ldrb r1,[r0]			// OBTENER CARACTER
	cmp r1,#0				// FIN?
	beq evaluate.end		// YEAH
	cmp r1,#0x20
	beq nextChar
	bl isOperator			// NO, ES OPERADOR?
	cmp r2,#1				// SI
	beq evaluar				// EVALUE
	bl readNum				// ES NUMERO
	push {r3}				// GUARDE EN STACK EL NUMERO
	push {r0}				// GUARDE EL PUNTERO
	b evaluate				// CICLO

nextChar:
	add r0,#1
	push {r0}
	b evaluate

evaluar:
	add r0,#1
	mov r12,r0		// guardamos el siguiente puntero
	cmp r1,#'+'
	beq suma
	cmp r1,#'-'
	beq resta
	cmp r1,#'*'
	beq multi
	cmp r1,#'/'
	beq divi
	cmp r1,#'^'
	beq exp
	b evaluate
suma:
	pop {r2,r3}		// pop nums
	add r2,r3		// add
	push {r2} 		// guarde result 
	push {r12}		// guarde puntero
	b evaluate		// ciclo

resta:
	pop {r2,r3}
	SUB r3,r2
	push {r3}
	push {r12}
	b evaluate

multi:
	pop {r2,r3}
	mul r3,r2
	push {r3}
	push {r12}
	b evaluate

divi:
	pop {r2,r3}
	sdiv r3,r2
	push {r3}
	push {r12}
	b evaluate

exp:	
	pop {r2,r3}
	bl pow
	push {r2}
	push {r12}
	b evaluate
	
	

evaluate.end:
	pop {r0}
	ldr r1,=result			// le damos la direccion del buffer
	bl int_to_ascii			// llamamos a la funcion
	
	ldr r1,=result
	mov r2,#11
	bl writeString

_exit:
	bl printEnter
	mov r7,#1
	mov r0,#0
	swi 0

@ ======== FUNCTIONS =========
readNum:
	//ldr r0,=numInput
	mov r2,#10
	mov r3,#0
	
	readNum.while:
		ldrb r1,[r0]
		cmp r1,#0x20
		BEQ readNum.exit
		
		sub r1,#0x30
		add r0,#1
		
		mul r3,r2
		add r3,r1
		BAL readNum.while
	readNum.exit:
		add r0,#1
		@ r0: contiene el puntero
		@ r3: contiene el resultado
		bx lr

cleaningExpression:
	@ funcion para limpiar los espacios dobles
	@ r0 = rpn
	@ r1 =  new rpn
	ldr r0,=reversePolishNotation
	ldr r1,=new_operacion
	mov r5,#0
	mov r4,#0
	cleaning.while:
		ldrb r2,[r0,r4]
		add r4,#1
		cmp r2,#0x7f
		beq cleaning.nextChar
		cmp r2,#0
		beq cleaning.exit
		strb r2,[r1,r5]
		add r5,#1
		b cleaning.while
	cleaning.nextChar:
		
		b cleaning.while
	cleaning.exit:
		bx lr
		
		

isOperator:
	@ REGISTROS QUE SALEN MODIFICADOS: R2,R3
	@ Funcion que recibe un byte en r1
	@ y devuelve 1 si es un operador, 0 si no es, en r2
	@ r3 devuelve la priodidad
	@ r1: receives byte
	mov r2,#1			// es un operador (por defecto)
	cmp r1,#')'
	beq isParenthesis
	cmp r1,#'('
	beq isParenthesis
	cmp r1,#'^'
	beq isExp
	cmp r1,#'*'
	beq isDivMul
	cmp r1,#'/'
	beq isDivMul
	cmp r1,#'+'
	beq isSumSub
	cmp r1,#'-'
	beq isSumSub
	mov r2,#0			// no es un operador
	bx lr
isParenthesis:
	mov r3,#5
	bx lr
isExp:
	mov r3,#4
	bx lr
isDivMul:
	mov r3,#3
	bx lr
isSumSub:
	mov r3,#2
	bx lr


isNumber:
	@ Funcion que recibe un byte en r1
	@ y devuelve 1 si es un numero, 0 si no es, en r2
	@ r1: receives byte
	cmp r1,#0x30
	blt notNumber
	cmp r1,#0x39
	bgt notNumber
	mov r2,#1
	bx lr
notNumber:
	mov r2,#0
	bx lr
	
readInput:
	@ r1: buffer
	@ r2: size
	mov r7,#3
	mov r0,#1
	swi 0
	bx lr

writeString:
	@ funcion para imprimir un string
	@ r1: receives buffer
	@ r2: receives length
	mov r0,#1
	mov r7,#4
	swi 0
	bx lr

strlen:
	@ Funcion para calcular el largo de un string
	@ R0: receives buffer
    PUSH {R1, R2, LR}    @ 
    MOV R2, R0           @ R0 contiene la direccion del buffer
    MOV R1, #0           @ init contador
strlen_loop:
    LDRB R3, [R0, R1]    @ r3 obtiene el byte del buffer
    CMP R3, #0           @ compara si ya llego al final
    BEQ strlen_done      @ si es asi termina
    ADD R1, R1, #1       @ aumenta el contador
    B strlen_loop        @ 
strlen_done:
    MOV R0, R1           @ 
    POP {R1, R2, LR}     @ 
    BX LR                @ 
    
delReturn:
	@ funcion para eliminar el enter de al final de un input
	@ R0: recibe el puntero del buffer
	delReturn_loop:
		ldrb r1,[r0]
		cmp r1,#10
		beq delReturn_del
		cmp r1,#0
		beq delReturn_exit
		add r0,#1
		b delReturn_loop
	delReturn_del:
		mov r2,#0x20
		str r2,[r0]
	delReturn_exit:
		bx lr
		
cleanDoubleSpace:
	@ r0: receives buffer
	mov r2,#0								// contador
	mov r5,#0
	cleanDoubleSpace.while:
		ldrb r1,[r0,r2]
		cmp r1,#0
		beq cleanDoubleSpace.exit
		add r5,#1
		cmp r1,#0x7f
		beq cleanDoubleSpace.checkNextChar	
		cmp r1,#0x20
		beq cleanDoubleSpace.checkNextChar						// aumentamos el contador
		add r2,#1
		b cleanDoubleSpace.while
	cleanDoubleSpace.checkNextChar:
		ldrb r3,[r0,r5]
		cmp r3,#0x20
		beq cleanDoubleSpace.clean
		add r2,#1							// aumentamos el contador
		b cleanDoubleSpace.while
	cleanDoubleSpace.clean:
		mov r4,#0x7f
		strb r4,[r0,r2]
		add r2,#1							// aumentamos el contador
		b cleanDoubleSpace.while
	cleanDoubleSpace.exit:
		bx lr

printEnter:
	mov r7,#4
	mov r0,#1
	ldr r1,=enter0ah
	mov r2,#2
	swi 0
	bx lr
	
int_to_ascii:
    PUSH {LR}            @
    MOV R2, R1           @ movemos el puntero del numero en decimal a r2
    MOV R3, #10          @ 
    ADD R4, R1, #11      @ 
    MOV R1, R4

loop:
    MOV R4, #0           @ 
    UDIV R4, R0, R3      @ 
    MLS R5, R4, R3, R0   @ r5 = r0 - (r4*10), es decir r0%10
    ADD R5, R5, #'0'     @ 
    STRB R5, [R1, #-1]!  @ 
    MOV R0, R4           @ 
    CMP R0, #0           @ 
    BNE loop             @ 

    @ 
    MOV R0, R2           @ 
    MOV R1, R1           @ 
    BL reverse           @ 
    POP {LR}             @
    BX LR                @ 


reverse:
    PUSH {R4, R5, LR}    @ 
    SUB R1, R1, #1       @ 
rev_loop:
    CMP R0, R1           @ 
    BHS rev_done         @ 
    LDRB R4, [R0]        @ 
    LDRB R5, [R1]        @ 
    STRB R5, [R0]        @ 
    STRB R4, [R1]        @ 
    ADD R0, R0, #1       @ 
    SUB R1, R1, #1       @ 
    B rev_loop           @
rev_done:
    POP {R4, R5, LR}     @ 
    BX LR                @ 

pow:
	@ funcion de exponente
	@ R3: recibe el numero
	@ R2: recibe el exponente
	mov r4,#0
	cmp r2,#0
	beq pow.cero
	mov r6,#1
	pow.while:
		cmp r4,r2
		beq pow.exit
		mul r6,r3
		add r4,#1
		b pow.while
	
	pow.exit:
		mov r2,r6
		bx lr
		
	pow.cero:
		mov r2,#1
		bx lr
