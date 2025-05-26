;============================================================
; ASCII RACING - Juego de carreras en consola usando TASM
; Plataforma: DOS 16-bit (usar con DOSBox o Extension de TASM)
; Autor: Dairo Rodriguez - Versi?n 2.2
;============================================================
.model small
.stack 100h
.data

; --- Textos de la interfaz ---
titleText db '== CARRERA ASCII == $', 0
instr1 db 'Usa las flechas IZQUIERDA y DERECHA para mover el auto. $', 0
instr2 db 'Evita los obstaculos que caen. $', 0
instr3 db 'Presiona ESPACIO para comenzar. $', 0
gameOverMsg db 'COLISION FIN DEL JUEGO$', 0
retryMsg    db 'Presiona r para reintentar o ESC para salir. $', 0
msgPuntaje  db 'Puntaje: $'

; --- Constantes ---
MAX_OBS       equ 3 ; M?ximo de obst?culos
PISTA_IZQ     equ 15 ; L?mite izquierdo de la pista
PISTA_DER     equ 32 ; L?mite derecho de la pista
CHAR_AUTO     equ 'A' ; Car?cter que representa el auto
CHAR_OBS      equ '#'; Car?cter que representa el obst?culo
SCREEN_HEIGHT equ 25
AUTO_Y        equ 24 ; Fila fija del auto
MIN_SPEED     equ 1  ; L?mite m?nimo para la velocidad

; --- Variables ---
carX        db 20
score       dw 0
speed       dw 0
obsX        db MAX_OBS dup(0)  
obsY        db MAX_OBS dup(0)

.code
start:
    mov ax, @data
    mov ds, ax

    call ShowStartScreen
    call InitGame
    jmp MainLoop

MainLoop:
    call ClearScreen
    call ShowScore
    call DrawBorders
    call DrawCar
    call DrawObstacles
    call UpdateObstacles
    call CheckCollision
    call CheckKeyInput
    call WaitDynamic
    jmp MainLoop

; ------------------------------------------------------------
; Subrutinas
; ------------------------------------------------------------

; Mostrar pantalla de inicio
; ------------------------------------------------------------
ShowStartScreen proc
    call ClearScreen
    ; Mostrar t?tulo
    mov ah, 02h
    xor bh, bh
    mov dh, 5
    mov dl, 30
    int 10h

    mov ah, 09h
    mov dx, offset titleText
    int 21h

    ; Mostrar instrucciones
    mov ah, 02h
    mov dh, 8
    mov dl, 10
    int 10h

    mov ah, 09h
    mov dx, offset instr1
    int 21h

    mov ah, 02h
    mov dh, 10
    int 10h
    mov ah, 09h
    mov dx, offset instr2
    int 21h

    mov ah, 02h
    mov dh, 12
    int 10h
    mov ah, 09h
    mov dx, offset instr3
    int 21h

WaitStartKey:
    mov ah, 00h
    int 16h
    cmp al, 32
    jne WaitStartKey
    ret
ShowStartScreen endp

; Limpiar pantalla
; ------------------------------------------------------------
ClearScreen proc
    mov ah, 0
    mov al, 3
    int 10h
    ret
ClearScreen endp

; Dibujar bordes de la pista
; ------------------------------------------------------------
DrawBorders proc
    mov dh, 0              ; Fila inicial
BucleBordes:
    ; Lado izquierdo
    mov ah, 02h            ; Funci?n: mover cursor
    mov bh, 0              ; P?gina 0
    mov dl, PISTA_IZQ      ; Columna izquierda
    int 10h

    mov ah, 09h            ; Funci?n: imprimir car?cter
    mov al, '|'            ; Car?cter del borde
    mov bl, 14              ; Color
    mov cx, 1
    int 10h

    ; Lado derecho
    mov ah, 02h
    mov dl, PISTA_DER      ; Columna derecha
    int 10h

    mov ah, 09h
    mov al, '|'
    mov bl, 14
    mov cx, 1
    int 10h

    inc dh                ; Siguiente fila
    cmp dh, SCREEN_HEIGHT
    jb BucleBordes        ; Repite hasta dh < SCREEN_HEIGHT
    ret
DrawBorders endp

; Dibujar el auto
; ------------------------------------------------------------
DrawCar proc
    mov ah, 02h ; Funci?n para mover el cursor
    mov bh, 0
    mov dh, AUTO_Y ; Fila del auto
    mov dl, carX ; Columna del auto
    int 10h ; Mover el cursor a la posici?n del auto
    mov ah, 09h ; Funci?n para mostrar el auto
    mov al, CHAR_AUTO ; Car?cter del auto
    mov bl, 10 ; Color del auto
    mov cx, 1 ; N?mero de caracteres a mostrar
    int 10h ; Dibujar el auto
    ret
DrawCar endp

; Dibujar obst?culos
; ------------------------------------------------------------
DrawObstacles proc
    mov si, 0
DibujarLoop:
    mov al, obsY[si] ; Obtener la posici?n del obst?culo
    mov ah, 02h ; Funci?n para mover el cursor
    mov bh, 0 ; P?gina de pantalla
    mov dh, al ; Fila del obst?culo
    mov dl, obsX[si] ; Columna del obst?culo
    int 10h ; Mover el cursor a la posici?n del obst?culo
    mov ah, 09h ; Mostrar obst?culo
    mov al, CHAR_OBS ; Car?cter del obst?culo
    mov bl, 12 ; Color del obst?culo
    mov cx, 1 ; N?mero de caracteres a mostrar
    int 10h ; Dibujar el obst?culo
    inc si ; Pasar al siguiente obst?culo
    cmp si, MAX_OBS ; Verificar si hay m?s obst?culos
    jl DibujarLoop ; Si hay m?s, repetir
    ret ; Fin de la subrutina
DrawObstacles endp

; Actualizar obst?culos
; ------------------------------------------------------------
UpdateObstacles proc
    xor si, si
ActualizarLoop:
    inc obsY[si]
    cmp obsY[si], 24
    jbe SinReiniciar

    ; Reiniciar obst?culo
    mov byte ptr obsY[si], 0
GenerarNuevo:
    mov ah, 0
    int 1Ah
    mov al, dl
    mov bx, si
    add al, bl
    and al, 15
    add al, PISTA_IZQ + 1
    cmp al, PISTA_DER - 1
    jbe GuardarObs
    jmp GenerarNuevo
GuardarObs:
    mov byte ptr obsX[si], al ; Asignar nueva posici?n al obst?culo
    ; Puntaje y dificultad
    inc score ; Incrementar puntaje
    mov ax, score ; Verificar puntaje
    xor dx, dx ; Limpiar dx
    mov bx, 10 ; Divisor para puntaje
    div bx ; Dividir puntaje por 10
    cmp dx, 0 ; Si el resto es 0, aumentar velocidad
    jne SinReiniciar ; Aumentar velocidad cada 10 puntos
    cmp speed, MIN_SPEED ; Verificar l?mite de velocidad
    jbe SinReiniciar ; Si la velocidad es menor o igual al m?nimo, no hacer nada
    sub speed, 2 ; Reducir velocidad
SinReiniciar:
    inc si
    cmp si, MAX_OBS
    jl ActualizarLoop
    ret
UpdateObstacles endp

; Mostrar puntaje en pantalla
; ------------------------------------------------------------
ShowScore proc
    mov ah, 02h
    mov bh, 0
    mov dh, 0
    mov dl, 0
    int 10h
    mov ah, 09h
    lea dx, msgPuntaje
    int 21h
    mov ax, score
    call PrintNumber
    ret
ShowScore endp

; Verificar entrada de teclado
; ------------------------------------------------------------
CheckKeyInput proc
    mov ah, 01h
    int 16h
    jz NoInput
    mov ah, 00h
    int 16h
    cmp ah, 4Bh
    je MoverIzquierda
    cmp ah, 4Dh
    je MoverDerecha
    cmp ah, 01h
    je Exit
    cmp al, 'r'
    je Restart
NoInput:
    ret

MoverIzquierda:
    cmp carX, PISTA_IZQ + 1
    jbe NoInput
    dec carX
    ret

MoverDerecha:
    cmp carX, PISTA_DER - 1
    jae NoInput
    inc carX
    ret

Restart:
    jmp start

Exit:
    mov ax, 4C00h
    int 21h
CheckKeyInput endp

; 1. Verificar colisi?n con obst?culos
; 2. Verifica que el auto no colisione con los obst?culos
; 3. Verifica que el auto no se salga de la pista
; ------------------------------------------------------------
CheckCollision proc
    mov si, 0
CollisionLoop:
    mov al, obsY[si]
    cmp al, AUTO_Y
    jne NoCheck
    mov al, carX
    cmp obsX[si], al
    jne NoCheck
    call GameOverScreen
    ret
NoCheck: ; Si no hay colisi?n
    inc si
    cmp si, MAX_OBS
    jl CollisionLoop
    ret
CheckCollision endp

; Mostrar pantalla de fin de juego
; ------------------------------------------------------------
GameOverScreen proc
    call ClearScreen

    ; Mostrar mensaje de fin de juego
    mov ah, 02h
    mov bh, 0
    mov dh, 8
    mov dl, 25
    int 10h
    mov ah, 09h
    mov dx, offset gameOverMsg
    int 21h

    ; Mostrar puntaje final
    mov ah, 02h
    mov dh, 10
    mov dl, 25
    int 10h
    mov ah, 09h
    lea dx, msgPuntaje
    int 21h
    mov ax, score
    call PrintNumber

    ;Instrucciones para reintentar o salir
    mov ah, 02h
    mov dh, 12
    mov dl, 10
    int 10h
    mov ah, 09h
    mov dx, offset retryMsg
    int 21h
WaitChoice:
    mov ah, 00h
    int 16h
    cmp al, 'r'
    je Restart
    cmp al, 27
    je Exit
    jmp WaitChoice
GameOverScreen endp

; Espera un tiempo din?mico basado en la velocidad
; ------------------------------------------------------------
WaitDynamic proc
    mov cx, speed
OuterLoop:
    mov dx, 0FFFFh
InnerLoop:
    dec dx
    jnz InnerLoop
    loop OuterLoop
    ret
WaitDynamic endp

; Inicializar el juego
; ------------------------------------------------------------
InitGame proc
    mov carX, 25
    mov score, 0
    mov speed, 5
    xor si, si          ; Asegura que cl = 0

InitLoop:
    mov byte ptr obsY[si], 0     ; Todos los obst?culos empiezan desde fila 0

GenerarColumna:
    mov ah, 0
    int 1Ah             ; Usar reloj para obtener valor "aleatorio"
    mov al, dl
    mov bx, si
    add al, bl          ; Asegurar que el valor sea ?nico para cada obst?culo
    and al, 5          ; Limitar el rango
    add al, PISTA_IZQ + 1
    cmp al, PISTA_DER - 1
    jbe ColumnaOK
    jmp GenerarColumna

ColumnaOK:
    mov byte ptr obsX[si], al
    inc si
    cmp si, MAX_OBS
    jl InitLoop
    ret
InitGame endp

; Imprimir n?mero en pantalla
; ------------------------------------------------------------
PrintNumber proc
    push ax
    push bx
    push cx
    push dx

    mov bx, 10
    xor cx, cx
    cmp ax, 0
    jne LoopDiv
    mov dl, '0'
    mov ah, 02h
    int 21h
    jmp SalirPrint
LoopDiv:
    xor dx, dx
    div bx
    push dx
    inc cx
    cmp ax, 0
    jne LoopDiv
MostrarDig:
    pop dx
    add dl, '0'
    mov ah, 02h
    int 21h
    loop MostrarDig
SalirPrint:
    pop dx
    pop cx
    pop bx
    pop ax
    ret
PrintNumber endp

end start