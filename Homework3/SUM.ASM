;===============================================================
;  SUM.ASM     作业3 基本要求
;  求 1 + 2 + ... + 100，并把结果 5050 打印到屏幕
;
;  累加器位置：★ 寄存器 AX ★        （第 1) 题的第一种写法）
;  另外两种写法见 SUM_MEM.ASM（数据段）和 SUM_STK.ASM（栈）
;
;  运行效果：
;      D:\>sum
;      5050
;
;  编译：BUILDD SUM        运行：BUILD\SUM
;
;  注意：1+...+100 = 5050，已经超过 255，
;        所以累加器必须是 16 位（一个字），不能用 AL / BL 这种 8 位寄存器。
;===============================================================
        .MODEL  SMALL
        .STACK  100H

        .DATA
        ; 本版本不需要数据段变量。
        ; 保留空的 .DATA 段是为了和另外两个版本结构一致，方便对比。

        .CODE
START:
        MOV     AX, @DATA
        MOV     DS, AX

;---------------------------------------------------------------
;  sum = 1 + 2 + ... + 100      —— 累加器就是 AX 本身
;---------------------------------------------------------------
        MOV     CX, 100                 ; 循环 100 次
        MOV     BX, 1                   ; BX = 当前要加的数 i
        XOR     AX, AX                  ; AX = 累加器，初值 0
                                        ;（XOR AX,AX 比 MOV AX,0 少一个字节）

SUM_LOOP:
        ADD     AX, BX                  ; sum = sum + i
        INC     BX                      ; i = i + 1
        LOOP    SUM_LOOP

;---------------------------------------------------------------
;  把 AX 里的结果按十进制输出
;---------------------------------------------------------------
        CALL    PRINT_DEC
        CALL    NEWLINE

        MOV     AX, 4C00H               ; 结束程序
        INT     21H

;===============================================================
;  子程序
;===============================================================

;---- PRINT_DEC : 入口 AX = 要输出的数，把它按十进制打印出来 ----
;     算法：反复除以 10，余数压栈；最后弹栈输出（栈后进先出，正好倒序）
PRINT_DEC PROC
        MOV     CX, 0                   ; 记录一共几位
        MOV     SI, 10
PD_LOOP:
        XOR     DX, DX                  ; ★ DIV 之前必须清零 DX
        DIV     SI                      ; AX = 商，DX = 余数
        PUSH    DX                      ; 余数入栈
        INC     CX
        CMP     AX, 0
        JNE     PD_LOOP
PD_OUT:
        POP     DX
        ADD     DL, '0'                 ; 数值 -> ASCII
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
