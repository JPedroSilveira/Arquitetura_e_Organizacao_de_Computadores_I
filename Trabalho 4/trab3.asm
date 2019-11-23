	.model		small
	.stack
		
CR		equ		0dh
LF		equ		0ah

	.data
FileNameSrc			db		256 dup (?)		; Nome do arquivo a ser lido
FileHandleSrc  		dw		0				; Handler de arquivo de entrada
FileHandleDst  		dw		0				; Handler de arquivo de saida
FileBuffer		    db		10 dup (?)		; Buffer de leitura/escrita do arquivo
MsgIdentificacao	db  	"Joao Pedro Silveira e Silva - 00303397", 0
MsgPedeArquivoSrc	db		"Nome do arquivo de entrada: ", 0
MsgPedeArquivoDst	db		"Nome do arquivo destino: ", 0
MsgErroOpenFileIn	db		"Erro na abertura do arquivo de entrada.", CR, LF, CR, LF, 0
MsgErroOpenCreateFileInReturn	db  "Voltando para fase anterior", 0
MsgErroCreateFileOut 			db 	"Erro na criacao do arquivo de saida", CR, LF, CR, LF, 0
MsgPoint						db  ".", 0
MsgErroCreateFile	db		"Erro na criacao do arquivo.", CR, LF, 0
MsgErroLendo		db      "Erro ao ler valor de arquivo.", CR, LF, 0
MsgErroReadFile		db		"Erro na leitura do arquivo.", CR, LF, 0
MsgErroWriteFile	db		"Erro na escrita do arquivo.", CR, LF, 0
MsgEncerramento		db  	"Programa encerrado devia a entrada do usuario.", CR, LF, 0
MsgErroAoContarCor  db      "Cor inválida lida.", CR, LF, 0
TextHeader			db  	"********* Autor: Joao Pedro Silveira e Silva ***** Matricula: 00303397 *********", 0
TextCleanLine		db 		"                                                                                ", 0
TextArquivo			db		"Arquivo", 0
TextSpace			db		" ", 0
TextSeparadorHifen	db		" - ", 0
TextLadrilhosCor	db		"Total de ladrilhos por cor:", CR, LF, 0
UpperBar			db		201, 78 dup (205), 187, 0
BottomBar			db		200, 78 dup (205), 188, 0
SideBar				db      186,0
StrFileInEndBig		db  	".PAR", 0
StrFileInEndSmall   db  	".par", 0
StrFileOutEnd       db  	".rel", 0
MsgCRLF				db		CR, LF, 0
MsgIgual			db		" = ", 0
DelayCounter		dw      0
Str1				dw  	0
Str2				dw 	 	0
TempB				db		0
TempW				dw		0
Contador			dw		0
ContadorB			db		0
NLadrilhosColuna	db		0
NLadrilhosLinha		db      0
LadoLadrilho		dw		0
LadrilhoCursorColumn dw      0
LadrilhoCursorLine	 dw      0
Coluna				dw		0
Linha				dw		0
ColunaAtual			db		0
LinhaAtual			db		0
CodCor				db      0
ReadNumber          db      0

ContLadrilhos		dw		16 dup(0) ; Vetor onde é armazenado a contagem dos ladrilhos
LadrilhoFooterSize  equ     24		; Tamanho dos ladrilhos do footer
LadrilhoFooterSpace equ     16		; Espaço entre os ladrilhos do footer
InfoLineColumn		equ     2		; Coluna onde se inicia a impressão da quantidade de ladrilhos
InfoLineRow			equ     29		; Linha onde se inicia a impressão da quantidade de ladrilhos
InfoLineSpace		equ     5       ; Espaço entre cada informação de linha
InfoLineDesl		db		0 		; Deslocamento entre as colunas na impressão da quantidade de ladrilhos
InitColumnLadrilhosFooter equ	9		; Coluna inicial dos ladrihos no footer
RowLadrilhosFooter	equ		430		; Linha dos ladrilhos do footer
InitColumn			dw		0
InitRow				dw		0
NLadrilhosFooter	equ     15		; Quantidade de ladrilhos do footer


; Variável interna usada na rotina printf_w
BufferWRWORD	db		10 dup (?)

; Variaveis para uso interno na função sprintf_w
sw_n	dw	0
sw_f	db	0
sw_m	dw	0

MAXSTRING	equ		200
String	db		MAXSTRING dup (?)		; Usado na funcao gets

	.code
	.startup
		MOV		AX,DS				; Seta ES = DS
		MOV		es,AX
		etapa_2:	
					CALL    set_text_mode
					CALL    print_header
					CALL 	get_file_name_src
					CALL	is_empty_file_name
					CMP		AX, 01h
					JE      program_end
					CALL    load_files
					CMP     AX, 00h
					JE		etapa_2
		etapa_3:
					CALL    set_video_mode
					CALL    print_header
					CALL    print_upper_line
					CALL    print_right_line
					CALL	print_left_line
					CALL    print_bottom_line
					CALL    print_footer
					CALL    init_draw_variables
					CALL    print_contagem_ladrilhos
					CALL    read_input_file
					JMP     final_end
	program_end:
		CALL    set_text_mode
		LEA     BX, MsgCRLF
		CALL	printf_s
		LEA     BX, MsgEncerramento
		CALL	printf_s
	final_end:
	.exit	0
	

;--------------------------------------------------------------------
;Funcao principal, lê e desenha os ladrilhos
;--------------------------------------------------------------------
read_input_file PROC near
	loop_leitura_ladrilhos:
		CALL read_ladrilho
		CMP  AX, 0
		JE   fim_leitura_ladrilhos
		MOV  CodCor, DL
		CALL add_contagem_ladrilho
		CALL draw_ladrilho_parede
		CALL print_contagem_ladrilhos	; Atualiza a contagem de ladrilhos em tela
		JMP  loop_leitura_ladrilhos
fim_leitura_ladrilhos:
	RET
read_input_file ENDP

;--------------------------------------------------------------------
;Funcao que adiciona um novo ladrilho a contagem
; Entrada: CodCor -> Codigo da cor do ladrilho
;--------------------------------------------------------------------
add_contagem_ladrilho PROC near
	MOV BH, 0
	MOV BL, CodCor
	ADD BL, CodCor
	INC ContLadrilhos[BX]
	RET
add_contagem_ladrilho ENDP
;--------------------------------------------------------------------
;Funcao para inicializar o quadro de desenho de ladrilhos
;--------------------------------------------------------------------
init_draw_variables	PROC near
	CALL    read_header_input_file
	CALL	calculate_draw_size	; Calcula o tamanho máximo para os ladrilhos de acordo com a quantidade
	MOV     LadrilhoCursorColumn, 0	; Zera os cursores de desenho
	MOV     LadrilhoCursorLine, 0
	MOV     LinhaAtual, 0
	MOV     ColunaAtual, 0
	MOV     ContadorB, 0
	zerar_contagem_cores_loop:
		MOV		BH, 0
		MOV     BL, ContadorB
		ADD     BL, ContadorB
		MOV 	ContLadrilhos[BX], 0	
		MOV     CL, ContadorB
		CMP     CL, NLadrilhosFooter
		JE      zerar_contagem_cores_fim 
		INC     ContadorB
		JMP     zerar_contagem_cores_loop
zerar_contagem_cores_fim:
	RET
init_draw_variables ENDP
;--------------------------------------------------------------------
;Read cabeçalho input file com as linhas e colunas
;--------------------------------------------------------------------
read_header_input_file PROC near
	CALL get_number_until_colon
	MOV  AL, ReadNumber
	MOV  NLadrilhosLinha, AL
	CALL get_number_until_colon
	MOV  AL, ReadNumber
	MOV  NLadrilhosColuna, AL
	RET
read_header_input_file ENDP
;--------------------------------------------------------------------
;Funcao para ler e carregar o handler do arquivo de entrada
;Retorna em AX: 01h para sucesso e 00h para erro
;--------------------------------------------------------------------
load_files PROC near
	CALL    add_file_in_sufix
	LEA		DX, FileNameSrc
	CALL    fopen
	jb		open_in_error
	MOV     FileHandleSrc, BX
	CALL    add_file_out_sufix
	LEA     DX, FileNameSrc
	CALL    fcreate
	jb      create_out_error
	MOV     FileHandleDst, BX
	MOV     AX, 01h
	RET
open_in_error:
	LEA     BX, MsgErroOpenFileIn
	CALL 	printf_s
	MOV		DelayCounter, 1
	CALL    create_open_error_animation
	MOV     AX, 00h
	RET
create_out_error:
	LEA     BX, MsgErroCreateFileOut
	CALL 	printf_s
	MOV		DelayCounter, 1
	CALL    create_open_error_animation
	MOV     AX, 00h
	RET
load_files ENDP


;--------------------------------------------------------------------
;Funcao exibe a mensagem de erro ao criar ou abrir arquivo
; Entrada: DelayCounter -> Tempo de exibição em segundos /2
;--------------------------------------------------------------------
create_open_error_animation PROC near
	loop_create_open_error_animation:
		CALL    clean_line
		LEA		BX, MsgErroOpenCreateFileInReturn
		CALL 	printf_s
		MOV     BX, 100
		CALL    delay
		LEA		BX, MsgPoint
		CALL 	printf_s
		MOV     BX, 100
		CALL    delay
		LEA		BX, MsgPoint
		CALL 	printf_s
		MOV     BX, 100
		CALL    delay
		LEA		BX, MsgPoint
		CALL 	printf_s
		MOV     BX, 200
		CALL    delay
		MOV     BX, DelayCounter
		CMP     BX, 0000h
		JE		create_open_error_animation_end
		DEC		BX
		MOV     DelayCounter, BX
		JMP 	loop_create_open_error_animation
	create_open_error_animation_end:
		RET
create_open_error_animation ENDP

;--------------------------------------------------------------------
;Funcao para limpar uma linha
;--------------------------------------------------------------------
clean_line PROC near
	CALL    set_cursor_init_line
	LEA		BX, TextCleanLine
	CALL 	printf_s
	CALL    set_cursor_return_one_line
	RET
clean_line ENDP

;--------------------------------------------------------------------
;Funcao configura o modo de exibição de vídeo
;--------------------------------------------------------------------
set_video_mode PROC near
	MOV 	AH, 00h
	MOV     AL, 12h
	INT 	10h
	RET
set_video_mode ENDP
;-----------------------------------------------------------------------
;Funcao que verifica se o nome do arquivo é vazio
;Se sim retorna 01h em AX, se não retorna 00h
;-----------------------------------------------------------------------
is_empty_file_name PROC near
	LEA		BX, FileNameSrc				; *BX = &FileNameSrc
	MOV		DL, [BX]					; DL = BX[0]
	CMP		DL, 00h						; if DL == 0:
	JE		return_empty_true			; 	return true
	MOV		AX, 00h						; return false
	RET
return_empty_true:
	MOV		AX, 01h
	RET
is_empty_file_name ENDP
;--------------------------------------------------------------------
;Funcao adiciona o sufixo .par na file_name lida
;--------------------------------------------------------------------
add_file_in_sufix PROC near
	CALL    filter_file_name			; Remove other sufix
	LEA     BX, FileNameSrc				; Call str_concat
	MOV		Str1, BX					; str_concat(Str1, Str2)
	LEA		BX, StrFileInEndSmall
	MOV     Str2, BX					
	CALL    str_concat
	RET
add_file_in_sufix ENDP
;--------------------------------------------------------------------
;Funcao adiciona o sufixo .REL na file_name lida
;--------------------------------------------------------------------
add_file_out_sufix PROC near
	CALL    filter_file_name			; Remove other sufix
	LEA     BX, FileNameSrc				; Call str_concat
	MOV		Str1, BX					; str_concat(Str1, Str2)
	LEA		BX, StrFileOutEnd
	MOV     Str2, BX					
	CALL    str_concat
	RET
add_file_out_sufix ENDP
;--------------------------------------------------------------------
;Funcao configura o modo de exibição de texto
;--------------------------------------------------------------------
set_text_mode PROC near
	MOV 	AH, 00h
	MOV 	AL, 03h
	INT 	10h
	RET
set_text_mode ENDP
;--------------------------------------------------------------------
;Funcao para imprimir o cabecalho na tela
; - Seta o cursor para o inicio
; - Escreve o texto
; - Move o cursor para baixo
;--------------------------------------------------------------------
print_header PROC near
    MOV 	AH, 02h 
	MOV		BH, 00h ;page number
	MOV     DH, 00h ;row
	MOV     DL, 00h ;column
	INT     10h
	LEA	    BX, TextHeader
	CALL    printf_s
	RET
print_header ENDP

;--------------------------------------------------------------------
;Funcao para imprimir o rodapé da tela
;--------------------------------------------------------------------
print_footer PROC near
	CALL    add_file_in_sufix
	LEA 	BX, TextArquivo
	CALL    printf_s
	LEA		BX, TextSpace
	CALL    printf_s
	LEA     BX, FileNameSrc
	CALL    printf_s
	LEA     BX, TextSeparadorHifen
	CALL    printf_s
	LEA     BX, TextLadrilhosCor
	CALL 	printf_s
	CALL    draw_ladrilhos_footer
	RET
print_footer ENDP

;--------------------------------------------------------------------
;Funcao para imprimir a contagem de cada ladrilho no rodapé
;--------------------------------------------------------------------
print_contagem_ladrilhos PROC near
	MOV  InfoLineDesl, 0
	MOV ContadorB, 0
	loop_print_contagem_ladrilhos:
		CALL set_cursor_info_line
		MOV		BH, 0
		MOV     BL, ContadorB
		ADD     BL, ContadorB
		MOV 	AX,	ContLadrilhos[BX]
		CALL	printf_w
		MOV     CL, ContadorB
		CMP     CL, NLadrilhosFooter
		JE      print_contagem_ladrilhos_fim 
		INC     ContadorB
		MOV     AL, InfoLineSpace
		ADD     InfoLineDesl, AL
		JMP     loop_print_contagem_ladrilhos
print_contagem_ladrilhos_fim:
	RET
print_contagem_ladrilhos ENDP

;--------------------------------------------------------------------
;Funcao para desenhar todos os ladrilhos de informacao do footer
;--------------------------------------------------------------------
draw_ladrilhos_footer	PROC near
	MOV ContadorB, 0
	MOV InitColumn, InitColumnLadrilhosFooter
	MOV InitRow, RowLadrilhosFooter
	draw_ladrilhos_footer_loop:
		MOV  AL, ContadorB
		MOV  CodCor, AL
		CALL draw_ladrilho_footer
		CMP ContadorB, NLadrilhosFooter
		JE  draw_ladrilhos_footer_end
		INC ContadorB
		ADD InitColumn, LadrilhoFooterSize
		ADD InitColumn, LadrilhoFooterSpace
		JMP draw_ladrilhos_footer_loop
draw_ladrilhos_footer_end:
	RET
draw_ladrilhos_footer	ENDP

;--------------------------------------------------------------------
;Funcao para desenhar ladrilho de informacao do footer
; Entrada: CodCor -> código da cor
; 		   InitColumn -> Coluna onde se inicia o desenho
;		   InitRow    -> Linha onde se inicia o desenho
;--------------------------------------------------------------------
draw_ladrilho_footer PROC near
	MOV Coluna, 0
	MOV Linha, 0
	loop_draw_ladrilho_footer_linha:
		loop_draw_ladrilho_footer_coluna:
			CMP Coluna, 0
			JE  Cor_Branca_footer
			CMP Linha, 0
			JE  Cor_Branca_footer
			MOV DX, LadrilhoFooterSize
			DEC DX
			CMP Coluna, DX
			JE  Cor_Branca_footer
			MOV DX, LadrilhoFooterSize
			DEC DX
			CMP Linha, DX
			JE  Cor_Branca_footer
			MOV AL, CodCor
			JMP Colorido_footer
		Cor_Branca_footer:
			MOV AL, 0fh
		Colorido_footer:
			MOV CX, Coluna
			ADD CX, InitColumn
			MOV DX, Linha
			ADD DX, InitRow
			CALL draw_pixel
			INC Coluna
			MOV AX, LadrilhoFooterSize
			CMP Coluna, AX
			JNE loop_draw_ladrilho_footer_coluna
		INC Linha
		MOV AX, LadrilhoFooterSize
		CMP Linha, AX
		JE draw_ladrilho_footer_fim
		MOV Coluna, 0
		JMP  loop_draw_ladrilho_footer_linha
draw_ladrilho_footer_fim:
	RET
draw_ladrilho_footer ENDP


;--------------------------------------------------------------------
;Funcao para desenhar ladrilho na parede
; Entrada: CodCor -> código da cor
;--------------------------------------------------------------------
draw_ladrilho_parede PROC near
	MOV Coluna, 0
	MOV Linha, 0
	loop_draw_ladrilho_parede_linha:
		loop_draw_ladrilho_parede_coluna:
			CMP Coluna, 0
			JE  Cor_Branca_parede
			CMP Linha, 0
			JE  Cor_Branca_parede
			MOV DX, LadoLadrilho
			DEC DX
			CMP Coluna, DX
			JE  Cor_Branca_parede
			MOV DX, LadoLadrilho
			DEC DX
			CMP Linha, DX
			JE  Cor_Branca_parede
			MOV AL, CodCor
			JMP Colorido_parede
		Cor_Branca_parede:
			MOV AL, 0fh
		Colorido_parede:
			MOV CX, Coluna
			ADD CX, LadrilhoCursorColumn
			MOV DX, Linha
			ADD DX, LadrilhoCursorLine
			CALL draw_pixel_parede
			INC Coluna
			MOV AX, LadoLadrilho
			CMP Coluna, AX
			JNE loop_draw_ladrilho_parede_coluna
		INC Linha
		MOV AX, LadoLadrilho
		CMP Linha, AX
		JE draw_ladrilho_parede_fim
		MOV Coluna, 0
		JMP  loop_draw_ladrilho_parede_linha
draw_ladrilho_parede_fim:
	MOV AX, LadoLadrilho
	ADD LadrilhoCursorColumn, AX
	INC ColunaAtual
	MOV BL, NLadrilhosColuna
	CMP ColunaAtual, BL
	JE	go_to_next_line
	RET
go_to_next_line:
	MOV LadrilhoCursorColumn, 0
	MOV ColunaAtual, 0
	MOV AX, LadoLadrilho
	ADD LadrilhoCursorLine, AX
	INC LinhaAtual
	RET
draw_ladrilho_parede ENDP

;--------------------------------------------------------------------
;Funcao para desenhar um pixel na parede
; Entrada: AL = cor do pixel
;		   CX = column
;		   DX = row
;--------------------------------------------------------------------
draw_pixel_parede PROC near
	ADD     CX, 08		; Centraliza, compensando um inicio em 0 até 624
	ADD     DX, 26		; Centraliza, compensando um inicio em 0 até 330
	CALL    draw_pixel
	RET
draw_pixel_parede ENDP

;--------------------------------------------------------------------
;Funcao para desenhar um pixel
; Entrada: AL = cor do pixel
;		   CX = column
;		   DX = row
;--------------------------------------------------------------------
draw_pixel PROC near
	MOV		BH, 00h	
	MOV 	AH,	0Ch
	INT 	10h
	RET
draw_pixel ENDP
;--------------------------------------------------------------------
;Funcao para imprimir a linha reta separadora inicial
; - Seta o cursor para o inicio
; - Escreve a linha
; - Move o cursor para baixo
;--------------------------------------------------------------------
print_upper_line PROC near
	MOV 	AH, 02h 
	MOV		BH, 00 ;page number
	MOV     DH, 01 ;row
	MOV     DL, 00 ;column
	INT     10h
	LEA		BX, UpperBar
	CALL    printf_s
	RET
print_upper_line ENDP

;--------------------------------------------------------------------
;Funcao para imprimir a linha reta separadora final
; - Seta o cursor para o final
; - Escreve a linha
; - Move o cursor para baixo
;--------------------------------------------------------------------
print_bottom_line PROC near
	MOV 	AH, 02h 
	MOV		BH, 00 ;page number
	MOV     DH, 24 ;row
	MOV     DL, 00 ;column
	INT     10h
	LEA		BX, BottomBar
	CALL    printf_s
	RET
print_bottom_line ENDP

;--------------------------------------------------------------------
;Funcao para imprimir a linha lateral direita
; - Seta o cursor para o inicio e para a ultima coluna
; - Escreve o simbolo
; - Move o cursor uma linha para baixo
;--------------------------------------------------------------------
print_right_line PROC near
	MOV 	AH, 02h 
	MOV		BH, 00 ;page number
	MOV     DH, 02 ;row
	MOV     DL, 79 ;column
	INT     10h
	MOV		Contador, 0
	loop_print_right_line:	
			LEA		BX, SideBar
			CALL    printf_s
			INC     Contador
			CMP     Contador, 22
			JE      end_print_right_line
			CALL    set_cursor_last_column
			JMP     loop_print_right_line
	end_print_right_line:
			RET
print_right_line ENDP

;--------------------------------------------------------------------
;Funcao para imprimir a linha lateral esquerda
; - Seta o cursor para o inicio e para a primeira coluna
; - Escreve o simbolo
; - Move o cursor uma linha para baixo
;--------------------------------------------------------------------
print_left_line PROC near
	MOV 	AH, 02h 
	MOV		BH, 00 ;page number
	MOV     DH, 02 ;row
	MOV     DL, 00 ;column
	INT     10h
	MOV		Contador, 0
	loop_print_left_line:	
			LEA		BX, SideBar
			CALL    printf_s
			INC     Contador
			CMP     Contador, 22
			JE      end_print_left_line
			CALL    set_cursor_init_line
			CALL    set_cursor_next_line
			JMP     loop_print_left_line
	end_print_left_line:
			RET
print_left_line ENDP


;--------------------------------------------------------------------
;Funcao Pede o nome do arquivo de origem salva-o em FileNameSrc
;--------------------------------------------------------------------
get_file_name_src	PROC	near
	;printf("Nome do arquivo origem: ")
	LEA		BX, MsgPedeArquivoSrc
	CALL	printf_s

	;gets(FileNameSrc);
	LEA		BX, FileNameSrc
	CALL	gets
	
	;printf("\r\n")
	LEA		BX, MsgCRLF
	CALL	printf_s
	
	RET
get_file_name_src	ENDP
;--------------------------------------------------------------------
;Funcao que filtra o nome do arquivo retirando referencia ao tipo
;--------------------------------------------------------------------
filter_file_name 	PROC 	near
	LEA		BX, FileNameSrc	; str* = FileNameSrc 
	MOV     Contador, 00h	; Contador = 0				
 	loop_filter:	MOV		DL, [BX]		; while (true) {
					CMP     DL, 2Eh			; 	if (str[i] == '.') {
					JE      point_found     ;		go to point_found
 	return_loop:	INC     BX				;
					INC     Contador		;   i++
					CMP     DL, 00h         ;   if (str[i] == '\0') {
					JNE     loop_filter     ;     	break
	JMP 	filter_end		; go to filter_end  
	RET
point_found:
	MOV	    AX, Contador				; TempW = Contador //Salva a posição do ponteiro quando encontrado o "."
	MOV		TempW, AX					; 
	JMP     return_loop					; go to return_loop
filter_end:
	LEA		BX, FileNameSrc			    ; str = FileNameSrc 
	ADD     BX, TempW					; str = str + TempW
	MOV		Str1, BX					; Str1 = str			
	LEA     BX, StrFileInEndBig			; str = StrFileInEndBig
	MOV     Str2, BX					; Str2 = str	
	CALL    compare_string				; if compare_string(Str1, Str2):
	CMP     AX, 01h 					; 	goto cut_string_end
	JE      cut_string_end				;	
	LEA		BX, FileNameSrc				; str* = FileNameSrc 
	ADD     BX, TempW					; str* = str* + Contador
	MOV		Str1, BX					; Str1* = str*	
	LEA     BX, StrFileInEndSmall		; str* = StrFileInEndSmall
	MOV     Str2, BX					; Str2* = str*
	CALL    compare_string				; if compare_string(Str1, Str2):
	CMP     AX, 01h 					; 	goto cut_string_end
	JE      cut_string_end				;
	LEA		BX, FileNameSrc				; str* = FileNameSrc 
	ADD     BX, TempW					; str* = str* + Contador
	MOV		Str1, BX					; Str1* = str*	
	LEA     BX, StrFileOutEnd			; str* = StrFileInEndSmall
	MOV     Str2, BX					; Str2* = str*
	CALL    compare_string				; if compare_string(Str1, Str2):
	CMP     AX, 01h 					; 	goto cut_string_end
	JE      cut_string_end				;
	RET									; return
cut_string_end:
	LEA		BX, FileNameSrc
	ADD     BX, TempW				    ; str* = str* + Contador
	MOV     [BX], 00h					; &str = 0 
	RET									; return  
filter_file_name 	ENDP
;--------------------------------------------------------------------
; Funcao que compara strings 
; Recebe em Str1 e Str2 
; Returna 1 para True e 0 para False em AX
;--------------------------------------------------------------------
compare_string PROC near
	compare_loop:	
					MOV BX, Str1	  ; while True :
					MOV AL, [BX]	  		
					MOV BX, Str2
					MOV DL, [BX]
					CMP DL, AL        ; 	if str[i] != str_2[i]:
					JNE compare_false ;			goto compare_false
					CMP DL, 00h	  	  ;     if str[i] == '\0':
					JE  compare_end   ;         if str_2[i] == '\0': goto compare_true
					CMP [BX], 00h     ;     elif str_2[i] == '\0':
					JE  compare_false ;     	goto compare_false
					INC Str1		  ;
					INC Str2          ;		i++
					JMP compare_loop  ;
compare_end:
	CMP AL, 00h       ;     if str_2[i] == '\0':
	JE  compare_true  ;     	goto compare_true
	JMP compare_false ;     elif: goto compare_false
compare_true:
	MOV	AX, 01h		  ; return True
	RET
compare_false:
	MOV	AX, 00h       ; return False
	RET
compare_string ENDP
;--------------------------------------------------------------------
;Funcao para concatenar strings
;Entra: Str1 -> ponteiro para string 1
;		Str2 -> ponteiro para string 2
;Sai:	&Str1 -> string resultado
;--------------------------------------------------------------------
str_concat PROC near
	MOV  BX, Str1	  				; *BX = Str1	  	
	CALL is_empty					; if is_empty(BX):
	CMP  AX, 01h					;   return
    JE   str_concat_end				;	
	MOV  BX, Str2					; *BX = Str2
	CALL is_empty					; if is_empty(AX):
	CMP  AX, 01h					; 	return	 
    JE  str_concat_end				;	 
	MOV BX, Str1	  				; *BX = Str1 
	str_concat_find_end_loop:		; while True 
		MOV DL, [BX]				; 	DL = BX[i]
		CMP DL, 00h	  	  			;   if DL == '\0':
		JE  str_concat_core			;		goto str_concat_core
		INC BX						;   i++
		JMP str_concat_find_end_loop;  
	str_concat_core:				
		MOV Str1, BX				; *Str1 = BX
		str_concat_loop:			; while True
			MOV BX, Str2			;  	BX = Str2
			CMP [BX], 00h			;   if BX[i] == 0:
			JE 	str_concat_end		;		goto str_concat_end
			MOV DL, [BX]			;  	DL = BX[i]
			MOV BX, Str1			;   BX = Str1
			MOV [BX], DL			;	BX[x] = DL
			INC BX					;	BX[x+1] = '\0'
			MOV [BX], 0 			;				
			INC Str1				;   i++
			INC Str2				;  	x++
			JMP str_concat_loop		;
	str_concat_end:
		RET							; return
str_concat ENDP 

;--------------------------------------------------------------------
;Função	Verifica se uma string é vazia
;Entra: BX -> ponteiro para o string
;Sai:   AX -> 01h para verdadeiro e 00h para falso
;--------------------------------------------------------------------
is_empty PROC near
	MOV DL, [BX]					; DL = BX[0]
	CMP DL, 00h						; if DL == 0:
    JE  is_empty_true				;	return True
	MOV AX, 00h						; else:
	RET								;   return False
is_empty_true:
	MOV AX, 01h
    RET
is_empty ENDP


;--------------------------------------------------------------------
;Função	Para Calcular o tamanho dos ladrilhos
;--------------------------------------------------------------------
calculate_draw_size PROC near
	MOV DX, 0
	MOV	AX, 624
	MOV CH, 0
	MOV CL, NLadrilhosColuna 
	DIV CX
	MOV LadoLadrilho, AX 
	MOV DX, 0
	MOV AX, 360
	MOV CH, 0
	MOV CL, NLadrilhosLinha
	DIV CX
	CMP LadoLadrilho, AX
	JG  choose_smaller
	RET
choose_smaller:
	MOV LadoLadrilho, AX
	RET
calculate_draw_size	ENDP

;--------------------------------------------------------------------
;Função	Abre o arquivo cujo nome está no string apontado por DX
;		boolean fopen(char *FileName -> DX)
;Entra: DX -> ponteiro para o string com o nome do arquivo
;Sai:   BX -> handle do arquivo
;       CF -> 0, se OK
;--------------------------------------------------------------------
fopen	PROC	near
	MOV		AL,0
	MOV		AH,3dh
	INT		21h
	MOV		BX,AX
	RET
fopen	ENDP
;--------------------------------------------------------------------
;Função Cria o arquivo cujo nome está no string apontado por DX
;		boolean fcreate(char *FileName -> DX)
;Sai:   BX -> handle do arquivo
;       CF -> 0, se OK
;--------------------------------------------------------------------
fcreate	PROC	near
	MOV		CX,0
	MOV		AH,3ch
	INT		21h
	MOV		BX,AX
	RET
fcreate	ENDP


;--------------------------------------------------------------------
;Entra:	BX -> file handle
;Sai:	CF -> "0" se OK
;--------------------------------------------------------------------
fclose	PROC	near
	MOV		AH,3eh
	INT		21h
	RET
fclose	ENDP

;--------------------------------------------------------------------
;Função	Le um ladrinho e retorna sua cor
;Sai:   DL -> Cor do ladrilho
;       AX -> 01 Sucesso, 00 Fim leitura
;--------------------------------------------------------------------
read_ladrilho PROC	near
	MOV		BX, FileHandleSrc
	CALL    getChar
	JB		error_reading
	CMP     AX, 0
	JE		fim_leitura_documento
	CMP     DL, CR				; if DL == CR
	JE		ladrilho_line_end
	JMP     read_ladrilho_color
error_reading:
	LEA 	BX, MsgErroLendo
	CALL 	printf_s
	MOV 	AX, 00h
	RET
ladrilho_line_end:
	MOV		BX, FileHandleSrc
	CALL    getChar
	JB		error_reading
	CMP     AX, 0
	JE		fim_leitura_documento
	MOV		BX, FileHandleSrc
	CALL    getChar
	JB		error_reading
	CMP     AX, 0
	JE		fim_leitura_documento
read_ladrilho_color:
	CMP     DL, CR				; if DL == CR
	JE      fim_leitura_documento
    CMP     DL, 58
	JL		read_ladrilho_int
	JMP     read_ladrilho_char
read_ladrilho_int:
	SUB     DL, 48
	MOV     AX, 01
	RET
read_ladrilho_char:
	SUB     DL, 55
	MOV     AX, 01
	RET
fim_leitura_documento:
	MOV     AX, 00
	RET
read_ladrilho	ENDP

;--------------------------------------------------------------------
;Função	Le um numero do arquivo de entrada
;Sai:   ReadNumber -> numero
;		AX -> 00h erro, 01h sucesso
;--------------------------------------------------------------------
get_number_until_colon PROC	near
	MOV ReadNumber, 0
	loop_until_colon:
		MOV		BX, FileHandleSrc
		CALL    getChar
		JB		get_number_error_reading
		CMP     DL, 44				; if DL == ','
		JE		number_end
		CMP     DL, CR				; if DL == CR
		JE		number_end_cr
		MOV     AL, ReadNumber
		MOV     BL, 10
		MUL		BL
		MOV     ReadNumber, AL
		SUB     DL, 48  
		ADD		ReadNumber, DL 
		JMP 	loop_until_colon
get_number_error_reading:
	LEA BX, MsgErroLendo
	CALL printf_s
	MOV AX, 00h
	RET
number_end_cr:
	MOV		BX, FileHandleSrc
	CALL    getChar
	JB		get_number_error_reading
number_end:
	MOV AX, 01h
	RET		
get_number_until_colon	ENDP

;--------------------------------------------------------------------
;Função	Le um caractere do arquivo identificado pelo HANLDE BX
;		getChar(handle->BX)
;Entra: BX -> file handle
;Sai:   DL -> caractere
;		AX -> numero de caracteres lidos
;		CF -> "0" se leitura ok
;--------------------------------------------------------------------
getChar	PROC	near
	MOV		AH,3fh
	MOV		CX,1
	LEA     DX,FileBuffer
	INT		21h
	MOV     DL,FileBuffer
	RET
getChar	ENDP

;--------------------------------------------------------------------
;Entra: BX -> file handle
;       DL -> caractere
;Sai:   AX -> numero de caracteres escritos
;		CF -> "0" se escrita ok
;--------------------------------------------------------------------
setChar	PROC	near
	MOV		AH,40h
	MOV		CX,1
	MOV		FileBuffer,DL
	LEA		DX,FileBuffer
	INT		21h
	RET
setChar	ENDP	

;--------------------------------------------------------------------
; Função para setar o cursor para o inicio da linha
;--------------------------------------------------------------------
set_cursor_init_line	PROC	near
	MOV		BH, 0
	MOV     AH, 3
	INT		10h			; Get cursor position
	MOV     DL, 0
	MOV     AH, 2
	INT     10h			; Set cursor position with column = 0
	RET
set_cursor_init_line	ENDP

;--------------------------------------------------------------------
; Função para setar o cursos para a ultima coluna
;--------------------------------------------------------------------
set_cursor_last_column	PROC	near
	MOV		BH, 0
	MOV     AH, 3
	INT		10h			; Get cursor position
	MOV     DL, 79
	MOV     AH, 2
	INT     10h			; Set cursor position with column = 0
	RET
set_cursor_last_column	ENDP

;--------------------------------------------------------------------
; Função para retornar uma linha
;--------------------------------------------------------------------
set_cursor_return_one_line PROC	near
	MOV		BH, 0
	MOV     AH, 3
	INT		10h			; Get cursor position
	DEC     DH
	MOV     DL, 0
	MOV     AH, 2
	INT     10h			; Set cursor position with column = 0
	RET
set_cursor_return_one_line ENDP

;--------------------------------------------------------------------
; Função para avançar uma linha
;--------------------------------------------------------------------
set_cursor_next_line PROC	near
	MOV		BH, 0
	MOV     AH, 3
	INT		10h			; Get cursor position
	INC     DH
	MOV     DL, 0
	MOV     AH, 2
	INT     10h			; Set cursor position with column = 0
	RET
set_cursor_next_line ENDP

;--------------------------------------------------------------------
; Função para posicionar o cursor na linha onde serão escritas
; as informações sobre a quantidade dos ladrilhos
;	Entrada: InfoLineDesl -> Deslocamento da coluna
;--------------------------------------------------------------------
set_cursor_info_line PROC	near
	MOV     DH, InfoLineRow		; Row
	MOV     DL, InfoLineColumn		; Column
	ADD     DL, InfoLineDesl
	MOV		BH, 0
	MOV     AH, 2
	INT     10h			
	RET
set_cursor_info_line ENDP

;--------------------------------------------------------------------
;Funcao Le um string do teclado e coloca no buffer apontado por BX
;		gets(char *s -> BX)
;--------------------------------------------------------------------
gets	PROC	near
	PUSH	BX

	MOV		AH,LF						; Lê uma linha do teclado
	LEA		DX,String
	MOV		byte ptr String, MAXSTRING-4	; 2 caracteres no inicio e um eventual CR LF no final
	INT		21h

	LEA		si,String+2					; Copia do buffer de teclado para o FileName
	pop		DI
	MOV		CL,String+1
	MOV		CH,0
	MOV		AX,DS						; Ajusta ES=DS para poder usar o MOVSB
	MOV		es,AX
	rep 	movsb

	MOV		byte ptr es:[DI],0			; Coloca marca de fim de string
	RET
gets	ENDP

;--------------------------------------------------------------------
;Função Escrever um string na tela
;		printf_s(char *s -> BX)
;--------------------------------------------------------------------
printf_s	PROC	near
	MOV		DL,[BX]
	CMP		DL,0
	JE		ps_1
	PUSH	BX
	MOV		AH,2
	INT		21H
	pop		BX

	INC		BX		
	JMP		printf_s
		
ps_1:
	RET
printf_s	ENDP

;
;--------------------------------------------------------------------
;Função: Escreve o valor de AX na tela
;		printf("%
;--------------------------------------------------------------------
printf_w	PROC	near
	; sprintf_w(AX, BufferWRWORD)
	LEA		BX,BufferWRWORD
	CALL	sprintf_w
	
	; printf_s(BufferWRWORD)
	LEA		BX,BufferWRWORD
	CALL	printf_s
	
	RET
printf_w	ENDP

;
;-------------------------------------------------------------------------
;Função: Delay, interrompe a execução do programa por n ms
; Entrada: BX -> número de ms
;-------------------------------------------------------------------------
delay PROC   
	loop_delay: 
		MOV AL, 00h		  ;Delay 1 milisecond
  		MOV CX, 0000h     ;HIGH WORD.
  		MOV DX, 03E8h  	  ;LOW WORD.
  		MOV AH, 86h       ;WAIT.
  		INT 15h
		DEC BX
		CMP BX, 00h
		JE  delay_return
		JMP loop_delay
	delay_return:
  		RET
delay ENDP      
;--------------------------------------------------------------------
;Função: Converte um inteiro (n) para (string)
;		 sprintf(string->BX, "%d", n->AX)
;--------------------------------------------------------------------
sprintf_w	PROC	near
	MOV		sw_n,AX
	MOV		CX,5
	MOV		sw_m,10000
	MOV		sw_f,0
	
sw_do:
	MOV		DX,0
	MOV		AX,sw_n
	DIV		sw_m
	
	CMP		AL,0
	JNE		sw_store
	CMP		sw_f,0
	JE		sw_continue
sw_store:
	ADD		AL,'0'
	MOV		[BX],AL
	INC		BX
	
	MOV		sw_f,1
sw_continue:
	
	MOV		sw_n,DX
	
	MOV		DX,0
	MOV		AX,sw_m
	MOV		bp,10
	DIV		bp
	MOV		sw_m,AX
	
	DEC		CX
	CMP		CX,0
	jnz		sw_do

	CMP		sw_f,0
	jnz		sw_continua2
	MOV		[BX],'0'
	INC		BX
sw_continua2:

	MOV		byte ptr[BX],0
	RET		
sprintf_w	ENDP
;
;--------------------------------------------------------------------
		end
;--------------------------------------------------------------------