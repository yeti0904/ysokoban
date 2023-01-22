videoMode:
	mov ah, 0x00
	mov al, 0x13 ; 320x200, 8bpp, 1 page video mode
	int 0x10
	ret
	
textMode:
	mov ah, 0x00
	mov al, 0x03 ; text mode
	int 0x10
	ret

;clear:
;	cmp al, 0x00
;	je .fast
;	mov cx, 0 ; x iterator
;	mov dx, 0 ; y iterator
;	.loop:
;		call drawPixel
;		inc cx
;		cmp cx, SCREENWIDTH
;		jl .loop
;		inc dx
;		mov cx, 0
;		cmp dx, SCREENHEIGHT
;		jl .loop
;	ret
;	.fast:
;		call videoMode
;		ret

clear:
	push ax

	; copy al to all bytes of eax
	mov ah, al
	push ax
	shl eax, 16
	pop ax
	push ax
	
	mov ax, SCRBUF
	mov es, ax
	pop ax
	xor di, di
	mov cx, 16000 ; (320x200) / 4
	rep stosd
	pop ax
	ret

flush:
	push ax
	push ds
	push si
	push es
	push di

	mov ax, SCRBUF
	mov ds, ax
	xor si, si
	mov ax, VRAM
	mov es, ax
	xor di, di

	mov cx, 16000
	rep movsd

	pop di
	pop es
	pop si
	pop ds
	pop ax
	ret

drawTile:
	; Parameters
	; cx = start x
	; dx = start y
	; si = sprite address
	pusha
	push di
	
	mov bx, cx ; x iterator
	mov di, bx
	add di, TILESIZE ; max
	mov ax, dx
	add ax, TILESIZE
	push ax
	.loop:
		push cx
		mov cx, bx
		lodsb
		call drawPixel
		pop cx
		inc bx
		cmp bx, di
		jl .loop
		inc dx
		mov bx, cx
		pop ax
		cmp dx, ax
		jl .nextY
		jmp .end
	.nextY:
		push ax
		jmp .loop
	.end:
		pop di
		popa
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
	push ax
	push bx
	push cx
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
		pop cx
		pop bx
		pop ax
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
	push di
	; Parameters
	; CX = x pos
	; DX = y pos
	; AL = colour
	push ax
	
	mov ax, SCRBUF
	mov es, ax
	
	mov ax, dx
	mov si, SCREENWIDTH
	mul si ; offset with Y
	mov di, ax

	add di, cx ; offset with X

	pop ax
	mov es:[di], al

	pop di
	popa
	ret

getchar:
	mov ah, 0x07
	int 0x21
	ret
