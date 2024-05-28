# ARM32 Assembly to Solve Math Expressions

This project involves developing a program to solve mathematical expressions using ARM assembly language on a Raspberry Pi. The objective is to leverage the low-level programming capabilities of ARM assembly to create an efficient and compact solution for evaluating mathematical expressions.

## Hardware and Software Requirements

### Hardware: 
- Raspberry Pi (any model with ARM architecture)
### Software:
- Raspberry Pi OS (formerly Raspbian)
- ARM assembly compiler (e.g., as - the GNU Assembler)
- Standard development tools (e.g., gcc for linking, gdb for debugging)

---

## Implementation Goals 

The expression to be solved is provided by the user as a string input. The program should be able to parse the numbers and operands

By using the Reverse Polish Notation, the program can be able to output the results from the expression.

---

## Reverse Polish Notation
Reverse Polish Notation (RPN), also known as postfix notation, is a mathematical notation in which operators follow their operands. It eliminates the need for parentheses used in infix notation, simplifying calculations and reducing ambiguity. Converting infix expressions (like A * (B + C) / D) to RPN (like A B C + * D /) involves a systematic process that respects operator precedence and parentheses. Understanding and applying these rules can enhance computational efficiency and is fundamental in various computer science applications, such as in stack-based calculators and expression evaluation in programming languages. This guide outlines the rules and provides a step-by-step method for converting infix expressions to RPN.

### Operator Precedence Chart

| Operator | Precedence |
|----------|------------|
|    )     |     5      |
|    (     |     5      |
|    ^     |     4      |
|    *     |     3      |
|    /     |     3      |
|    +     |     2      |
|    -     |     2      |

---

### Operands:

- If the character is an operand (e.g., a variable or a number), add it directly to the output string.

### Operators:
When you read an operator (like +, -, *, /):
- Compare it with the operator on the top of the stack.
- If the stack is empty or has a left parenthesis ( on top, PUSH the current operator onto the stack.
- If the operator is greater in precedence than top of stack, push.
- If the operator is equal o less in precedence than top of stack, POP top operator from stack, put it on output string, PUSH current operator to stack until the next top precedence is lower than the actuak operador.

### Left Parenthesis (:

- If the character is a left parenthesis (, push it onto the stack.
  
### Right Parenthesis ):

- If the character is a right parenthesis ), pop from the stack to the output string until a left parenthesis ( is at the top of the stack. Pop and discard the left parenthesis.

### End of Expression:

- When the end of the infix expression is reached, pop all operators from the stack to the output string.

---

### Examples used in the program
![image](https://github.com/liangbinjie/ARM32_Math_Expressions_Solver/assets/67171031/27fcf0e5-1e91-4fe8-84b4-c061bdd6ad35)

### Input value for every variable
![image](https://github.com/liangbinjie/ARM32_Math_Expressions_Solver/assets/67171031/c128c006-5d49-48f6-9d50-77cc38ab95a0)

---

## Evaluate Expression

After converting infix to reverse Polish Notation, the next step is to evaluate the expression. For doing such task, we will need to use back our friend the *STACK*.

Using the stack, we push the operands (numbers and letters) from left to right. When we encounter an operator, we pop two operands from the stack and we evaluate the arithmetic expression, after getting the result, we push the result into the stack. If the expression is out of operators, it means we have reached to the end of the evaluation.

### Example:

We have the following RPN expression `12 3 * 4 3 - +` | Original expression: `( 12 * 3 ) + ( 4 - 3 )`

First we push the numbers

|   STACK  |
|----------|
|    12    |
|    3     |

We now encounter a multiplication operator `*`, so, we pop the last two numbers out of the stack, and we multiply them, which we give us `36`, with the result 36, we push it into the stack. Then we push the other two numbers. (3, 4)

|   STACK  |
|----------|
|    4     |
|    3     |
|    36    |

After pushing 3 and 4, we encounter `-` sign, we need to substract, giving us the result of `1`, we push `1` into the stack

|   STACK  |
|----------|
|    1     |
|    36    |

The next character in the expression is `+` operator, we need to pop the two numbers left in the stack and make an addition. This will give the final result of `37`.

