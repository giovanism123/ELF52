        PUBLIC  __iar_program_start
        PUBLIC  __vector_table

        SECTION .text:CODE:REORDER(1)
        
        ;; Keep vector table even if it's not referenced
        REQUIRE __vector_table
        
        THUMB
        
__iar_program_start




;;------------------------------------------------------------------------------
;;
;; Entradas:
;; R0 - Entrada do numerador
;; R1 - Entrada do denomonador
;;
;; Respostas:
;; R2 - R0*R1
;; R3 - R0/R1
;; R4 - resto R0/R1
;;
;; Obs:
;; R6, R7 e R9 não usados internamente na função de multiplicação,
;; como entrada 1, entrada 2 e resultado, sucessivamente
;; Foi feito desta forma, pois com o intuíto de economizar memória de programa, 
;; a divisão foi feita usando a lógica invertida da multiplicação.
;; Porém essa decisão NÃO resulta no melhor processamento possível.

main
        MOV R0, #0x00000001
        MOV R1, #0x00000004
        MOV R6, R1
        MOV R7, R0
        BL Mul8b
        MOV R2, R9
        BL Div8b
loop:
        B loop



;; Multiplicação
Mul8b:
        MOV R9, #0
        CBZ R7, return_mult
doWhile_mult
        ADD R9, R9, R6
        SUB R7, R7, #1
        CBZ R7, return_mult
        B doWhile_mult
return_mult
        BX LR


;; Divisão 
Div8b:
        CBZ R1, return_invalid_div
        MOV R6, R1
        MOV R7, R3
        MOV R9, #0
doWhile_div
        CMP R9, R0
        BHI return_div
        ADD R3, R3, #1
        MOV R7, R3
        PUSH {LR}
        BL Mul8b
        POP {LR}
        B doWhile_div
return_div
        SUB R3, R3, #1
        MOV R7, R3
        PUSH {LR}
        BL Mul8b
        POP {LR}
        SUBS R4, R0, R9
        BX LR
return_invalid_div
        BX LR
        
        
        
        
;;------------------------------------------------------------------------------        
        
        

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
