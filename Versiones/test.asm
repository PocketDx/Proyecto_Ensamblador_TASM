;============================================================
; ASCII RACING - Juego de carreras en consola usando TASM
; Plataforma: DOS 16-bit (usar con DOSBox)
; Autor: Dairo - Ensamblador educativo
;============================================================

.model small
.stack 100h
.data

titleText db '== CARRERA ASCII ==', 0
instr1 db 'Usa las flechas IZQUIERDA y DERECHA para mover el auto.', 0
instr2 db 'Evita los obstaculos que caen.', 0
instr3 db 'Presiona ESPACIO para comenzar.', 0

gameOverMsg db '¡COLISION! FIN DEL JUEGO', 0
retryMsg    db 'Presiona R para reintentar o ESC para salir.', 0


; --- Constantes ---
MAX_OBS     equ 5       ; Máximo número de obstáculos
PISTA_IZQ   equ 20      ; Límite izquierdo de la pista
PISTA_DER   equ 60      ; Límite derecho de la pista
CHAR_AUTO   equ 'A'     ; Carácter que representa el auto
CHAR_OBS    equ '#'     ; Carácter que representa el obstáculo
SCREEN_HEIGHT equ 25

; --- Variables ---
carX        db 40       ; Posición horizontal del auto
score       dw 0        ; Puntaje del jugador
speed       dw 1000     ; Velocidad inicial (valor de retardo)

obsX        db MAX_OBS dup(0)  ; Posiciones X de obstáculos
obsY        db MAX_OBS dup(0)  ; Posiciones Y de obstáculos

msgPuntaje  db 'Puntaje: $'

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
    call ReadKey
    call WaitDynamic
    jmp MainLoop

;============================================================
; Subrutinas principales
;============================================================

; ----------------------------
; Muestra la pantalla de inicio
; ----------------------------
ShowStartScreen proc
    call ClearScreen

    ; Mostrar título
    mov ah, 02h
    xor bh, bh
    mov dh, 5       ; fila
    mov dl, 30      ; columna
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
    mov dl, 10
    int 10h

    mov ah, 09h
    mov dx, offset instr2
    int 21h

    mov ah, 02h
    mov dh, 12
    mov dl, 10
    int 10h

    mov ah, 09h
    mov dx, offset instr3
    int 21h

    ; Esperar que el jugador presione ESPACIO
WaitStartKey:
    mov ah, 00h
    int 16h
    cmp al, 32          ; Código ASCII de ESPACIO
    jne WaitStartKey

    ret
ShowStartScreen endp

; Limpiar pantalla
ClearScreen proc
    mov ah, 0
    mov al, 3
    int 10h
    ret
ClearScreen endp

; Dibujar bordes laterales de la pista
DrawBorders proc
    mov cx, SCREEN_HEIGHT
    mov dx, 0
BucleBordes:
    ; Línea izquierda
    mov ah, 02h
    mov bh, 0
    mov dh, dl
    mov dl, PISTA_IZQ
    int 10h
    mov ah, 09h
    mov al, '|'
    mov bl, 7
    mov cx, 1
    int 10h

    ; Línea derecha
    mov ah, 02h
    mov dh, dl
    mov dl, PISTA_DER
    int 10h
    mov ah, 09h
    mov al, '|'
    mov cx, 1
    int 10h

    inc dx
    loop BucleBordes
    ret
DrawBorders endp

; Dibujar el auto
DrawCar proc
    mov ah, 02h
    mov bh, 0
    mov dh, 23           ; Fila fija
    mov dl, carX
    int 10h
    mov ah, 09h
    mov al, CHAR_AUTO
    mov bl, 10
    mov cx, 1
    int 10h
    ret
DrawCar endp

; Dibujar obstáculos
DrawObstacles proc
    mov si, 0
DibujarLoop:
    mov ah, 02h
    mov bh, 0
    mov dh, obsY[si]
    mov dl, obsX[si]
    int 10h
    mov ah, 09h
    mov al, CHAR_OBS
    mov bl, 12
    mov cx, 1
    int 10h

    inc si
    cmp si, MAX_OBS
    jl DibujarLoop
    ret
DrawObstacles endp

; Actualizar obstáculos (bajar 1 línea)
UpdateObstacles proc
    mov si, 0
ActualizarLoop:
    inc obsY[si]
    cmp obsY[si], 24
    jbe SinReiniciar

    ; Reiniciar obstáculo
    mov obsY[si], 0
GenerarNuevo:
    ; Asegurar que esté dentro de los bordes
    mov ah, 0
    int 1Ah         ; Obtener reloj para pseudoaleatorio
    mov al, dl
    and al, 15
    add al, PISTA_IZQ + 1
    cmp al, PISTA_DER - 1
    jbe GuardarObs
    jmp GenerarNuevo
GuardarObs:
    mov obsX[si], al

    ; Incrementar puntaje
    inc score
    ; Aumentar dificultad cada 10 puntos
    mov ax, score
    mov dx, 0
    mov bx, 10
    div bx
    cmp dx, 0
    jne SinReiniciar
    sub speed, 50
    jmp SinReiniciar

SinReiniciar:
    inc si
    cmp si, MAX_OBS
    jl ActualizarLoop
    ret
UpdateObstacles endp

; Mostrar puntaje en pantalla
ShowScore proc
    mov ah, 02h
    mov bh, 0
    mov dh, 0
    mov dl, 0
    int 10h
    mov ah, 09h
    lea dx, msgPuntaje
    int 21h

    ; Mostrar número
    mov ax, score
    call PrintNumber
    ret
ShowScore endp

; Leer tecla y mover auto
ReadKey proc
    mov ah, 01h
    int 16h
    jz SinTecla
    mov ah, 00h
    int 16h
    cmp ah, 4Bh         ; Flecha izquierda
    je MoverIzquierda
    cmp ah, 4Dh         ; Flecha derecha
    je MoverDerecha
    cmp ah, 01h         ; ESC
    je Exit
    cmp ah, 13h         ; R (reintentar)
    jmp near ptr start  ; Salto a inicio del juego
SinTecla:
    ret

MoverIzquierda:
    cmp carX, PISTA_IZQ + 1
    jbe SinTecla
    dec carX
    ret

MoverDerecha:
    cmp carX, PISTA_DER - 1
    jae SinTecla
    inc carX
    ret

Exit:
    mov ah, 4Ch
    int 21h
ReadKey endp

; Verifica colisiones entre auto y obstáculos
CheckCollision proc
    mov si, 0
CollisionLoop:
    mov al, obsY[si]
    cmp al, 23          ; Fila del auto
    jne NoCheck

    mov al, carX
    cmp obsX[si], al
    jne NoCheck

    ; Colisión detectada
    call GameOverScreen
EsperarTecla:
    call ReadKey
    ret

NoCheck:
    inc si
    cmp si, MAX_OBS
    jl CollisionLoop
    ret
CheckCollision endp

; ----------------------------
; Muestra pantalla de fin del juego
; ----------------------------
GameOverScreen proc
    call ClearScreen

    ; Mostrar "¡Colisión!"
    mov ah, 02h
    mov bh, 0
    mov dh, 8
    mov dl, 25
    int 10h

    mov ah, 09h
    mov dx, offset gameOverMsg
    int 21h

    ; Mostrar instrucción
    mov ah, 02h
    mov dh, 10
    mov dl, 10
    int 10h

    mov ah, 09h
    mov dx, offset retryMsg
    int 21h

WaitChoice:
    mov ah, 00h
    int 16h
    cmp al, 'R'
    je RestartGame
    cmp al, 27          ; ESC
    je ExitGame
    jmp WaitChoice

RestartGame:
    jmp start           ; ← Reiniciar desde la pantalla de inicio

ExitGame:
    mov ax, 4C00h       ; Terminar el programa
    int 21h
GameOverScreen endp


; Retardo según velocidad (controla dificultad)
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

; Inicializar estado del juego
InitGame proc
    mov carX, 40
    mov score, 0
    mov speed, 1000

    ; Inicializar obstáculos
    mov si, 0
InitLoop:
    mov al, cl
    mov obsY[si], al
    mov obsX[si], 30
    inc si
    cmp si, MAX_OBS
    jl InitLoop
    ret
InitGame endp

; Mostrar número (usado por ShowScore)
PrintNumber proc
    ; push todos los registros necesarios manualmente
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
    ; pop los mismos registros en orden inverso
    pop dx
    pop cx
    pop bx
    pop ax
    ret
PrintNumber endp

end start