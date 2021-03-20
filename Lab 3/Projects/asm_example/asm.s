        PUBLIC  __iar_program_start
        PUBLIC  __vector_table

        SECTION .text:CODE:REORDER(1)
        
        ;; Keep vector table even if it's not referenced
        REQUIRE __vector_table
        
        THUMB
        
__iar_program_start

;; R5, R6 são usados para realizar a operação de multiplicação - input da funcao
;; R7 é usado para armazenar a resposta da multiplicação - return da funcao
;; R0 - Entrada do numerador
;; R1 - Entrada do denomonador
;; R2 - R0*R1
;; R3 - R0/R1
;; R4 - R0%R1

;; main program begins here
main
        MOV R0, #0x0000000b
        MOV R1, #0x00000005
        MOV R5, R1
        MOV R6, R0
        BL Mul8b
        MOV R2, R7
        BL Div8b
loop:
        B loop

Mul8b:
        MOV R7, #0
repete_mult
        ADD R7, R7, R5
        SUB R6, R6, #1
        CBZ R6, back_to_mult
        B repete_mult
back_to_mult
        BX LR

Div8b:
        CBZ R1, back_to_div
        MOV R5, R1
        MOV R6, R3
        MOV R7, #0
repete_div
        CMP R7, R0
        BHI back_to_div
        ADD R3, R3, #1  ;; incrementa em 1 R3
        MOV R6, R3      ;; passa o valor de R3 para R6
        PUSH {LR}
        BL Mul8b        ;; atualiza o valor de R7
        POP {LR}
        B repete_div
back_to_div
        SUB R3, R3, #1  ;; R3 sai somado de um da logica
        MOV R6, R3      ;; passa o valor para R6 para multiplciar
        PUSH {LR}       ;; salva o valor do PC antes de executar a funcao para nao perder a ref
        BL Mul8b        ;; chama a multiplicacao so para att R7
        POP {LR}         ;; consome o valor de PC que estava na pilha para retomar o ponto de inicio
        SUBS R4, R0, R7
        BX LR           ;; retorna para ponto de origem

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
