# --- Herramientas ---
CC = gcc
YACC = bison
LEX = flex

# --- Banderas (Flags) ---
# -I.: Busca headers (parser.tab.h) en el directorio actual
CFLAGS = -Wall -g -I. -I$(SRC_DIR)
# Enlazamos con la librería de flex (yywrap, etc.)
LDFLAGS = -lfl
YFLAGS = -d   # -d genera el header (parser.tab.h)

# --- Archivos ---
# Nombre del ejecutable final
TARGET = juego_pelea

# Directorio de los archivos fuente
SRC_DIR = src

# Archivos de código fuente
YACC_SRC = $(SRC_DIR)/parser.y
LEX_SRC = $(SRC_DIR)/lexer.l
MAIN_SRC = $(SRC_DIR)/main.c

# Archivos de código generados (en el directorio raíz)
YACC_C = parser.tab.c
YACC_H = parser.tab.h
LEX_C = lex.yy.c
PR_H = parser.h

# Agrupar generados para facilitar la limpieza
GENERATED_C = $(YACC_C) $(LEX_C)
GENERATED_H = $(YACC_H) $(PR_H)

# Archivos objeto (en el directorio raíz)
OBJECTS = main.o parser.tab.o lex.yy.o

# Comandos
RM = rm -f

# --- Reglas ---

# Regla por defecto: 'make' o 'make all'
all: $(TARGET)

# 1. Regla de Enlace (Linking): Crea el ejecutable final
$(TARGET): $(OBJECTS)
	@echo "Enlazando para crear el ejecutable: $@"
	$(CC) $(CFLAGS) -o $(TARGET) $(OBJECTS) $(LDFLAGS)

# --- 2. Reglas de Compilación de Objetos (.o) ---

# Compila main.o a partir de src/main.c
main.o: $(MAIN_SRC) $(YACC_H)
	@echo "Compilando (main): $< -> $@"
	$(CC) $(CFLAGS) -c $(MAIN_SRC) -o $@

# Compila parser.tab.o a partir de parser.tab.c
parser.tab.o: $(YACC_C) $(YACC_H)
	@echo "Compilando (parser): $< -> $@"
	$(CC) $(CFLAGS) -c $(YACC_C) -o $@

# Compila lex.yy.o a partir de lex.yy.c
lex.yy.o: $(LEX_C) $(PR_H)
	@echo "Compilando (lexer): $< -> $@"
	$(CC) $(CFLAGS) -c $(LEX_C) -o $@

# --- 3. Reglas de Generación de Código (Bison/Flex) ---

# Bison: genera parser.tab.c y parser.tab.h a partir de parser.y
$(YACC_C) $(YACC_H): $(YACC_SRC)
	@echo "Generando parser (Bison)..."
	$(YACC) $(YFLAGS) -o $(YACC_C) $(YACC_SRC)

# Crear un alias 'parser.h' porque algunos ficheros (ej. lexer.l) incluyen "parser.h"
parser.h: $(YACC_H)
	@echo "Creando parser.h (embebiendo src/types.h y luego $(YACC_H))..."
	@echo '/* Auto-generated wrapper: types definitions then bison header */' > $@
	@cat $(SRC_DIR)/types.h >> $@
	@echo "\n/* End of embedded types.h */\n" >> $@
	@cat $(YACC_H) >> $@


# Flex: genera lex.yy.c a partir de lexer.l (depende de parser.h)
$(LEX_C): $(LEX_SRC) parser.h
	@echo "Generando lexer (Flex)..."
	$(LEX) -o $@ $(LEX_SRC)

# --- 4. Regla 'clean' ---

clean:
	@echo "Limpiando archivos de compilación..."
	$(RM) $(OBJECTS) $(GENERATED_C) $(GENERATED_H) $(TARGET)

# Objetivos phony
.PHONY: all clean