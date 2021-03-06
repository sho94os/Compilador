/* declaraciones */

%{
	/* includes */

	#include <stdio.h>
	#include <conio.h>
	#include <stdlib.h>
	#include <locale.h>
	#include <string.h>
	#include <float.h>
	#include "y.tab.h"

	/* defines */

	#define CARACTER_NOMBRE "_"
	#define NO_ENCONTRADO -1
	#define SIN_ASIGNAR "SinAsignar"
	#define TRUE 1
	#define FALSE 0
	#define ERROR -1
	#define OK 3

	/* enums */

	enum valorMaximo{
		ENTERO_MAXIMO = 32768,
		CADENA_MAXIMA = 31,
		TAM = 100
	};

	enum tipoDato{
		tipoInt,
		tipoFloat,
		tipoString,
		tipoArray,
		sinTipo
	};

	enum sectorTabla{
		sectorVariables,
		sectorConstantes
	};

	enum error{
		ErrorIdRepetida,
		ErrorIdNoDeclarado,
		ErrorArraySinTipo,
		ErrorArrayFueraDeRango,
		ErrorLimiteArrayNoPermitido,
		ErrorOperacionNoValida,
		ErrorIdDistintoTipo,
		ErrorConstanteDistintoTipo
	};

	enum tipoDeError{
		ErrorSintactico,
		ErrorLexico
	};

	enum tipoCondicion{
		condicionIf,
		condicionWhile
	};

	enum and_or{
		and,
		or,
		condicionSimple
	};

	enum tipoSalto{
		normal,
		inverso
	};

	/* structs */

	typedef struct{
		char nombre[100];
		char valor[100];
		enum tipoDato tipo;
		int longitud;
		int limite;
	} registro;

	typedef struct
	{
		char *cadena;
		int cantExpresiones;
		int salto1;
		int salto2;
		int nro;
		enum and_or andOr;
		enum tipoDato tipo;
	}t_info;

	/* funciones */

	int buscarEnTablaDeSimbolos(enum sectorTabla, char*);
	void grabarTablaDeSimbolos(int);
	char* obtenerTipo(enum sectorTabla, enum tipoDato);
	int yyerrormsj(char *,enum tipoDeError,enum error, const char*);
	int yyerror();
	int yylex();

	/* variables globales */

	extern registro tablaVariables[TAM];
	extern registro tablaConstantes[TAM];
	extern int yylineno;
	extern int indiceConstante;
	extern int indiceVariable;
	extern char *tiraDeTokens;
	int yystopparser=0;
	FILE  *yyin;
	char *yyltext;
	char *yytext;
	int indicesParaAsignarTipo[TAM];
	enum tipoDato tipoAsignacion=sinTipo;
	int esAsignacion=0;
	int esAsignacionVectorMultiple;
	int contadorListaVar=0;
	int contadorExpresionesVector=0;
	int cantidadDeExpresionesEsperadasEnVector=0;
	int contadorIf=0;
	int contadorWhile=0;
	int auxiliaresNecesarios=0;
	char ultimoComparador[3];
	char nombreVector[CADENA_MAXIMA];
	int inicioAsignacionMultiple;
	int expresionesRestantes;
	enum tipoCondicion tipoCondicion;

%}

%union {
	int entero;
	double real;
	char cadena[50];
}

/* tokens */

%token DIGITO
%token LETRA
%token LETRA_MINUS
%token LETRA_MAYUS
%token CTE_INT
%token CTE_FLOAT
%token CTE_STRING		
%token ID
%token INICIO_PROGRAMA
%token FIN_PROGRAMA
%token OP_SUM
%token OP_REST
%token OP_MULT
%token OP_DIV
%token OP_ASIG
%token OP_DEC
%token OP_AND
%token OP_OR
%token OP_NOT
%token PARENTESIS_I
%token PARENTESIS_F
%token LLAVE_I
%token LLAVE_F
%token CORCHETE_I
%token CORCHETE_F
%token COMENTARIO_I
%token COMENTARIO_F
%token PUNTO_Y_COMA
%token COMA
%token COMP_MAYOR_ESTR
%token COMP_MENOR_ESTR
%token COMP_MAYOR_IGUAL
%token COMP_MENOR_IGUAL
%token COMP_IGUAL
%token COMP_DIST
%token DECVAR
%token ENDDEC
%token WHILE
%token ENDWHILE
%token DO
%token IF
%token ELSE
%token ELSIF
%token ENDIF
%token INTEGER
%token FLOAT
%token STRING
%token READ
%token WRITE
%token BETWEEN
%token INLIST
%token COMENTARIO

%right OP_ASIG
%left OP_SUM OP_REST
%left OP_MULT OP_DIV

%start programa

/* definicion de reglas */

%%

	programa:			INICIO_PROGRAMA
						{
							printf("inicio del programa\n");
						}
						bloque
						FIN_PROGRAMA
						{
							printf("fin del programa\n");
	             		}
	;

	bloque:            	lista_sentencias
						{
							printf("bloque\n");
						}
	;
	
	lista_sentencias: 	sentencia
						{

						}
	|					
						lista_sentencias sentencia
						{

						}
	;

	sentencia:			bloque_declaracion
						{
							printf("bloque de declaracion\n");
						}
	|
	                 	asignacion
	                 	{
	                 		printf("asignacion\n");
	                 	}
	|
	                 	lectura
	                 	{
	                 		printf("lectura\n");
	                 	}
	|
						escritura
						{
							printf("escritura\n");
						}
	|
	                 	iteracion
	                 	{
	                 		printf("iteracion\n");
	                 	}
	|
	                 	seleccion
	                 	{
	                 		printf("seleccion\n");
	                 	}
	|                 	
						COMENTARIO
						{
							printf("comentario\n");
						}
	;

	asignacion:			ID OP_ASIG expresion
						{
							if(tablaVariables[buscarEnTablaDeSimbolos(sectorVariables,$<cadena>1)].tipo==sinTipo)
							{
								yyerrormsj($<cadena>1,ErrorSintactico,ErrorIdNoDeclarado,"");
							}
							esAsignacion=1;
							printf("asignacion: %s\t", $<cadena>1);
							tipoAsignacion=tablaVariables[buscarEnTablaDeSimbolos(sectorVariables,$<cadena>1)].tipo;
							printf("(tipo: %s)\n",obtenerTipo(sectorVariables,tipoAsignacion));
						}
	;

	iteracion:  		WHILE PARENTESIS_I condicion PARENTESIS_F
						{
							printf("while\n");
						}
						DO bloque
						ENDWHILE
	;

	seleccion:			IF PARENTESIS_I condicion PARENTESIS_F
						{
							printf("if\n");
						}
	                  	DO resto
	                  	ENDIF
	;

	condicion: 			comparacion
						{
							printf("comparacion\n");
						}
	|					
						comparacion
						{

						}
	                    OP_AND
	                    {
	                    	printf("and\n");
	                    }
	                    comparacion
	                  	{

	                  	}
	|
						comparacion
						{

						}
	                    OP_OR
						{
							printf("or\n");	
						}
	                    comparacion
	                  	{

	                  	}
	|
						OP_NOT
						{
							printf("not\n");
						}
						comparacion
	                  	{

	                  	}
	|
						between
						{
							printf("between\n");
						}
	|
						inlist
						{
							printf("in list\n");
						}
	;

	comparacion:		expresion
						{

						}
						COMP_MAYOR_ESTR
						{
							printf(">\n");
						}
						expresion
						{

						}
	|					
						expresion
						{

						}
						COMP_MENOR_ESTR
						{
							printf("<\n");
						}
						expresion
						{

						}
	|					
						expresion
						{

						}
						COMP_MAYOR_IGUAL
						{
							printf(">=\n");
						}
						expresion
						{

						}
	|					
						expresion
						{

						}
						COMP_MENOR_IGUAL
						{
							printf("<=\n");
						}
						expresion
						{

						}
	|					
						expresion
						{

						}
						COMP_IGUAL
						{
							printf("==\n");
						}
						expresion
						{

						}
	|					
						expresion
						{

						}
						COMP_DIST
						{
							printf("!=\n");
						}
						expresion
						{

						}		
	;

	resto:				bloque
						{
							printf("if true\n");
						}
	|
						bloque
	                  	{
	                  		printf("if true\n");
	                  	}
	                    ELSE
	                    {
	                    	printf("else\n");
	                    }
	                    bloque
	                    {
	                    	printf("if false\n");
	                    }
	|
						bloque
						{
							printf("if true\n");
						}
						ELSIF PARENTESIS_I condicion PARENTESIS_F
						{
							printf("elsif");
						}
	                  	bloque
						ELSE
						{
							printf("else");
						}
						bloque
						{
							printf("if false");
						}
	;

	lectura:			READ
	                    {
	                    	printf("read\n");
	                    }
	                    ID
	;

	escritura:			WRITE ID
	                    {
	                    	printf("write id\n");
	                    }
 	|
 						WRITE CTE_STRING
 						{
 							printf("write string\n");
 						}
	;

	bloque_declaracion:	DECVAR
						{
							printf("bloque de declaracion\n");
						}
						declaraciones ENDDEC
						{
							printf("fin bloque de declaracion\n");
						}
	;

	declaraciones:		declaraciones lista_id_y_tipo
						{
							printf("múltiple\n");
						}
	|
						lista_id_y_tipo
	;

	lista_id_y_tipo: 	ID COMA lista_id_y_tipo
	|
						ID OP_DEC tipodato 
	;

	tipodato: 			INTEGER
						{
							int posicion=buscarEnTablaDeSimbolos(sectorVariables,yylval.cadena);
							printf("Tipo de a: %s", obtenerTipo(sectorVariables, tablaVariables[posicion].tipo));
							if(strcmp("sin tipo",obtenerTipo(sectorVariables, tablaVariables[posicion].tipo)) == 0)
							{
								tablaVariables[posicion].tipo=tipoInt;
							}
							else
							{
								yyerrormsj(tablaVariables[posicion].valor,ErrorSintactico,ErrorIdRepetida,"");
							}										
							
							printf("tipo entero\n");							
						}
	|					FLOAT
						{
							int posicion=buscarEnTablaDeSimbolos(sectorVariables,yylval.cadena);
							printf("Tipo de a: %s", obtenerTipo(sectorVariables, tablaVariables[posicion].tipo));
							if(strcmp("sin tipo",obtenerTipo(sectorVariables, tablaVariables[posicion].tipo)) == 0)
							{
								tablaVariables[posicion].tipo=tipoFloat;
							}
							else
							{
								yyerrormsj(tablaVariables[posicion].valor,ErrorSintactico,ErrorIdRepetida,"");
							}
							
							printf("tipo flotante\n");
						}
	|					STRING
						{	
							int posicion=buscarEnTablaDeSimbolos(sectorVariables,yylval.cadena);
							printf("Tipo de a: %s", obtenerTipo(sectorVariables, tablaVariables[posicion].tipo));
							if(strcmp("sin tipo",obtenerTipo(sectorVariables, tablaVariables[posicion].tipo)) == 0)
							{
								tablaVariables[posicion].tipo=tipoString;
							}
							else
							{
								yyerrormsj(tablaVariables[posicion].valor,ErrorSintactico,ErrorIdRepetida,"");
							}
							
							printf("tipo string\n");
						}
	;

	expresion:			expresion OP_SUM termino
						{
							printf("+\n");
						}
	|
						expresion OP_REST termino
						{
							printf("-\n");
						}
	|
						termino
						{
							printf("termino\n");
						}
	;

	termino: 			termino OP_MULT factor
	                  	{
	                    	printf("*\n");
	                    }
	|
						termino OP_DIV factor
	                  	{
							printf("/\n");
	                  	}
	|
	                  	factor
						{
							printf("factor\n");
	                    }
	;

	factor: 			CTE_INT
    					{
					    	printf("CTE_INT: %s\n", $<cadena>1);
					    	/*
				    		if(esAsignacion==1&&tipoAsignacion!=tipoInt)
				    		{
				    			yyerrormsj($<cadena>1, ErrorSintactico,ErrorConstanteDistintoTipo,"");
				    		}
				    		*/
					    }
	| 					
						CTE_FLOAT
					    {
					    	printf("CTE_FLOAT: %s\n", $<cadena>1);
					    	/*
					    	if(esAsignacion==1&&tipoAsignacion!=tipoFloat)
					    	{
					    		yyerrormsj($<cadena>1, ErrorSintactico,ErrorConstanteDistintoTipo,"");
					    	}
					    	*/
					    }
	|					
						CTE_STRING
						{
							printf("CTE_STRING: %s\n", $<cadena>1);
							/*
							if(esAsignacion==1&&tipoAsignacion!=tipoString)
							{
					    		yyerrormsj($<cadena>1, ErrorSintactico,ErrorConstanteDistintoTipo,"");
							}
							*/
						}
	|
	                  	ID
	                  	{
	                  		printf("id\n");
	                  		printf("%s\n", yylval.cadena);
	                  		int posicion=buscarEnTablaDeSimbolos(sectorVariables,yylval.cadena);
							indicesParaAsignarTipo[contadorListaVar++]=posicion;
	                  	}
	|
						PARENTESIS_I expresion PARENTESIS_F
	;

	between:			BETWEEN PARENTESIS_I ID COMA rango PARENTESIS_F
	;

	rango:				CORCHETE_I expresion PUNTO_Y_COMA expresion CORCHETE_F
						{
							printf("rango\n");
						}
	;

	inlist:				INLIST PARENTESIS_I ID PUNTO_Y_COMA lista_expresiones PARENTESIS_F
	;

	lista_expresiones:	CORCHETE_I expresiones CORCHETE_F
						{
							printf("lista de expresiones\n");
						}
	;

	expresiones: 		expresion
	|
						expresion PUNTO_Y_COMA expresiones
	;

%%

/* codigo */

int main(int argc,char *argv[])
{

	setlocale(LC_CTYPE,"Spanish");

  	if ((yyin = fopen(argv[1], "rt")) == NULL)
	{
		printf("\n No se puede abrir el archivo: %s\n", argv[1]);
	}
	else
	{
		tiraDeTokens=(char*)malloc(sizeof(char));
		if(tiraDeTokens==NULL)
		{
			printf("\n Error al solicitar memoria\n");
			exit(1);
		}
		strcpy(tiraDeTokens,"");
		yyparse();
	}
	fclose(yyin);

	grabarTablaDeSimbolos(0);

	printf("\n*** COMPILACION EXITOSA ***\n");

  	return 0;
}

/* funciones */

int yyerrormsj(char * info,enum tipoDeError tipoDeError ,enum error error, const char *infoAdicional)
{
	setlocale(LC_CTYPE,"Spanish");
	grabarTablaDeSimbolos(1);
	printf("[Línea %d] ",yylineno);
  	switch(tipoDeError){
        case ErrorSintactico:
            printf("Error sintáctico. ");
            break;
        case ErrorLexico:
            printf("Error lexico. ");
            break;
    }
  	switch(error){
		case ErrorIdRepetida:
			printf("Descripcion: el id '%s' ha sido declarado más de una vez\n",info);
			break;
		case ErrorIdNoDeclarado:
			printf("Descripcion: el id '%s' no ha sido declarado\n",info);
			break;
		case ErrorArraySinTipo:
			printf("Descripcion: el id '%s' NO tiene un tipo asignado\n",info);
			break;
		case ErrorArrayFueraDeRango:
			printf("Descripcion: vector '%s(0..%d)' fuera de rango. Se intenta acceder a '%s[%s]'\n",info,(tablaVariables[buscarEnTablaDeSimbolos(sectorVariables,info)].limite),info,infoAdicional);
			break;
		case ErrorLimiteArrayNoPermitido:
			printf("Descripcion: el vector %s (%s) no tiene un límite válido, debe ser mayor a 0\n",info, infoAdicional);
			break;
		case ErrorOperacionNoValida:
			printf("Descripcion: La operacion %s no es válida para variables de tipo %s\n",info, obtenerTipo(sectorVariables, tipoAsignacion));
			break;
		case ErrorIdDistintoTipo:
			printf("Descripcion: La variable '%s' no es de tipo %s\n",info,obtenerTipo(sectorVariables, tipoAsignacion));
			break;
		case ErrorConstanteDistintoTipo:
			printf("Descripcion: La constante %s no es de tipo %s\n", info, obtenerTipo(sectorVariables, tipoAsignacion));
			break;
    }

  	system ("Pause");
    exit (1);
}

int yyerror()
{
	setlocale(LC_CTYPE,"Spanish");
	grabarTablaDeSimbolos(1);
	printf("Error sintáctico \n");
	system ("Pause");
	exit (1);
}