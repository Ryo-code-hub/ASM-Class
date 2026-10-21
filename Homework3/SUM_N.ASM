;===============================================================
;  SUM_N.ASM     作业3 第 2) 题
;  用户输入 1~100 内的任意一个数 N，程序计算 1+2+...+N
;  并把十进制结果输出到屏幕。
;
;  输入数据用的是 21H 号中断的 01H 号功能：
;      入口：AH = 01H
;      出口：AL = 输入的字符（并且自动回显到屏幕）
;      按回车（0DH）表示输入结束
;      （另外 0AH 号功能是"带缓冲的字符串输入"，本题逐个字符读更好控制）
;
;  运行效果：
;      D:\>sum_n
;      Please input N (1-100):
;      100
;      5050
;
;  编译：BUILDD SUM_N        运行：BUILD\SUM_N
;
;  数据范围提醒：1+...+N 的结果要放在 16 位寄存器里，
;      最大只能表示 65535；N 到 361 时和是 65341，N 到 362 时就溢出了。
;      本题限制 N ≤ 100，和最大 5050，不会溢出。
;===============================================================
        .MODEL  SMALL
        .STACK  100H

        .DATA
MSG_IN  DB  'Please input N (1-100):', 0DH, 0AH, '$'
MSG_ERR DB  'N must be in 1..100 !', 0DH, 0AH, '$'

        .CODE
START:
        MOV     AX, @DATA
        MOV     DS, AX

        MOV     DX, OFFSET MSG_IN
        MOV     AH, 09H
        INT     21H                     ; 输出提示

;---------------------------------------------------------------
;  逐字符读入一个十进制数，结果放在 BX
;      N = N * 10 + 这一位
;---------------------------------------------------------------
        XOR     BX, BX                  ; BX = 输入的数 N，初值 0

READ_LOOP:
        MOV     AH, 01H
        INT     21H                     ; AL = 输入的字符（自动回显）
        CMP     AL, 0DH                 ; 按下回车 -> 输入结束
        JE      READ_DONE
        CMP     AL, '0'                 ; 比 '0' 小，不是数字，丢掉
        JB      READ_LOOP
        CMP     AL, '9'                 ; 比 '9' 大，不是数字，丢掉
        JA      READ_LOOP

        SUB     AL, '0'                 ; '0'..'9' -> 0..9
        XOR     AH, AH
        PUSH    AX                      ; 先保存这一位（MUL 会破坏 AX）
        MOV     AX, BX
        MOV     DX, 10
        MUL     DX                      ; AX = BX * 10
        MOV     BX, AX
        POP     AX
        ADD     BX, AX                  ; N = N * 10 + 这一位
        JMP     READ_LOOP

READ_DONE:
        CALL    NEWLINE

;---------------------------------------------------------------
;  检查 N 是否在 1~100 之间
;---------------------------------------------------------------
        CMP     BX, 100
        JA      RANGE_ERR
        CMP     BX, 1
        JB      RANGE_ERR

;---------------------------------------------------------------
;  sum = 1 + 2 + ... + N        —— 累加器在寄存器 AX
;---------------------------------------------------------------
        MOV     CX, BX                  ; 循环 N 次（先把 N 挪到 CX）
        XOR     AX, AX                  ; AX = 累加器，初值 0
        MOV     BX, 1                   ; BX = 当前要加的数 i

SUM_LOOP:
        ADD     AX, BX                  ; sum = sum + i
        INC     BX                      ; i = i + 1
        LOOP    SUM_LOOP

;---------------------------------------------------------------
;  输出结果
;---------------------------------------------------------------
        CALL    PRINT_DEC
        CALL    NEWLINE
        JMP     EXIT

RANGE_ERR:
        MOV     DX, OFFSET MSG_ERR
        MOV     AH, 09H
        INT     21H

EXIT:
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
