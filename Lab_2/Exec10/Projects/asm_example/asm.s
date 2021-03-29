        PUBLIC  __iar_program_start
        PUBLIC  __vector_table

        SECTION .text:CODE:REORDER(1)
        
        ;; Keep vector table even if it's not referenced
        REQUIRE __vector_table
        
        THUMB
        
__iar_program_start






        ;; main program begins here
main    MOV R0, #0xCDFE
        MOVT R0,#0x89AB
        MOV R1, #0x4567
        MOVT R1, #0x0123
        MOV R2, #0x4321
        MOVT R2, #0x8765
        MOV R3, #0xCBA9
        MOVT R3, #0x0FED
        
        ;;                  R1      R0
        ;; valor 1 = 0x0123 4567_89AB CDFE = 0123456789ABCDFE
        ;; valor 2 = 0x0FED CBA9_8765 4321 = 0FEDCBA987654321
        ;;                  R3        R2


        ;;valor1+valor2=


        SUBS R4, R0, R2
        SBCS R5, R1, R3
        
        MOV R5, #4
        MOV R4, #5
        
        CMP R5, R4
        ITE GE
        MOVGE R7, #2
        MOVLT R7, #4
        

loop    
        B       loop            ; go to loop
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
