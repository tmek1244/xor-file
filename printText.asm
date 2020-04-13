dane1 segment
 
zoom	db 3 dup('$')
tekst 	db 40 dup('$')
 
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

;	mov dx, offset tekst
;	call print
	
;	mov dx, offset zoom
;	call print

	mov ax, seg tekst
	mov ds, ax
	mov si, offset tekst
przejscie_po_tekst:
	cmp byte ptr ds:[si], '$'
	je zakonczenie_wypisywania
	; funkcja do wypisania literek
	mov ah, 2
	mov dl, ds:[si]
	int 021h
	inc si
	; koniec funkcji do wypisania literek
	jmp przejscie_po_tekst
	
zakonczenie_wypisywania:

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
	; -------------------------- zoom --------------------------------	
		mov	si, offset zoom 
		call pomin_biale_znaki
	parametr1:
		mov	al, byte ptr ds:[di]
		
		mov	byte ptr es:[si], al ; zapis znaku do zoom
	 

	; -------------------------- tekst --------------------------------
		inc di
		dec cx
		dec cx	
	drugi_parametr:
		call pomin_biale_znaki
		mov si, offset tekst
		
		cmp cx, 0
		jz blad_zla_liczba_arg
		mov	al, byte ptr ds:[di]

	parametr2:	
		mov	al, byte ptr ds:[di]
		mov	byte ptr es:[si],al	
		
		inc	di  ; di - iteruje po wejscu
		inc	si ; iteruje po tekst
		loop parametr2

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