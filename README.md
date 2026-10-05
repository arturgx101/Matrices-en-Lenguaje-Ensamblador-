Matrices-en-Lenguaje-Ensamblador-

Matrices en Lenguaje Ensamblador Se realiza en ASM lo siguiente: Suma de dos matrices Transpuesta Multiplicacion Diagonal Suma de columnas Suma de renglones
Introducción

Esta aplicación en ensamblador (TASM/TLINK, modo real DOS) implementa un sistema de
operaciones con matrices 4×4, permitiendo al usuario interactuar mediante un menú para
realizar diferentes cálculos como:
• Suma de matrices
• Obtención de la transpuesta
• Cálculo de diagonal principal y suma total
• Suma de columnas
• Suma de renglones
• Multiplicación (no implementada completamente)
Incluye además un reloj en vivo en pantalla que se actualiza por centésimas de segundo.
Objetivo General
Proveer una herramienta educativa que permita visualizar el proceso de cálculo de
operaciones matriciales en un entorno de bajo nivel, demostrando:
• Manipulación directa de memoria
• Uso de interrupciones de BIOS/DOS
• Control manual del cursor y pantalla
• Diseño estructurado en ensamblador
Filosofía de Diseño
El programa fue construido siguiendo tres principios clave:
1. Modularidad
Cada operación está encapsulada en un procedimiento (PROC). Esto permite:
• Reutilizar funciones auxiliares (imprimir número, leer entrada, formatear matrices)
• Mantener el código más ordenado y fácil de depurar
2. Interacción clara con el usuario
Se emplea un menú visual con opciones A–F, donde cada pantalla:
• Limpia el modo de video
• Coloca textos en posiciones específicas
• Muestra matriz, resultado o instrucciones según el caso
El usuario controla toda la ejecución mediante teclado.
3. Transparencia del cálculo
Las operaciones muestran:
• Matriz original
• Resultados únicamente cuando el usuario presiona "I"
• Un retorno claro al menú con ESC
4. Arquitectura General del Programa
El programa está estructurado en bloques funcionales:
A. Menú principal
Muestra opciones y lee teclas mediante interrupciones 10h y 16h.
B. Módulo de reloj
Obtiene hora del sistema (INT 21h, función 2Ch), la convierte a ASCII y la actualiza en
pantalla solo cuando hay cambios.
C. Captura de matrices
Rutina Ingresar matrices :
• Lee números usando entrada carácter por carácter
• Detecta coma, Enter y ESC
• Convierte dígitos ASCII a valores numéricos
• Llena secuencialmente los 16 elementos de la matriz
D. Operaciones matriciales
Cada operación trabaja con índices y desplazamientos exactos en memoria (2 bytes por
elemento) para:
• Suma elemento a elemento
• Transpuesta (T[i][j] = A[j][i])
• Cálculo de diagonal
• Suma por columnas
• Suma por filas

Se tuvo complicaciones, falta mas documentación y arroja errores a la hora de multiplicar. 
