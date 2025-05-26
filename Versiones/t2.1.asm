;============================================================
; ASCII RACING - Juego de carreras en consola usando TASM
; Plataforma: DOS 16-bit (usar con DOSBox o Extension de TASM)
; Autor: Dairo Rodriguez - Versión 2.1
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
MAX_OBS       equ 5 ; Máximo de obstáculos
PISTA_IZQ     equ 15 ; Límite izquierdo de la pista
PISTA_DER     equ 35 ; Límite derecho de la pista
CHAR_AUTO     equ 'A' ; Carácter que representa el auto
CHAR_OBS      equ '#'; Carácter que representa el obstáculo
SCREEN_HEIGHT equ 25
AUTO_Y        equ 24       ; Fila fija del auto
MIN_SPEED     equ 1      ; Límite mínimo para la velocidad

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

ShowStartScreen proc
    call ClearScreen
    ; Mostrar título
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

ClearScreen proc
    mov ah, 0
    mov al, 3
    int 10h
    ret
ClearScreen endp

DrawBorders proc
    mov dh, 0              ; Fila inicial
BucleBordes:
    ; Lado izquierdo
    mov ah, 02h            ; Función: mover cursor
    mov bh, 0              ; Página 0
    mov dl, PISTA_IZQ      ; Columna izquierda
    int 10h

    mov ah, 09h            ; Función: imprimir carácter
    mov al, '|'            ; Carácter del borde
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


DrawCar proc
    mov ah, 02h
    mov bh, 0
    mov dh, AUTO_Y
    mov dl, carX
    int 10h
    mov ah, 09h
    mov al, CHAR_AUTO
    mov bl, 10
    mov cx, 1
    int 10h
    ret
DrawCar endp

DrawObstacles proc
    mov si, 0
DibujarLoop:
    mov al, obsY[si] ; Obtener la posición del obstáculo
    mov ah, 02h ; Función para mover el cursor
    mov bh, 0 ; Página de pantalla
    mov dh, al ; Fila del obstáculo
    mov dl, obsX[si] ; Columna del obstáculo
    int 10h ; Mover el cursor a la posición del obstáculo
    mov ah, 09h ; Mostrar obstáculo
    mov al, CHAR_OBS ; Carácter del obstáculo
    mov bl, 12 ; Color del obstáculo
    mov cx, 1 ; Número de caracteres a mostrar
    int 10h ; Dibujar el obstáculo
    inc si ; Pasar al siguiente obstáculo
    cmp si, MAX_OBS ; Verificar si hay más obstáculos
    jl DibujarLoop ; Si hay más, repetir
    ret ; Fin de la subrutina
DrawObstacles endp

UpdateObstacles proc
    mov si, 0
ActualizarLoop:
    inc obsY[si]
    cmp obsY[si], 24
    jbe SinReiniciar

    ; Reiniciar obstáculo
    mov obsY[si], 0
GenerarNuevo:
    mov ah, 0
    int 1Ah
    mov al, dl
    and al, 15
    add al, PISTA_IZQ + 1
    cmp al, PISTA_DER - 1
    jbe GuardarObs
    jmp GenerarNuevo
GuardarObs:
    mov obsX[si], al ; Asignar nueva posición al obstáculo
    ; Puntaje y dificultad
    inc score ; Incrementar puntaje
    mov ax, score ; Verificar puntaje
    xor dx, dx ; Limpiar dx
    mov bx, 10 ; Divisor para puntaje
    div bx ; Dividir puntaje por 10
    cmp dx, 0 ; Si el resto es 0, aumentar velocidad
    jne SinReiniciar ; Aumentar velocidad cada 10 puntos
    cmp speed, MIN_SPEED ; Verificar límite de velocidad
    jbe SinReiniciar ; Si la velocidad es menor o igual al mínimo, no hacer nada
    sub speed, 2 ; Reducir velocidad
SinReiniciar:
    inc si
    cmp si, MAX_OBS
    jl ActualizarLoop
    ret
UpdateObstacles endp

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
NoCheck: ; Si no hay colisión
    inc si
    cmp si, MAX_OBS
    jl CollisionLoop
    ret
CheckCollision endp

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

InitGame proc
    mov carX, 25
    mov score, 0
    mov speed, 5
    mov cl, 0
    xor si, si          ; Asegura que si = 0

InitLoop:
    mov obsY[si], 0     ; Todos los obstáculos empiezan desde fila 0

GenerarColumna:
    mov ah, 0
    int 1Ah             ; Usar reloj para obtener valor "aleatorio"
    mov al, dl
    and al, 15          ; Limitar el rango
    add al, PISTA_IZQ + 1
    cmp al, PISTA_DER - 1
    jbe ColumnaOK
    jmp GenerarColumna

ColumnaOK:
    mov obsX[si], al
    inc si
    cmp si, MAX_OBS
    jl InitLoop
    ret
InitGame endp

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