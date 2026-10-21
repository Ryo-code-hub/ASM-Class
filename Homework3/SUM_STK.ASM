;===============================================================
;  SUM_STK.ASM     作业3 第 1) 题 · 第三种写法
;  求 1 + 2 + ... + 100 = 5050
;
;  累加器位置：★ 栈 ★
;      进循环之前先用 PUSH 在栈顶放一个 0 当作累加器；
;      每轮循环 POP 出来、加上 i、再 PUSH 回去。
;      最后 POP 一次，取出的就是最终结果。
;
;      （栈是"后进先出"，PUSH 在前 POP 在后，正好一进一出，
;        数据就一直在栈顶这一格上滚。）
;
;  编译：BUILDD SUM_STK        运行：BUILD\SUM_STK
;===============================================================
        .MODEL  SMALL
        .STACK  100H

        .DATA
        ; 本版本把累加器放在栈里，不需要数据段变量

        .CODE
START:
        MOV     AX, @DATA
        MOV     DS, AX

;---------------------------------------------------------------
;  sum = 1 + 2 + ... + 100      —— 累加器在栈顶
;---------------------------------------------------------------
        MOV     CX, 100                 ; 循环 100 次
        MOV     BX, 1                   ; BX = 当前要加的数 i
        XOR     AX, AX
        PUSH    AX                      ; ★ 在栈顶放一个 0，当累加器 ★

SUM_LOOP:
        POP     AX                      ; ★ 把累加器从栈里取出来
        ADD     AX, BX                  ; sum = sum + i
        PUSH    AX                      ; ★ 再存回栈里 ★
        INC     BX                      ; i = i + 1
        LOOP    SUM_LOOP

        POP     AX                      ; 循环结束，取出最后的结果

;---------------------------------------------------------------
;  按十进制输出
;---------------------------------------------------------------
        CALL    PRINT_DEC
        CALL    NEWLINE

        MOV     AX, 4C00H
        INT     21H

;===============================================================
;  子程序
;===============================================================

;---- PRINT_DEC : 入口 AX = 要输出的数 ----
PRINT_DEC PROC
        MOV     CX, 0
        MOV     SI, 10
PD_LOOP:
        XOR     DX, DX
        DIV     SI
        PUSH    DX
        INC     CX
        CMP     AX, 0
        JNE     PD_LOOP
PD_OUT:
        POP     DX
        ADD     DL, '0'
        MOV     AH, 02H
        INT     21H
        LOOP    PD_OUT
        RET
PRINT_DEC ENDP

;---- NEWLINE : 输出回车 + 换行 ----
NEWLINE PROC
        MOV     DL, 0DH
        MOV     AH, 02H
        INT     21H
        MOV     DL, 0AH
        MOV     AH, 02H
        INT     21H
        RET
NEWLINE ENDP

        END     START
