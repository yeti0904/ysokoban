bits 16
org 0x100
jmp init

%define SCREENWIDTH  320
%define SCREENHEIGHT 200
%define TILESIZE     16

; game variables
playerPosX:
	dw 5
playerPosY:
	dw 10

videoMode:
	mov ah, 0x00
	mov al, 0x0D ; 320x200, 4bpp, 8 pages video mode
	int 0x10
	ret
	
textMode:
	mov ah, 0x00
	mov al, 0x03 ; text mode
	int 0x10
	ret

clear:
	cmp al, 0x00
	je .fast
	mov cx, 0 ; x iterator
	mov dx, 0 ; y iterator
	.loop:
		call drawPixel
		inc cx
		cmp cx, SCREENWIDTH
		jl .loop
		inc dx
		mov cx, 0
		cmp dx, SCREENHEIGHT
		jl .loop
	ret
	.fast:
		call videoMode
		ret

fillRect:
	; Parameters
	; cx = start x
	; dx = start y
	; si = end x
	; di = end y
	; al = colour
	mov bx, cx ; x iterator
	.loop:
		push cx
		mov cx, bx
		call drawPixel
		pop cx
		inc bx
		cmp bx, si
		jl .loop
		inc dx
		mov bx, cx
		cmp dx, di
		jl .loop
	ret

putstr:
	mov ah, 0x0E
	.loop:
		lodsb
		cmp al, 0
		je .done
		int 0x10
		jmp .loop
	.done:
		ret

putstrAttribute:
	pusha
	mov ah, 0x09
	mov bh, 0
	mov cx, 1
	.loop:
		lodsb
		cmp al, 0
		je .done
		int 0x10
		call getCursor
		inc dl
		call setCursor
		jmp .loop
	.done:
		popa
		ret

setCursor:
	pusha
	mov ah, 0x02
	mov bh, 0
	int 0x10
	popa
	ret

getCursor:
	push cx
	push bx
	push ax
	mov ah, 0x03
	mov bh, 0
	int 0x10
	pop ax
	pop bx
	pop cx
	ret

drawPixel:
	pusha
	mov ah, 0x0C
	int 0x10
	popa
	ret

getchar:
	mov ah, 0x07
	int 0x21
	ret

createPlayerBox:
	push bx
	push ax
	mov bx, TILESIZE ; multiplier
	
	mov ax, [playerPosX]
	mul bx
	mov cx, ax
	mov ax, [playerPosY]
	mul bx
	mov dx, ax
	add dx, 8 ; offset from info bar at the top

	mov si, cx
	add si, TILESIZE
	mov di, dx
	add di, TILESIZE

	pop ax
	pop bx
	
	ret

init:
	call videoMode

gameLoop:
	; render
	mov al, 0x0B ; blue
	call clear

	mov al, 0x00 ; black
	mov cx, 0
	mov dx, 0
	mov si, SCREENWIDTH
	mov di, 8
	call fillRect

	mov al, 0x0E ; yellow
	call createPlayerBox
	call fillRect

	mov dl, 0
	mov dh, 0
	call setCursor

	mov bl, 0x0F
	mov si, str
	call putstrAttribute

	jmp .input

.input:
	call getchar
	
	cmp al, 'q'
	je gameEnd

	cmp al, 'w'
	je .moveUp

	cmp al, 'a'
	je .moveLeft

	cmp al, 's'
	je .moveDown

	cmp al, 'd'
	je .moveRight
	
	jmp gameLoop

.moveUp:
	cmp word [playerPosY], 0
	je gameLoop

	dec word [playerPosY]
	jmp gameLoop

.moveDown:
	cmp word [playerPosY], 11
	je gameLoop

	inc word [playerPosY]
	jmp gameLoop

.moveLeft:
	cmp word [playerPosX], 0
	je gameLoop

	dec word [playerPosX]
	jmp gameLoop

.moveRight:
	cmp word [playerPosX], 19
	je gameLoop

	inc word [playerPosX]
	jmp gameLoop

gameEnd:
	call textMode
	int 0x20

; variables
str: db "Sokoban", 0
