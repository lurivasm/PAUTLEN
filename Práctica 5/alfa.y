
%{
#include <stdio.h>
#include <string.h>
#include "alfa.h"
#include "generacion.h"
#include "tabla_simbolos.h"

extern FILE* yyout;
extern int yylex();
extern size_t nlines;
void yyerror(const char *s);
tablas_smb *tabla;

<<<<<<< HEAD
int num_total_parametros = 0;   /* Numero de parametros para declarar una funcion */
int num_total_varlocs = 0;      /* Numero de variables locales, por ej, dentro de una funcion */
int tamanio = 1;                /* Para controlar el tamaño del identificador */
int tipo;                       /* Para darle un tipo entero o booleano a un identificador */
int funcion_retorno = 0;        /* Comprueba que hay un return en la funcion */
=======
int num_total_parametros = 0;
int categoria_estructura = 0;
int tamanio = 1; /* Para controlar el tamaño del identificador */
int tipo;        /* Para darle un tipo entero o booleano a un identificador */
int funcion_retorno = 0; /* Comprueba que hay un return en la funcion */
>>>>>>> 08f14aaf417776767173a0ad3d780f3a3534ea05
int etiqueta = 0;
%}

%union {
  tipo_atributos atributos;
}

%token <atributos> TOK_IDENTIFICADOR
%token <atributos> TOK_CONSTANTE_ENTERA

%token TOK_MAIN
%token TOK_INT
%token TOK_BOOLEAN
%token TOK_ARRAY
%token TOK_FUNCTION
%token TOK_IF
%token TOK_ELSE
%token TOK_WHILE
%token TOK_SCANF
%token TOK_PRINTF
%token TOK_RETURN

%token TOK_PUNTOYCOMA
%token TOK_COMA
%token TOK_PARENTESISIZQUIERDO
%token TOK_PARENTESISDERECHO
%token TOK_CORCHETEIZQUIERDO
%token TOK_CORCHETEDERECHO
%token TOK_LLAVEIZQUIERDA
%token TOK_LLAVEDERECHA
%token TOK_ASIGNACION
%token TOK_MAS
%token TOK_MENOS
%token TOK_DIVISION
%token TOK_ASTERISCO
%token TOK_AND
%token TOK_OR
%token TOK_NOT
%token TOK_IGUAL
%token TOK_DISTINTO
%token TOK_MENORIGUAL
%token TOK_MAYORIGUAL
%token TOK_MENOR
%token TOK_MAYOR

%token TOK_TRUE
%token TOK_FALSE

%token TOK_ERROR

%type <atributos> constante
%type <atributos> constante_logica
%type <atributos> constante_entera
%type <atributos> identificador
%type <atributos> comparacion
%type <atributos> exp
%type <atributos> condicional
%type <atributos> bucle
%type <atributos> elemento_vector
%type <atributos> funcion




%left TOK_IGUAL TOK_MENORIGUAL  TOK_MENOR TOK_MAYORIGUAL TOK_MAYOR TOK_DISTINTO
%left TOK_AND TOK_OR
%left TOK_MAS TOK_MENOS
%left TOK_ASTERISCO TOK_DIVISION
%right TOK_NOT
%%

programa                  :   TOK_MAIN inicio TOK_LLAVEIZQUIERDA declaraciones funciones sentencias TOK_LLAVEDERECHA
                              {fprintf(yyout,";R1:\t<programa> ::= main { <declaraciones> <funciones> <sentencias> }\n");
                               escribir_fin(out);
                               LiberarTablas(tabla);}
                          ;
inicio:                   :  {  tabla = CrearTablas();
                                if(tabla == NULL){
                                  print("No existe la tabla de símbolos\n");
                                  return -1;
                                }
                                escribir_subseccion_data(yyout);
                                escribir_cabecera_bss(yyout);}
                          ;
declaraciones             :   declaracion
                              {fprintf(yyout,";R2:\t<declaraciones> ::= <declaracion>\n");}
                          |   declaracion declaraciones
                              {fprintf(yyout,";R3:\t<declaraciones> ::= <declaracion> <declaraciones>\n");}
                          ;
declaracion               :   clase identificadores TOK_PUNTOYCOMA
                              {fprintf(yyout,";R4:\t<declaracion> ::= <clase> <identificadores> ;\n");}
                          ;
clase                     :   clase_escalar
                              {fprintf(yyout,";R5:\t<clase> ::= <clase_escalar>\n");
                               categoria_estructura = ESCALAR;}
                          |   clase_vector
                              {fprintf(yyout,";R7:\t<clase> ::= <clase_vector>\n");
                               categoria_estructura = VECTOR;}
                          ;
clase_escalar             :   tipo
                              {fprintf(yyout,";R9:\t<clase_escalar> ::= <tipo>\n");
                               tamanio = 1;}
                          ;
tipo                      :   TOK_INT
                              {fprintf(yyout,";R10:\t<tipo> ::= int\n");
                               tipo = ENTERO;}
                          |   TOK_BOOLEAN
                              {fprintf(yyout,";R11:\t<tipo> ::= boolean\n");
                               tipo = BOOLEANO;}
                          ;
clase_vector              :   TOK_ARRAY tipo TOK_CORCHETEIZQUIERDO constante_entera TOK_CORCHETEDERECHO
                              {fprintf(yyout,";R15:\t<clase_vector> ::= array <tipo> [ <constante_entera> ]\n");
                              longitud = $4.valor_entero;
                              if(longitud <= 0 || longitud > MAX_TAMANIO_VECTOR){
                                printf("****Error semántico en lin %lu: El tamanyo del vector %s excede los limites permitidos (1,64).\n", nlines, $1.lexema);
                                LiberarTablas(tabla);
                                return -1;
                              }}
                          ;
identificadores           :   identificador
                              {fprintf(yyout,";R18:\t<identificadores> ::= <identificador>\n");}
                          |   identificador TOK_COMA identificadores
                              {fprintf(yyout,";R19:\t<identificadores> ::= <identificador> , <identificadores>\n");}
                          ;
funciones                 :   funcion funciones
                              {fprintf(yyout,";R20:\t<funciones> ::= <funcion> <funciones>\n");}
                          |   %empty
                              {fprintf(yyout,";R21:\t<funciones> ::= \n");}
                          ;
funcion                   :   fn_declaration sentencias TOK_LLAVEDERECHA
                              {fprintf(yyout,";R22:\t<funcion> ::= function <tipo> <identificador> ( <parametros_funcion> ) { <declaraciones_funcion> <sentencias> }\n");
                              if (funcion_retorno < 1){
                                print("***Error semántico en lin %lu : Funcion %s sin sentencia return\n", nlines, $1.lexema);
                                LiberarTablas(tabla);
                                return -1;
                              }
                              simbolo *simbolo;
                              simbolo = BusquedaElemento(tabla, $1.lexema);
                              if (simbolo == NULL){
                                printf("***Error en la tabla de simbolos\n");
                                LiberarTablas(tabla);
                                return -1;
                              }
                              simbolo->n_parametros = num_total_parametros;
                              num_total_parametros = 0;
                              }
                          ;
fn_declaration            :   fn_name TOK_PARENTESISIZQUIERDO parametros_funcion TOK_PARENTESISIZQUIERDO TOK_CORCHETEIZQUIERDO declaraciones_funcion
                              {
                               simbolo *simbolo;
                               simbolo = BusquedaElemento(tabla, $1.lexema);
                               if (simbolo == NULL){
                                 printf("***Error en la tabla de simbolos\n");
                                 LiberarTablas(tabla);
                                 return -1;
                               }
                               simbolo->n_parametros = num_total_parametros;
                               simbolo->n_varloc = num_total_varlocs;
                               strcpy($$.lexema, $1.lexema);
                               declararFuncion(yyout, $1.lexema, num_total_varlocs);
                              }
                          ;
fn_name                   :   TOK_FUNCTION tipo TOK_IDENTIFICADOR
                              {
                                /* La funcion no existia y la metemos en tabla simbolos */
                                if (BusquedaElemento(tabla, $3.lexema) == NULL){
                                  simbolo *simbolo;
                                  //TODO

                                }
                                /* La funcion ya existe */
                                else{
                                  printf("***Error semantico en lin %lu: Declaracion duplicada\n");
                                  LiberarTablas(tablas);
                                  return -1;
                                }
                              }
                          ;
parametros_funcion        :   parametro_funcion resto_parametros_funcion
                              {fprintf(yyout,";R23:\t<parametros_funcion> ::= <parametro_funcion> <resto_parametros_funcion>\n");}
                          |   %empty
                              {fprintf(yyout,";R24:\t<parametros_funcion> ::= \n");}
                          ;
resto_parametros_funcion  :   TOK_PUNTOYCOMA parametro_funcion resto_parametros_funcion
                              {fprintf(yyout,";R25:\t<resto_parametros_funcion> ::= ; <parametro_funcion> <resto_parametros_funcion>\n");}
                          |   %empty
                              {fprintf(yyout,";R26:\t<resto_parametros_funcion> ::= \n");}
                          ;
parametro_funcion         :   tipo idpf
                              {fprintf(yyout,";R27:\t<parametro_funcion> ::= <tipo> <identificador>\n");
                               num_total_parametros++;
                               posicion_parametro++;}
                          ;
idpf                      :   TOK_IDENTIFICADOR
                              {
                               //TODO
                              }
declaraciones_funcion     :   declaraciones
                              {fprintf(yyout,";R28:\t<declaraciones_funcion> ::= <declaraciones>\n");}
                          |   %empty
                              {fprintf(yyout,";R29:\t<declaraciones_funcion> ::= \n");}
                          ;
sentencias                :   sentencia
                              {fprintf(yyout,";R30:\t<sentencias> ::= <sentencia>\n");}
                          |   sentencia sentencias
                              {fprintf(yyout,";R31:\t<sentencias> ::= <sentencia> <sentencias>\n");}
                          ;
sentencia                 :   sentencia_simple TOK_PUNTOYCOMA
                              {fprintf(yyout,";R32:\t<sentencia> ::= <sentencia_simple> ;\n");}
                          |   bloque
                              {fprintf(yyout,";R33:\t<sentencia> ::= <bloque>\n");}
                          ;
sentencia_simple          :   asignacion
                              {fprintf(yyout,";R34:\t<sentencia_simple> ::= <asignacion>\n");}
                          |   lectura
                              {fprintf(yyout,";R35:\t<sentencia_simple> ::= <lectura>\n");}
                          |   escritura
                              {fprintf(yyout,";R36:\t<sentencia_simple> ::= <escritura>\n");}
                          |   retorno_funcion
                              {fprintf(yyout,";R38:\t<sentencia_simple> ::= <retorno_funcion>\n");}
                          ;
bloque                    :   condicional
                              {fprintf(yyout,";R40:\t<bloque> ::= <condicional>\n");}
                          |   bucle
                              {fprintf(yyout,";R41:\t<bloque> ::= <bucle>\n");}
                          ;
asignacion                :   TOK_IDENTIFICADOR TOK_ASIGNACION exp
                              {
                                fprintf(yyout,";R43:\t<asignacion> ::= <identificador> = <exp>\n");
                                simbolo *simbolo;
                                if((simbolo = BusquedaElemento(tabla, $1.lexema)) == NULL){
                                  printf("****Error semántico en lin %lu: Acceso a variable no declarada (%s)\n", nlines, $1.lexema);
                                  LiberarTablas(tabla);
                                  return -1;
                                }
                                if (simbolo->categoria_estructura == VECTOR) {
                                  printf("****Error semantico en lin %lu: Asignacion incompatible. \n", nlines);
                                  LiberarTablas(tabla);
                                  return -1;
                                }
                                if (simbolo->categoria == FUNCION) {
                                  printf("****Error semantico en lin %lu: Asignacion incompatible. \n", nlines);
                                  LiberarTablas(tabla);
                                  return -1;
                                }

                                if (simbolo->tipo != $3.tipo) {
                                  printf("****Error semantico en lin %lu: Asignacion incompatible. \n", nlines);
                                  LiberarTablas(tabla);
                                  return -1;
                                }
                                // TODO funcion ambito
                                if(Ambito(tabla) == GLOBAL){
                                  asignar(yyout, $1.lexema, $3.es_direccion);
                                }else{
                                  escribirVariableLocal(out,simbolo->posicion);
                                  asignarDestinoEnPila(out,$3.es_direccion);
                                }
                              }
                          |   elemento_vector TOK_ASIGNACION exp
                              {
                                fprintf(yyout,";R44:\t<asignacion> ::= <elemento_vector> = <exp>\n");
                                simbolo *simbolo;
                                if((simbolo = BusquedaElemento(tabla, $1.lexema)) == NULL){
                                  printf("****Error semántico en lin %lu: Acceso a variable no declarada (%s)\n", nlines, $1.lexema);
                                  LiberarTablas(tabla);
                                  return -1;
                                }
                                if ($1.tipo != $3.tipo) {
                                  printf("****Error semantico en lin %lu: Asignacion incompatible. \n", nlines);
                                  LiberarTablas(tabla);
                                  return -1;
                                }
                                char v[MAX_TAM_ENTERO];
                                sprintf(v,"%d",$1.valor_entero);
                                escribir_operando(yyout,v,0);
                                escribir_elemento_vector(yyout,$1.lexema,simbolo->longitud,$3.es_direccion);
                                asignarDestinoEnPila(yyout,$3.es_direccion);
                              }
                          ;
elemento_vector           :   identificador TOK_CORCHETEIZQUIERDO exp TOK_CORCHETEDERECHO
                              {fprintf(yyout,";R48:\t<elemento_vector> ::= <identificador> [ <exp> ]\n");
                              simbolo *simbolo;
                              if ((simbolo = BusquedaElemento(tabla, $1.lexema)) == NULL){
                                printf("****Error semántico en lin %lu: Acceso a variable no declarada (%s)\n", nlines, $1.lexema);
                                LiberarTablas(tabla);
                                return -1;
                              }
                              if (simbolo->categoria_estructura != VECTOR) {
                                printf("****Error semántico en lin %lu: Intento de indexacion que no es de tipo vector \n", nlines);
                                LiberarTablas(tabla);
                                return -1;
                              }
                              if ($3.tipo != ENTERO) {
                                printf("****Error semántico en lin %lu: El indice en una operacion de indexacion tiene que ser de tipo entero.\n", nlines);
                                LiberarTablas(tabla);
                                return -1;
                              }
                              $$.tipo = simbolo->tipo;
                              $$.es_direccion = 1;
                              $$.valor_entero = $3.valor_entero;
                              //TODO USAR AQUI EL Escribir elemento vector
                              }
                          ;
condicional               :   if_exp TOK_PARENTESISDERECHO TOK_LLAVEIZQUIERDA sentencias TOK_LLAVEDERECHA
                              {fprintf(yyout,";R50:\t<condicional> ::= if ( <exp> ) { <sentencias> }\n");
                              ifthen_fin(out, $1.etiqueta);
                              }
                          |   if_else_exp TOK_ELSE TOK_LLAVEIZQUIERDA sentencias TOK_LLAVEDERECHA
                              {fprintf(yyout,";R51:\t<condicional> ::= if ( <exp> ) { <sentencias> } else { <sentencias> }\n");
                              ifthenelse_fin(out, $1.etiqueta);
                              }
                          ;
if_exp                    :   TOK_IF TOK_PARENTESISIZQUIERDO exp
                              {
                              if ($3.tipo != BOOLEANO) {
                                printf("****Error semántico en lin %lu: Condicional con condicion tipo int.\n", nlines);
                                LiberarTablas(tabla);
                                return -1;
                              }
                              $$.etiqueta = etiqueta++;
                              ifthen_inicio(yyout, $3.es_direccion, $$.etiqueta);
                              }
                          ;
if_else_exp               :   if_exp TOK_PARENTESISDERECHO TOK_LLAVEIZQUIERDA sentencias TOK_LLAVEDERECHA
                              {
                              $$.etiqueta = $1.etiqueta;
                              ifthenelse_fin_then(out, $$etiqueta);
                              }
                          ;
bucle                     :   while_exp TOK_LLAVEIZQUIERDA sentencias TOK_LLAVEDERECHA
                              {fprintf(yyout,";R52:\t<bucle> ::= while ( <exp> ) { <sentencias> }\n");
                              while_fin(out, $1.etiqueta);
                              }
                          ;
while_exp                 :   while TOK_PARENTESISIZQUIERDO exp TOK_PARENTESISDERECHO
                              {
                              if ($3.tipo != BOOLEANO) {
                                printf("****Error semántico en lin %lu: Condicional con condicion tipo int.\n", nlines);
                                LiberarTablas(tabla);
                                return -1;
                              }

                              $$.etiqueta =$1.etiqueta;
                              while_exp_pila(out, $2.es_direccion, $$.etiqueta)
                              }
                          ;
while_exp                 :   TOK_WHILE
                              {
                              $$.etiqueta = etiqueta++;
                              while_inicio(out, $$.etiqueta);
                              }
                          ;
lectura                   :   TOK_SCANF identificador
                              {fprintf(yyout,";R54:\t<lectura> ::= scanf <identificador>\n");
                               simbolo *simbolo;
                               simbolo = BusquedaElemento(tabla, $2.lexema);

                               if (simbolo == NULL){
                                printf("***Error semantico en lin %lu: Acceso a variable no declarada (%s)", nlines, $2.lexema);
                                LiberarTablas(tabla);
                                return -1;
                               }

                               }
                          ;
escritura                 :   TOK_PRINTF exp
                              {fprintf(yyout,";R56:\t<escritura> ::= printf <exp>\n");}
                          ;
retorno_funcion           :   TOK_RETURN exp
                              {fprintf(yyout,";R61:\t<retorno_funcion> ::= return <exp>\n");}
                          ;
exp                       :   exp TOK_MAS exp
                              {fprintf(yyout,";R72:\t<exp> ::= <exp> + <exp>\n");}
                          |   exp TOK_MENOS exp
                              {fprintf(yyout,";R73:\t<exp> ::= <exp> - <exp>\n");}
                          |   exp TOK_DIVISION exp
                              {fprintf(yyout,";R74:\t<exp> ::= <exp> / <exp>\n");}
                          |   exp TOK_ASTERISCO exp
                              {fprintf(yyout,";R75:\t<exp> ::= <exp> * <exp>\n");}
                          |   TOK_MENOS exp
                              {fprintf(yyout,";R76:\t<exp> ::= - <exp>\n");}
                          |   exp TOK_AND exp
                              {
                                fprintf(yyout,";R77:\t<exp> ::= exp> && <exp>\n");
                                if(($1.tipo != BOOLEANO) || ($3.tipo != BOOLEANO)){
                                  printf("****Error semantico en lin %lu: Operacion logica con operandos int.",nlines);
                                  LiberarTablas(tabla);
                                  return -1;
                                }
                                y(yyout, $1.es_direccion, $2.es_direccion);
                                $$.tipo = BOOLEANO;
                                $$.es_direccion = 0;
                              }
                          |   exp TOK_OR exp
                              {
                                fprintf(yyout,";R78:\t<exp> ::= <exp> || <exp>\n");
                                if(($1.tipo == ENTERO) || ($3.tipo == ENTERO)){
                                  printf("****Error semantico en lin %lu: Operacion logica con operandos int.",nlines);
                                  LiberarTablas(tabla);
                                  return -1;
                                }
                                o(yyout, $1.es_direccion, $2.es_direccion);
                                $$.tipo = BOOLEANO;
                                $$.es_direccion = 0;
                              }
                          |   TOK_NOT exp
                              {
                                fprintf(yyout,";R79:\t<exp> ::= ! <exp>\n");
                                if($2.tipo == ENTERO){
                                  printf("****Error semantico en lin %lu: Operacion logica con operandos int.",nlines);
                                  LiberarTablas(tabla);
                                  return -1;
                                }
                                no(yyout, $1.es_direccion, etiqueta);
                                etiqueta++;
                                $$.tipo = BOOLEANO;
                                $$.es_direccion = 0;
                              }
                          |   TOK_IDENTIFICADOR
                              {fprintf(yyout,";R80:\t<exp> ::= <identificador>\n");
                              simbolo *simbolo;
                              if ((simbolo = BusquedaElemento(tabla, $1.lexema)) == NULL){
                                printf("****Error semántico en lin %lu: Acceso a variable no declarada (%s)\n", nlines, $1.lexema);
                                LiberarTablas(tabla);
                                return -1;
                              }
                              if (simbolo->categoria == FUNCION || simbolo->categoria_estructura == VECTOR) {
                                printf("****Error semántico en lin %lu: Intento de indexacion que no es de tipo vector \n", nlines);
                                LiberarTablas(tabla);
                                return -1;
                              }
                              $$.tipo = simbolo->tipo;
                              $$.es_direccion = 1;
                              if (simbolo->categoria == PARAMETRO) {
                                escribirParametro(yyout, simbolo->posicion, num_total_parametros);
                              } else if (simbolo->categoria == VARIABLE) {
                              //TODO Si no es local?
                                escribirVariableLocal(yyout, simbolo->posicion_varloc);
                              }
                          |   constante
                              {fprintf(yyout,";R81:\t<exp> ::= <constante>\n");}
                          |   TOK_PARENTESISIZQUIERDO exp TOK_PARENTESISDERECHO
                              {fprintf(yyout,";R82:\t<exp> ::= ( <exp> )\n");}
                          |   TOK_PARENTESISIZQUIERDO comparacion TOK_PARENTESISDERECHO
                              {fprintf(yyout,";R83:\t<exp> ::= ( <comparacion> )\n");}
                          |   elemento_vector
                              {fprintf(yyout,";R85:\t<exp> ::= <elemento_vector>\n");}
                          |   identificador TOK_PARENTESISIZQUIERDO lista_expresiones TOK_PARENTESISDERECHO
                              {fprintf(yyout,";R88:\t<exp> ::= <identificador> ( <lista_expresiones> )\n");}
                          ;
lista_expresiones         :   exp resto_lista_expresiones
                              {fprintf(yyout,";R89:\t<lista_expresiones> ::= <exp> <resto_lista_expresiones>\n");}
                          |   %empty
                              {fprintf(yyout,";R90:\t<lista_expresiones> ::= \n");}
                          ;
resto_lista_expresiones   :   TOK_COMA exp resto_lista_expresiones
                              {fprintf(yyout,";R91:\t<resto_lista_expresiones> ::= , <exp> <resto_lista_expresiones>\n");}
                          |   %empty
                              {fprintf(yyout,";R92:\t<resto_lista_expresiones> ::= \n");}
                          ;
comparacion               :   exp TOK_IGUAL exp
                              {
                                fprintf(yyout,";R93:\t<comparacion> ::= <exp> == <exp>\n");
                                if(($1.tipo == BOOLEANO) || ($3.tipo == BOOLEANO)){
                                  printf("****Error semantico en lin %lu: Operacion aritmetica con operandos boolean.",nlines);
                                  LiberarTablas(tabla);
                                  return -1;
                                }
                                igual(yyout, $1.es_direccion, $3.es_direccion, etiqueta);
                                etiqueta++;
                                $$.tipo = BOOLEANO;
                                $$.es_direccion = 0;
                              }
                          |   exp TOK_DISTINTO exp
                              {
                                fprintf(yyout,";R94:\t<comparacion> ::= <exp> != <exp>\n");
                                if(($1.tipo == BOOLEANO) || ($3.tipo == BOOLEANO)){
                                  printf("****Error semantico en lin %lu: Operacion aritmetica con operandos boolean.",nlines);
                                  LiberarTablas(tabla);
                                  return -1;
                                }
                                distinto(yyout, $1.es_direccion, $3.es_direccion, etiqueta);
                                etiqueta++;
                                $$.tipo = BOOLEANO;
                                $$.es_direccion = 0;
                              }
                          |   exp TOK_MENORIGUAL exp
                              {
                                fprintf(yyout,";R95:\t<comparacion> ::= <exp> <= <exp>\n");
                                if(($1.tipo == BOOLEANO) || ($3.tipo == BOOLEANO)){
                                  printf("****Error semantico en lin %lu: Operacion aritmetica con operandos boolean.",nlines);
                                  LiberarTablas(tabla);
                                  return -1;
                                }
                                menor_igual(yyout, $1.es_direccion, $3.es_direccion, etiqueta);
                                etiqueta++;
                                $$.tipo = BOOLEANO;
                                $$.es_direccion = 0;
                              }
                          |   exp TOK_MAYORIGUAL exp
                              {
                                fprintf(yyout,";R96:\t<comparacion> ::= <exp> >= <exp>\n");
                                if(($1.tipo == BOOLEANO) || ($3.tipo == BOOLEANO)){
                                  printf("****Error semantico en lin %lu: Operacion aritmetica con operandos boolean.",nlines);
                                  LiberarTablas(tabla);
                                  return -1;
                                }
                                mayor_igual(yyout, $1.es_direccion, $3.es_direccion, etiqueta);
                                etiqueta++;
                                $$.tipo = BOOLEANO;
                                $$.es_direccion = 0;
                              }
                          |   exp TOK_MENOR exp
                              {
                                fprintf(yyout,";R97:\t<comparacion> ::= <exp> < <exp>\n");
                                if(($1.tipo == BOOLEANO) || ($3.tipo == BOOLEANO)){
                                  printf("****Error semantico en lin %lu: Operacion aritmetica con operandos boolean.",nlines);
                                  LiberarTablas(tabla);
                                  return -1;
                                }
                                menor(yyout, $1.es_direccion, $3.es_direccion, etiqueta);
                                etiqueta++;
                                $$.tipo = BOOLEANO;
                                $$.es_direccion = 0;
                              }
                          |   exp TOK_MAYOR exp
                              {
                                fprintf(yyout,";R98:\t<comparacion> ::= <exp> > <exp>\n");
                                if(($1.tipo == BOOLEANO) || ($3.tipo == BOOLEANO)){
                                  printf("****Error semantico en lin %lu: Operacion aritmetica con operandos boolean.",nlines);
                                  LiberarTablas(tabla);
                                  return -1;
                                }
                                mayor(yyout, $1.es_direccion, $3.es_direccion, etiqueta);
                                etiqueta++;
                                $$.tipo = BOOLEANO;
                                $$.es_direccion = 0;
                              }
                          ;
constante                 :   constante_logica
                              {
                                fprintf(yyout,";R99:\t<constante> ::= <constante_logica>\n");
                                $$.tipo = $1.tipo;
                                $$.es_direccion = $1.es_direccion;
                              }
                          |   constante_entera
                              {
                                fprintf(yyout,";R100:\t<constante> ::= <constante_entera>\n");
                                $$.tipo = $1.tipo;
                                $$.es_direccion = $1.es_direccion;
                              }
                          ;
constante_logica          :   TOK_TRUE
                              {
                                fprintf(yyout,";R102:\t<constante_logica> ::= true\n");
                                $$.tipo = BOOLEANO;
                                $$.es_direccion = 0;
                                char v[1];
                                sprintf(v,"1");
                                escribir_operando(yyout,v,0);
                              }
                          |   TOK_FALSE
                              {
                                fprintf(yyout,";R103:\t<constante_logica> ::= false\n");
                                $$.tipo = BOOLEANO;
                                $$.es_direccion = 0;
                                char v[1];
                                sprintf(v,"0");
                                escribir_operando(yyout,v,0);
                              }
                          ;
constante_entera          :   TOK_CONSTANTE_ENTERA
                              {
                                fprintf(yyout,";R104:\t<constante_entera> ::= TOK_CONSTANTE_ENTERA\n");
                                $$.tipo = ENTERO;
                                $$.es_direccion = 0;
                                $$.valor_entero = $1.valor_entero;
                                char v[MAX_TAM_ENTERO];
                                sprintf(v,"%d",$$.valor_entero);
                                escribir_operando(yyout,v,0);
                              }
                          ;
identificador             :   TOK_IDENTIFICADOR
                              {fprintf(yyout,";R108:\t<identificador> ::= TOK_IDENTIFICADOR\n");
                               /* Si la variable no estaba declarada antes, la declaramos */
                               if (BusquedaElemento(tabla, $1.lexema) == NULL){
                                //TODO
                               }
                               /* Ya existia la variable luego error por duplicado*/
                               else{
                                printf("***Error semantico en lin %lu: Declaracion duplicada.\n", nlines);
                                LiberarTablas(tabla);
                                return -1;
                               }}
%%

void yyerror(const char *s){
  extern size_t nlines;
  extern size_t ncols;
  extern int err_morf;
  extern int yyleng;
  if(!err_morf){
    printf("****Error sintáctico en [lin %lu col %lu]\n",nlines, ncols-yyleng);
    return;
  }
  err_morf = 0;
  return;
}
