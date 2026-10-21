;===============================================================
;  SUM_MEM.ASM     作业3 第 1) 题 · 第二种写法
;  求 1 + 2 + ... + 100 = 5050
;
;  累加器位置：★ 数据段 ★
;      在 .DATA 里定义一个字变量 SUM，每加一次就往内存里写一次。
;
;  对比：
;      SUM.ASM      累加器在寄存器 AX   —— 最快，但寄存器数量有限
;      SUM_MEM.ASM  累加器在数据段 SUM  —— 直观、容量大，但每次都要访问内存
;      SUM_STK.ASM  累加器在栈里        —— 用 PUSH/POP 保存
;
;  编译：BUILDD SUM_MEM        运行：BUILD\SUM_MEM
;===============================================================
        .MODEL  SMALL
        .STACK  100H

        .DATA
SUM     DW      0                       ; ★ 累加器放在数据段（一个字 = 16 位）★

        .CODE
START:
        MOV     AX, @DATA
        MOV     DS, AX                  ; 让 DS 指向数据段，否则访问不到 SUM

;---------------------------------------------------------------
;  sum = 1 + 2 + ... + 100      —— 累加器是内存变量 SUM
;---------------------------------------------------------------
        MOV     SUM, 0                  ; SUM = 0
        MOV     CX, 100                 ; 循环 100 次
        MOV     BX, 1                   ; BX = 当前要加的数 i

SUM_LOOP:
        ADD     SUM, BX                 ; SUM = SUM + i   （直接改内存）
        INC     BX                      ; i = i + 1
        LOOP    SUM_LOOP

;---------------------------------------------------------------
;  把 SUM 取到 AX，再按十进制输出
;---------------------------------------------------------------
        MOV     AX, SUM                 ; 结果从内存取回寄存器
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
