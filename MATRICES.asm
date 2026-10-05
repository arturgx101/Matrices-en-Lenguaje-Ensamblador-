; =================================================================
; PROYECTO.ASM - Sistema de Operaciones con Matrices 4x4
; TASM/TLINK 
; Autor:Garcia Trejo Arturo

.MODEL small      ; Modelo de memoria pequeño (un segmento de datos, uno de código)
.STACK 100h       ; Reserva 256 bytes (100h) para la pila

.DATA
    ; Mensajes principales
    titulo      db 'OPERACIONES CON MATRICES$'  ; Cadena terminada en $ para mostrar
  
    ; Opciones del menú
    opA         db 'A) Suma de 2 Matrices$'
    opB         db 'B) Obtener transpuesta$'
    opC         db 'C) Multiplicar MATRICES$'
    opD         db 'D) Diagonal Principal y Suma$'
    opE         db 'E) Suma de Columnas de una matriz$'
    opF         db 'F) Suma de Renglones de una matriz$'
    
    ; Mensajes de operaciones
    tit_suma    db 'SUMA DE 2 MATRICES$'
    tit_trans   db 'OBTENER TRANSPUESTA$'
    tit_mul     db 'MULTIPLICAR MATRICES$'
    tit_diag    db 'DIAGONAL PRINCIPAL Y SUMA$'
    tit_sumcol  db 'SUMA DE COLUMNAS DE UNA MATRIZ$'
    tit_sumrow  db 'SUMA DE RENGLONES DE UNA MATRIZ$'
    
    ; Mensajes generales
    matA        db 'MATRIZ A:$'
    matB        db 'MATRIZ B:$'
    resul       db 'RESULTADO:$'
    trans_msg   db 'TRANSPUESTA:$'
    diag_msg    db 'Diagonal: $'
    sum_diag    db 'Suma de la Diagonal: $'
    sum_matriz  db 'Suma de la Matriz: $'
    sum_col_msg db 'Suma Columnas: $'
    sum_row_msg db 'Suma Filas: $'
    ingrese     db 'Ingrese la matriz 4x4 por renglon con separacion de una "," $'
    no_mul      db 'Multiplicacion no implementada completamente$'
    
    ; Matrices 4x4 (16 elementos cada una, 2 bytes por elemento = 32 bytes)
    matrizA     dw 16 dup(0)   ; Reserva 16 palabras (words) inicializadas en 0
    matrizB     dw 16 dup(0)   ; Otra matriz 4x4
    matrizR     dw 16 dup(0)   ; Matriz para resultados
    matrizT     dw 16 dup(0)   ; Matriz para transpuesta
    sumas_col   dw 4 dup(0)    ; Array para 4 sumas de columnas
    sumas_row   dw 4 dup(0)    ; Array para 4 sumas de filas
    
    ; Variables para hora
    hora_buffer db '00:00:00:00$'  ; Formato HH:MM:SS:CC (centésimas)
    old_cent    db 0               ; Guarda las centésimas anteriores para comparar
    flag_esc    db 0               ; Bandera: 1 si se presionó ESC
    suma_total  dw 0               ; Variable para almacenar sumas
    mostrar_res db 0               ; 0=no mostrar, 1=mostrar resultado
    
    ; Buffer para entrada
    buffer      db 50 dup(0)       ; Buffer para lectura de texto (no se usa aquí)
    num_temp    dw 0               ; Almacena temporalmente números durante entrada
    
    ; Variables de formato
    espaciado   db '   $'          ; Espacios para formatear
    col_labels  db 'C1  C2  C3  C4 $'  ; Etiquetas columnas
    row_labels  db 'F1  F2  F3  F4 $'  ; Etiquetas filas

.CODE

; =================================================================
; PROGRAMA PRINCIPAL
; =================================================================
START:
    mov ax, @data   ; Carga la dirección del segmento de datos en AX
    mov ds, ax      ; Copia AX a DS (Data Segment) para acceder a variables
    
    mov ax, 0003h   ; Llama a interrupción 10h función 00h (modo video)
    int 10h         ; Ejecuta la interrupción (limpia pantalla)
    
    mov ah, 1       ; Función 01h de int 10h: configurar cursor
    mov ch, 32      ; CH=20h (32 decimal) oculta el cursor
    int 10h         ; Ejecuta (cursor invisible)
    
    call menu_principal ; Llama al menú principal
    
    mov ax, 4C00h   ; Función 4Ch de int 21h: terminar programa
    int 21h         ; Devuelve el control al DOS

; =================================================================
; MENÚ PRINCIPAL
; =================================================================
menu_principal PROC
menu_loop:
    mov ax, 0003h   ; Limpia la pantalla cada vez que vuelve al menú
    int 10h
    
    ; Mostrar título en posición (0, 28)
    mov dh, 0       ; Fila 0
    mov dl, 28      ; Columna 28 (centrado aproximadamente)
    mov bh, 0       ; Página de video 0
    mov ah, 2       ; Función 02h de int 10h: posicionar cursor
    int 10h         ; Posiciona cursor
    mov dx, OFFSET titulo  ; DX apunta a la cadena 'titulo'
    mov ah, 9       ; Función 09h de int 21h: imprimir cadena
    int 21h         ; Muestra "OPERACIONES CON MATRICES"
    
    ; Mostrar hora en vivo en posición (3, 35)
    call mostrar_hora_actual
    
    ; Mostrar opciones del menú desde fila 6, columna 28
    mov dh, 6       ; Fila 6
    mov dl, 28      ; Columna 28
    call mostrar_texto_at  ; Posiciona cursor y muestra texto
    mov dx, OFFSET opA
    call mostrar_texto     ; Muestra "A) Suma de 2 Matrices"
    
   
    mov dh, 7
    mov dl, 28
    call mostrar_texto_at
    mov dx, OFFSET opB
    call mostrar_texto
    
    mov dh, 8
    mov dl, 28
    call mostrar_texto_at
    mov dx, OFFSET opC
    call mostrar_texto
    
    mov dh, 9
    mov dl, 28
    call mostrar_texto_at
    mov dx, OFFSET opD
    call mostrar_texto
    
    mov dh, 10
    mov dl, 28
    call mostrar_texto_at
    mov dx, OFFSET opE
    call mostrar_texto
    
    mov dh, 11
    mov dl, 28
    call mostrar_texto_at
    mov dx, OFFSET opF
    call mostrar_texto
    
leer_opcion:
    ; Actualizar hora si cambió (cada centésima de segundo)
    call actualizar_hora_si_cambio
    
    mov ah, 1       ; Función 01h de int 16h: verificar tecla disponible
    int 16h         ; Consulta buffer de teclado
    jz leer_opcion  ; Si ZF=1 (no hay tecla), repite
    
    mov ah, 0       ; Función 00h de int 16h: leer tecla
    int 16h         ; AL = carácter ASCII, AH = scan code
    
    cmp al, 1Bh     ; Compara con ESC (ASCII 27)
    je salir_programa
    
    ; Verifica opciones del menú (mayúsculas y minúsculas)
    cmp al, 'A'
    je opcion_A
    cmp al, 'a'
    je opcion_A
    
    cmp al, 'B'
    je opcion_B
    cmp al, 'b'
    je opcion_B
    
    cmp al, 'C'
    je opcion_C
    cmp al, 'c'
    je opcion_C
    
    cmp al, 'D'
    je opcion_D
    cmp al, 'd'
    je opcion_D
    
    cmp al, 'E'
    je opcion_E
    cmp al, 'e'
    je opcion_E
    
    cmp al, 'F'
    je opcion_F
    cmp al, 'f'
    je opcion_F
    
    jmp leer_opcion  ; Si no es opción válida, vuelve a leer

; Saltos a las funciones correspondientes
opcion_A:
    call suma_matrices
    jmp menu_loop   ; Vuelve al menú después de la operación

opcion_B:
    call transpuesta_matriz
    jmp menu_loop

opcion_C:
    call multiplica_matrices
    jmp menu_loop

opcion_D:
    call diagonal_suma
    jmp menu_loop

opcion_E:
    call suma_columnas
    jmp menu_loop

opcion_F:
    call suma_renglones
    jmp menu_loop

salir_programa:
    mov ax, 4C00h
    int 21h

; Subrutina para posicionar cursor y mostrar texto
mostrar_texto_at:
    mov bh, 0       ; Página 0
    mov ah, 2       ; Función posicionar cursor
    int 10h
    ret

mostrar_texto:
    mov ah, 9       ; Función imprimir cadena
    int 21h
    ret
menu_principal ENDP

; =================================================================
; FUNCIONES AUXILIARES - HORA EN VIVO
; =================================================================

mostrar_hora_actual PROC
    ; Obtener hora del sistema
    mov ah, 2Ch     ; Función 2Ch de int 21h: obtener tiempo
    int 21h         ; CH=horas, CL=minutos, DH=segundos, DL=1/100 segundos
    
    ; Guardar centésimas para detectar cambios
    mov old_cent, dl
    
    ; Convertir horas (CH) a ASCII de 2 dígitos
    mov al, ch      ; Mueve horas a AL
    call convertir_a_ascii  ; Convierte AL a 2 caracteres en AL/AH
    mov [hora_buffer], al    ; Primer dígito de horas
    mov [hora_buffer+1], ah  ; Segundo dígito de horas
    
    ; Convertir minutos (CL) a ASCII
    mov al, cl
    call convertir_a_ascii
    mov [hora_buffer+3], al   ; Primer dígito minutos
    mov [hora_buffer+4], ah   ; Segundo dígito minutos
    
    ; Convertir segundos (DH) a ASCII
    mov al, dh
    call convertir_a_ascii
    mov [hora_buffer+6], al   ; Primer dígito segundos
    mov [hora_buffer+7], ah   ; Segundo dígito segundos
    
    ; Convertir centésimas (DL) a ASCII
    mov al, dl
    call convertir_a_ascii
    mov [hora_buffer+9], al   ; Primer dígito centésimas
    mov [hora_buffer+10], ah  ; Segundo dígito centésimas
    
    ; Mostrar hora en posición (3, 35)
    mov dh, 3
    mov dl, 35
    mov bh, 0
    mov ah, 2
    int 10h         ; Posiciona cursor
    
    mov dx, OFFSET hora_buffer
    mov ah, 9
    int 21h         ; Muestra la hora
    
    ret
mostrar_hora_actual ENDP

convertir_a_ascii PROC
    ; Convierte AL (0-99) a dos caracteres ASCII en AL (decenas) y AH (unidades)
    push bx         ; Guarda BX en pila
    mov ah, 0       ; Limpia AH para la división
    mov bl, 10      ; Divisor = 10
    div bl          ; AL = cociente (decenas), AH = resto (unidades)
    
    add al, '0'     ; Convierte decenas a ASCII sumando '0'
    add ah, '0'     ; Convierte unidades a ASCII sumando '0'
    
    pop bx          ; Restaura BX
    ret
convertir_a_ascii ENDP

actualizar_hora_si_cambio PROC
    ; Verificar si las centésimas cambiaron
    mov ah, 2Ch
    int 21h         ; Obtiene hora actual (DL = centésimas)
    
    cmp dl, old_cent ; Compara con las centésimas guardadas
    je no_cambio    ; Si son iguales, no actualiza
    
    ; Si cambiaron, actualizar la hora en pantalla
    call mostrar_hora_actual
    
no_cambio:
    ret
actualizar_hora_si_cambio ENDP

; =================================================================
; ENTRADA DE MATRIZ 
; =================================================================
ingresar_matriz PROC
    push ax
    push bx
    push cx
    push si         ; Guarda registros en la pila
    
    mov flag_esc, 0 ; Inicializa bandera ESC en 0
    
    ; Mostrar mensaje de instrucción en (8, 20)
    mov dh, 8
    mov dl, 20
    call posicionar_cursor
    mov dx, OFFSET ingrese
    mov ah, 9
    int 21h         ; Muestra "Ingrese la matriz..."
    
    ; Posicionar para entrada de datos en (10, 20)
    mov dh, 10
    mov dl, 20
    call posicionar_cursor
    
    mov bx, 0       ; BX = índice para matriz (0, 2, 4, ..., 30)
    mov cx, 0       ; CX = contador de números leídos (0 a 16)
    
leer_16_numeros:
    call leer_numero_simple  ; Lee un número, devuelve en AX
    cmp flag_esc, 1 ; ¿Se presionó ESC?
    je salir_matriz_esc  ; Si sí, sale
    
    mov [si + bx], ax  ; Guarda número en matriz[índice]
                       ; SI = dirección base de la matriz
                       ; BX = desplazamiento (0, 2, 4, ...)
    add bx, 2        ; Incrementa índice en 2 (cada elemento es word = 2 bytes)
    inc cx           ; Incrementa contador
    cmp cx, 16       ; ¿Ya leyó 16 números?
    jb leer_16_numeros ; Si menor, continúa
    
    jmp salir_matriz_ok ; Si ya son 16, termina
    
salir_matriz_esc:
    pop si
    pop cx
    pop bx
    pop ax
    ret
    
salir_matriz_ok:
    pop si
    pop cx
    pop bx
    pop ax
    ret
ingresar_matriz ENDP

leer_numero_simple PROC
    push bx
    push cx
    
    mov num_temp, 0 ; Inicializa número temporal en 0
    
ciclo_leer_num:
    mov ah, 1       ; Función 01h de int 21h: leer carácter con eco
    int 21h         ; Lee carácter, lo muestra en pantalla, lo guarda en AL
    
    cmp al, 13      ; ¿Es Enter (ASCII 13)?
    je fin_leer_num ; Sí: termina número
    cmp al, ','     ; ¿Es coma?
    je fin_leer_num ; Sí: termina número
    cmp al, 1Bh     ; ¿Es ESC (ASCII 27)?
    je esc_leer_num ; Sí: marca bandera y termina
    
    ; Verifica si es dígito (0-9)
    cmp al, '0'
    jb no_es_digito ; Si es menor que '0', no es dígito
    cmp al, '9'
    ja no_es_digito ; Si es mayor que '9', no es dígito
    
    ; Es un dígito: lo convierte a valor y acumula
    sub al, '0'     ; Convierte carácter ASCII a número (resta 48)
    mov ah, 0       ; Limpia AH para usar AX completo
    
    push ax         ; Guarda dígito temporalmente
    mov ax, num_temp ; Carga número acumulado
    mov bx, 10      ; Multiplicador base 10
    mul bx          ; Multiplica AX por 10 (resultado en DX:AX)
    mov num_temp, ax ; Guarda resultado (asume que cabe en 16 bits)
    pop ax          ; Recupera dígito
    add num_temp, ax ; Suma dígito al número acumulado
    
no_es_digito:
    jmp ciclo_leer_num ; Lee siguiente carácter

esc_leer_num:
    mov flag_esc, 1 ; Establece bandera ESC
    jmp fin_leer_proc

fin_leer_num:
    mov ax, num_temp ; Devuelve número en AX

fin_leer_proc:
    pop cx
    pop bx
    ret
leer_numero_simple ENDP

; =================================================================
; IMPRIMIR NÚMERO CON ANCHO FIJO (3 espacios)
; =================================================================
imprimir_numero_fijo PROC
    push ax
    push bx
    push cx
    push dx
    
    push ax         ; Guarda el número a imprimir
    
    mov bx, 10      ; Base decimal
    mov cx, 0       ; Contador de dígitos
    
div_loop_num:
    xor dx, dx      ; Limpia DX para división (DX:AX / BX)
    div bx          ; Divide AX entre 10
                    ; AX = cociente, DX = resto
    push dx         ; Guarda dígito (resto) en pila
    inc cx          ; Incrementa contador de dígitos
    test ax, ax     ; ¿Cociente = 0?
    jnz div_loop_num ; Si no, sigue dividiendo
    
    ; Determina cuántos dígitos tiene para alinear a 3 espacios
    cmp cx, 3       ; ¿Tiene 3 dígitos?
    je imprimir_3_digitos
    cmp cx, 2       ; ¿Tiene 2 dígitos?
    je imprimir_2_digitos
    cmp cx, 1       ; ¿Tiene 1 dígito?
    je imprimir_1_digito
    
imprimir_3_digitos:
    pop dx          ; Saca primer dígito (centenas)
    add dl, '0'     ; Convierte a ASCII
    mov ah, 2       ; Función 02h de int 21h: imprimir carácter
    int 21h         ; Imprime primer dígito
    pop dx          ; Saca segundo dígito (decenas)
    add dl, '0'
    mov ah, 2
    int 21h         ; Imprime segundo dígito
    pop dx          ; Saca tercer dígito (unidades)
    add dl, '0'
    mov ah, 2
    int 21h         ; Imprime tercer dígito
    jmp fin_imprimir_fijo
    
imprimir_2_digitos:
    mov dl, ' '     ; Imprime espacio para alinear
    mov ah, 2
    int 21h
    pop dx          ; Saca primer dígito (decenas)
    add dl, '0'
    mov ah, 2
    int 21h
    pop dx          ; Saca segundo dígito (unidades)
    add dl, '0'
    mov ah, 2
    int 21h
    jmp fin_imprimir_fijo
    
imprimir_1_digito:
    mov dl, ' '     ; Imprime dos espacios para alinear
    mov ah, 2
    int 21h
    mov dl, ' '
    mov ah, 2
    int 21h
    pop dx          ; Saca único dígito
    add dl, '0'
    mov ah, 2
    int 21h
    
fin_imprimir_fijo:
    mov dl, ' '     ; Imprime espacio separador entre números
    mov ah, 2
    int 21h
    
    pop ax          ; Restaura AX (el número original)
    pop dx
    pop cx
    pop bx
    pop ax
    ret
imprimir_numero_fijo ENDP

; =================================================================
; IMPRIMIR MATRIZ CON FORMATO
; =================================================================
imprimir_matriz_formato PROC
    push ax
    push bx
    push cx
    push dx
    push si         ; Guarda registros
    
    mov bx, 0       ; BX = índice para recorrer matriz (0, 2, 4, ...)
    mov cx, 4       ; CX = contador de filas (4 filas)
    
ciclo_filas_fmt:
    push cx         ; Guarda contador de filas
    push dx         ; Guarda posición inicial (DH=fila, DL=columna)
    
    ; Posiciona cursor en (DH, DL)
    mov bh, 0
    mov ah, 2
    int 10h
    
    mov cx, 4       ; 4 columnas por fila
    
ciclo_cols_fmt:
    mov ax, [si + bx]  ; Carga elemento matriz[índice]
    call imprimir_numero_fijo  ; Imprime con ancho fijo
    add bx, 2        ; Avanza al siguiente elemento
    loop ciclo_cols_fmt ; Repite 4 veces
    
    pop dx           ; Recupera posición inicial
    inc dh           ; Incrementa fila (baja una línea)
    pop cx           ; Recupera contador de filas
    loop ciclo_filas_fmt ; Repite 4 veces
    
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
imprimir_matriz_formato ENDP

; =================================================================
; POSICIONAR CURSOR
; =================================================================
posicionar_cursor PROC
    mov bh, 0       ; Página de video 0
    mov ah, 2       ; Función posicionar cursor
    int 10h         ; DH = fila, DL = columna
    ret
posicionar_cursor ENDP

; =================================================================
; MOSTRAR MATRICES Y ESPERAR I
; =================================================================
mostrar_y_esperar PROC
    push ax
    push dx
    
    mov mostrar_res, 0  ; Inicializa bandera

esperar_tecla:
    mov ah, 0       ; Función 00h de int 16h: leer tecla
    int 16h         ; Espera tecla
    
    cmp al, 1Bh     ; ¿Es ESC?
    je salir_esperar ; Sí: sale sin mostrar resultado
    
    cmp al, 'I'     ; ¿Es 'I' mayúscula?
    je mostrar_resultado_tecla
    cmp al, 'i'     ; ¿Es 'i' minúscula?
    je mostrar_resultado_tecla
    
    jmp esperar_tecla ; Si no es I ni ESC, sigue esperando

mostrar_resultado_tecla:
    mov mostrar_res, 1  ; Establece bandera para mostrar resultado

salir_esperar:
    pop dx
    pop ax
    ret
mostrar_y_esperar ENDP

; =================================================================
; ESPERAR ESC
; =================================================================
esperar_esc PROC
    push ax
    
esperar_esc_loop:
    mov ah, 0       ; Lee tecla
    int 16h
    cmp al, 1Bh     ; ¿Es ESC?
    jne esperar_esc_loop ; No: sigue esperando
    
    pop ax
    ret
esperar_esc ENDP

; =================================================================
; SUMA DE MATRICES
; =================================================================
suma_matrices PROC
    mov flag_esc, 0
    
    ; Pantalla para Matriz A
    mov ax, 0003h
    int 10h         ; Limpia pantalla
    
    mov dh, 2
    mov dl, 32
    call posicionar_cursor
    mov dx, OFFSET tit_suma
    mov ah, 9
    int 21h         ; Muestra "SUMA DE 2 MATRICES"
    
    mov dh, 5
    mov dl, 10
    call posicionar_cursor
    mov dx, OFFSET matA
    mov ah, 9
    int 21h         ; Muestra "MATRIZ A:"
    
    mov si, OFFSET matrizA  ; Puntero a matriz A
    call ingresar_matriz    ; Ingresa 16 números
    
    cmp flag_esc, 1
    je salir_suma          ; Si ESC, regresa al menú
    
    ; Pantalla para Matriz B
    mov ax, 0003h
    int 10h         ; Limpia pantalla nuevamente
    
    mov dh, 2
    mov dl, 32
    call posicionar_cursor
    mov dx, OFFSET tit_suma
    mov ah, 9
    int 21h
    
    mov dh, 5
    mov dl, 10
    call posicionar_cursor
    mov dx, OFFSET matB
    mov ah, 9
    int 21h         ; Muestra "MATRIZ B:"
    
    mov si, OFFSET matrizB  ; Puntero a matriz B
    call ingresar_matriz    ; Ingresa 16 números
    
    cmp flag_esc, 1
    je salir_suma
    
    ; Calcular suma: matrizR[i] = matrizA[i] + matrizB[i]
    mov si, OFFSET matrizA  ; SI apunta a matrizA
    mov di, OFFSET matrizB  ; DI apunta a matrizB
    mov bx, OFFSET matrizR  ; BX apunta a matriz resultado
    mov cx, 16              ; 16 elementos
    
ciclo_suma:
    mov ax, [si]      ; Carga elemento de matrizA en AX
    add ax, [di]      ; Suma elemento de matrizB
    mov [bx], ax      ; Guarda resultado en matrizR
    add si, 2         ; Avanza al siguiente elemento (2 bytes)
    add di, 2
    add bx, 2
    loop ciclo_suma   ; Repite 16 veces
    
    ; Mostrar matrices A, B y resultado
    call mostrar_matrices_suma
    
    ret
    
salir_suma:
    ret
suma_matrices ENDP

mostrar_matrices_suma PROC
    mov ax, 0003h
    int 10h         ; Limpia pantalla para mostrar resultados
    
    mov dh, 2
    mov dl, 35
    call posicionar_cursor
    mov dx, OFFSET tit_suma
    mov ah, 9
    int 21h         ; Título
    
    ; Matriz A en columna 15
    mov dh, 5
    mov dl, 15
    call posicionar_cursor
    mov dx, OFFSET matA
    mov ah, 9
    int 21h         ; "MATRIZ A:"
    
    mov dh, 7
    mov dl, 15
    mov si, OFFSET matrizA
    call imprimir_matriz_formato  ; Imprime matriz A
    
    ; Matriz B en columna 40
    mov dh, 5
    mov dl, 40
    call posicionar_cursor
    mov dx, OFFSET matB
    mov ah, 9
    int 21h         ; "MATRIZ B:"
    
    mov dh, 7
    mov dl, 40
    mov si, OFFSET matrizB
    call imprimir_matriz_formato  ; Imprime matriz B
    
    ; Esperar 'I' para mostrar resultado
    call mostrar_y_esperar
    
    cmp mostrar_res, 1  ; Se presionó 'I'
    jne salir_mostrar_suma  ; 
    
    ; Mostrar resultado en columna 65
    mov dh, 5
    mov dl, 65
    call posicionar_cursor
    mov dx, OFFSET resul
    mov ah, 9
    int 21h         ; "RESULTADO:"
    
    mov dh, 7
    mov dl, 65
    mov si, OFFSET matrizR
    call imprimir_matriz_formato  ; Imprime matriz resultado
    
    ; Esperar ESC para regresar al menú
    call esperar_esc

salir_mostrar_suma:
    ret
mostrar_matrices_suma ENDP

; =================================================================
; TRANSPUESTA DE MATRIZ
; =================================================================
transpuesta_matriz PROC
    mov flag_esc, 0
    
    mov ax, 0003h
    int 10h         ; Limpia pantalla
    
    mov dh, 2
    mov dl, 32
    call posicionar_cursor
    mov dx, OFFSET tit_trans
    mov ah, 9
    int 21h         ; "OBTENER TRANSPUESTA"
    
    mov dh, 5
    mov dl, 10
    call posicionar_cursor
    mov dx, OFFSET matA
    mov ah, 9
    int 21h         ; "MATRIZ A:"
    
    mov si, OFFSET matrizA
    call ingresar_matriz    ; Ingresa matriz A
    
    cmp flag_esc, 1
    je salir_trans
    
    ; Calcular transpuesta
    ; Matriz original: 4x4, Matriz transpuesta: 4x4
    ; Fórmula: T[i][j] = A[j][i]
    ; Se accede por filas: A[fila*4 + columna]
    ; Cada elemento es word (2 bytes), índice = (fila*4 + columna)*2
    
    mov si, OFFSET matrizA  ; Origen
    mov di, OFFSET matrizT  ; Destino (transpuesta)
    
    ; Fila 0 -> Columna 0
    mov ax, [si]        ; A[0][0]
    mov [di], ax        ; T[0][0] = A[0][0]
    
    mov ax, [si+2]      ; A[0][1]
    mov [di+8], ax      ; T[1][0] = A[0][1] (desplazamiento 8 = 4 elementos * 2 bytes)
    
    mov ax, [si+4]      ; A[0][2]
    mov [di+16], ax     ; T[2][0] = A[0][2]
    
    mov ax, [si+6]      ; A[0][3]
    mov [di+24], ax     ; T[3][0] = A[0][3]
    
    ; Fila 1 -> Columna 1
    mov ax, [si+8]      ; A[1][0]
    mov [di+2], ax      ; T[0][1] = A[1][0]
    
    mov ax, [si+10]     ; A[1][1]
    mov [di+10], ax     ; T[1][1] = A[1][1]
    
    mov ax, [si+12]     ; A[1][2]
    mov [di+18], ax     ; T[2][1] = A[1][2]
    
    mov ax, [si+14]     ; A[1][3]
    mov [di+26], ax     ; T[3][1] = A[1][3]
    
    ; Fila 2 -> Columna 2
    mov ax, [si+16]     ; A[2][0]
    mov [di+4], ax      ; T[0][2] = A[2][0]
    
    mov ax, [si+18]     ; A[2][1]
    mov [di+12], ax     ; T[1][2] = A[2][1]
    
    mov ax, [si+20]     ; A[2][2]
    mov [di+20], ax     ; T[2][2] = A[2][2]
    
    mov ax, [si+22]     ; A[2][3]
    mov [di+28], ax     ; T[3][2] = A[2][3]
    
    ; Fila 3 -> Columna 3
    mov ax, [si+24]     ; A[3][0]
    mov [di+6], ax      ; T[0][3] = A[3][0]
    
    mov ax, [si+26]     ; A[3][1]
    mov [di+14], ax     ; T[1][3] = A[3][1]
    
    mov ax, [si+28]     ; A[3][2]
    mov [di+22], ax     ; T[2][3] = A[3][2]
    
    mov ax, [si+30]     ; A[3][3]
    mov [di+30], ax     ; T[3][3] = A[3][3]
    
    call mostrar_matriz_transpuesta
    
    ret
    
salir_trans:
    ret
transpuesta_matriz ENDP

mostrar_matriz_transpuesta PROC
    mov ax, 0003h
    int 10h         ; Limpia pantalla
    
    mov dh, 2
    mov dl, 35
    call posicionar_cursor
    mov dx, OFFSET tit_trans
    mov ah, 9
    int 21h         ; "OBTENER TRANSPUESTA"
    
    ; Matriz original
    mov dh, 5
    mov dl, 25
    call posicionar_cursor
    mov dx, OFFSET matA
    mov ah, 9
    int 21h         ; "MATRIZ A:"
    
    mov dh, 7
    mov dl, 25
    mov si, OFFSET matrizA
    call imprimir_matriz_formato  ; Imprime matriz original
    
    ; Esperar 'I' para mostrar transpuesta
    call mostrar_y_esperar
    
    cmp mostrar_res, 1
    jne salir_mostrar_trans
    
    ; Mostrar transpuesta
    mov dh, 5
    mov dl, 50
    call posicionar_cursor
    mov dx, OFFSET trans_msg
    mov ah, 9
    int 21h         ; "TRANSPUESTA:"
    
    mov dh, 7
    mov dl, 50
    mov si, OFFSET matrizT
    call imprimir_matriz_formato  ; Imprime transpuesta
    
    call esperar_esc
    
salir_mostrar_trans:
    ret
mostrar_matriz_transpuesta ENDP

; =================================================================
; MULTIPLICACIÓN DE MATRICES - VERSIÓN SIMPLIFICADA
; =================================================================
multiplica_matrices PROC
    mov flag_esc, 0
    
    mov ax, 0003h
    int 10h
    
    mov dh, 2
    mov dl, 32
    call posicionar_cursor
    mov dx, OFFSET tit_mul
    mov ah, 9
    int 21h
    
    mov dh, 5
    mov dl, 10
    call posicionar_cursor
    mov dx, OFFSET matA
    mov ah, 9
    int 21h
    
    mov si, OFFSET matrizA
    call ingresar_matriz
    
    cmp flag_esc, 1
    je salir_mul
    
    mov ax, 0003h
    int 10h
    
    mov dh, 2
    mov dl, 32
    call posicionar_cursor
    mov dx, OFFSET tit_mul
    mov ah, 9
    int 21h
    
    mov dh, 5
    mov dl, 10
    call posicionar_cursor
    mov dx, OFFSET matB
    mov ah, 9
    int 21h
    
    mov si, OFFSET matrizB
    call ingresar_matriz
    
    cmp flag_esc, 1
    je salir_mul
    
    call mostrar_no_multiplicacion
    
    ret
    
salir_mul:
    ret
multiplica_matrices ENDP

mostrar_no_multiplicacion PROC
    
    mov ax, 0003h
    int 10h
    
    mov dh, 2
    mov dl, 35
    call posicionar_cursor
    mov dx, OFFSET tit_mul
    mov ah, 9
    int 21h
    
    mov dh, 5
    mov dl, 15
    call posicionar_cursor
    mov dx, OFFSET matA
    mov ah, 9
    int 21h
    
    mov dh, 7
    mov dl, 15
    mov si, OFFSET matrizA
    call imprimir_matriz_formato
    
    mov dh, 5
    mov dl, 40
    call posicionar_cursor
    mov dx, OFFSET matB
    mov ah, 9
    int 21h
    
    mov dh, 7
    mov dl, 40
    mov si, OFFSET matrizB
    call imprimir_matriz_formato
    
    mov dh, 15
    mov dl, 25
    call posicionar_cursor
    mov dx, OFFSET no_mul
    mov ah, 9
    int 21h
    
    call esperar_esc
    
    ret
mostrar_no_multiplicacion ENDP ; no compila la multiplicacion:/

; =================================================================
; DIAGONAL PRINCIPAL Y SUMA TOTAL
; =================================================================
diagonal_suma PROC
    mov flag_esc, 0
    
    mov ax, 0003h
    int 10h         ; Limpia pantalla
    
    mov dh, 3
    mov dl, 30
    call posicionar_cursor
    mov dx, OFFSET tit_diag
    mov ah, 9
    int 21h         ; "DIAGONAL PRINCIPAL Y SUMA"
    
    mov dh, 5
    mov dl, 10
    call posicionar_cursor
    mov dx, OFFSET matA
    mov ah, 9
    int 21h         ; "MATRIZ A:"
    
    mov si, OFFSET matrizA
    call ingresar_matriz    ; Ingresa matriz A
    
    cmp flag_esc, 1
    je salir_diag
    
    ; Calcular diagonal principal
    ; Elementos de la diagonal: (0,0), (1,1), (2,2), (3,3)
    ; Índices en matriz lineal: 0, 10, 20, 30 (cada índice *2 bytes)
    
    mov ax, [matrizA]    ; Carga elemento (0,0) - índice 0
    mov [matrizR], ax    ; Guarda primer elemento de diagonal en matrizR[0]
    mov bx, ax          ; BX acumula suma de diagonal (comienza con elemento (0,0))
    
    mov ax, [matrizA+10] ; Carga elemento (1,1) - índice 10 (5 elementos * 2 bytes)
    mov [matrizR+2], ax  ; Guarda segundo elemento de diagonal en matrizR[1]
    add bx, ax          ; Suma al acumulador BX
    
    mov ax, [matrizA+20] ; Carga elemento (2,2) - índice 20 (10 elementos * 2 bytes)
    mov [matrizR+4], ax  ; Guarda tercer elemento de diagonal en matrizR[2]
    add bx, ax
    
    mov ax, [matrizA+30] ; Carga elemento (3,3) - índice 30 (15 elementos * 2 bytes)
    mov [matrizR+6], ax  ; Guarda cuarto elemento de diagonal en matrizR[3]
    add bx, ax
    
    ; Calcular suma total de la matriz (todos los elementos)
    mov cx, 16           ; 16 elementos a sumar
    mov si, OFFSET matrizA ; Apunta al inicio de la matriz
    mov ax, 0            ; Inicializa acumulador en 0
    
sumar_matriz:
    add ax, [si]         ; Suma elemento actual
    add si, 2            ; Avanza al siguiente elemento (2 bytes)
    loop sumar_matriz    ; Repite 16 veces
    
    mov suma_total, ax   ; Guarda suma total
    
    ; Mostrar resultado
    call mostrar_matriz_diagonal
    
    ret
    
salir_diag:
    ret
diagonal_suma ENDP

mostrar_matriz_diagonal PROC
    mov ax, 0003h
    int 10h         ; Limpia pantalla
    
    mov dh, 2
    mov dl, 35
    call posicionar_cursor
    mov dx, OFFSET tit_diag
    mov ah, 9
    int 21h         ; Título
    
    ; Matriz A completa
    mov dh, 5
    mov dl, 35
    call posicionar_cursor
    mov dx, OFFSET matA
    mov ah, 9
    int 21h         ; "MATRIZ A:"
    
    mov dh, 7
    mov dl, 30
    mov si, OFFSET matrizA
    call imprimir_matriz_formato  ; Imprime matriz completa
    
    ; Esperar 'I' para mostrar diagonal y sumas
    call mostrar_y_esperar
    
    cmp mostrar_res, 1
    jne salir_mostrar_diag  ; Si no presionó 'I', sale
    
    ; Mostrar diagonal principal
    mov dh, 14
    mov dl, 30
    call posicionar_cursor
    mov dx, OFFSET diag_msg
    mov ah, 9
    int 21h         ; "Diagonal: "
    
    mov dh, 14
    mov dl, 42
    call posicionar_cursor
    
    mov cx, 4       ; 4 elementos de la diagonal
    mov si, OFFSET matrizR  ; Apunta a donde guardamos los elementos diagonales
mostrar_diag_valores:
    mov ax, [si]    ; Carga elemento de la diagonal
    call imprimir_numero_fijo  ; Imprime con formato
    add si, 2       ; Siguiente elemento
    loop mostrar_diag_valores
    
    ; Mostrar suma de la diagonal
    mov dh, 16
    mov dl, 30
    call posicionar_cursor
    mov dx, OFFSET sum_diag
    mov ah, 9
    int 21h         ; "Suma de la Diagonal: "
    
    mov dh, 16
    mov dl, 52
    call posicionar_cursor
    mov ax, bx      ; BX tenía la suma de la diagonal
    call imprimir_numero_fijo
    
    ; Mostrar suma total de la matriz
    mov dh, 18
    mov dl, 30
    call posicionar_cursor
    mov dx, OFFSET sum_matriz
    mov ah, 9
    int 21h         ; "Suma de la Matriz: "
    
    mov dh, 18
    mov dl, 52
    call posicionar_cursor
    mov ax, suma_total  ; Carga suma total
    call imprimir_numero_fijo
    
    ; Esperar ESC para regresar al menú
    call esperar_esc

salir_mostrar_diag:
    ret
mostrar_matriz_diagonal ENDP

; =================================================================
; SUMA DE COLUMNAS
; =================================================================
suma_columnas PROC
    mov flag_esc, 0
    
    mov ax, 0003h
    int 10h         ; Limpia pantalla
    
    mov dh, 2
    mov dl, 25
    call posicionar_cursor
    mov dx, OFFSET tit_sumcol
    mov ah, 9
    int 21h         ; "SUMA DE COLUMNAS DE UNA MATRIZ"
    
    mov dh, 5
    mov dl, 10
    call posicionar_cursor
    mov dx, OFFSET matA
    mov ah, 9
    int 21h         ; "MATRIZ A:"
    
    mov si, OFFSET matrizA
    call ingresar_matriz    ; Ingresa matriz A
    
    cmp flag_esc, 1
    je salir_sumcol
    
    ; Calcular suma de columnas
    ; Columna 0: elementos (0,0), (1,0), (2,0), (3,0)
    ; Índices: 0, 8, 16, 24 (cada fila tiene 4 elementos * 2 bytes = 8 bytes)
    mov ax, [matrizA]    ; Elemento (0,0)
    add ax, [matrizA+8]  ; + Elemento (1,0)
    add ax, [matrizA+16] ; + Elemento (2,0)
    add ax, [matrizA+24] ; + Elemento (3,0)
    mov [sumas_col], ax   ; Guarda suma columna 0
    
    ; Columna 1: elementos (0,1), (1,1), (2,1), (3,1)
    ; Índices: 2, 10, 18, 26
    mov ax, [matrizA+2]  ; Elemento (0,1)
    add ax, [matrizA+10] ; + Elemento (1,1)
    add ax, [matrizA+18] ; + Elemento (2,1)
    add ax, [matrizA+26] ; + Elemento (3,1)
    mov [sumas_col+2], ax ; Guarda suma columna 1
    
    ; Columna 2: elementos (0,2), (1,2), (2,2), (3,2)
    ; Índices: 4, 12, 20, 28
    mov ax, [matrizA+4]  ; Elemento (0,2)
    add ax, [matrizA+12] ; + Elemento (1,2)
    add ax, [matrizA+20] ; + Elemento (2,2)
    add ax, [matrizA+28] ; + Elemento (3,2)
    mov [sumas_col+4], ax ; Guarda suma columna 2
    
    ; Columna 3: elementos (0,3), (1,3), (2,3), (3,3)
    ; Índices: 6, 14, 22, 30
    mov ax, [matrizA+6]  ; Elemento (0,3)
    add ax, [matrizA+14] ; + Elemento (1,3)
    add ax, [matrizA+22] ; + Elemento (2,3)
    add ax, [matrizA+30] ; + Elemento (3,3)
    mov [sumas_col+6], ax ; Guarda suma columna 3
    
    ; Mostrar resultado
    call mostrar_matriz_columnas
    
    ret
    
salir_sumcol:
    ret
suma_columnas ENDP

mostrar_matriz_columnas PROC
    mov ax, 0003h
    int 10h         ; Limpia pantalla
    
    mov dh, 2
    mov dl, 35
    call posicionar_cursor
    mov dx, OFFSET tit_sumcol
    mov ah, 9
    int 21h         ; Título
    
    ; Matriz A completa
    mov dh, 5
    mov dl, 35
    call posicionar_cursor
    mov dx, OFFSET matA
    mov ah, 9
    int 21h         ; "MATRIZ A:"
    
    mov dh, 7
    mov dl, 30
    mov si, OFFSET matrizA
    call imprimir_matriz_formato  ; Imprime matriz completa
    
    ; Esperar 'I' para mostrar sumas de columnas
    call mostrar_y_esperar
    
    cmp mostrar_res, 1
    jne salir_mostrar_col  ; Si no presionó 'I', sale
    
    ; Mostrar etiquetas de columnas
    mov dh, 14
    mov dl, 35
    call posicionar_cursor
    mov dx, OFFSET col_labels
    mov ah, 9
    int 21h         ; "C1  C2  C3  C4"
    
    ; Mostrar sumas de columnas
    mov dh, 15
    mov dl, 35
    call posicionar_cursor
    
    mov cx, 4       ; 4 columnas
    mov si, OFFSET sumas_col  ; Apunta a las sumas
mostrar_sum_col:
    mov ax, [si]    ; Carga suma de columna
    call imprimir_numero_fijo  ; Imprime con formato
    add si, 2       ; Siguiente suma
    loop mostrar_sum_col
    
    ; Mostrar mensaje "Suma Columnas"
    mov dh, 17
    mov dl, 30
    call posicionar_cursor
    mov dx, OFFSET sum_col_msg
    mov ah, 9
    int 21h         ; "Suma Columnas: "
    
    ; Esperar ESC para regresar al menú
    call esperar_esc

salir_mostrar_col:
    ret
mostrar_matriz_columnas ENDP

; =================================================================
; SUMA DE RENGLONES
; =================================================================
suma_renglones PROC
    mov flag_esc, 0
    
    mov ax, 0003h
    int 10h         ; Limpia pantalla
    
    mov dh, 2
    mov dl, 25
    call posicionar_cursor
    mov dx, OFFSET tit_sumrow
    mov ah, 9
    int 21h         ; "SUMA DE RENGLONES DE UNA MATRIZ"
    
    mov dh, 5
    mov dl, 10
    call posicionar_cursor
    mov dx, OFFSET matA
    mov ah, 9
    int 21h         ; "MATRIZ A:"
    
    mov si, OFFSET matrizA
    call ingresar_matriz    ; Ingresa matriz A
    
    cmp flag_esc, 1
    je salir_sumrow
    
    ; Calcular suma de renglones (filas)
    ; Renglón 0: elementos (0,0), (0,1), (0,2), (0,3)
    ; Índices: 0, 2, 4, 6 (4 elementos consecutivos)
    mov ax, [matrizA]    ; Elemento (0,0)
    add ax, [matrizA+2]  ; + Elemento (0,1)
    add ax, [matrizA+4]  ; + Elemento (0,2)
    add ax, [matrizA+6]  ; + Elemento (0,3)
    mov [sumas_row], ax   ; Guarda suma fila 0
    
    ; Renglón 1: elementos (1,0), (1,1), (1,2), (1,3)
    ; Índices: 8, 10, 12, 14
    mov ax, [matrizA+8]  ; Elemento (1,0)
    add ax, [matrizA+10] ; + Elemento (1,1)
    add ax, [matrizA+12] ; + Elemento (1,2)
    add ax, [matrizA+14] ; + Elemento (1,3)
    mov [sumas_row+2], ax ; Guarda suma fila 1
    
    ; Renglón 2: elementos (2,0), (2,1), (2,2), (2,3)
    ; Índices: 16, 18, 20, 22
    mov ax, [matrizA+16] ; Elemento (2,0)
    add ax, [matrizA+18] ; + Elemento (2,1)
    add ax, [matrizA+20] ; + Elemento (2,2)
    add ax, [matrizA+22] ; + Elemento (2,3)
    mov [sumas_row+4], ax ; Guarda suma fila 2
    
    ; Renglón 3: elementos (3,0), (3,1), (3,2), (3,3)
    ; Índices: 24, 26, 28, 30
    mov ax, [matrizA+24] ; Elemento (3,0)
    add ax, [matrizA+26] ; + Elemento (3,1)
    add ax, [matrizA+28] ; + Elemento (3,2)
    add ax, [matrizA+30] ; + Elemento (3,3)
    mov [sumas_row+6], ax ; Guarda suma fila 3
    
    ; Mostrar resultado
    call mostrar_matriz_renglones
    
    ret
    
salir_sumrow:
    ret
suma_renglones ENDP

mostrar_matriz_renglones PROC
    mov ax, 0003h
    int 10h         ; Limpia pantalla
    
    mov dh, 2
    mov dl, 35
    call posicionar_cursor
    mov dx, OFFSET tit_sumrow
    mov ah, 9
    int 21h         ; Título
    
    ; Matriz A completa
    mov dh, 5
    mov dl, 35
    call posicionar_cursor
    mov dx, OFFSET matA
    mov ah, 9
    int 21h         ; "MATRIZ A:"
    
    mov dh, 7
    mov dl, 30
    mov si, OFFSET matrizA
    call imprimir_matriz_formato  ; Imprime matriz completa
    
    ; Esperar 'I' para mostrar sumas de renglones
    call mostrar_y_esperar
    
    cmp mostrar_res, 1
    jne salir_mostrar_row  ; Si no presionó 'I', sale
    
    ; Mostrar etiquetas de renglones
    mov dh, 14
    mov dl, 30
    call posicionar_cursor
    mov dx, OFFSET row_labels
    mov ah, 9
    int 21h         ; "F1  F2  F3  F4"
    
    ; Mostrar sumas de renglones
    mov dh, 15
    mov dl, 30
    call posicionar_cursor
    
    mov cx, 4       ; 4 filas
    mov si, OFFSET sumas_row  ; Apunta a las sumas
mostrar_sum_row:
    mov ax, [si]    ; Carga suma de fila
    call imprimir_numero_fijo  ; Imprime con formato
    add si, 2       ; Siguiente suma
    loop mostrar_sum_row
    
    ; Mostrar mensaje "Suma Filas"
    mov dh, 17
    mov dl, 30
    call posicionar_cursor
    mov dx, OFFSET sum_row_msg
    mov ah, 9
    int 21h         ; "Suma Filas: "
    
    ; Esperar ESC para regresar al menú
    call esperar_esc

salir_mostrar_row:
    ret
mostrar_matriz_renglones ENDP

END START