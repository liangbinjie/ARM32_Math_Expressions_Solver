AS = as
LD = ld

TARGET = main

OBJ = main.o

all:$(TARGET)

$(OBJ): main.s
	$(AS) main.s -o $(OBJ)

$(TARGET): $(OBJ)
	$(LD) $(OBJ) -o $(TARGET)

clean:
	rm -f $(0BJ) $(TARGET)
