.section .data
	operacion: .space 1025
	reversePolishNotation: .space 1025
	new_rpn: .space 1025
	variables: .space 11
	char: .space 1
	num: .space 11
	new_operacion: .space 1025
	result: .space 11
	minus: .byte 0									// se utliza como una señal para indicar si el resultado va a ser negativo o positivo

	minusSign: .asciz "-"
	enter0ah: .asciz "\n"

	inputVariable: .asciz " > Ingrese su valor: "
	inputVariableLen = .-inputVariable

	inputMsg: .asciz "Ingrese una operacion matematica: "
	inputMsgLen = .-inputMsg

	divErrorMsg: .asciz "Division invalida, division entre 0\n"
	divErrorLen = .-divErrorMsg

	OverflowErrorMsg: .asciz "Resultado supera a 32 bits\n"
	OverflowErrorMsgLen = .-OverflowErrorMsg

	invalidMsg: .asciz "Expresion invalida\n"
	invalidMsgLen = .-invalidMsg

	invalidVariables: .asciz "Cantidad de variables no soportado\n"
	invalidVariablesLen = .-invalidVariables

	invalidValue: .asciz "Valor invalido\n"
	invalidValueLen = .-invalidValue

.section .text
.global _start

_start:

@ IMPRIMIMOS EL MENSAJE PARA QUE INGRESE UN INPUT
	ldr r1,=inputMsg
	ldr r2,=inputMsgLen
	bl writeString
	
@ LLAMAMOS LA FUNCION LEER INPUT
	ldr r1,=operacion
	mov r2,#1025									
	bl readInput

@ SI NO SE INGRESO NADA, ERROR
	ldr r0,=operacion
	ldrb r1,[r0]
	cmp r1,#10								// error si solo es un enter
	beq badExpression
	cmp r1,#0x20							// error si ingresa un espacio al inicio
	beq badExpression

@ VERIFICAR QUE EL PRIMER CARACTER NO SEA UN OPERADOR
	ldr r0,=operacion
	ldrb r1,[r0]
	cmp r1,#'('
	beq siga
	bl isOperator
	cmp r2,#1
	beq badExpression

siga:	

@ VERIFICAR QUE EL ULTIMO CARACTER NO SEA UN OPERADOR
	bl checkLastOperator
	bl isOperator
	cmp r2,#1
	beq badExpression						// si lo es, fin

@ ELIMINAMOS AL ENTER DEL FINAL DEL INPUT
	ldr r0,=operacion
	bl delReturn

@ CHECKEAMOS SI LA EXPRESION ESTA BIEN PUESTA
	@ checkeo de parentesis
	ldr r0,=operacion
	bl checkParenthesis
	cmp r0,#0
	beq badExpression

@ FALTA: CHECKEAR QUE LOS SIGNOS NO ESTEN MAL PUESTOS

@ CONVERTIMOS DE INFIJO -> RPN
	// si es un operando (un numero o letra, va directo al string)
	// si es un operador (+-/*^) va al stack basado en su prioridad
	// orden de prioridad: PEMDSR
	// si un operador tiene una prioridad menor o igual al operador tope del stack, se saca ese operador del stack
	// con el operador tope sacado del stack, se pone en el output. Con el operador actual lo comparamos con el nuevo tope
	// si el operador tiene una mayor prioridad al tope del stack, simplemente se hace push, no hay pop.
	// pero si el operador actual sigue siendo menor o igual en prioridad al tope, se hace el mismo proceso, hasta tener un
	// tope con menor prioridad que actual
	
	ldr r11,=reversePolishNotation			// puntero de rpn
	mov r12,#0								// indice del rpn
	ldr r0,=operacion						// puntero de input
	mov r10,#0								// indice infix
	ldr r8,=variables						// puntero de variables
	mov r9,#0				 				// indice de variables, servira para contar cuantas variables tenemos
	
@ CICLO DE CONVERSION INFIJO A REVERSE POLISH NOTATION
InfixToRPN:
	ldrb r1,[r0, r10]						// r1 recibiria el byte que tiene el input en la posicion R10
	
	cmp r1, #0								// llegamos al fin del input?
	beq endRPNConvertion					// si es asi, sacamos lo que tiene pendiente la pila
	@ VERIFICAR SI ES PARENTESIS )
	cmp r1,#')'								// R1 es ')'?
	beq popPila								// buscamos el su parentesis homologo

	cmp r1,#'('								// R1 es '('?
	beq pushParenthesis						// push simplemente

	bl isNumber
	cmp r2,#1								// es numero?
	beq storeNumber							// guarde el numero en el output
	bl isOperator							// es operador?
	cmp r2,#0								// no?
	beq storeVariable						// guarde variable
	
	@ aqui tenemos que ver el operador actual y de la pila
	@ r1 contiene el operador actual del input
	@ r3 contiene la prioridad del operador actual
	@ tenemos que saber si la pila esta vacia
	@ por lo tanto, utilizando el stack pointer
	@ obtenemos el tope de la pila
	@ verificamos que sea un operador, si no, hacemos push
	@ si es un operador, comparamos prioridades
	@ si los operadores actuales son parentesis
	@ la posicion de r12 (index rpn) no aumenta
	
	ldr r2, [sp]							// R2 lee el tope de la pila con el stack pointer
	cmp r2,#'('								// si es un parentesis abierto
	beq pushParenthesis						// hacemos push al operador actual

	@ si no es un parentesis abierto
	push {r1, r3} 							// guardamos el operador actual con su respectiva prioridad en la pila
	mov r1,r2								// r1 recibe el tope de la pila, previamente leido en R2 por el SP
	bl isOperator							// llamamos la funcion, para saber si la pila esta vacia
	cmp r2,#0								// la pila esta vacia?
	beq pushPila							// PUSH
	
	@ aqui la pila no esta vacia, por lo tanto
	@ R1 contiene actualmente el OPERADOR del TOPE
	@ R3 contiene la PRIORIDAD del TOPE
	@ en la pila habiamos metido anteriormente el operador y su prioridad actual
	@ entonces tenemos que hacerles pop en algun lado para ver quien entra o sale
	@ entonces se decidee: R2 recibe el OPERADOR actual, mientras que R4, recibe la PRIORIDAD

	add r10,#1								// aumentamos el indice de R10 (indice del input)

compareStack:	
	pop {r2,r4}								// POP (operadorActual, prioridad)
	cmp r4,r3								// CMP (prioridadActual - prioridadTope)								
	bgt pushPila2							// si el operador actual tiene mayor prioridad, PUSH, fin

	@ SI NO FUE ASI, ENTONCES,
	@ R1: OPERADOR TOPE
	@ R2: OPERADOR ACTUAL
	@ R3: PRIORIDAD TOPE
	@ R4: PRIORIDAD ACTUAL
	@ el stack todavia tiene el operador tope, no se le ha hecho pop	
	
	pop {r1}								// POP al tope
	strb r1,[r11,r12]						// lo guardamos al output [=rpn, r12]						
	add r12,#1								// aumentamos el indice de R12 (indice de rpn)
	mov r7,#' '								// a la par del operador
	strb r7, [r11,r12]						// le guardamos un espacio
	add r12,#1								// por si ocurren errores de strb

	@ con el tope guardado, tenemos que evaluar al siguiente tope
	@ r2 y r4 aun tienen informacion (R2: OPERADOR ACTUAL | R4: PRIORIDAD ACTUAL)

	ldr r1,[sp]								// leemos en R1 el tope
	push {r2,r4}							// push operadorActual, prioridadActual

	bl isOperator							// es el tope un operador o esta vacio?
	cmp r2,#0								// si esta vacio
	beq InfixToRPN							// vamos de regreso al ciclo de conversion
	
	@ ahora R1 vuelve a tener el operador tope
	@ y R3 tiene la prioridad tope
	
	b compareStack							// nos devolvemos al ciclo del stack

pushParenthesis:							// label para solamente hacer PUSH y modificar el indice del input
	push {r1}
	add r10,#1								// aumentamos el indice (input)
	b InfixToRPN
	
pushPila2:									// label para solamente hacer PUSH sin modificar el indice del input
	@ ESTE PUSH SE HACE CUANDO ESTAMOS DENTRO DEL CICLO DE COMPARACION DE LA PILA
	push {r2}								// metemos solo el operador a la pila
	b InfixToRPN							// nos devolvemos al ciclo

pushPila:									// label para hacer push y modificar indice input
	@ ESTE PUSH SE HACE CUANDO EL OPERADOR ACTUAL ES MAYOR QUE EL TOPE
	pop {r1,r3}								// sacamos la prioridad y el operador actual que habiamos hecho PUSH anteriormente
	push {r1}								// metemos solo el operador a la pila
	add r10,#1								// aumentamos el indice del 
	b InfixToRPN							// nos devolvemos al ciclo
	
popPila:									// label para hacerle pop a la pila
	@ ESTE POP SE HACE EN EL CASO: SE ENCUENTRA UN ')'
	@ actualmente la pila no esta modificado, por lo tanto, hay que llegar hasta ( o fin de la pila
	pop {r1}								// pop a la pila (R1 contiene el byte)
	cmp r1,#'('								// es R1 igual a '('?
	beq popPila.end							// fin
	strb r1,[r11,r12]						// si no, agregue el operador al output
	add r12,#1								// aumente el indice del output

	b popPila								// regresamos al ciclo pop
	
popPila.end:
	add r10,#1								// aumente ciclo de R10
	b InfixToRPN							// volvemos al ciclo de conversion
	
storeNumber:
	strb r1,[r11,r12]						// store number in rpn[i]
	add r12,#1								// pasamos al siguiente indice del rpn
	add r10,#1								// pasamos al siguiente caracter del input 
	b InfixToRPN							// nos devolvemos al loop
	
storeVariable:
	strb r1,[r11,r12]						// store number in rpn[i]
	add r12,#1								// pasamos al siguiente indice del rpn
	add r10,#1								// aumentamos el indice del input
	cmp r1,#0x20							// es un espacio?
	beq noGuardeEspacio						// pasamos al siguiente caracter del input 
	push {r0-r12}							// es una variable?
	bl checkVariable						// verificamos si esta en la lista
	cmp r0,#0								// no esta en la lista?
	beq storeVariableList					// guardemoslo
	pop {r0-r12}							
	b InfixToRPN							// devuelta al ciclo de conversion

storeVariableList:
	pop {r0-r12}
	strb r1,[r8,r9]							// guardamos la variable en variables
	add r9,#1								// aumentamos el indice
	cmp r9,#10								// vemos si supero los 10 variables
	bgt overflowVariables					// si es asi, error
	noGuardeEspacio:						// 
	b InfixToRPN							// nos devolvemos al loop
	
endRPNConvertion:
	@ SACAMOS LO QUE QUEDA DE OPERADORES
	pop {r1}								// sacamos lo que tiene la pila
	bl isOperator							// es un operador?
	cmp r2,#0								// no, la pila esta vacia
	beq endRPN								// fin de conversion
	strb r1,[r11,r12]						// si, es un operador, guarde en output
	add r12,#1								// aumenta indice r12
	mov r7,#0x20							// guardamos un espacio
	strb r7, [r11,r12]						// a la par del operador
	add r12,#1								// aumentamos indice
	
	b endRPNConvertion						// volvemos al ciclo de fin de conversion
	
endRPN:

@ SECCION DONDE CAMBIAMOS LAS VARIABLES POR LOS VALORES QUE INDIQUEMOS

	ldr r0,=reversePolishNotation			// limpiamos los
	bl cleanDoubleSpace						// espacios dobles del output
	bl cleaningExpression					// new_operacion va a tener una version mas limpia del output

	ldr r0,=new_rpn							// copiamos en new_rpn lo que tiene
	ldr r1,=new_operacion					// new_operacion
	bl cpyBuffer

	ldr r4,=variables						// obtenemos las variables 
	ldr r3,=char							// buffer para guardar variable

askInput:
	@ lectura de variable
	ldrb r1,[r4]							// R1 lee una variable de la lista variables[i]
	cmp r1,#0								// es el fin de la lista?
	beq askInput.end						// terminamos de preguntar por cada valor
	
	strb r1,[r3]							// lo guardamos en el buffer =char
	PUSH {R1}								// guardamos la variable en la pila

	@ imprimir variable
	ldr r1,=char							// R1 recibe el puntero a la variable =char
	mov r2,#1								// para asi poder imprimir
	bl writeString							// la variable en la que estamos trabajando
	ldr r1,=inputVariable
	ldr r2,=inputVariableLen
	bl writeString
	
	@ obtener valor
	mov r7,#3
	mov r0,#1
	ldr r1,=num								// =num va a contener el valor en ASCII del valor
	mov r2,#10
	swi 0

@ VERIFICAR SI ES UN NUMERO
	push {r0-r12}

	ldr r0,=num
	bl isNum

	cmp r0,#0
	beq invalidValueInput

	pop {r0-r12}

@ CONTINUAR
	@ cambiar variable por valor
	POP {R1}								// sacamos la variable
	PUSH {R0-R12}							// guardamos todos los datos de la pila
	bl overwriteVariable					// vamos a sobreescribir la variable del output por su valor
	ldr r0,=new_operacion					// limpiamos new_operacion
	bl cleanBuffer

	ldr r0,=new_operacion					// copiamos lo que tiene =new_rpn
	ldr r1,=new_rpn							// dentro de new_operacion
	bl cpyBuffer

	POP {R0-R12}							// sacamos los datos de la pila

	add r4,#1								// avanzamos a la siguiente variable
	b askInput								// devuelta al ciclo

askInput.end:
	@ imprimir lo que quedo con el cambio de variables
	ldr r1,=new_rpn
	mov r2,#1025
	bl writeString
	bl printEnter
	
	ldr r0,=new_rpn
	push {r0}

@ EVALUAMOS LA OPERACION
evaluate:
	pop {r0}								// OBTENER PUNTERO DE NEW_RPN de la pila
	ldrb r1,[r0]							// OBTENER CARACTER
	cmp r1,#0								// FIN?
	beq evaluate.end						// YEAH
	cmp r1,#0x20							// es un espacio
	beq nextChar							// avance a la siguiente direccion
	bl isOperator							// NO, ES OPERADOR?
	cmp r2,#1								// SI
	beq evaluar								// EVALUE

	@ si es un numero
	bl readNum								// ES NUMERO, PASAR DE ASCII A INT
	push {r3}								// GUARDE EN STACK EL NUMERO (funcion devuelve en R3 el valor)
	push {r0}								// GUARDE EL PUNTERO (funcion readNum ya devuelve el puntero)
    b evaluate								// CICLO

nextChar:
	add r0,#1								// aumente puntero =new_rpn 
	push {r0}								// guarde en pila
	b evaluate

evaluar:									// label para evaluar dos operandos
	add r0,#1								// aumentamos R0 para que apunte al siguiente puntero en el output
	mov r12,r0								// guardamos el siguiente puntero en R12
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
	pop {r2,r3}								// pop nums
	adds r2,r3								// add
	bcs overflowError
	push {r2} 								// guarde result 
	push {r12}								// guarde puntero
	b evaluate								// ciclo

resta:
	@ ES UNA OPERACION DE RESTA
	@ R3: PRIMER OPERANDO
	@ R2: SEGUNDO OPERANDO
	mov r10,r0			
	add r10,#1								// si el siguiente caracter de RPN
	ldrb r11,[r10]							// es un signo de resta
	cmp r1,r11								// es decir comparamos "-" y "-"
	bne noCambios							// si el siguiente no es un signo de resta, siga sin cambios
	push {r0-r12}							// pero si ese no es el caso, osea si es un signo de resta
	bl NOTMinus								// cambiamos la señal del signo negativo
	pop {r0-r12}							// para que se considere como una "suma", -- = +
noCambios:
	pop {r2,r3}
	cmp r2,r3 
	bgt restaABS							// el segundo operando es mas grande
	SUB r4,r3,r2
	b restaContinuar
restaABS:									// la operacion va a quedar negativo
	push {r0-r12}
	bl NOTMinus								// le hacemos NOT a nuestra señal de menos
	pop {r0-r12}
	SUB r4,R2,R3

restaContinuar:
	push {r4}
	push {r12}
	b evaluate

multi:
	@ ES UNA OPERACION CON MULTIPLICACION
	pop {r2,r3}
	muls r3,r2
	bmi overflowError
	push {r3}
	push {r12}
	b evaluate

divi:
	@ ES UNA OPERACION CON DIVISION
	pop {r2,r3}
	cmp r2,#0
	beq divError							// division entre 0
	sdiv r3,r2
	push {r3}
	push {r12}
	b evaluate

exp:	
	@ ES UNA OPERACION CON EXPONENTE
	pop {r2,r3}
	bl pow
	push {r2}
	push {r12}
	b evaluate

@ IMPRIMIR RESULTADO	
evaluate.end:

	pop {r0}
	ldr r1,=result							// le damos la direccion del buffer
	bl int_to_ascii							// convertimos de int a ASCII
	
	ldr r0,=minus							
	ldrb r1,[r0]							// es negativo o positivo?
	cmp r1,#0
	beq printPositive
	ldr r1,=minusSign
	mov r2,#1
	bl writeString
printPositive:
	ldr r1,=result
	mov r2,#11
	bl writeString

@ FIN DE PROGRAMA =================================================================
_exit:
	bl printEnter
	mov r7,#1
	mov r0,#0
	swi 0

@ SECCION DE MENSAJES ============================================================
divError:
	ldr r1,=divErrorMsg
	ldr r2,=divErrorLen
	bl writeString
	b _exit

overflowError:
	ldr r1,=OverflowErrorMsg
	ldr r2,=OverflowErrorMsgLen
	bl writeString
	b _exit

badExpression:
	ldr r1,=invalidMsg
	ldr r2,=invalidMsgLen
	bl writeString
	b _exit

overflowVariables:
	ldr r1,=invalidVariables
	ldr r2,=invalidVariablesLen
	bl writeString
	b _exit

invalidValueInput:
	ldr r1,=invalidValue
	ldr r2,=invalidValueLen
	bl writeString
	pop {r0-r12}
	b askInput

@ ======== FUNCTIONS ==============================================================

@===========================================================
cpyBuffer:
	@ funcion para copiar un buffer
	@ r0: buffer a guardar
	@ r1: buffer a copiar
	cpyBuffer.while:
		ldrb r2,[r1]
		cmp r2,#0							// fin de buffer a copiar
		beq cpyBuffer.end
		strb r2,[r0]
		add r0,#1
		add r1,#1
		b cpyBuffer.while
	cpyBuffer.end:
		bx lr
@===========================================================

@===========================================================
cleanBuffer:
	@ funcion para limpiar un buffer
	@ r0: recibe el buffer
	cleanBuffer.while:
		ldrb r1,[r0]
		cmp r1,#0
		beq cleanBuffer.end
		mov r2,#0
		strb r2,[r0]
		add r0,#1
		b cleanBuffer.while
	cleanBuffer.end:
		bx lr
@===========================================================

@===========================================================
overwriteVariable:
	@ funcion para sobreescribir la variable por su valor
	@ r0: expression pointer
	@ r1: variable 
	@ r2: number pointer
	@ r3: new_rpn 
	ldr r0,=new_operacion
	ldr r3,=new_rpn
	overwriteVariable.while:
	ldr r2,=num
	ldrb r4,[r0]							// obtenemos el caracter de la expresion =new_operacion
	cmp r4,#0								// end?
	beq overwriteVariable.end	
	add r0,#1								// aumentamos el puntero de =new_operacion
	cmp r4,r1								// es el caracter igual a la variable que estamos buscando?
	beq overwrite							// yes? overwrite 

	strb r4,[r3]							// no es igual, guarde caracter en new_rpn[r3]
	add r3,#1								// aumenta indice =new_rpn
	b overwriteVariable.while
	
	overwrite:
		ldrb r5,[r2]						// lee el numero
		cmp r5,#10							// fin del numero?
		beq overwriteVariable.while
		strb r5,[r3]						// guarde el numero en new_rpn[r3]
		add r3,#1							// aumenta indice de r3
		add r2,#1							// aumenta indice del numero
		b overwrite							// regreso al loop_overwrite
	overwriteVariable.end:
		bx lr
@===========================================================
	
@===========================================================
checkVariable:
	@ funcion para revisar si una variable se encuentra ya en la lista
	@ R1: recibe la variable que deseamos verificar
	@ ret: r0: 0 no se encuentra. r0: 1 si se encuentra
	ldr r2,=variables
	checkVariable.while:
	ldrb r3,[r2]
	cmp r3,#0
	beq notInList
	cmp r1,r3
	beq inList
	add r2,#1
	b checkVariable.while
	inList:
		mov r0,#1
		bx lr
	notInList:
		mov r0,#0
		bx lr
@===========================================================

@===========================================================
readNum:
	@ funcion que convierte de ascii a decimal
	@ r0:  =numInput
	@ RET:
	@ r0: contiene el puntero
	@ r3: contiene el resultado
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
		bx lr
@===========================================================

@===========================================================
cleaningExpression:
	@ funcion para limpiar los espacios dobles
	@ con el fin de tener en new_operacion un string sin bytes basura
	@ ejemplo: 123(20h)(7fh)+A  ---> 123(20h)+A
	@ r0 = rpn
	@ r1 =  new rpn
	@ r4: indice de rpn
	@ r5: indice del nuevo rpn
	ldr r0,=reversePolishNotation
	ldr r1,=new_operacion
	mov r5,#0
	mov r4,#0
	cleaning.while:
		ldrb r2,[r0,r4]							// cargamos el caracter de rpn 
		add r4,#1								// aumentamos rpn
		cmp r2,#0x7f							// es el caracter un 7fh?
		beq cleaning.nextChar					// si es asi, no lo guardamos en new_rpn
		cmp r2,#0								// es el fin de rpn?
		beq cleaning.exit						// exit
		strb r2,[r1,r5]							// guardamos el caracter en new_rpn[r5]
		add r5,#1								// aumentamos indice de R5
		b cleaning.while
	cleaning.nextChar:
		b cleaning.while
	cleaning.exit:
		bx lr
@===========================================================
		
@===========================================================
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
@===========================================================

@===========================================================
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
@===========================================================

@===========================================================
isNum:
	@ funcion para verificar si es un numero
	mov r2,#10
	@r0: buffer del num
	isNum.while:
		ldrb r1,[r0]
		cmp r1,r2
		BEQ isNum.exit
		cmp r1,#0x29
		blt notNum
		cmp r1,#0x40
		bge notNum
		add r0,#1
		BAL isNum.while
	isNum.exit:
		mov r0,#1
		bx lr
	notNum:
		mov r0,#0
		bx lr
@===========================================================

@===========================================================
readInput:
	@ r1: buffer
	@ r2: size
	mov r7,#3
	mov r0,#1
	swi 0
	bx lr
@===========================================================

@===========================================================
writeString:
	@ funcion para imprimir un string
	@ r1: receives buffer
	@ r2: receives length
	mov r0,#1
	mov r7,#4
	swi 0
	bx lr
@===========================================================

@===========================================================
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
@===========================================================

@===========================================================
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
		
@===========================================================
cleanDoubleSpace:
	@ funcion que limpia los espacios dobles de un string, cambia los espacios dobles por un 7fh
	@ r0: receives buffer
	mov r2,#0										// contador
	mov r5,#0
	cleanDoubleSpace.while:
		ldrb r1,[r0,r2]
		cmp r1,#0
		beq cleanDoubleSpace.exit
		add r5,#1
		cmp r1,#0x7f
		beq cleanDoubleSpace.checkNextChar	
		cmp r1,#0x20
		beq cleanDoubleSpace.checkNextChar			// aumentamos el contador
		add r2,#1
		b cleanDoubleSpace.while
	cleanDoubleSpace.checkNextChar:
		ldrb r3,[r0,r5]
		cmp r3,#0x20
		beq cleanDoubleSpace.clean
		add r2,#1									// aumentamos el contador
		b cleanDoubleSpace.while
	cleanDoubleSpace.clean:
		mov r4,#0x7f
		strb r4,[r0,r2]
		add r2,#1									// aumentamos el contador
		b cleanDoubleSpace.while
	cleanDoubleSpace.exit:
		bx lr
@===========================================================

@===========================================================
printEnter:
	mov r7,#4
	mov r0,#1
	ldr r1,=enter0ah
	mov r2,#2
	swi 0
	bx lr
@===========================================================

@===========================================================
int_to_ascii:
	@ funcion para convertir INT -> ASCII
	@ R0: INT
	@ R1: buffer
    PUSH {LR}            @
    MOV R2, R1           @ movemos el puntero del numero en decimal a r2
    MOV R3, #10          @ 
    ADD R4, R1, #11      @ 
    MOV R1, R4

	int_to_ascii.loop:
    MOV R4, #0           @ 
    UDIV R4, R0, R3      @ 
    MLS R5, R4, R3, R0   @ r5 = r0 - (r4*10), es decir r0%10
    ADD R5, R5, #'0'     @ 
    STRB R5, [R1, #-1]!  @ 
    MOV R0, R4           @ 
    CMP R0, #0           @ 
    BNE int_to_ascii.loop

    MOV R0, R2           @ 
    MOV R1, R1           @ 
    BL reverse           @ 
    POP {LR}             @
    BX LR                @ 

@===========================================================
reverse:
	@ Funcion para reverse un string
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
@===========================================================

@===========================================================
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
@===========================================================

@===========================================================
checkParenthesis:
	@ funcion para verificar que la expresion dada, los parentesis esten bien puestos
	@ r0: expresion
	@ r2: contador de (
	@ r3: contador de )
	mov r2,#0
	mov r3,#0
	checkParenthesis.while:
		ldrb r1,[r0]
		add r0,#1
		cmp r1,#0
		beq checkParenthesis.end
		cmp r1,#'('
		beq addLeftPthsis
		cmp r1,#')'
		beq addRightPthsis
		b checkParenthesis.while
	addLeftPthsis:
		add r2,#1
		b checkParenthesis.while
	addRightPthsis:
		add r3,#1
		b checkParenthesis.while
	checkParenthesis.end:
		cmp r3,r2 
		beq checkedPthsis
		mov r0,#0					// no estan bien colocados
		bx lr
	checkedPthsis:
		mov r0,#1					// estan bien colocados
		bx lr
@===========================================================

@===========================================================
NOTMinus:
	ldr r0,=minus					// lee el puntero de minus
	ldrb r1,[r0]					// carga su valor
	mvn r2,r1						// not r1, store in r2
	strb r2,[r0]					// guarda el valor en minus
	bx lr							// return

checkLastOperator:
	@ funcion para verificar que el ultimo caracter no sea un operador
	ldr r0,=operacion
	checkLastOperator.while:
		ldrb r1,[r0]
		cmp r1,#')'
		beq checkLastOperator.end
		cmp r1,#0
		beq checkLastOperator.end
		cmp r1,#10
		beq checkLastOperator.end
		ldrb r2,[r0]
		add r0,#1
		b checkLastOperator.while
	checkLastOperator.end:
		mov r1,r2
		bx lr

