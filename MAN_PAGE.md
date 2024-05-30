# Math Expression Evaluator Manual

## Overview

This program evaluates a mathematical expression provided by the user. It is written in ARM assembly for the Raspberry Pi and can handle expressions up to 1024 characters in length.

## Prerequisites

Before installing and running the program, ensure you have the following:

1. **Raspberry Pi**: Any model with ARM architecture.
2. **Operating System**: A Unix-like operating system (e.g., Raspbian).
3. **ARM Toolchain**: Installed and configured.
   - You can install the GNU ARM toolchain using the following command:
     ```sh
     $ sudo apt-get install gcc-arm-none-eabi
     ```
4. **Make Utility**: Ensure `make` is installed.
   - Install `make` using:
     ```sh
     $ sudo apt-get install make
     ```

## Installation

1. **Download the program folder**:
   - Download the folder containing the source code and Makefile from the repository or provided location.

2. **Navigate to the program folder**:
   ```sh
   $ cd path/to/program-folder```

## Compilation

To compile the program, a Makefile is provided. This Makefile will assemble the main.s file into an executable named main.
```sh
  $ make
```

## Usage

After compiling the program, you can run it from the command line.

1. **Run the program:**
```sh
  $ ./main
```

2. **Input Restrictions:**

- The input should not begin or end with an operator.
- The maximum length of the input expression is 1024 characters.

3. **Example:**
```sh
  $ ./main
  Enter expression: 3+5*2
  Result: 13
```

## Troubleshooting

**Compilation Errors:**

- Ensure you have the ARM toolchain installed and properly configured.
- Verify that you are in the correct directory containing the main.s file and Makefile.

**Runtime Errors:**

- Ensure the input expression does not begin or end with an operator.
- Ensure the input expression does not exceed 1024 characters in length.
