;===============================================================
;  9.ASM     作业4：乘法指令和过程调用
;            输出九九乘法表
;
;  运行效果：
;      C:\>9
;      The 9mul9 table:
;      9*1=9   9*2=18  9*3=27  ...  9*9=81
;      8*1=8   8*2=16  8*3=24  ...  8*8=64
;      ...
;      1*1=1
;
;  本题三个要点：
;    ① 用 CALL / RET 实现过程调用。
;    ② 过程内部使用了主过程也在用的寄存器（AX/BX/CX/DX），
;       因此过程一进门就把它们 PUSH 起来，返回前再按相反顺序 POP 回去。
;       ★ 其中 CX 最要紧：它是外层的行号计数器，而 PRINT_AX 里的
;         除法循环也会把 CX 减到 0。若不做保护，外层循环立刻失控。
;    ③ 双重循环：
;         外层  CX = 行号，9 -> 1 递减（用 LOOP 指令）
;         内层  BX = 列号，1 -> 行号 递增
;
;  编译：BUILDD 9        运行：BUILD\9
;===============================================================
        .MODEL  SMALL
        .STACK  100H

        .DATA
MSG     DB      'The 9mul9 table:', 0DH, 0AH, '$'

        .CODE
START:
        MOV     AX, @DATA
        MOV     DS, AX

        MOV     DX, OFFSET MSG
        MOV     AH, 09H
        INT     21H                     ; 输出表头

;---------------------------------------------------------------
;  外层循环：行号 CX 从 9 递减到 1
;---------------------------------------------------------------
        MOV     CX, 9                   ; CX = 行号

ROW_LOOP:
        MOV     BX, 1                   ; 内层：列号从 1 开始

;---------------------------------------------------------------
;  内层循环：列号 BX 从 1 递增到 CX（即当前行号）
;---------------------------------------------------------------
COL_LOOP:
        MOV     AX, CX
        CALL    PRINT_AX                ; 输出「行号」

        MOV     DL, '*'
        CALL    PUTCH

        MOV     AX, BX
        CALL    PRINT_AX                ; 输出「列号」

        MOV     DL, '='
        CALL    PUTCH

        MOV     AX, CX                  ; AX = 行号
        MUL     BX                      ; DX:AX = 行号 × 列号
                                        ;   本表最大 9×9=81，AX 足够放
        CALL    PRINT_AX                ; 输出「积」

        MOV     DL, 9                   ; 09H 是制表符 Tab，用来对齐各列
        CALL    PUTCH

        INC     BX                      ; 列号 +1
        CMP     BX, CX                  ; 列号 ≤ 行号 ？
        JBE     COL_LOOP                ; 是，继续本行

        CALL    NEWLINE                 ; 一行结束，回车换行
        LOOP    ROW_LOOP                ; 行号 -1，不为 0 就继续下一行

        MOV     AX, 4C00H               ; 结束程序
        INT     21H

;===============================================================
;                        子 程 序
;===============================================================

;---------------------------------------------------------------
;  PRINT_AX : 把 AX 里的无符号数以十进制输出
;
;  内部要用 AX、BX、CX、DX 四个寄存器，而这四个寄存器主过程都在用：
;      CX = 外层行号      BX = 内层列号
;  所以一进门就把它们全部 PUSH 保存，返回前再按相反顺序 POP 恢复。
;
;  ★ 若漏掉 PUSH CX / POP CX，外层 LOOP 就会失控：
;    这里的除法循环每除一次 INC CX、LOOP 结束前把 CX 减到别的值，
;    回到主过程时 CX 已被破坏，行号就乱了。
;---------------------------------------------------------------
PRINT_AX PROC
        PUSH    AX
        PUSH    BX
        PUSH    CX
        PUSH    DX

        MOV     BX, 10                  ; 除数 10
        MOV     CX, 0                   ; 数一数一共几位

PA_DIV:
        XOR     DX, DX                  ; ★ DIV 之前必须清零 DX
        DIV     BX                      ; AX = 商，DX = 余数
        PUSH    DX                      ; 余数入栈
        INC     CX
        CMP     AX, 0
        JNE     PA_DIV

PA_OUT:
        POP     DX                      ; 后进先出，正好把余数倒过来
        ADD     DL, '0'
        MOV     AH, 02H
        INT     21H
        LOOP    PA_OUT

        POP     DX                      ; 恢复现场，顺序与 PUSH 相反
        POP     CX
        POP     BX
        POP     AX
        RET                             ; 返回主过程
PRINT_AX ENDP

;---------------------------------------------------------------
;  PUTCH : 输出 DL 中指定的字符（保护 AX）
;---------------------------------------------------------------
PUTCH PROC
        PUSH    AX
        MOV     AH, 02H                 ; 02H 号功能：显示单个字符
        INT     21H
        POP     AX
        RET
PUTCH ENDP

;---------------------------------------------------------------
;  NEWLINE : 输出回车换行（保护 AX、DX）
;---------------------------------------------------------------
NEWLINE PROC
        PUSH    AX
        PUSH    DX
        MOV     DL, 0DH                 ; 回车 CR
        MOV     AH, 02H
        INT     21H
        MOV     DL, 0AH                 ; 换行 LF
        MOV     AH, 02H
        INT     21H
        POP     DX
        POP     AX
        RET
NEWLINE ENDP

        END     START
