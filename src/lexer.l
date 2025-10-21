%option noyywrap
%{
#include "parser.h"
#include <string.h>
#include <stdlib.h>

static char *recuperar_token(const char *identificador_base) {
    char *almacena_token = malloc(strlen(identificador_base)+1);
    strcpy(almacena_token, identificador_base);
    return almacena_token;
}

%}

numero     [0-9]+
ID         [A-Za-z_][A-Za-z0-9_áéíóúñÁÉÍÓÚÑ]*
%%
[ \t\r\n]+                  ;
"//".*                       ;
"/*"([^*]|\*+[^*/])*"*/"   ;
"luchador"                   { return LUCHADOR; }
"stats"                      { return STATS; }
"acciones"                  { return ACCIONES; }
"combos"                    { return COMBOS; }
"simulacion"                { return SIMULACION; }
"config"                    { return CONFIG; }
"pelea"                     { return PELEA; }
"turno"                     { return TURNO; }
"usa"                       { return USA; }
"si"                        { return SI; }
"sino"                      { return SINO; }
"inicia"                    { return INICIA; }
"turnos_max"                { return TURNOS_MAX; }
"vs"                        { return VS; }
"luchadores"                { return LUCHADORES; }
"st_req"                    { return ST_REQ; }
"daño"                      { return DANIO; }
"danio"                     { return DANIO; }
"costo"                     { return COSTO; }
"altura"                    { return ALTURA; }
"forma"                     { return FORMA; }
"giratoria"                 { return GIRATORIA; }
"hp"                        { return HP; }
"st"                        { return ST; }
"self"                      { return SELF; }
"oponente"                  { return OPONENTE; }
"alta"                      { yylval.valor_char = recuperar_token("alta"); return variable; }
"media"                     { yylval.valor_char = recuperar_token("media"); return variable; }
"baja"                      { yylval.valor_char = recuperar_token("baja"); return variable; }
"frontal"                   { yylval.valor_char = recuperar_token("frontal"); return variable; }
"lateral"                   { yylval.valor_char = recuperar_token("lateral"); return variable; }
"no"                        { yylval.valor_char = recuperar_token("no"); return variable; }
"yes"                       { yylval.valor_char = recuperar_token("yes"); return variable; }
"=="                        { return EQ; }
"!="                        { return NEQ; }
"<="                        { return LE; }
">="                        { return GE; }
"("                         { return '('; }
")"                         { return ')'; }
"{"                         { return '{'; }
"}"                         { return '}'; }
":"                         { return ':'; }
","                         { return ','; }
";"                         { return ';'; }
"="                         { return '='; }
"\."                       { return '.'; }
"<"                         { return '<'; }
">"                         { return '>'; }
{numero}                     { yylval.valor_entero = atoi(yytext);  return numeros; }
{ID}                         { yylval.valor_char = recuperar_token(yytext); return variable; }
.                            {  }
%%