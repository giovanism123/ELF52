        PUBLIC  __iar_program_start
        PUBLIC  __vector_table

        SECTION .text:CODE:REORDER(1)
        
        ;; Keep vector table even if it's not referenced
        REQUIRE __vector_table
        
        THUMB
        
__iar_program_start




;;A ideia deste programa é decompor o segundo fator em potências de 2
;; ex: 11 = b1011 => 2^3 + 2^1 + 2^0
;; o valor do fator deslocado n vezes para a esquerda é o mesmo que fazer fator^n
;; Somando os valores dos deslocamentos, quando houver carry = 1, podemos chegar ao resultado da multiplicação de R0*R1
;; Entradas R0 * R1 = 
;; Saída R2
        ;; main program begins here
main    MOV R0, #20
        MOV R1, #25
        BL Mul16b
        B Loop

Mul16b:
        PUSH {R1}
deslocamento
        CMP R1, #0 ;quando R1 = 0, não há o que deslocar. Finaliza a multiplicação
        BEQ fim
        LSRS R1, R1, #1  ;; deslocando para a direita. DICA: VISUALIZAR OS REGISTRADORES EM BINARIO
        ITT CS ;;se o resultado do deslocamento subir um carry, (jogou para a direita um bit 1)
          LSLCS R4, R0, R3 ;; vai salvar em R4 (aux) o valor de R0 deslocado em R3(valor do expoente)
          ADDCS R2, R2, R4 ;; vai acrescer em R2 (resposta) o valor de R4 (aux)
        ADD R3, R3, #1 ;; apos deslocar para direita, acrescenta 1 ao valor do exponte
        B deslocamento ;;volta para a operação de deslocamento
fim
        POP {R1} ;;devolve o valor de R1 que estava salvo antes da função ser chamada
        BX LR
Loop
        B Loop
        ;; main program ends here














        ;; Forward declaration of sections.
        SECTION CSTACK:DATA:NOROOT(3)
        SECTION .intvec:CODE:NOROOT(2)
        
        DATA

__vector_table
        DCD     sfe(CSTACK)
        DCD     __iar_program_start

        DCD     NMI_Handler
        DCD     HardFault_Handler
        DCD     MemManage_Handler
        DCD     BusFault_Handler
        DCD     UsageFault_Handler
        DCD     0
        DCD     0
        DCD     0
        DCD     0
        DCD     SVC_Handler
        DCD     DebugMon_Handler
        DCD     0
        DCD     PendSV_Handler
        DCD     SysTick_Handler

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Default interrupt handlers.
;;

        PUBWEAK NMI_Handler
        PUBWEAK HardFault_Handler
        PUBWEAK MemManage_Handler
        PUBWEAK BusFault_Handler
        PUBWEAK UsageFault_Handler
        PUBWEAK SVC_Handler
        PUBWEAK DebugMon_Handler
        PUBWEAK PendSV_Handler
        PUBWEAK SysTick_Handler

        SECTION .text:CODE:REORDER:NOROOT(1)
        THUMB

NMI_Handler
HardFault_Handler
MemManage_Handler
BusFault_Handler
UsageFault_Handler
SVC_Handler
DebugMon_Handler
PendSV_Handler
SysTick_Handler
Default_Handler
__default_handler
        CALL_GRAPH_ROOT __default_handler, "interrupt"
        NOCALL __default_handler
        B __default_handler

        END
