AS = as
LD = ld

TARGET = TareaP2

OBJ = TareaP2.o

all:$(TARGET)

$(OBJ): TareaP2.s
	$(AS) TareaP2.s -o $(OBJ)

$(TARGET): $(OBJ)
	$(LD) $(OBJ) -o $(TARGET)

clean:
	rm -f $(0BJ) $(TARGET)
