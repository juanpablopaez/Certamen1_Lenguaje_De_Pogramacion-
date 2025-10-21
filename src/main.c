#include <stdio.h>
#include <stdlib.h>

extern FILE *yyin;
int yyparse(void);
void imprimir_roster(void);
void correr_simulacion(void);

int main(int argc, char **argv) {
    if (argc < 2) {
        fprintf(stderr, "Usage: %s <input.file>\n", argv[0]);
        return 1;
    }
    yyin = fopen(argv[1], "r");
    if (yyparse() == 0) {
        imprimir_roster();
        correr_simulacion();
    }
    return 0;
}