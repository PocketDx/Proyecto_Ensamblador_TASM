; ================================================
; ASCII Racing Game - main.asm
; Versión inicial: movimiento lateral del auto
; Autor: Dairo
; ================================================

.model small
.stack 100h

MAX_OBS equ 5     ; Máximo número de obstáculos

.data
    carPos db 40       ; Posición X inicial del auto (columna)
    carY   db 23       ; Fila fija del auto (abajo del todo)
    crashMsg db 'Colisión, Fin del juego.$'
    obstacles db MAX_OBS * 2 dup(0) ; Arreglo: obstáculos (X, Y)
    score dw 0
    scoreText db 'Puntaje: ', 0

.code
start:
    mov ax, @data
    mov ds, ax

MainLoop:
    call ClearScreen
    call DrawCar
    call DrawObstacles
    call UpdateObstacles
    call CheckCollision
    call ShowCrash
    call RandomX         ; Generar obstáculos nuevos
    call ShowScore
    call PrintNum
    call ReadKey
    jmp MainLoop

; ----------------------------
; Rutina: ClearScreen
; Limpia la pantalla (modo texto 80x25)
; ----------------------------
ClearScreen proc
    mov ah, 0          ; Función 0: Set video mode
    mov al, 3          ; Modo 3: texto 80x25 color
    int 10h
    ret
ClearScreen endp

; ----------------------------
; Rutina: DrawCar
; Imprime el auto en pantalla en la posición actual
; ----------------------------
DrawCar proc
    mov ah, 02h                ; Función: mover cursor
    xor bh, bh                 ; Página 0
    mov dh, carY               ; Fila
    mov dl, carPos             ; Columna
    int 10h

    mov ah, 09h                ; Función: imprimir carácter
    mov al, 'A'                ; Símbolo del auto
    mov bh, 0                  ; Página 0
    mov bl, 0Ah                ; Atributo (verde claro)
    mov cx, 1
    int 10h
    ret
DrawCar endp

; ----------------------------
; Rutina: ReadKey
; Lee una tecla (sin eco) y mueve el auto
; ----------------------------
ReadKey proc
    mov ah, 00h
    int 16h                    ; Espera una tecla

    cmp ah, 4Bh                ; Flecha izquierda
    je MoverIzquierda
    cmp ah, 4Dh                ; Flecha derecha
    je MoverDerecha
    cmp al, 27                 ; ESC (salir)
    je Salir
    ret

MoverIzquierda:
    cmp carPos, 30             ; Límite izquierdo
    jbe NoMoveLeft
    dec carPos
NoMoveLeft:
    ret

MoverDerecha:
    cmp carPos, 49             ; Límite derecho
    jae NoMoveRight
    inc carPos
NoMoveRight:
    ret

Salir:
    mov ah, 4Ch
    int 21h
ReadKey endp

; ----------------------------
; Dibuja todos los obstáculos actuales
; ----------------------------
DrawObstacles proc
    mov si, 0
DrawObsLoop:
    cmp si, MAX_OBS
    jge EndDrawObs

    mov bx, si
    shl bx, 1          ; BX = si * 2 (cada obstáculo son 2 bytes)

    ; Coordenadas
    mov dl, [obstacles + bx]      ; X
    mov dh, [obstacles + bx + 1]  ; Y

    ; Solo dibujar si está dentro del rango visible
    cmp dh, 24
    jg NextObs

    ; Mueve cursor
    mov ah, 02h
    xor bh, bh
    int 10h

    ; Dibuja carácter
    mov ah, 09h
    mov al, 'X'
    mov bh, 0
    mov bl, 0Ch      ; Rojo claro
    mov cx, 1
    int 10h

NextObs:
    inc si
    jmp DrawObsLoop
EndDrawObs:
    ret
DrawObstacles endp

; ----------------------------
; Mueve obstáculos hacia abajo (Y++)
; Si se salen, reiniciarlos arriba
; ----------------------------
UpdateObstacles proc
    mov si, 0
UpdObsLoop:
    cmp si, MAX_OBS
    jge EndUpdObs

    mov bx, si
    shl bx, 1

    ; Y++
    inc byte ptr [obstacles + bx + 1]

    ; Si Y > 24, reiniciar
    mov al, [obstacles + bx + 1]
    cmp al, 24
    jbe NextUpd

    ; Reiniciar Y y X aleatorio
    mov byte ptr [obstacles + bx + 1], 1
    call RandomX
    mov [obstacles + bx], al
    inc score         ; Incrementar puntaje

NextUpd:
    inc si
    jmp UpdObsLoop
EndUpdObs:
    ret
UpdateObstacles endp


; ----------------------------
; Verifica si algún obstáculo colisiona con el auto
; ----------------------------
CheckCollision proc
    mov si, 0
CheckLoop:
    cmp si, MAX_OBS
    jge EndCheck

    mov bx, si
    shl bx, 1         ; BX = si * 2

    ; Cargar posición del obstáculo
    mov al, [obstacles + bx]       ; X
    mov ah, [obstacles + bx + 1]   ; Y

    ; Comparar Y con carY
    cmp ah, carY
    jne NextCheck

    ; Comparar X con carPos
    cmp al, carPos
    je GameOver         ; Colisión directa

    ; (Opcional: margen de error)
    mov bl, carPos
    sub bl, 1
    cmp al, bl
    je GameOver

    mov bl, carPos
    add bl, 1
    cmp al, bl
    je GameOver

NextCheck:
    inc si
    jmp CheckLoop

EndCheck:
    ret

GameOver:
    call ShowCrash
    mov ah, 4Ch
    int 21h
CheckCollision endp


; ----------------------------
; Muestra mensaje de colisión
; ----------------------------
ShowCrash proc
    ; Limpiar pantalla
    mov ah, 0
    mov al, 3
    int 10h

    ; Posicionar cursor al centro
    mov ah, 02h
    xor bh, bh
    mov dh, 12
    mov dl, 30
    int 10h

    ; Mostrar mensaje
    mov ah, 09h
    mov dx, offset crashMsg
    int 21h
    ret
ShowCrash endp


; ----------------------------
; Genera número aleatorio entre 30 y 49
; (usando reloj del sistema)
; ----------------------------
RandomX proc
    mov ah, 2Ch
    int 21h           ; Get system time

    ; AL = segundos (0-59)
    xor ah, ah
    mov bl, 20
    div bl            ; AL = 0..19
    add al, 30        ; Ajustamos al rango 30-49
    ret
RandomX endp

; ----------------------------
; Muestra el puntaje actual en la parte superior
; ----------------------------
ShowScore proc
    ; Mostrar texto "Puntaje:"
    mov ah, 02h
    xor bh, bh
    mov dh, 0      ; fila
    mov dl, 2      ; columna
    int 10h

    mov ah, 09h
    mov dx, offset scoreText
    int 21h

    ; Mostrar número del puntaje
    ; Convertimos el número a caracteres (0-9999)
    mov ax, score
    call PrintNum

    ret
ShowScore endp

; ----------------------------
; Imprime AX como número decimal en pantalla
; ----------------------------
PrintNum proc
    push ax
    push bx
    push cx
    push dx

    mov cx, 0        ; Contador de dígitos
    mov bx, 10

NextDigit:
    xor dx, dx
    div bx           ; AX ÷ 10 → AL=cociente, AH=resto
    push dx          ; Guardamos el dígito
    inc cx
    test ax, ax
    jnz NextDigit

    ; Imprimir los dígitos (desde la pila)
PrintLoop:
    pop dx
    add dl, '0'
    mov ah, 02h
    int 21h
    loop PrintLoop

    pop dx
    pop cx
    pop bx
    pop ax
    ret
PrintNum endp


end start