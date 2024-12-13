;--------------------------------------------------------------------------------------------------
		;TRABALHO INTEL - Mariana Siqueira Zamora
		
;criterios implementados no codigo:
;	-laço de impressao
;	-movimento das teclas
;	-teste de limites laterais
;	-variacao aleatoria
;	-teste de colisao com fim de jogo
; 	-profundidade informada durante e no fim do jogo
;	-largura diminui com o tempo
;	-variacao aumenta com o tempo
;	-fim de jogo por resistencia ("ganhou o jogo")
;	-look ahead de 4 linhas
;extras:
;	-menu inicial com escolha de dificuldade (escolhe a profundidade necessaria para ganhar)
;	-cabeçalho que mostra a profundidade conforme aumenta e a largura conforme diminui
;	-jogador decide se recomeca o jogo ou nao quando acaba

;--------------------------------------------------------------------------------------------------

;inicialização
.model small
.stack 1000

;--------------------------------------------------------------------------------------------------
		;AREA DE DADOS
.data
	;variaveis de controle
winvar	dw 0
gameover db 0
depth dw 0, 0
deslocamento db 0
variation db 0
random db 0
dificulty db 0
	;constantes
_251 db 251
_2 db 2
_7	db 7
	;variaveis de posição
nave db 0
pleft db 0		;foi preferivel guardar somente o ponteiro de inicio e largura do vale para nao ocupar o espaço de 4 strings na memoria 
pwidth db 0
pleft1 db 0
pwidth1 db 0
pleft2 db 0
pwidth2 db 0
pleft3	db 0
pwidth3	db 0
	;string de controle(0)
snave  db 'V', '$'
buffer db 70 dup('.')
endbuf db 13,10,'$'
	;cabeçalho
header db 201, 68 dup(205), 187, 13, 10, 186, 25 dup(' '), 'profundidade: '
hprofundidade db '0000', 25 dup(' '), 186, 13, 10, 186, 28 dup(' '), 'largura: '
hlargura db '025', 28 dup(' '), 186, 13, 10, 200, 68 dup(205), 188, 13, 10, '$'
	;tela de game over
gameoverstring	db 201, 68 dup(205), 187, 13, 10, 186, 68 dup(' '), 186, 13, 10, 186, 29 dup(' '), 'Game over!', 29 dup(' '), 186, 13, 10
continuastring db 186, 19 dup(' '), 'Deseja tentar novamente? (S/N)', 19 dup(' '), 186, 13, 10, 186, 68 dup(' '), 186, 13, 10, 200, 68 dup(205), 188, '$'
	;tela de win
gamewinstring	db 201, 68 dup(205), 187, 13, 10, 186, 68 dup(' '), 186, 13, 10, 186, 23 dup(' '), 'Parabens! Voce ganhou!', 23 dup(' '), 186, 13, 10
cwinstring db 186, 20 dup(' '), 'Deseja jogar novamente?(S/N)', 20 dup(' '), 186, 13, 10, 186, 68 dup(' '), 186, 13, 10, 200, 68 dup(205), 188, '$'
	;menu
menustring	db '	Selecione a dificuldade: ', 13, 10, '		1- Facil (alcance 150 de profundidade para ganhar)', 13, 10, '		2- Medio (alcance 250 de profundidade para ganhar)'
continuamenu db 13, 10, '		3- Dificil (alcance 350 de profundidade para ganhar)', 13, 10, '		Qualquer outra tecla- Infinito', 13, 10, 13, 10
tutorial db ' Como jogar: Use a tecla A para ir para a Esquerda e D para ir para a Direita!', 13, 10, 13, 10, '	Digite sua opcao: ', '$'

;--------------------------------------------------------------------------------------------------
		;INICIALIZAÇÃO DO CODIGO
.code
.startup
start: 
		;inicializa o es
		mov 	ax, ds
		mov 	es, ax
		;inicializa as variaveis de posicao
		mov 	pleft, 25
		mov 	pwidth, 25
		mov		pleft1, 25
		mov 	pwidth1, 25
		mov		pleft2, 25
		mov		pwidth2, 25
		mov 	pleft3, 25
		mov 	pwidth3, 25
		mov 	nave, 38
		mov 	gameover, 0
		mov 	depth, 0
		;reinicia as variaveis do cabeçalho
		mov 	al, '0'
		mov 	bl, 0
		mov 	bx, 0
		mov		[hprofundidade+bx], al
		inc 	bx
		mov		[hprofundidade+bx], al
		inc 	bx
		mov		[hprofundidade+bx], al
		inc 	bx
		mov		[hprofundidade+bx], al
		mov 	hlargura, al
		mov 	al, '2'
		mov 	bl, 1
		mov 	[hlargura+bx], al
		mov 	al, '5'
		inc 	bx
		mov 	[hlargura+bx], al
		
		;inicializa outras variaveis
		mov 	variation, 4
		mov 	random, 1
		mov 	deslocamento, 1
		
		;coloca a tela em modo texto
		mov		ah, 0
		mov		al, 3h
		INT 	10h
		
		;chama a funcao que escreve o menu
		call 	SELECT_DIFICULTY
		
		;coloca o modo da tela de novo para limpar
		mov		ah, 0
		mov		al, 3h
		INT 	10h
		
		;muda a posicao do cursor inicial
		mov 	ah, 2
		mov 	bh, 0
		mov 	dl, 0
		mov		dh, 25
		int 	10h
		
		;chama a funcao que escreve o cabeçalho
		call 	PRINT_HEADER
;--------------------------------------------------------------------------------------------------
		;INICIO DO LOOP
		
maingameloop:
		
		;chama função de escrita de 'O' na string de controle
		call 	RESET_STRING
		;chama função que calcula a aleatoriedade do vale
		call 	CALC_VALLEY
		;chama função de escrita de ' ' na string de controle
		call 	WRITE_VALLEY
		;chama a função que atualiza o cabeçalho
		call 	UPDATE_HEADER
		;chama a função que escreve o cabeçalho
		call 	PRINT_HEADER
		;chama função que atualiza a posição da nave +(pega a entrada)
		call	UPDATE_SHIP
		;chama função que escreve a string na tela
		call 	PRINT_STRING
		;chama função que verifica a colisão
		call	CHECK_COLLISION
		;logo depois de conferir a colisão vê se precisa encerrar o loop
		mov 	al, gameover
		cmp 	al, 1
		je 		endgame
		;chama função que diminui espaços depois de certa profundidade
		call 	INC_DIFICULTY
		;atualiza a variavel de profundidade
		inc 	depth
		;chama função que diminui a velocidade do código
		call 	SLOW_DOWN
		call	SLOW_DOWN
		call 	SLOW_DOWN
		call 	SLOW_DOWN
		call 	SLOW_DOWN
		call	SLOW_DOWN
		;atualiza as variaveis de posicao
		mov 	al, pleft2
		mov 	pleft3, al
		mov 	al, pwidth3
		mov 	pwidth3, al
		mov 	al, pleft1
		mov 	pleft2, al
		mov		al, pwidth1
		mov		pwidth2, al
		mov 	al, pleft
		mov 	pleft1, al
		mov		al, pwidth
		mov		pwidth1, al
		;confere se ganhou o jogo a partir da dificuldade selecionada
		mov 	ax, depth
		cmp 	ax, winvar
		je 		gamewin
		jmp 	maingameloop
endgame:
		call	PRINT_GAMEOVER
		call 	PRINT_HEADER	;é necessário imprimir o header depois do game over para evitar que o scroll da tela apague o cabeçalho
		jmp		 finish
gamewin:
		call 	PRINT_WIN
		call 	PRINT_HEADER
finish:
		;coloca cursor no lugar certo
		mov 	ah, 2
		mov 	bh, 0
		mov 	dl, 34
		mov		dh, 23
		int 	10h
		;verifica se o usuario quer recomecar o jogo
		mov 	ah, 1
		int 	21h
		;muda a variavel winvar de acordo com a opcao escolhida
		cmp 	al, 'S'
		je 		start
		cmp 	al, 's'
		je 		start
		cmp 	al, 'N'
		je 		acaba
		cmp 	al, 'n'
		je 		acaba
		jmp 	finish
acaba:
		;coloca cursor na ultima linha
		mov 	ah, 2
		mov 	bh, 0
		mov 	dl, 0
		mov		dh, 24
		int 	10h
		.exit 

;--------------------------------------------------------------------------------------------------
;função que escreve o menu para selecionar a dificuldade
SELECT_DIFICULTY	PROC NEAR
		;imprime o menu
		lea 	dx, menustring
		mov 	ah, 9
		mov 	al, 0
		int 	21h
		;espera tecla
		mov 	ah, 1
		int 	21h
		;muda a variavel winvar de acordo com a opcao escolhida
		cmp 	al, '1'
		je 		facil
		cmp 	al, '2'
		je 		medio
		cmp 	al, '3'
		je 		dificil 
		mov 	winvar, 1000
		jmp		acaboumenu
facil:
		mov 	winvar, 150
		jmp 	acaboumenu
medio:
		mov 	winvar, 250
		jmp		acaboumenu
dificil:
		mov 	winvar, 350
acaboumenu:
		RET
SELECT_DIFICULTY	ENDP
;--------------------------------------------------------------------------------------------------
;funcao que aumenta a dificuldade depois de 75 linhas
INC_DIFICULTY	PROC NEAR
		inc 	dificulty
		mov		al, dificulty
		cmp		al, 75
		jne 	volta_pra_main
		mov 	dificulty,0
		inc 	variation
		dec 	pwidth
		;aqui tambem diminui a largura mostrada no cabeçalho e confere se precisa diminuir a casa das dezenas tambem
		mov		bl, 2
		mov		bh, 0
		mov		al, [hlargura+BX]
		cmp 	al, '0'
		je		dec_dezenas
		dec		[hlargura+bx]
		jmp 	voltapramain
dec_dezenas:
		mov		al, '9'
		mov		[hlargura+bx], al
		mov 	bl, 1
		dec 	[hlargura+bx]
volta_pra_main:
		RET
INC_DIFICULTY	ENDP
;--------------------------------------------------------------------------------------------------
;funcao que imprime a string de game over na tela
PRINT_GAMEOVER	PROC NEAR
		lea 	dx, gameoverstring
		mov 	ah, 9
		mov 	al, 0
		int 	21h
		RET
PRINT_GAMEOVER	ENDP		
;--------------------------------------------------------------------------------------------------
;funcao que imprime a string que anuncia que o jogador venceu
PRINT_WIN	PROC NEAR
		lea 	dx, gamewinstring
		mov 	ah, 9
		mov 	al, 0
		int 	21h
		RET
PRINT_WIN	ENDP
;--------------------------------------------------------------------------------------------------
;funcao que escreve 'O' na string da memoria
RESET_STRING 	PROC NEAR
		mov cx, 70
		mov ch, 0
		lea di, buffer
		cld
		mov al, 'O'
		REP STOSB 
		RET
RESET_STRING	ENDP
;--------------------------------------------------------------------------------------------------
;funcao que calcula o lugar que o vale vai ocupar na string
CALC_VALLEY		PROC NEAR
		call 	DET_DIRECTION	;para isso chama uma função que calcula aleatoriamente se vai para esquerda ou direita
		call 	DET_VARIATION	;chama função que tambem calcula aleatoriamente quantos caracteres vai andar para esse lado
		cmp		random, 1
		je		esquerda
direita:
		mov		al, pleft
		add		al, deslocamento
		cmp		al, 40  ;compara se chegou no limite lateral direito: 70 (tamanho total) - 25 (tamanho max de largura) - 5 tamanho minimo 
		JGE		esquerda	;se sim anda a variacao calculada para a esquerda
		mov		pleft, al
		JMP		return
esquerda:
		mov		al, pleft
		sub 	al, deslocamento
		cmp		al, 5	;compara se chegou no limite lateral esquerdo
		JLE		direita	;se sim anda a variacao calculada para a direita
		mov		pleft, al
return:
		RET
CALC_VALLEY		ENDP
;--------------------------------------------------------------------------------------------------
;funcao que escreve o vale na string de memoria depois de atualizado o ponteiro esquerdo
WRITE_VALLEY 	PROC NEAR	
		mov		 cl, pwidth
		mov	 	ch, 0
		mov 	bl, pleft
		mov		 bh, 0
		lea 	di, [buffer+BX]
		cld
		mov 	al, ' '
		REP STOSB
		RET
WRITE_VALLEY	ENDP
;--------------------------------------------------------------------------------------------------
;funcao que imprime a string na tela
PRINT_STRING	PROC NEAR
		lea 	dx, buffer
		mov 	ah, 9
		mov 	al, 0
		int 	21h
		RET
PRINT_STRING	ENDP
;--------------------------------------------------------------------------------------------------
DET_DIRECTION	PROC NEAR
;função usa o algoritmo aleatório para calcular se vai se deslocar para esquerda ou direita
		mov 	ax, depth
		mul 	_7
		add 	ax, 47
		div 	_251
		mov 	random, ah
		mov 	al, random
		mov 	ah, 0
		add 	ax, 250
		mov		dh, 0
		mov 	dl, 0
		div 	_2
		mov 	random, ah
		RET
DET_DIRECTION	ENDP
;--------------------------------------------------------------------------------------------------
;funcao que usa o algoritmo aleatorio (com algumas modificacoes) para calcular o numero de caracteres a serem deslocados
DET_VARIATION	PROC NEAR
		mov 	ax, depth
		mul 	deslocamento
		add 	ax, 47
		div 	_251
		mov 	deslocamento, ah
		mov 	al, deslocamento
		mov 	ah, 0
		mov		dh, 0
		mov 	dl, 0
		div 	variation
		mov 	deslocamento, ah
		inc 	deslocamento
		RET
DET_VARIATION	ENDP
;--------------------------------------------------------------------------------------------------
;funcao que serve para diminuir a velocidade do codigo (loop grande)
SLOW_DOWN		PROC NEAR
		mov 	cx, 60000
loop1:
		LOOP	loop1
		RET
SLOW_DOWN	ENDP
;--------------------------------------------------------------------------------------------------
;funcao que verifica se houve output e atualiza a posicao da nave de acordo
UPDATE_SHIP		PROC NEAR
		mov 	ah, 1
		mov 	al, 0
		int 	16h		;chama a interrupção que verifica se uma tecla foi apertada
		jz		retorna
		mov		ah, 0	;se sim chama a interrupção que retira a tecla do buffer
		int 	16h
		cmp 	al, 'd'
		je		n_direita
		cmp		al, 'D'
		je		n_direita
		cmp		al, 'a'
		je 		n_esquerda
		cmp		al, 'A'
		je		n_esquerda
		cmp		al, 'X'	;ao apertar x há game over para fins de teste
		je		fecha
		cmp		al, 'x'
		je		fecha
		JMP		retorna
n_direita:		
		inc		nave	;a nave anda sempre dois espaços para a direita ou esquerda
		inc 	nave
		JMP		retorna
n_esquerda:
		dec		nave
		dec 	nave
		JMP		retorna
fecha:
		mov		gameover, 1
		JMP		retorna
retorna:
		call WRITE_SHIP	;chama a funcao que escreve a nave na tela
		RET
UPDATE_SHIP	ENDP
;--------------------------------------------------------------------------------------------------
;funcao que verifica se houve colisao e se sim, da game over
CHECK_COLLISION		PROC NEAR
		mov 		bl, pleft3
		add 		bl, pwidth3
		cmp		nave, bl	;igual ou maior
		jl		sem_colisao_direita
		mov		gameover, 1
sem_colisao_direita:
		mov		bl, pleft3
		cmp 	nave, bl
		jg		volta
		mov		gameover, 1
volta:
		RET
CHECK_COLLISION	ENDP
;--------------------------------------------------------------------------------------------------
;funcao que escreve a nave na tela
WRITE_SHIP		PROC NEAR
	;primeiro muda a posicao do cursor
	mov 	ah, 2
	mov 	bh, 0
	mov 	dl, nave
	mov		dh, 21
	int 	10h
	;depois escreve a nave na posicao do cursor
	lea 	dx, snave
	mov 	ah, 9
	mov 	al, 0
	int 	21h
	;coloca o cursor novamente na posicao certa
	mov 	ah, 2
	mov 	bh, 0
	mov 	dl, 0
	mov		dh, 24
	int 	10h
	RET
WRITE_SHIP	ENDP
;--------------------------------------------------------------------------------------------------
;funcao que imprime o cabeçalho na tela
PRINT_HEADER PROC NEAR
	;primeiro muda a posicao do cursor
	mov 	ah, 2
	mov 	bh, 0
	mov 	dl, 0
	mov		dh, 1
	int 	10h
	;depois escreve a string do cabeçalho na tela
	lea 	dx, header
	mov 	ah, 9
	mov 	al, 0
	int 	21h
	;termina colocando o cursor na posicao certa
	mov 	ah, 2
	mov 	bh, 0
	mov 	dl, 0
	mov		dh, 24
	int 	10h
	RET
PRINT_HEADER ENDP
;--------------------------------------------------------------------------------------------------
;funcao que atualiza os dados mostrados no cabeçalho
UPDATE_HEADER	PROC NEAR
	mov		bl, 3
	mov		bh, 0
	mov		al, [hprofundidade+bx]
	cmp		al, '9'		;primeiro confere se precisa aumentar a casa das dezenas da profundidade
	je		aumenta_dezenas
	inc 	[hprofundidade+bx]
	JMP		voltapramain
aumenta_dezenas:
	mov		al, '0'
	mov		[hprofundidade+bx], al
	dec 	bx
	mov		al, [hprofundidade+bx]
	cmp 	al, '9'		;confere se precisa aumentar a casa das centenas de profundidade
	je		aumenta_centenas
	inc 	[hprofundidade+bx]
	jmp 	voltapramain
aumenta_centenas:
	mov 	al, '0'
	mov 	[hprofundidade+bx], al
	dec 	bx 
	mov 	al, [hprofundidade+bx]
	cmp 	al, '9'
	je 		aumenta_milhares	;confere se precisa aumentar a casa dos milhares de profundidade
	inc 	[hprofundidade+bx]	
	jmp 	voltapramain
aumenta_milhares:
	inc 	hprofundidade
voltapramain:
	RET
UPDATE_HEADER	ENDP
;--------------------------------------------------------------------------------------------------
END