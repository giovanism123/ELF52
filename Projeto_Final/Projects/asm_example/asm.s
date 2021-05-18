        PUBLIC  __iar_program_start
        EXTERN  __vector_table

        SECTION .text:CODE:REORDER(2)
        
        ;; Keep vector table even if it's not referenced
        REQUIRE __vector_table
        
        THUMB

; System Control definitions
SYSCTL_BASE             EQU     0x400FE000
SYSCTL_RCGCGPIO         EQU     0x0608
SYSCTL_PRGPIO		EQU     0x0A08
SYSCTL_RCGCUART         EQU     0x0618
SYSCTL_PRUART           EQU     0x0A18
; System Control bit definitions
PORTA_BIT               EQU     000000000000001b ; bit  0 = Port A
PORTF_BIT               EQU     000000000100000b ; bit  5 = Port F
PORTJ_BIT               EQU     000000100000000b ; bit  8 = Port J
PORTN_BIT               EQU     001000000000000b ; bit 12 = Port N
UART0_BIT               EQU     00000001b        ; bit  0 = UART 0

; NVIC definitions
NVIC_BASE               EQU     0xE000E000
NVIC_EN1                EQU     0x0104
VIC_DIS1                EQU     0x0184
NVIC_PEND1              EQU     0x0204
NVIC_UNPEND1            EQU     0x0284
NVIC_ACTIVE1            EQU     0x0304
NVIC_PRI12              EQU     0x0430

; GPIO Port definitions
GPIO_PORTA_BASE         EQU     0x40058000
GPIO_PORTF_BASE    	EQU     0x4005D000
GPIO_PORTJ_BASE    	EQU     0x40060000
GPIO_PORTN_BASE    	EQU     0x40064000
GPIO_DIR                EQU     0x0400
GPIO_IS                 EQU     0x0404
GPIO_IBE                EQU     0x0408
GPIO_IEV                EQU     0x040C
GPIO_IM                 EQU     0x0410
GPIO_RIS                EQU     0x0414
GPIO_MIS                EQU     0x0418
GPIO_ICR                EQU     0x041C
GPIO_AFSEL              EQU     0x0420
GPIO_PUR                EQU     0x0510
GPIO_DEN                EQU     0x051C
GPIO_PCTL               EQU     0x052C

; UART definitions
UART_PORT0_BASE         EQU     0x4000C000
UART_FR                 EQU     0x0018
UART_IBRD               EQU     0x0024
UART_FBRD               EQU     0x0028
UART_LCRH               EQU     0x002C
UART_CTL                EQU     0x0030
UART_CC                 EQU     0x0FC8
;UART bit definitions
TXFE_BIT                EQU     10000000b ; TX FIFO full
RXFF_BIT                EQU     01000000b ; RX FIFO empty
BUSY_BIT                EQU     00001000b ; Busy


; PROGRAMA PRINCIPAL



; R3 OPERAÇÃO (1, 2, 3, 4 PARA +, -, *, /,Respectivamente)

__iar_program_start
        
main:   MOV R2, #(UART0_BIT)
	BL UART_enable ; habilita clock ao port 0 de UART

        MOV R2, #(PORTA_BIT)
	BL GPIO_enable ; habilita clock ao port A de GPIO
        
	LDR R0, =GPIO_PORTA_BASE
        MOV R1, #00000011b ; bits 0 e 1 como especiais
        BL GPIO_special

	MOV R1, #0xFF ; máscara das funções especiais no port A (bits 1 e 0)
        MOV R2, #0x11  ; funções especiais RX e TX no port A (UART)
        BL GPIO_select

	LDR R0, =UART_PORT0_BASE
        BL UART_config ; configura periférico UART0
        
        ; recepção e envio de dados pela UART utilizando sondagem (polling)
        ; resulta em um "eco": dados recebidos são retransmitidos pela UART
        
        MOV R3, #0 ;ZERA O OPERADOR
        MOV R10, #0 ;ZERA O CONTADOR DE DIGITOS
        MOV R4, #0
        MOV R5, #0
        MOV R11, #0

loop:
wrx:    LDR R2, [R0, #UART_FR] ; status da UART
        TST R2, #RXFF_BIT ; receptor cheio?
        BEQ wrx
        LDR R1, [R0] ; lê do registrador de dados da UART0 (recebe) - SALVA EM R1
        
        ;AND R1, R1, #0xFF     ;ignora paridade na entrada. só que ainda precisa implementar na saída :(
 
        ;BL leitura_bin ;debbug


;verifica_dig:
        CMP R1, #0x3D ;se igual
        BEQ igual
        
        CMP R1, #0x2B ;se +
        BEQ op_adi
        
        CMP R1, #0x2D ;se -
        BEQ op_sub
        
        CMP R1, #0x2A ;se *
        BEQ op_mul
        
        CMP R1, #0x2F ;se /
        BEQ op_div
        
        
        CMP R1, #0x30 ;se for menor que 0x30 (zero em ascii) volta pra ler
        BLO loop
        CMP R1, #0x3A ;se for menor ou igual a 0x39 (9 em ascii), e maior que 30 (não desviou) monta o numero
        BLO monta_num
        
        B loop        ;se o valor não é esperado, volta pra leitura


monta_num:
        ADD R10, R10, #1 ;+1 no contador de digitos
        CMP R10, #4;maior que 4?
        BHI loop    ;se for, a entrada é invalida. Volta a leitura
        MOV R2, #10
        MULS R5, R5, R2 ;multiplica R5 por 10
        SUBS R2, R1, #0x30
        ADD R5, R5, R2 ;soma R5 ao valor lido 
        B wtx      ;ecoa o digito

igual:
        CMP R3, #0 ;se ainda não tiver operação, a entrada é invalida
        BEQ loop
        CMP R10, #0 ;caso nenhum digito foi inserido, é uma entrada invalida,
        BEQ loop   ;então volta a leitura 
igual_wtx:              ;imprime o =                                                
        LDR R2, [R0, #UART_FR] ; status da UART
        TST R2, #TXFE_BIT ; transmissor vazio?
        BEQ igual_wtx
        STR R1, [R0] ; escreve no registrador de dados da UART0 (transmite)
        
        BL Calculate ;faz R4 (operação) R5
        ;Adicionar \r e \n (CR, LF) na pilha 
        ;Converter o resultado para pilha ascii
        
        MOV R3, #0;limpar R3, R4, R5, R10
        MOV R4, #0
        MOV R5, #0
        MOV R10, #0
        MOV R11, #0
        B loop


op_adi:
        CMP R3, #0 ;caso já possua um valor de operação, é uma entrada invalida,
        BNE loop   ;então volta a leitura
        CMP R10, #0 ;caso nenhum digito foi inserido, é uma entrada invalida,
        BEQ loop   ;então volta a leitura 
        MOV R4, R5 ;R5 receve o valor do numero digirado antes do operador
        MOV R5, #0 ;R5 zerado para receber o segundo numero
        MOV R3, #1   ;operação 1 (soma)
        MOV R10, #0  ;zera o contador de digitos 
        B wtx        ;ecoa o operador
op_sub:
        CMP R3, #0
        BNE loop
        CMP R10, #0
        BEQ loop   
        MOV R4, R5
        MOV R5, #0
        MOV R3, #2
        MOV R10, #0
        B wtx
op_mul:
        CMP R3, #0
        BNE loop
        CMP R10, #0
        BEQ loop   
        MOV R4, R5
        MOV R5, #0
        MOV R3, #3
        MOV R10, #0
        B wtx
op_div:
        CMP R3, #0
        BNE loop
        CMP R10, #0
        BEQ loop   
        MOV R4, R5
        MOV R5, #0
        MOV R3, #4
        MOV R10, #0
        B wtx

wtx:    LDR R2, [R0, #UART_FR] ; status da UART
        TST R2, #TXFE_BIT ; transmissor vazio?
        BEQ wtx
        STR R1, [R0] ; escreve no registrador de dados da UART0 (transmite)

        B loop
        




Serial_write:
        LDR R2, [R0, #UART_FR] ; status da UART
        TST R2, #TXFE_BIT ; transmissor vazio?
        BEQ Serial_write
        STR R1, [R0] ; escreve no registrador de dados da UART0 (transmite)
        BX LR
        
        
        
Calculate:
        PUSH {LR}
          
        CMP R3, #1                             ; SOMA
        IT EQ
          ADDEQ R1, R4, R5
          
        CMP R3, #2                             ; SUB
        IT EQ
          BLEQ Execute_sub
        
        CMP R3, #3                             ; MULTIPICACAO
        IT EQ
          MULEQ R1, R4, R5
        
        CMP R3, #4                             ; DIV
        IT EQ
          BLEQ Execute_div

        BL Show_result

        POP {PC}

Execute_sub:  
        SUBS R1, R4, R5
        ITTT MI
          MOVMI R11, #1 ;flag sub com resultado negativo
          MVNMI R1, R1  ;inverte para o complemento de 2
          ADDMI R1, R1, #1 ;ajusta o valor para ser exibido para humanos
        BX LR

Execute_div:
        UDIV R1, R4, R5
        CMP R5, #0
        IT EQ
          MOVEQ R11, #2
        BX LR


Show_result:
        PUSH {LR}
        PUSH {R7, R8, R9}                                   ; Conserva os registradores

        MOV R7, #0xAA                                   ; Dado de stop para pilha
        PUSH {R7}                                       ; aplica na pilha o stop  
        MOV R7, #10
        
        MOV R2, #10  ;\n
        PUSH {R2}
        MOV R2, #13  ;\r
        PUSH {R2}


        CMP R11, #2 ;Se for divisão por zero, R11=2
        ITTT EQ     ;Se for, adiciona 'E' na pilha e já salta para o código que imprime
          MOVEQ R1, #69
          PUSHEQ {R1}   
          BEQ Print_result
        
        CMP R11, #1 ;se for negativo, printa um '-' e continua no fluxo normal
        ITTTT EQ
          PUSHEQ {R1}
          MOVEQ R1, #45                                 ; printa '-'
          BLEQ Serial_write
          POPEQ {R1}
        
        CMP R1, #0 ;verifica se o resultado do calculo é igual a zero (Quando não é div/0, pq ja teria saido do fluxo antes)
        ITTT EQ    ;Se for, acidiona 0x30 na pilha já saltará para o código que imprime
        ADDEQ R1, R1, #0x30 
        PUSHEQ {R1}
        BEQ Print_result 
        
Decomposition:  ;Código responsável pela tradução do resultado em uma pilha ASCII
        CMP R1, #0 ;Neste caso, se R1=0, significa que já encerrou a decomposição
        BEQ Print_result
        
        UDIV R8, R1, R7 ;realiza a divisão do resultado por #10
        MUL R9, R8, R7 ;No aux R9 é salvo o resultado da divisão anterior vezes #10
        SUB R9, R1, R9 ;No aux fica salvo o valor do resto da divisão do resultado por #10 ( R9=(R1-(R1/#10)) )
        ADD R9, R9, #0x30 ;soma-se #0x30 para converter em ASCII
        PUSH {R9} ;coloca na pilha
        MOV R1, R8 ;R1 receve o valor do resultado da divisão de R1 por #10
        B Decomposition ;retorna para decompor o restante do resultado

Print_result: ;vai tirando os valores da pilha e imprimindo, até chegar no valor 0xAA, adicionado antes de escrever a saída do programa
        POP {R1}
        CMP R1, #0xAA
        IT EQ
        BEQ End_show_result
        BL Serial_write
        B Print_result

End_show_result:
        POP {R7, R8, R9}
        POP {PC}

;===============================================================================;
;                                             
;===============================================================================;













        
;leitura_bin ;código esdruxulo pra imprimir no teraterm o valor de R1 em binário 
;;(Meu debbuger está com problema e fui obrigado a fazer todo projeto sem utilizar esta ferramenta)
;;Destroi R2
;        PUSH {R3}
;        PUSH {R1}
;        LSRS R1, R1, #1
;        ITE CS
;        MOVCS R3, #0x31
;        MOVCC R3, #0x30
;        PUSH {R3}
;        LSRS R1, R1, #1
;        ITE CS
;        MOVCS R3, #0x31
;        MOVCC R3, #0x30
;        PUSH {R3}
;        LSRS R1, R1, #1
;        ITE CS
;        MOVCS R3, #0x31
;        MOVCC R3, #0x30
;        PUSH {R3}
;        LSRS R1, R1, #1
;        ITE CS
;        MOVCS R3, #0x31
;        MOVCC R3, #0x30
;        PUSH {R3}
;        LSRS R1, R1, #1
;        ITE CS
;        MOVCS R3, #0x31
;        MOVCC R3, #0x30
;        PUSH {R3}
;        LSRS R1, R1, #1
;        ITE CS
;        MOVCS R3, #0x31
;        MOVCC R3, #0x30
;        PUSH {R3}
;        LSRS R1, R1, #1
;        ITE CS
;        MOVCS R3, #0x31
;        MOVCC R3, #0x30
;        PUSH {R3}
;        LSRS R1, R1, #1
;        ITE CS
;        MOVCS R3, #0x31
;        MOVCC R3, #0x30
;        PUSH {R3}
;        
;        
;        
;        
;        POP {R1}
;debwtx1:    
;        LDR R2, [R0, #UART_FR] ; status da UART
;        TST R2, #TXFE_BIT ; transmissor vazio?
;        BEQ debwtx1
;        STR R1, [R0] ; escreve no registrador de dados da UART0 (transmite)
;
;        POP {R1}
;debwtx2:    
;        LDR R2, [R0, #UART_FR] ; status da UART
;        TST R2, #TXFE_BIT ; transmissor vazio?
;        BEQ debwtx2
;        STR R1, [R0] ; escreve no registrador de dados da UART0 (transmite)
;
;        POP {R1}
;debwtx3:    
;        LDR R2, [R0, #UART_FR] ; status da UART
;        TST R2, #TXFE_BIT ; transmissor vazio?
;        BEQ debwtx3
;        STR R1, [R0] ; escreve no registrador de dados da UART0 (transmite)
;
;        POP {R1}
;debwtx4:    
;        LDR R2, [R0, #UART_FR] ; status da UART
;        TST R2, #TXFE_BIT ; transmissor vazio?
;        BEQ debwtx4
;        STR R1, [R0] ; escreve no registrador de dados da UART0 (transmite)
;
;        POP {R1}
;debwtx5:    
;        LDR R2, [R0, #UART_FR] ; status da UART
;        TST R2, #TXFE_BIT ; transmissor vazio?
;        BEQ debwtx5
;        STR R1, [R0] ; escreve no registrador de dados da UART0 (transmite)
;
;        POP {R1}        
;debwtx6:    
;        LDR R2, [R0, #UART_FR] ; status da UART
;        TST R2, #TXFE_BIT ; transmissor vazio?
;        BEQ debwtx6
;        STR R1, [R0] ; escreve no registrador de dados da UART0 (transmite)
;
;        POP {R1}
;debwtx7:    
;        LDR R2, [R0, #UART_FR] ; status da UART
;        TST R2, #TXFE_BIT ; transmissor vazio?
;        BEQ debwtx7
;        STR R1, [R0] ; escreve no registrador de dados da UART0 (transmite)
;
;        POP {R1}
;debwtx8:    
;        LDR R2, [R0, #UART_FR] ; status da UART
;        TST R2, #TXFE_BIT ; transmissor vazio?
;        BEQ debwtx8
;        STR R1, [R0] ; escreve no registrador de dados da UART0 (transmite)
;        
;        
;        MOV R1, #0x0D ;CR
;debwtx9:    
;        LDR R2, [R0, #UART_FR] ; status da UART
;        TST R2, #TXFE_BIT ; transmissor vazio?
;        BEQ debwtx9
;        STR R1, [R0] ; escreve no registrador de dados da UART0 (transmite)
;
;        MOV R1, #0x0A ;LF
;debwtx10:    
;        LDR R2, [R0, #UART_FR] ; status da UART
;        TST R2, #TXFE_BIT ; transmissor vazio?
;        BEQ debwtx10
;        STR R1, [R0] ; escreve no registrador de dados da UART0 (transmite)
;
;        POP {R1}
;        POP {R3}
;        BX LR
        
        
 

        
        
        
        
        
;===============================================================================       
;Subrotinas já disponibilizadas no exemplo uart-2

; SUB-ROTINAS

;----------
; UART_enable: habilita clock para as UARTs selecionadas em R2
; R2 = padrão de bits de habilitação das UARTs
; Destrói: R0 e R1
UART_enable:
        LDR R0, =SYSCTL_BASE
	LDR R1, [R0, #SYSCTL_RCGCUART]
	ORR R1, R2 ; habilita UARTs selecionados
	STR R1, [R0, #SYSCTL_RCGCUART]

waitu	LDR R1, [R0, #SYSCTL_PRUART]
	TEQ R1, R2 ; clock das UARTs habilitados?
	BNE waitu

        BX LR
        
; UART_config: configura a UART desejada
; R0 = endereço base da UART desejada
; Destrói: R1
UART_config:
        LDR R1, [R0, #UART_CTL]
        BIC R1, #0x01 ; desabilita UART (bit UARTEN = 0)
        STR R1, [R0, #UART_CTL]

        ; clock = 16MHz, baud rate = 14400 bps
        MOV R1, #69;calculado para clock de 16MHz, baud rate de 14400
        STR R1, [R0, #UART_IBRD]
        MOV R1, #29;calculado para clock de 16MHz, baud rate de 14400
        STR R1, [R0, #UART_FBRD]
        
        ;MOV R1, #0x60         ; Para 8 bits, 1 stop, no parity, FIFOs disabled, no interrupts
        MOV R1, #01000000b     ; Para 7 bits, 1 stop, no parity, FIFOs disabled, no interrupts
        ;MOV R1, #11000110b    ;Alterado para 7 bits, 1 stop, even parity, FIFOs disabled, no interrupts(Deveria ser implementado)
        STR R1, [R0, #UART_LCRH]
        
        ; clock source = system clock
        MOV R1, #0x00
        STR R1, [R0, #UART_CC]
        
        LDR R1, [R0, #UART_CTL]
        ORR R1, #0x01 ; habilita UART (bit UARTEN = 1)
        STR R1, [R0, #UART_CTL]

        BX LR


; GPIO_special: habilita funcões especiais no port de GPIO desejado
; R0 = endereço base do port desejado
; R1 = padrão de bits (1) a serem habilitados como funções especiais
; Destrói: R2
GPIO_special:
	LDR R2, [R0, #GPIO_AFSEL]
	ORR R2, R1 ; configura bits especiais
	STR R2, [R0, #GPIO_AFSEL]

	LDR R2, [R0, #GPIO_DEN]
	ORR R2, R1 ; habilita função digital
	STR R2, [R0, #GPIO_DEN]

        BX LR

; GPIO_select: seleciona funcões especiais no port de GPIO desejado
; R0 = endereço base do port desejado
; R1 = máscara de bits a serem alterados
; R2 = padrão de bits (1) a serem selecionados como funções especiais
; Destrói: R3
GPIO_select:
	LDR R3, [R0, #GPIO_PCTL]
        BIC R3, R1
	ORR R3, R2 ; seleciona bits especiais
	STR R3, [R0, #GPIO_PCTL]

        BX LR
;----------

; GPIO_enable: habilita clock para os ports de GPIO selecionados em R2
; R2 = padrão de bits de habilitação dos ports
; Destrói: R0 e R1
GPIO_enable:
        LDR R0, =SYSCTL_BASE
	LDR R1, [R0, #SYSCTL_RCGCGPIO]
	ORR R1, R2 ; habilita ports selecionados
	STR R1, [R0, #SYSCTL_RCGCGPIO]

waitg	LDR R1, [R0, #SYSCTL_PRGPIO]
	TEQ R1, R2 ; clock dos ports habilitados?
	BNE waitg

        BX LR

; GPIO_digital_output: habilita saídas digitais no port de GPIO desejado
; R0 = endereço base do port desejado
; R1 = padrão de bits (1) a serem habilitados como saídas digitais
; Destrói: R2
GPIO_digital_output:
	LDR R2, [R0, #GPIO_DIR]
	ORR R2, R1 ; configura bits de saída
	STR R2, [R0, #GPIO_DIR]

	LDR R2, [R0, #GPIO_DEN]
	ORR R2, R1 ; habilita função digital
	STR R2, [R0, #GPIO_DEN]

        BX LR

; GPIO_write: escreve nas saídas do port de GPIO desejado
; R0 = endereço base do port desejado
; R1 = máscara de bits a serem acessados
; R2 = bits a serem escritos
GPIO_write:
        STR R2, [R0, R1, LSL #2] ; escreve bits com máscara de acesso
        BX LR

; GPIO_digital_input: habilita entradas digitais no port de GPIO desejado
; R0 = endereço base do port desejado
; R1 = padrão de bits (1) a serem habilitados como entradas digitais
; Destrói: R2
GPIO_digital_input:
	LDR R2, [R0, #GPIO_DIR]
	BIC R2, R1 ; configura bits de entrada
	STR R2, [R0, #GPIO_DIR]

	LDR R2, [R0, #GPIO_DEN]
	ORR R2, R1 ; habilita função digital
	STR R2, [R0, #GPIO_DEN]

	LDR R2, [R0, #GPIO_PUR]
	ORR R2, R1 ; habilita resitor de pull-up
	STR R2, [R0, #GPIO_PUR]

        BX LR

; GPIO_read: lê as entradas do port de GPIO desejado
; R0 = endereço base do port desejado
; R1 = máscara de bits a serem acessados
; R2 = bits lidos
GPIO_read:
        LDR R2, [R0, R1, LSL #2] ; lê bits com máscara de acesso
        BX LR

; SW_delay: atraso de tempo por software
; R0 = valor do atraso
; Destrói: R0
SW_delay:
        CBZ R0, out_delay
        SUB R0, R0, #1
        B SW_delay        
out_delay:
        BX LR

; LED_write: escreve um valor binário nos LEDs D1 a D4 do kit
; R0 = valor a ser escrito nos LEDs (bit 3 a bit 0)
; Destrói: R1, R2, R3 e R4
LED_write:
        AND R3, R0, #0010b
        LSR R3, R3, #1
        AND R4, R0, #0001b
        ORR R3, R3, R4, LSL #1 ; LEDs D1 e D2
        LDR R1, =GPIO_PORTN_BASE
        MOV R2, #000000011b ; máscara PN1|PN0
        STR R3, [R1, R2, LSL #2]

        AND R3, R0, #1000b
        LSR R3, R3, #3
        AND R4, R0, #0100b
        ORR R3, R3, R4, LSL #2 ; LEDs D3 e D4
        LDR R1, =GPIO_PORTF_BASE
        MOV R2, #00010001b ; máscara PF4|PF0
        STR R3, [R1, R2, LSL #2]
        
        BX LR

; Button_read: lê o estado dos botões SW1 e SW2 do kit
; R0 = valor lido dos botões (bit 1 e bit 0)
; Destrói: R1, R2, R3 e R4
Button_read:
        LDR R1, =GPIO_PORTJ_BASE
        MOV R2, #00000011b ; máscara PJ1|PJ0
        LDR R0, [R1, R2, LSL #2]
        
dbc:    MOV R3, #50 ; constante de debounce
again:  CBZ R3, last
        LDR R4, [R1, R2, LSL #2]
        CMP R0, R4
        MOV R0, R4
        ITE EQ
          SUBEQ R3, R3, #1
          BNE dbc
        B again
last:
        BX LR

; Button_int_conf: configura interrupções do botão SW1 do kit
; Destrói: R0, R1 e R2
Button_int_conf:
        MOV R2, #00000001b ; bit do PJ0
        LDR R1, =GPIO_PORTJ_BASE
        
        LDR R0, [R1, #GPIO_IM]
        BIC R0, R0, R2 ; desabilita interrupções
        STR R0, [R1, #GPIO_IM]
        
        LDR R0, [R1, #GPIO_IS]
        BIC R0, R0, R2 ; interrupção por transição
        STR R0, [R1, #GPIO_IS]
        
        LDR R0, [R1, #GPIO_IBE]
        BIC R0, R0, R2 ; uma transição apenas
        STR R0, [R1, #GPIO_IBE]
        
        LDR R0, [R1, #GPIO_IEV]
        BIC R0, R0, R2 ; transição de descida
        STR R0, [R1, #GPIO_IEV]
        
        LDR R0, [R1, #GPIO_ICR]
        ORR R0, R0, R2 ; limpeza de pendências
        STR R0, [R1, #GPIO_ICR]
        
        LDR R0, [R1, #GPIO_IM]
        ORR R0, R0, R2 ; habilita interrupções no port GPIO J
        STR R0, [R1, #GPIO_IM]

        MOV R2, #0xE0000000 ; prioridade mais baixa para a IRQ51
        LDR R1, =NVIC_BASE
        
        LDR R0, [R1, #NVIC_PRI12]
        ORR R0, R0, R2 ; define prioridade da IRQ51 no NVIC
        STR R0, [R1, #NVIC_PRI12]

        MOV R2, #10000000000000000000b ; bit 19 = IRQ51
        MOV R0, R2 ; limpa pendências da IRQ51 no NVIC
        STR R0, [R1, #NVIC_UNPEND1]

        LDR R0, [R1, #NVIC_EN1]
        ORR R0, R0, R2 ; habilita IRQ51 no NVIC
        STR R0, [R1, #NVIC_EN1]
        
        BX LR

; Button1_int_enable: habilita interrupções do botão SW1 do kit
; Destrói: R0, R1 e R2
Button1_int_enable:
        MOV R2, #00000001b ; bit do PJ0
        LDR R1, =GPIO_PORTJ_BASE
        
        LDR R0, [R1, #GPIO_IM]
        ORR R0, R0, R2 ; habilita interrupções
        STR R0, [R1, #GPIO_IM]

        BX LR

; Button1_int_disable: desabilita interrupções do botão SW1 do kit
; Destrói: R0, R1 e R2
Button1_int_disable:
        MOV R2, #00000001b ; bit do PJ0
        LDR R1, =GPIO_PORTJ_BASE
        
        LDR R0, [R1, #GPIO_IM]
        BIC R0, R0, R2 ; desabilita interrupções
        STR R0, [R1, #GPIO_IM]

        BX LR

; Button1_int_clear: limpa pendência de interrupções do botão SW1 do kit
; Destrói: R0 e R1
Button1_int_clear:
        MOV R0, #00000001b ; limpa o bit 0
        LDR R1, =GPIO_PORTJ_BASE
        STR R0, [R1, #GPIO_ICR]

        BX LR

        END
