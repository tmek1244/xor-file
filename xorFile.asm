dane1 segment
 
txt1	db 20 dup(0)
txt2 	db 20 dup(0)
key	db 200 dup('$')

wsk1	dw ?
wsk2	dw ?
key_counter dw 0
key_len db 5
ile_znakow_wczytano dw ?

dane_z_pliku1 db 200 dup('$') 
dane_z_pliku2 db 200 dup(0) 
pom db ?
 
err_zla_liczba_arg db 'Zla liczba argumentow!' 
kod db 'cos'
 
dane1 ends
 
 
 
 
code1 segment
 
start1:
	;ds -> wskazuje na segment programu
	;offset: 080h = liczbe znakow buforu
	;        081h = spacja
	;	 082h = poczatek buforu
 
 
 
	;inicjowanie stosu
	mov	sp, offset wstosu
	mov	ax, seg wstosu
	mov	ss, ax
 
	call wczytanie_danych
;	mov dx, offset key
;	call print
;ODCZYT
    ;otwieramy plik ds:dx
    mov ax, seg txt1
    mov ds,ax
    mov dx, offset txt1
	mov cx, 0 ;bez specjalnych atrybutow
    mov al, 0 ;tryb read only
    mov ah, 3dh;otwarcie z ds:dx
    int 21h
	
	JC koniec_programu

    mov word ptr ds:[wsk1],ax
 
	mov ax, seg txt2
    mov ds,ax
    mov dx, offset txt2
	mov cx, 0
    mov ah, 3dh;otwarcie z ds:dx
    mov al, 1 ;tryb read only
    int 21h
    mov word ptr ds:[wsk2],ax
	
	JC koniec_programu
	mov ax, seg dane1
	mov es, ax
	mov ax, offset key
	mov word ptr es:[key_counter], ax
	

;	mov si, es:[key_counter]
;	mov dl, byte ptr es:[si]
;	call print_char
	;mov dx, offset key
	;call print
	mov si, offset key
		
;	mov dl, byte ptr ds:[si]
;	call print_char
przepis:

    ;sprawdzamy flagę CF
    mov bx, word ptr ds:[wsk1]
    mov cx, 10;maksymalnie 200 znaków z pliku
    mov ax, seg dane1
    mov ds, ax
    mov dx, offset dane_z_pliku1;ds:dx-> bufor do czytania
    mov ah, 3fh ;odczyt
    int 21h
	
	cmp ax, 0
	je koniec_przepisu
;---------------------------------------------------


;-------------------Wczytano <= 1024 bajty------------
	mov cx, ax
	mov ds:[ile_znakow_wczytano], ax
;	mov dl, ds:[ile_znakow_wczytano]
;	call print_char
	mov bx, offset dane_z_pliku1
xor_bufor:
	cmp byte ptr ds:[si], '$'
	je zeruj_licznik
continue:



	mov dh, byte ptr ds:[bx]

	xor dh, byte ptr ds:[si] ;<-----------------------XOR
;	mov dl, byte ptr ds:[si]
;	call print_char
	
	inc si
	mov byte ptr ds:[bx], dh
	inc bx
	loop xor_bufor
	
;---------------------Zxorowano <= 1024 bajty----------
    mov bx, word ptr ds:[wsk2]
    mov cx, ds:[ile_znakow_wczytano];maksymalnie 200 znaków z pliku
    mov ax, seg dane1
    mov ds, ax
    mov dx, offset dane_z_pliku1;ds:dx-> bufor do czytania
    mov ah, 40h ;zapis
    int 21h
	jmp przepis
	
koniec_przepisu:
	
;	mov dx, offset dane_z_pliku1
;	call print
;	mov dx, offset dane_z_pliku2
;	call print
 
 
    ;zamkniecie pliku
    mov bx, word ptr ds:[wsk1]
    mov ah, 3eh
    int 21h;zamkniecie	 
	;zamkniecie pliku
    mov bx, word ptr ds:[wsk2]
    mov ah, 3eh
    int 21h;zamkniecie	 
	
	
 
; -------------------------- po wczytaniu argumentow ----------------------
koniec_wczytywania:
;	mov dx, offset key
;	call print
;	call print_enter
;	mov dx, offset txt2
;	call print
;	call print_enter
;	mov dx, offset txt1
;	call print
;	call print_enter
	
koniec_programu:
	mov	ah,4ch  ; zakoncz program i wroc do systemu
	int	021h
 
 ; ----------------------------- Wczytanie Danych -------------------------
 
 wczytanie_danych:
	mov	bx,0
	mov	bl,byte ptr ds:[080h]
	;mov	byte ptr ds:[080h +1 + bx],'$'
	;   es:[si]
 
	mov	di,082h
	mov	cx,bx
	
	mov	ax,seg dane1
	mov	es,ax ; extra segment
; -------------------------- parametr 1 --------------------------------	
	mov	si,offset txt1 
p1:	
	push cx
	mov	al, byte ptr ds:[di]
	inc di ; di - iteruje po wejscu
	cmp al, ' '
	jz poczatek2
	mov	byte ptr es:[si],al
	inc	si ; iteruje po txt1
	pop	cx
	loop	p1
 

; -------------------------- parametr 2 --------------------------------	
poczatek2:
	pop cx
	dec cx
	mov si, offset txt2
p2:	
	push cx
	mov	al, byte ptr ds:[di]
	inc	di  ; di - iteruje po wejscu
	cmp al, ' '
	jz poczatek3
	mov	byte ptr es:[si],al
	inc	si ; iteruje po txt2
	pop	cx
	loop	p2 
 
 
; -------------------------- parametr 3 --------------------------------	
poczatek3:
	pop cx
	dec cx
	dec cx
	mov si, offset key
p3:		
	push cx
	mov	al, byte ptr ds:[di]
	inc	di  ; di - iteruje po wejscu
	cmp al, ' '
	jz blad_zla_liczba_arg
	mov	byte ptr es:[si],al	
	inc	si ; iteruje po key
	pop	cx
	loop	p3
 
	ret
	


; -------------------------- DODATKOWE PROCEDURY -------------------------
zeruj_licznik:
	mov si, offset key
	jmp continue



blad_zla_liczba_arg:
	pop cx
	mov dx, offset err_zla_liczba_arg
	call print
	jmp koniec_programu
	

print: ; funkcja wypisuje string zakonczony $, ktorego offset znajduje sie w dx
	push ax
	push ds
	mov ax, seg dane1
	mov ds, ax
	mov ah, 9
	int 21h
	
	pop ds
	pop ax
	ret
 
 
print_enter:
	mov dl, 10
	call print_char
	mov dl, 13
	call print_char
	ret
	
print_char:
	mov ah, 2
	int 21h
	ret
 
code1 ends
 
 
 
stos1 segment stack
	dw 200 dup(?)
wstosu	dw ?
stos1 ends
 
 
end start1