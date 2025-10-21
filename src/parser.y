%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int yylex(void);
int yyparse(void);

#define MAX_ACCIONES 128
#define MAX_COMBOS 128
#define MAX_LUCHADORES 128
#define MAX_COMANDOS_TURNO 128

/*definicion de tipos de datos a utilizar*/
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

typedef struct Comando {
    tipo_comando tipo;
    char *accion_nombre;
    Condicion condicional;
    struct Lista_comandos *lista_si;
    struct Lista_comandos *lista_sino;
} Comando;

typedef struct Lista_comandos {
    Comando comandos[MAX_COMANDOS_TURNO];
    int contador_comandos;
} Lista_comandos;

typedef struct luchador_en_ejecucion {
    Luchador *def;
    int hp;
    int st;
} luchador_en_ejecucion;


/*definicion de variables*/
Luchador roster[MAX_LUCHADORES];
int roster_cantidad;
Luchador estadisticas_actuales; 
Accion accion_actual[32];
int contador_acciones;
Combo combo_actual[32];
int contador_combos;
char config_luchador1[64];
char config_luchador2[64];
char config_inicial[64];
int turnos;
Lista_comandos* logica_turnos[MAX_COMANDOS_TURNO];
char* logica_turnos_nombres[MAX_COMANDOS_TURNO];
int logica_turnos_contador = 0;
int danio_momento = 0;
int costo_momento = 0;
char *altura_momento = NULL;
char *forma_momento = NULL;
char *giratoria_momento = NULL;
char *combo_momento[32];
int largo_combo_momento = 0;

/*declaracion de funciones a utilizar*/
Accion *buscar_accion(Luchador *l, const char *nombre);
Combo *buscar_combo(Luchador *l, const char *nombre);
void imprimir_roster(void);
void correr_simulacion(void);
void agregar_luchador(char *nombre, Luchador stats, Accion acciones[], Combo combos[]);
void ejecutar_accion_combo(char *nombre, luchador_en_ejecucion *attacker, luchador_en_ejecucion *defender);
int evaluar_condicion(Condicion *condicional, luchador_en_ejecucion *attacker, luchador_en_ejecucion *defender);
void ejecutar_comandos(Lista_comandos *lista, luchador_en_ejecucion *attacker, luchador_en_ejecucion *defender);

/*funcion que pide parser par ejecutar*/
void yyerror(const char *s) {
}

%}
/**/
%union {
    int valor_entero;
    char *valor_char;
    struct Accion *accion;
    struct Condicion valor_condicion;
    struct Comando valor_comando;
    struct Lista_comandos *lista_valores_comandos;
}

/*definicion de los token a utilizar*/
%token <valor_char> variable
%token <valor_entero> numeros
%token LUCHADOR LUCHADORES STATS ACCIONES COMBOS SIMULACION CONFIG PELEA TURNO USA SI SINO INICIA TURNOS_MAX VS ST_REQ
%token DANIO COSTO ALTURA FORMA GIRATORIA HP ST SELF OPONENTE
%token ALTURA_VAL FORMA_VAL GIRA_VAL
%token LE GE EQ NEQ
%type <valor_condicion> base_condicion
%type <lista_valores_comandos> flujo_condicional
%type <valor_comando> definicion_condicional
%type <valor_char> definicion_quien definicion_hp_st definicion_compardador

/*inicio del programa*/
%start programa

%%
/*gramatica a utilizar por el programa*/
programa:
    roster_lista base_simulacion;

roster_lista:
    /*vacio*/
    | roster_lista definicion_luchador;

definicion_luchador:
    LUCHADOR variable '{' base_estadisticas base_accion base_combos '}'
    {agregar_luchador($2, estadisticas_actuales, accion_actual, combo_actual);};

base_estadisticas:
    STATS '(' flujo_hp_st ')' ';';

flujo_hp_st:
    declaracion_hp_st
    | flujo_hp_st ',' declaracion_hp_st;

declaracion_hp_st:
    HP '=' numeros
    {estadisticas_actuales.hp_max = $3;}
    | ST '=' numeros
    {estadisticas_actuales.st_max = $3;};

base_accion:
    ACCIONES '{' flujo_conjunto_acciones '}';

flujo_conjunto_acciones:
    /*vacio*/
    | flujo_conjunto_acciones declaracion_acciones;

declaracion_acciones:
    variable ':' flujo_accion ';';

flujo_accion:
    definicion_accion
    | flujo_accion ',' definicion_accion;

definicion_accion:
    variable '(' flujo_datos_accion ')'  {
        Accion a = {0};
        a.nombre = strdup($1);
        a.danio = danio_momento;
        a.costo = costo_momento;
        a.altura = altura_momento ? strdup(altura_momento) : NULL;
        a.forma = forma_momento ?
        strdup(forma_momento) : NULL;
        a.giratoria = giratoria_momento ? strdup(giratoria_momento) : NULL;
        accion_actual[contador_acciones++] = a;
        danio_momento = 0;
        costo_momento = 0;
        altura_momento = NULL;
        forma_momento = NULL;
        giratoria_momento = NULL;}
    | variable  {
        Accion a = {0};
        a.nombre = strdup($1);
        danio_momento = 0;
        costo_momento = 0;
        altura_momento = NULL;
        forma_momento = NULL;
        giratoria_momento = NULL;
        accion_actual[contador_acciones++] = a;};

flujo_datos_accion:
    definicion_datos_accion
    | flujo_datos_accion ',' definicion_datos_accion;

definicion_datos_accion:
    DANIO '=' numeros { danio_momento = $3;}
    | COSTO '=' numeros { costo_momento = $3; }
    | ALTURA '=' variable { if (altura_momento) free(altura_momento); altura_momento = strdup($3); }
    | FORMA '=' variable { if (forma_momento) free(forma_momento); forma_momento = strdup($3); }
    | GIRATORIA '=' variable { if (giratoria_momento) free(giratoria_momento); giratoria_momento = strdup($3); }
    | GIRATORIA '=' SI { if (giratoria_momento) free(giratoria_momento); giratoria_momento = strdup("si"); };

base_combos:
    /*vacio*/
    | COMBOS '{' flujo_combo '}';

flujo_combo:
    /*vacio*/
    | flujo_combo definicion_combo;

definicion_combo:
    variable '(' ST_REQ '=' numeros ')' '{' definicion_datos_combo '}'
    {
        Combo c = {0};
        c.nombre = strdup($1);
        c.st_req = $5;
        for (int i = 0; i < largo_combo_momento; ++i) {
            c.seq[i] = strdup(combo_momento[i]);}
        c.seq_len = largo_combo_momento;
        combo_actual[contador_combos++] = c;
        largo_combo_momento = 0;
        };

definicion_datos_combo:
    variable { combo_momento[largo_combo_momento++] = $1; }
    | definicion_datos_combo ',' variable { combo_momento[largo_combo_momento++] = $3; };

base_simulacion:
    SIMULACION '{' CONFIG '{' definicion_config '}' PELEA '{' flujo_turno '}' '}';

definicion_config:
    LUCHADORES ':' variable VS variable ';' INICIA ':' variable ';' TURNOS_MAX ':' numeros ';'
    {
        strcpy(config_luchador1, $3);
        strcpy(config_luchador2, $5);
        strcpy(config_inicial, $9);
        turnos = $13;};

flujo_turno:
    /*vacio*/
    | flujo_turno TURNO variable '{' flujo_condicional '}'
    {
        if (logica_turnos_contador < MAX_COMANDOS_TURNO) {
            logica_turnos_nombres[logica_turnos_contador] = $3;
            logica_turnos[logica_turnos_contador] = $5;
            logica_turnos_contador++;
        } else {
            free($5);
        }
    };

flujo_condicional:
    /*vacio*/
    {
        $$ = (Lista_comandos*)calloc(1, sizeof(Lista_comandos));
    }
    | flujo_condicional definicion_condicional
    {
        $$ = $1;
        if ($$ && $$->contador_comandos < MAX_COMANDOS_TURNO) {
            $$->comandos[$$->contador_comandos++] = $2;
        }
    };

definicion_condicional:
    USA variable ';' 
    { 
        $$.tipo = comando_usa;
        $$.accion_nombre = $2;
        $$.lista_si = NULL;
        $$.lista_sino = NULL;
    }
    | SI '(' base_condicion ')' '{' flujo_condicional '}' SINO '{' flujo_condicional '}' 
    { 
        $$.tipo = comando_sino;
        $$.condicional = $3;
        $$.lista_si = $6;
        $$.lista_sino = $10;
    }
    | SI '(' base_condicion ')' '{' flujo_condicional '}' 
    { 
        $$.tipo = comando_si;
        $$.condicional = $3;
        $$.lista_si = $6;
        $$.lista_sino = NULL;
    };

base_condicion:
    definicion_quien '.' definicion_hp_st definicion_compardador numeros
    {
        $$.quien = $1;
        $$.stat = $3;
        $$.operando = $4;
        $$.valor = $5;
    };

definicion_quien: 
    SELF { $$ = "self"; } 
    | OPONENTE { $$ = "oponente"; };

definicion_hp_st: 
    HP { $$ = "hp"; } 
    | ST { $$ = "st"; };

definicion_compardador: 
    '<' { $$ = "<"; } 
    | '>' { $$ = ">"; } 
    | LE { $$ = "<="; } 
    | GE { $$ = ">="; } 
    | EQ { $$ = "=="; } 
    | NEQ { $$ = "!="; };

%%

void agregar_luchador(char *nombre, Luchador stats, Accion acciones[], Combo combos[]) {
    if (roster_cantidad >= MAX_LUCHADORES) return;
    Luchador *l = &roster[roster_cantidad++];
    l->nombre = strdup(nombre);
    l->hp_max = stats.hp_max;
    l->st_max = stats.st_max;
    l->acciones_count = contador_acciones;
    for (int i = 0; i < contador_acciones; ++i) {
        l->acciones[i] = accion_actual[i];
    }
    l->combos_count = contador_combos;
    for (int i = 0; i < contador_combos; ++i) {
        l->combos[i] = combo_actual[i];
    }
    for (int i = 0; i < l->combos_count; ++i) {
        Combo *c = &l->combos[i];
        for (int j = 0; j < c->seq_len; ++j) {
            const char *ref = c->seq[j];
            int found = 0;
            for (int a = 0; a < l->acciones_count; ++a) {
                if (l->acciones[a].nombre && ref && strcmp(l->acciones[a].nombre, ref) == 0) { found = 1;
 break; }
            }
            if (!found) {
                fprintf(stderr, "Alerta: el siguiente combo %s no se encuentra la accion %s en el luchador %s\n", c->nombre, ref, l->nombre);
            }
        }
    }
    contador_acciones = 0;
    contador_combos = 0;
}

void add_acciones_group(char *tipo, void *list) {
}

Accion *buscar_accion(Luchador *l, const char *nombre) {
    for (int i = 0; i < l->acciones_count; ++i) {
        if (strcmp(l->acciones[i].nombre, nombre) == 0) return &l->acciones[i];
    }
    return NULL;
}

Combo *buscar_combo(Luchador *l, const char *nombre) {
    for (int i = 0; i < l->combos_count; ++i) {
        if (strcmp(l->combos[i].nombre, nombre) == 0) return &l->combos[i];
    }
    return NULL;
}

static int busca_id_luchador(const char *name) {
    for (int i = 0; i < roster_cantidad; ++i) if (strcmp(roster[i].nombre, name) == 0) return i;
    return -1;
}

void imprimir_roster() {
    printf("roster tiene %d luchadores:\n", roster_cantidad);
    for (int i = 0; i < roster_cantidad; ++i) {
        Luchador *l = &roster[i];
        printf(" - %s (HP=%d ST=%d) Acciones=%d Combos=%d\n", l->nombre, l->hp_max, l->st_max, l->acciones_count, l->combos_count);
    }
}

void ejecutar_accion_combo(char *nombre, luchador_en_ejecucion *attacker, luchador_en_ejecucion *defender) {
    Combo *c = buscar_combo(attacker->def, nombre);
    if (c) {
        if (attacker->st >= c->st_req) {
            printf("%s usa COMBO %s (st_req=%d)\n", attacker->def->nombre, c->nombre, c->st_req);
            for (int i = 0; i < c->seq_len && defender->hp > 0; ++i) {
                Accion *a = buscar_accion(attacker->def, c->seq[i]);
                if (!a) { 
                    printf("Combo no encuentra accion %s\n", c->seq[i]); 
                    continue; 
                }
                
                int costo_actual = a->costo;
                if (attacker->st < costo_actual) {
                    printf("%s no tiene stamina para %s en combo\n", attacker->def->nombre, a->nombre);
                    break;
                }
                attacker->st -= costo_actual;
                defender->hp -= a->danio;
                if (defender->hp < 0) defender->hp = 0;
                printf("%s (d=%d,c=%d) -> %s HP=%d, %s ST=%d\n", a->nombre, a->danio, a->costo, defender->def->nombre, defender->hp, attacker->def->nombre, attacker->st);
            }
        } else {
            printf("%s intenta COMBO %s pero falla (req=%d, tiene=%d)\n", attacker->def->nombre, c->nombre, c->st_req, attacker->st);
            
            if (c->seq_len > 0) {
                char *primera_accion_nombre = c->seq[0];
                printf("Utiliza solo la primera accion: %s\n", primera_accion_nombre);
                Accion *a = buscar_accion(attacker->def, primera_accion_nombre);
                
                if (a) {
                    int costo_actual = a->costo;
                    
                    defender->hp -= a->danio;
                    if (defender->hp < 0) defender->hp = 0;
                    
                    if (attacker->st >= costo_actual) {
                        attacker->st -= costo_actual;
                    } else {
                        attacker->st = 0;
                    }

                    printf("%s usa ACCION (por insficiencia de st) %s (d=%d,c=%d) -> %s HP=%d, %s ST=%d\n", attacker->def->nombre, a->nombre, a->danio, a->costo, defender->def->nombre, defender->hp, attacker->def->nombre, attacker->st);

                } else {
                    printf("Error: La primera accion '%s' del combo no se encontro.\n", primera_accion_nombre);
                }
            } else {
                printf("Error: El combo %s esta vacio, no se puede aplicar primera accion.\n", c->nombre);
            }
        }
        return;
    }
    
    Accion *a = buscar_accion(attacker->def, nombre);
    if (a) {
        int costo_actual = a->costo;
        if (attacker->st >= costo_actual) {
            attacker->st -= costo_actual;
            defender->hp -= a->danio;
            if (defender->hp < 0) defender->hp = 0;
            printf("%s usa ACCION %s (d=%d,c=%d) -> %s HP=%d, %s ST=%d\n", attacker->def->nombre, a->nombre, a->danio, a->costo, defender->def->nombre, defender->hp, attacker->def->nombre, attacker->st);
        } else {
            printf("%s intenta %s, pero no tiene stamina (req=%d, tiene=%d)\n", attacker->def->nombre, a->nombre, a->costo, attacker->st);
        }
        return;
    }
    
    fprintf(stderr, "Error: %s intento usar accion/combo desconocido '%s'\n", attacker->def->nombre, nombre);
}

int evaluar_condicion(Condicion *condicional, luchador_en_ejecucion *attacker, luchador_en_ejecucion *defender) {
    luchador_en_ejecucion *target = (strcmp(condicional->quien, "self") == 0) ? attacker : defender;
    int valor_stat = (strcmp(condicional->stat, "hp") == 0) ? target->hp : target->st;
    int valor_comparar = condicional->valor;
    if (strcmp(condicional->operando, "<") == 0) return valor_stat < valor_comparar;
    if (strcmp(condicional->operando, ">") == 0) return valor_stat > valor_comparar;
    if (strcmp(condicional->operando, "<=") == 0) return valor_stat <= valor_comparar;
    if (strcmp(condicional->operando, ">=") == 0) return valor_stat >= valor_comparar;
    if (strcmp(condicional->operando, "==") == 0) return valor_stat == valor_comparar;
    if (strcmp(condicional->operando, "!=") == 0) return valor_stat != valor_comparar;
    return 0;
}

void ejecutar_comandos(Lista_comandos *lista, luchador_en_ejecucion *attacker, luchador_en_ejecucion *defender) {
    if (!lista) return;
    for (int i = 0; i < lista->contador_comandos; i++) {
        if (attacker->hp <= 0 || defender->hp <= 0) return;
        switch (lista->comandos[i].tipo) {
            case comando_usa:
                ejecutar_accion_combo(lista->comandos[i].accion_nombre, attacker, defender);
                break;
            case comando_si:
                if (evaluar_condicion(&lista->comandos[i].condicional, attacker, defender)) {
                    ejecutar_comandos(lista->comandos[i].lista_si, attacker, defender);
                }
                break;
            case comando_sino:
                if (evaluar_condicion(&lista->comandos[i].condicional, attacker, defender)) {
                    ejecutar_comandos(lista->comandos[i].lista_si, attacker, defender);
                } else {
                    ejecutar_comandos(lista->comandos[i].lista_sino, attacker, defender);
                }
                break;
        }
    }
}


void correr_simulacion() {
    printf("Configuracion de la simulacion: %s vs %s, inicia=%s, turnos_max=%d\n", config_luchador1, config_luchador2, config_inicial, turnos);
    int idx1 = busca_id_luchador(config_luchador1);
    int idx2 = busca_id_luchador(config_luchador2);
    if (idx1 < 0 || idx2 < 0) { printf("Error: luchadores no encontrados\n");
        return; }
    luchador_en_ejecucion r1 = { &roster[idx1], roster[idx1].hp_max, roster[idx1].st_max };
    luchador_en_ejecucion r2 = { &roster[idx2], roster[idx2].hp_max, roster[idx2].st_max };
    luchador_en_ejecucion *attacker = strcmp(config_inicial, r1.def->nombre) == 0 ? &r1 : &r2;
    luchador_en_ejecucion *defender = attacker == &r1 ? &r2 : &r1;
    int turno_actual = 0;
    while (turno_actual < turnos && r1.hp > 0 && r2.hp > 0) {
        printf("--- Turno %d: %s (HP %d ST %d) vs %s (HP %d ST %d)\n", 
               turno_actual + 1, 
               attacker->def->nombre, attacker->hp, attacker->st, 
               defender->def->nombre, defender->hp, defender->st);
        Lista_comandos *lista_comandos_turno = NULL;
        for (int i = 0; i < logica_turnos_contador; i++) {
            if (strcmp(logica_turnos_nombres[i], attacker->def->nombre) == 0) {
                lista_comandos_turno = logica_turnos[i];
                break;
            }
        }

        if (lista_comandos_turno) {
            ejecutar_comandos(lista_comandos_turno, attacker, defender);
        } else {
            printf("%s no tiene logica de turno definida. Pasa el turno.\n", attacker->def->nombre);
        }
        
        if (defender->hp <= 0) {
            break;
        }
        luchador_en_ejecucion *tmp = attacker; 
        attacker = defender; 
        defender = tmp;
        turno_actual++;
    }
    printf("--- Fin de la Simulacion ---\n");
    if (r1.hp <= 0) {
        printf("GANADOR: %s (HP=%d)\n", r2.def->nombre, r2.hp);
        printf("PERDEDOR: %s (HP=%d)\n", r1.def->nombre, r1.hp);
    } else if (r2.hp <= 0) {
        printf("GANADOR: %s (HP=%d)\n", r1.def->nombre, r1.hp);
        printf("PERDEDOR: %s (HP=%d)\n", r2.def->nombre, r2.hp);
    } else {
        printf("SE ACABO EL TIEMPO (Turno %d)\n", turno_actual);
        printf("Resultado: %s HP=%d, %s HP=%d\n", r1.def->nombre, r1.hp, r2.def->nombre, r2.hp);
    }
}