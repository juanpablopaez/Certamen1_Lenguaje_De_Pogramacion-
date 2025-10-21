#ifndef TYPES_H
#define TYPES_H

#include <stdlib.h>

#define MAX_ACCIONES 128
#define MAX_COMBOS 128
#define MAX_LUCHADORES 128
#define MAX_COMANDOS_TURNO 128

typedef struct Accion {
    char *nombre;
    int danio;
    int costo;
    char *altura;
    char *forma;
    char *giratoria;
} Accion;

typedef struct Combo {
    char *nombre;
    int st_req;
    char *seq[32];
    int seq_len;
} Combo;

typedef struct Luchador {
    char *nombre;
    int hp_max;
    int st_max;
    Accion acciones[MAX_ACCIONES];
    int acciones_count;
    Combo combos[MAX_COMBOS];
    int combos_count;
} Luchador;

typedef enum {
    comando_usa,
    comando_si,
    comando_sino
} tipo_comando;

typedef struct Condicion {
    char *quien;
    char *stat;
    char *operando;
    int valor;
} Condicion;

typedef struct Lista_comandos Lista_comandos; /* forward */

typedef struct Comando {
    tipo_comando tipo;
    char *accion_nombre;
    Condicion condicional;
    struct Lista_comandos *lista_si;
    struct Lista_comandos *lista_sino;
} Comando;

struct Lista_comandos {
    Comando comandos[MAX_COMANDOS_TURNO];
    int contador_comandos;
};

typedef struct luchador_en_ejecucion {
    Luchador *def;
    int hp;
    int st;
} luchador_en_ejecucion;

#endif /* TYPES_H */
