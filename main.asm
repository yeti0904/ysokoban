bits 16
org 0x100
jmp init

%define SCREENWIDTH  320
%define SCREENHEIGHT 200
%define TILESIZE     16
%define TILEAREA     256
%define VRAM         0xA000
%define SCRBUF       0x7E00
%define LEVELWIDTH   20
%define LEVELHEIGHT  11

; tiles
%define EMPTYTILE 0x00
%define WALLTILE  0x01
%define CRATETILE 0x02

%include "graphics.asm"
%include "sprites.asm"
%include "level1.asm"

; consts
gameTitle: db "Yeti's Sokoban", 0

; game variables
playerPosX:
	dw 5
playerPosY:
	dw 5

; game util functions
getLevelTile:
	; Parameters
	; cx = x pos
	; dx = y pos
	; si = level pointer
	push bx
	
	mov ax, dx
	mov bx, LEVELWIDTH
	mul bx
	add ax, cx
	add si, ax
	mov al, [si]

	pop bx
	
	ret

setLevelTile:
	; Parameters
	; cx = x pos
	; dx = y pos
	; al = tile
	; si = level pointer
	push bx
	push ax

	mov ax, dx
	mov bx, LEVELWIDTH
	mul bx
	add ax, cx
	add si, ax

	pop ax
	mov [si], al
	pop bx
	ret

; game rendering functions
renderLevelLine:
	; Parameters
	; dx = y pos
	; di = level pointer
	pusha
	push si
	mov cx, 0
	.loop:
		mov al, [di]
		cmp al, EMPTYTILE ; nothing
		je .continue
		mov bx, wallSprite
		cmp al, WALLTILE ; wall
		je .render
		mov bx, crateSprite
		cmp al, CRATETILE ; crate
		je .render
	.render:
		mov si, bx
		call drawTile
	.continue:
		inc di
		add cx, TILESIZE
		cmp cx, SCREENWIDTH
		jge .done
		jmp .loop
	.done:
		pop si
		popa
		ret

renderLevel:
	; Parameters
	; di = level pointer
	pusha
	mov dx, 8

	.loop:
		 call renderLevelLine
		 add dx, TILESIZE
		 add di, LEVELWIDTH
		 cmp dx, SCREENHEIGHT
		 jge .done
		 jmp .loop
	.done:
		popa
		ret

; game functions
createPlayerBox:
	push bx
	push ax
	push si
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

	pop si
	pop ax
	pop bx
	
	ret

init:
	call videoMode

gameLoop:
	; render
	mov al, 0x1A ; grey
	call clear

	mov al, 0x00 ; black
	mov cx, 0
	mov dx, 0
	mov si, SCREENWIDTH
	mov di, 8
	call fillRect

	mov di, level1
	call renderLevel

	mov si, playerSprite
	call createPlayerBox
	call drawTile

	call flush

	mov dl, 0
	mov dh, 0
	call setCursor

	mov bl, 0x0F
	mov si, gameTitle
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

	mov cx, [playerPosX]
	mov dx, [playerPosY]
	mov si, level1
	call getLevelTile

	cmp al, CRATETILE
	je .placeCrateUp

	cmp al, EMPTYTILE
	jne .moveDown
	
	jmp gameLoop

.moveDown:
	cmp word [playerPosY], LEVELHEIGHT
	je gameLoop

	inc word [playerPosY]

	mov cx, [playerPosX]
	mov dx, [playerPosY]
	mov si, level1
	call getLevelTile

	cmp al, CRATETILE
	je .placeCrateDown

	cmp al, EMPTYTILE
	jne .moveUp
	
	jmp gameLoop

.moveLeft:
	cmp word [playerPosX], 0
	je gameLoop

	dec word [playerPosX]

	mov cx, [playerPosX]
	mov dx, [playerPosY]
	mov si, level1
	call getLevelTile

	cmp al, CRATETILE
	je .placeCrateLeft

	cmp al, EMPTYTILE
	jne .moveRight
	
	jmp gameLoop

.moveRight:
	cmp word [playerPosX], (LEVELWIDTH - 1)
	je gameLoop

	inc word [playerPosX]

	mov cx, [playerPosX]
	mov dx, [playerPosY]
	mov si, level1
	call getLevelTile

	cmp al, CRATETILE
	je .placeCrateRight

	cmp al, EMPTYTILE
	jne .moveLeft
	
	jmp gameLoop

.removeCrate:
	push cx
	push dx
	push si
	push ax

	mov cx, [playerPosX]
	mov dx, [playerPosY]
	mov si, level1
	mov al, EMPTYTILE
	call setLevelTile

	pop ax
	pop si
	pop dx
	pop cx
	ret

.placeCrateUp:
	call .removeCrate
	
	mov cx, [playerPosX]
	mov dx, [playerPosY]
	dec dx
	mov si, level1
	mov al, CRATETILE
	call setLevelTile
	jmp gameLoop

.placeCrateDown:
	call .removeCrate
	
	mov cx, [playerPosX]
	mov dx, [playerPosY]
	inc dx
	mov si, level1
	mov al, CRATETILE
	call setLevelTile
	jmp gameLoop

.placeCrateRight:
	call .removeCrate
	
	mov cx, [playerPosX]
	mov dx, [playerPosY]
	inc cx
	mov si, level1
	mov al, CRATETILE
	call setLevelTile
	jmp gameLoop

.placeCrateLeft:
	call .removeCrate
	
	mov cx, [playerPosX]
	mov dx, [playerPosY]
	dec cx
	mov si, level1
	mov al, CRATETILE
	call setLevelTile
	jmp gameLoop

gameEnd:
	call textMode
	int 0x20

