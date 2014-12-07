assume cs:code_seg, ds:data_seg, ss:stack_seg

stack_seg 			segment 	stack
	db 				200 		dup(?)
	top 			db 			?
stack_seg 						ends

data_seg 						segment

	win_msg			db			10, 13, 9, 9, 9, "       Congratulations. You win!", 10,13,"$"
	over_msg		db			10, 13, 9, 9, 9, 9, "    Game over...", 10,13,"$"
	exit_msg		db			10, 13, 9, 9, 9, 9, " Game was exited...", 10,13,"$"
	score_msg		db			10, 13, 9, 9, 9, 9, "  Your score is ", "$"
	racket  		dw			185 												;x współrzędna rakietki
	d_x				dw			1  													;przesunięcie rakietki po x
	d_y				dw			1   												;przesunięcie rakietki po y
	ball_x  		dw			0 													;x współrzędna piłeczki
	ball_y  		dw			0   												;y współrzędna piłeczki
	color   		db			31 													;kolor rakietki
	score 			dw			0 													;początkowa liczba punktów
	time			dw 			10000												;początkowy czas spania

data_seg 						ends

code_seg segment


start:

	mov 			ax, seg top 													;inicjujemy stos
	mov 			ss,	ax
	mov 			sp, offset top
	
	mov 			ax, seg data_seg 												;inicjujemy data segment
	mov 			ds,ax
	
	call 			graphics_mode													;włączamy tryb graficzny
	call 			ball_init														;odrysowujemy piłkę
	call 			racket_init														;odrysowujemy rakietkę
	
	main:
		call 			sleep														;śpimy jakiś czas
		call 			processing													;obsługujemy zdarzenia
		
		event:
			call 			move_ball												;liczymy nowe współrzędne piłki
			call 			clear 													;wyczyszczamy pole
			call 			racket_init 											;odrysowujemy rakietkę
			call 			ball_init												;odrysowujemy piłkę
			jmp 			main
	
	sleep: 																			;śpimy zadaną liczbę mikrosekund w zmiennej time
		mov 			cx, 0 														
		mov 			dx, word ptr ds:[time] 										
		mov 			ah, 86h
		int 			15h
	
	clear: 																			;wyczyszczamy pole(zarysowujemy czarnym)
		xor 			cx, cx 														;idziemy od lewego górnego piksela
		mov 			dx, 63999 													;do prawego dolnego
		xor 			bx, bx 														;wybieramy czarny kolor
		mov 			ah, 06h 
		mov 			al, 00
		int 			10h

		ret
		
	graphics_mode: 																	;przechodzimy w tryb graficzny 320x200
		mov 			ax, 13h
		int 			10h
		mov 			ax, 0a000h
		mov 			es, ax
		ret
	
	text_mode: 																		;wracamy do trybu tekstowego
		mov 			ax, 03h
		int 			10h
		ret
	
	processing: 																	;sprawdzamy i obsługujemy zdarzenia
		xor 			ax, ax
		mov 			ah, 01h 													;sprawdamy czy jest coś na wejściu
		int 			16h
		jz 				event 														;jeżeli nic - sprawdzamy dalej
		mov 			ah, 00h 													
		int 			16h
		cmp 			ah, 4bh 													;porównujemy czy to strzałka w lewo
		je 				left_arrow
		cmp 			ah, 4dh 													;porównujemy czy to strzałka w prawo
		je 				right_arrow
		cmp 			ah, 01h 													;sprawdamy czy to ESC
		je 				exit_pass
		jmp 			event
	
	left_arrow: 																	;obsługa ruchu w lewo
		mov 			ax, word ptr ds:[racket]
		sub 			ax, 15 														;przesunięcie rakietki
		cmp 			ax, 50 														;sprawdzamy czy daleko od lewej ściany
		jg 				left_wall 													;jeżeli blizko - przesuwamy do końca
		mov 			word ptr ds:[racket], 50
		jmp 			event
		
		left_wall:
			mov 			word ptr ds:[racket],ax
			jmp 			event
	
	right_arrow: 																	;obsługa ruchu w prawo
		mov 			ax, word ptr ds:[racket]
		add				ax, 15 														;przesunięcie rakietki
		cmp 			ax, 320 													;sprawdzamy czy daleko od prawej ściany
		jl 				right_wall 													;jeżeli blizko - przesuwamy do końca
		mov 			word ptr ds:[racket], 320
		jmp 			event
		
		right_wall:
			mov 			word ptr ds:[racket], ax
			jmp 			event
	
	losers_pass:
		jmp 			losers_gate

	exit_pass:
		jmp				exit_gate
	
	move_ball: 																		;przesuwamy piłkę i sprawdzamy na kolizje
		
		mov 			ax, word ptr ds:[ball_x] 									;zmieniamy x współrzędną
		add 			ax, word ptr ds:[d_x]
		mov 			word ptr ds:[ball_x], ax
		
		mov 			bx, word ptr ds:[ball_y] 									;zmieniamy y współrzędną
		add 			bx, word ptr ds:[d_y]
		mov 			word ptr ds:[ball_y], bx
		
		mov 			cx, word ptr ds:[racket] 									;zachowujemy pozycję rakietki
		
		cmp 			ax, 0 														;sprawdzamy kolizję z lewą ścianą
		jg 				not_left_edge
		mov 			word ptr ds:[d_x], 1 										;jeżeli wystąpiła - zmieniamy wektor co do x
		jmp 			top_bottom
		
		not_left_edge:
			cmp 			ax, 315 												;sprawdzamy kolizję z prawą ścianą
			jl 				top_bottom
			mov 			word ptr ds:[d_x], -1 									;jeżeli tak - zmieniamy wektor co do y
		
		top_bottom:
			cmp 			bx, 0 													;sprawdzamy kolizję z górną ścianą
			jg 				not_top_edge
			mov 			word ptr ds:[d_y], 1 									;jeżeli tak - zmieniamy wektor co do y(w dół)
			ret
			
		not_top_edge:
			cmp 			bx, 195 												;sprawdzamy kolizję z dolną ścianą
			jg 				losers_pass 											;jeżeli niżej tego - koniec
			cmp 			bx, 188 												;inaczej trafiliśmy
			jl 				hit
			add 			cx, 5
			cmp 			ax, cx 													;piłka nad prawą częścią rakietki
			jg 				hit
			sub 			cx, 60
			cmp 			ax, cx 													;piłka nad lewą częścią rakietki
			jl 				hit
			cmp 			bx, 188 												;kolizja z rakietką
			je 				central_sector
			add 			cx, 25	
			cmp 			ax, cx 													;kontakt ze ścianą rakietki(obsługujemy jednakowo)
			jl 				left_sector
			mov 			word ptr ds:[d_x], 1 									;zmieniamy kierunek
			ret
		
		left_sector:
			mov 			word ptr ds:[d_x], -1 									;kierunek w lewo
			ret
		
		central_sector:																;trafiliśmy rakietką
			mov 			word ptr ds:[d_y], -1 									;kierunek w górę
			inc 			word ptr ds:[score]
			
			cmp 			byte ptr ds:[score], 20 								;sprawdzamy liczbę punktów
			je 				winners_gate 											;jeżeli więcej 20 - zwycięctwo

			mov 			cx, 400 												;inaczej zwiększamy prędkość
			inc_time:
				dec 			word ptr ds:[time]
				loop 			inc_time

			ret
		
		hit:
			ret
	
	racket_init: 																	;odrysowujemy rakietkę
		mov 			al,byte ptr ds:[color]
		mov 			ax, 193
		mov 			cx,	320
		mul 			cx
		mov 			di, ax
		mov 			al, byte ptr ds:[color]
		add 			di, word ptr ds:[racket] 									
		mov 			cx, 4
		
		lines1:
			add 			di, 270
			push 			cx
			mov 			cx, 50
			call 			create_line
			pop 			cx
			loop 			lines1
		ret
	
	ball_init: 																		;odrysowujemy piłkę
		mov 			ax, word ptr ds:[ball_y]
		mov 			cx, 320
		mul 			cx
		mov 			di, ax
		sub 			di, 315
		mov 			al, byte ptr ds:[color]										;kolor piłki
		add 			di, word ptr ds:[ball_x] 
		mov 			cx, 5
		
		lines2:
			add 			di, 315
			push 			cx
			mov 			cx, 5
			call 			create_line
			pop 			cx
			loop 			lines2
		ret
	
	create_line: 
		mov 			byte ptr es:[di], al
		inc 			di
		loop 			create_line
		ret
	
	winners_gate: 																		;drukujemy komunikat o zwycięctwie
		call 			text_mode
		
		mov 			dx, offset win_msg
		mov 			ah, 09
		int 			21h

		mov 			dx, offset score_msg
		mov 			ah, 09
		int 			21h

		jmp	 			print_score

	exit_gate: 																			;drukujemy komunikat o wyściu z gry
		call 			text_mode

		mov 			dx, offset exit_msg
		mov 			ah, 09
		int 			21h

		mov 			dx, offset score_msg
		mov 			ah, 09
		int 			21h

		jmp 			print_score
	
	losers_gate: 																		;drukujemy komunikat o przegraniu gry
		call 			text_mode
		
		mov 			dx, offset over_msg
		mov 			ah, 09
		int 			21h

		mov 			dx, offset score_msg
		mov 			ah, 09
		int 			21h

		jmp 			print_score
	
	
	print_score: 																		;drukujemy liczbę nabranych punktów

		mov 			bx, word ptr ds:[score]
		k1:
			mov 		ax, bx
	        mov 		bx, 0
	        mov 		dx, 000ah
	        mov 		cx, 0000 														;liczba umieszczeń na stos
		k2:
			div			dl     
	        mov 		bl, ah
	        push 		bx
	        mov 		ah, 0
	        inc 		cx					    										;zwiększamy licznik na 1
	        cmp 		ax, 0
	        jne 		k2    															;otrzymujemy następną cyfrę
	        mov 		ah, 02
		k3:
			pop 		dx
	        add 		dl, 30h
	        int 		21h
	        loop 		k3

	exit_cmd: 																			;kończymy program

		mov 		ah, 4ch
		xor 		al, al
		int 		21h
	
code_seg 			ends
end 				start