dane1 segment
 
plik1	db 20 dup(0)
plik2 	db 20 dup(0)
key	db 200 dup('$')

wsk1	dw ?
wsk2	dw ?
ile_znakow_wczytano dw ?

dane_z_pliku1 db 200 dup('$') 
 
err_zla_liczba_arg db 'Zla liczba argumentow!$' 
err_brak_cudzyslowa_na_koniec db 'Nie ma cudzyslowa na koncu klucza$'
err_brak_cudzyslowa_na_poczatku db 'Klucz musi zaczynac sie od "$'
err_nie_ma_pliku_wejsciowego db 'Nie udalo sie otworzyc pliku wejscioweg$'
err_nie_ma_pliku_wyjsciowego db 'Nie udalo sie otworzyc pliku wyjscioweg$'

msg_success db 'Udalo sie zaszyfrowac plik$'
 
dane1 ends
 
 
 
 
code1 segment
 
start1:
	;inicjowanie stosu
	mov	sp, offset wstosu
	mov	ax, seg wstosu
	mov	ss, ax
 
	call wczytanie_danych

    mov ax, seg plik1
    mov ds,ax
    mov dx, offset plik1
	mov cx, 0 ;bez specjalnych atrybutow
    mov al, 0 ;tryb read only
    mov ah, 3dh;otwarcie z ds:dx
    int 21h
	
	JC blad_otwieranie_pliku_wejsciowego

    mov word ptr ds:[wsk1],ax
 
	mov ax, seg plik2
    mov ds,ax
    mov dx, offset plik2
	mov cx, 0
    mov ah, 3dh;otwarcie z ds:dx
    mov al, 1 ;tryb read only
    int 21h
    mov word ptr ds:[wsk2],ax
	
	JC blad_otwieranie_pliku_wyjsciowego

	mov si, offset key
przepis:
		mov bx, word ptr ds:[wsk1]
		mov cx, 1024 ;maksymalnie 1024 znaki z pliku
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

		mov bx, offset dane_z_pliku1 ; w bx offset buffora
	xor_bufor:
		cmp byte ptr ds:[si], '$' ; sprawdzenie czy nie doszlismy do konca klucza
		je zeruj_licznik ; jesli tak to wracamy na poczatek
	continue:
		mov dh, byte ptr ds:[bx]
		xor dh, byte ptr ds:[si] ; operacja xorowania
		
		mov byte ptr ds:[bx], dh ; zapis wyniku tej operacji
		inc si
		inc bx
		loop xor_bufor
		
	;---------------------Zxorowano <= 1024 bajty----------
		mov bx, word ptr ds:[wsk2]
		mov cx, ds:[ile_znakow_wczytano]
		mov ax, seg dane1
		mov ds, ax
		mov dx, offset dane_z_pliku1 ;ds:dx-> bufor do czytania
		mov ah, 40h ;zapis
		int 21h
		jmp przepis
	

koniec_przepisu:
    ;zamkniecie pliku
    mov bx, word ptr ds:[wsk1]
    mov ah, 3eh
    int 21h;zamkniecie	 
	;zamkniecie pliku
    mov bx, word ptr ds:[wsk2]
    mov ah, 3eh
    int 21h;zamkniecie	  
; -------------------------- po wczytaniu argumentow ----------------------
	mov dx, offset msg_success
	call print

koniec_programu:
	mov	ah,4ch  ; zakoncz program i wroc do systemu
	int	021h
 
 
 ; ----------------------------- Wczytanie Danych -------------------------
 
 wczytanie_danych:	
		mov	di, 082h ; wskaznik na buffor z argumentami
		xor cx, cx
		mov	cl, byte ptr ds:[080h] ; wpisanie do bl liczby znakow
		
		mov	ax, seg dane1
		mov	es, ax ; extra segment
	; -------------------------- parametr 1 --------------------------------	
		mov	si, offset plik1 
		call pomin_biale_znaki
	parametr1:
		mov	al, byte ptr ds:[di]
		
		cmp al, ' '
		jz drugi_parametr
		cmp al, '	'
		jz drugi_parametr
		
		mov	byte ptr es:[si], al ; zapis znaku do plik1
		
		inc di ; di - iteruje po wejscu
		inc	si ; si - iteruje po segmencie danych
		loop parametr1
	 

	; -------------------------- parametr 2 --------------------------------
	drugi_parametr:
		call pomin_biale_znaki
		mov si, offset plik2
	parametr2:

		cmp cx, 0
		jz  blad_zla_liczba_arg
		mov	al, byte ptr ds:[di]
		
		cmp al, ' '
		jz trzeci_parametr
		cmp al, '	'
		jz trzeci_parametr
		
		mov	byte ptr es:[si], al
		
		inc	si ; iteruje po plik2
		inc di ; di - iteruje po wejscu
		loop parametr2
	 
	 
	 
	; -------------------------- parametr 3 --------------------------------	
	trzeci_parametr:
		call pomin_biale_znaki
		mov si, offset key
		
		cmp cx, 0
		jz blad_zla_liczba_arg
		mov	al, byte ptr ds:[di]
		cmp al, '"'
		jz poczatkowy_cudzyslow
		
		call blad_brak_cudzyslowa_na_poczatek ; haslo musi byc w "
		
		
	poczatkowy_cudzyslow:
		inc di
		dec cx
	;cmp al, '	'	
	;jz  p3r
		mov si, offset key	
	parametr3:	
		mov	al, byte ptr ds:[di]
		cmp cx, 0
		jz blad_brak_cudzyslowa_na_koniec ; na koncu musi byc "
		cmp al, '"'
		jz return
		mov	byte ptr es:[si],al	
		
		inc	di  ; di - iteruje po wejscu
		inc	si ; iteruje po key
		dec cx
		jmp parametr3

		;komunikat ze na koncu klucza powinno byc "
		ret
	

; -------------------------- DODATKOWE PROCEDURY -------------------------
return:
	ret
	
pomin_biale_znaki:
	mov	al, byte ptr ds:[di]
	
	cmp al, ' '
	jz znaleziony_bialy_znak
	cmp al, '	'
	jz znaleziony_bialy_znak
	ret

znaleziony_bialy_znak:
	inc di
	dec cx
	cmp cx, 0
	jz return
	jmp pomin_biale_znaki
	ret

zeruj_licznik:
	mov si, offset key
	jmp continue

blad_brak_cudzyslowa_na_poczatek:
	mov dx, offset err_brak_cudzyslowa_na_poczatku
	call print
	jmp koniec_programu

blad_brak_cudzyslowa_na_koniec:
	mov dx, offset err_brak_cudzyslowa_na_koniec
	call print
	jmp koniec_programu

blad_zla_liczba_arg:
	mov dx, offset err_zla_liczba_arg
	call print
	jmp koniec_programu
	
blad_otwieranie_pliku_wejsciowego:
	mov dx, offset err_nie_ma_pliku_wejsciowego
	call print
	jmp koniec_programu

blad_otwieranie_pliku_wyjsciowego:
	mov dx, offset err_nie_ma_pliku_wyjsciowego
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
code1 ends
 
 
 
stos1 segment stack
	dw 200 dup(?)
wstosu	dw ?
stos1 ends
 
 
end start1