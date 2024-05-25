.section .data
        inputMsg: .asciz "Ingrese una operacion matematica: "
        inputMsgLen = .-inputMsg
        operacion: .space 101
        reversePolishNotation: .space 101
        variables: .space 100

.section .text
.global _start

_start:

@ IMPRIMIMOS EL MENSAJE PARA QUE INGRESE UN INPUT
        ldr r1,=inputMsg
        ldr r2,=inputMsgLen
        bl writeString

@ LLAMAMOS LA FUNCION LEER INPUT
        ldr r1,=operacion
        mov r2,#100                                                                     // tiene un limite de 100 caracteres
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

        mov r12,#0                                                              // indice del rpn
        ldr r11,=reversePolishNotation                  // puntero de rpn
        mov r10,#0                                                              // indice infix
        ldr r0,=operacion                                               // puntero de input
        ldr r8,=variables                                               // puntero de variables
        mov r9,#0                                                               // indice de variables

        @ leemos el byte
InfixToRPN:
        ldrb r1,[r0, r10]                                               // r1 recibiria el byte

        cmp r1, #0                                                              // llegamos al fin del input?
        beq endRPNConvertion
        @ VERIFICAR SI ES PARENTESIS )
        cmp r1,#')'
        beq popPila

        cmp r1,#'('
        beq pushParenthesis

        bl isNumber
        cmp r2,#1                                                               // es numero?
        beq storeNumber
        bl isOperator                                                   // es operador?
        cmp r2,#0
        beq storeVariable                                               // no? guarde variable




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

        ldr r2, [sp]                                                    // r2 lee el tope de la pila
        cmp r2,#'('
        beq pushParenthesis
        push {r1, r3}                                                   // guardamos el operador actual con su respectiva prioridad
        mov r1,r2                                                               // r1 recibe el tope de la pila
        bl isOperator                                                   // para saber si la pila esta vacia
        cmp r2,#0                                                               // la pila esta vacia?
        beq pushPila                                                    // PUSH

        @ aqui la pila no esta vacia, por lo tanto
        @ r1 contiene actualmente el operador del tope
        @ r3 contiene la prioridad del tope
        @ en la pila habiamos metido anteriormente el operador y su prioridad actual
        @ entonces tenemos que hacerles pop en algun lado para ver quien entra o sale
        @ entonces, r2 recibiria el operador actual, mientras que r4, recibe la prioridad

        pop {r2,r4}                                                             // POP (operadorActual, prioridad)
        cmp r4,r3                                                               // CMP (prioridadActual - prioridadTope)
        bgt pushPila                                                    // si el operador actual tiene mayor prioridad, PUSH

        @ si no, hacemos POP en r1, PUSH a r2
        pop {r1}                                                                // POP al tope
        push {r2}                                                               // PUSH al operador actual

        strb r1,[r11,r12]
        add r10,#1
        add r12,#1
        b InfixToRPN

pushParenthesis:
        push {r1}
        add r10,#1
        //add r12,#1
        b InfixToRPN

pushPila:
        pop {r1,r3}                                                             // sacamos la prioridad y el operador actual que habiamos hecho PUSH anteriormente
        push {r1}                                                               // metemos solo el operador a la pila
        add r10,#1                                                              // aumentamos el indice del
        b InfixToRPN                                                    // nos devolvemos al ciclo

popPila:
        @ actualmente la pila no esta modificado, por lo tanto, hay que llegar hasta ( o fin de la pila
        pop {r1}
        cmp r1,#'('
        beq popPila.end
        cmp r1,#0
        beq popPila.exit
        strb r1,[r11,r12]
        add r12,#1
        add r10,#1


        b popPila

popPila.end:
        add r10,#1
        b InfixToRPN

popPila.exit:
        pop {r1}
        b endRPN


storeNumber:
        strb r1,[r11,r12]                                               // store number in rpn[i]
        add r12,#1                                                              // pasamos al siguiente indice del rpn
        add r10,#1                                                              // pasamos al siguiente caracter del input
        b InfixToRPN                                                    // nos devolvemos al loop

storeVariable:
        strb r1,[r11,r12]                                               // store number in rpn[i]
        add r12,#1                                                              // pasamos al siguiente indice del rpn
        add r10,#1                                                              // pasamos al siguiente caracter del input
        strb r1,[r8,r9]                                                 // guardamos la variable en variables
        add r9,#1                                                               // aumentamos el indice de variables
        b InfixToRPN                                                    // nos devolvemos al loop

endRPNConvertion:
        @ SACAMOS LO QUE QUEDA DE OPERADORES
        pop {r1}
        bl isOperator
        cmp r2,#0
        beq endRPN
        strb r1,[r11,r12]
        add r12,#1
        b endRPNConvertion

endRPN:
        push {r1}                                                               // metemos el ultimo valor de la pila, ya que ese no era un operador

@ IMPRIMIMOS EL INPUT
        ldr r1,=reversePolishNotation
        mov r2,#101
        bl writeString


_exit:
        mov r7,#1
        mov r0,#0
        swi 0

@ ======== FUNCTIONS =========

isOperator:
        @ REGISTROS QUE SALEN MODIFICADOS: R2,R3
        @ Funcion que recibe un byte en r1
        @ y devuelve 1 si es un operador, 0 si no es, en r2
        @ r3 devuelve la priodidad
        @ r1: receives byte
        mov r2,#1                       // es un operador (por defecto)
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
        mov r2,#0                       // no es un operador
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
        cmp r1,#30
        blt notNumber
        cmp r1,#39
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
