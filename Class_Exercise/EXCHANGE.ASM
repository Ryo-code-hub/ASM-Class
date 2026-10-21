;===============================================================
;  EXCHANGE.ASM     课堂练习题：进制转换
;
;  基本要求：输入 1~2 位十六进制数，输出对应的十进制数
;  追加要求：实现十进制 -> 十六进制的转换
;
;  运行效果：
;      Please input a Hex number:
;      ff
;      The Dec number:
;      255
;      Please input a Dec number:
;      100
;      The Hex number:
;      64
;
;  编译：BUILDD EXCHANGE        运行：BUILD\EXCHANGE
;  如果只想完成基本要求，把主程序里 CALL DEC2HEX 那一行注释掉即可
;===============================================================
        .MODEL  SMALL
        .STACK  100H

        .DATA
MSG_H   DB  'Please input a Hex number:', 0DH, 0AH, '$'
MSG_D   DB  'The Dec number:', 0DH, 0AH, '$'
MSG_D2  DB  'Please input a Dec number:', 0DH, 0AH, '$'
MSG_H2  DB  'The Hex number:', 0DH, 0AH, '$'

; DOS 0AH 号功能输入缓冲区：第0字节=最大长度，第1字节=实长，之后是字符
IN_BUF  DB  8, 0, 8 DUP(0)

        .CODE
START:
        MOV     AX, @DATA
        MOV     DS, AX

;---------------------------------------------------------------
;  第一部分：十六进制 -> 十进制        （基本要求）
;---------------------------------------------------------------
        MOV     DX, OFFSET MSG_H
        MOV     AH, 09H
        INT     21H                     ; 输出提示

        MOV     DX, OFFSET IN_BUF
        MOV     AH, 0AH
        INT     21H                     ; 读入一行（DOS 自动回显）

        MOV     DX, OFFSET MSG_D
        MOV     AH, 09H
        INT     21H                     ; 输出提示

        CALL    HEX2BIN                 ; 输入串 -> BX 中的数值
        CALL    PRINT_DEC               ; 把 BX 按十进制输出
        CALL    NEWLINE

;---------------------------------------------------------------
;  第二部分：十进制 -> 十六进制        （追加要求）
;  只要基本要求的话，把下面这一行前面加 ; 注释掉再编译
;---------------------------------------------------------------
        CALL    DEC2HEX

        MOV     AX, 4C00H               ; 功能 4CH：结束程序
        INT     21H

;===============================================================
;                          子 程 序
;===============================================================

;---------------------------------------------------------------
;  HEX2BIN : 把 IN_BUF 里的十六进制字符串转成数值 -> BX
;            算法：从左到右，每读一位就 BX = BX * 16 + 该位
;---------------------------------------------------------------
HEX2BIN PROC
        MOV     CL, IN_BUF+1            ; 实际输入的字符个数
        XOR     CH, CH
        MOV     SI, OFFSET IN_BUF+2     ; 指向第一个字符
        XOR     BX, BX
        JCXZ    H2B_DONE                ; 空输入直接返回
                                        ;（不判断的话 LOOP 会跑 65536 次）
H2B_LOOP:
        MOV     AL, [SI]
        CALL    HEX_DIGIT               ; AL = 0..15
        SHL     BX, 1                   ; BX = BX * 16
        SHL     BX, 1
        SHL     BX, 1
        SHL     BX, 1
        XOR     AH, AH
        ADD     BX, AX                  ; 累加这一位
        INC     SI
        LOOP    H2B_LOOP
H2B_DONE:
        RET
HEX2BIN ENDP

;---------------------------------------------------------------
;  HEX_DIGIT : 入口 AL = 一个十六进制字符的 ASCII 码
;              出口 AL = 对应的数值 0..15
;---------------------------------------------------------------
HEX_DIGIT PROC
        CMP     AL, '9'
        JBE     HD_NUM                  ; '0'..'9'
        AND     AL, 0DFH                ; 小写字母 -> 大写（清掉 bit5）
        SUB     AL, 'A'
        ADD     AL, 10                  ; 'A'..'F' -> 10..15
        RET
HD_NUM:
        SUB     AL, '0'
        RET
HEX_DIGIT ENDP

;---------------------------------------------------------------
;  PRINT_DEC : 把 BX 里的数以十进制输出
;              算法：反复除以 10，余数压栈，最后弹栈输出
;                   栈是后进先出，正好把余数倒过来
;---------------------------------------------------------------
PRINT_DEC PROC
        MOV     AX, BX
        MOV     CX, 0                   ; 记录一共几位
        MOV     SI, 10
PD_LOOP:
        XOR     DX, DX
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

;---------------------------------------------------------------
;  DEC2HEX : 追加要求 —— 输入十进制数，输出十六进制数
;---------------------------------------------------------------
DEC2HEX PROC
        MOV     DX, OFFSET MSG_D2
        MOV     AH, 09H
        INT     21H

        MOV     DX, OFFSET IN_BUF
        MOV     AH, 0AH
        INT     21H

        MOV     DX, OFFSET MSG_H2
        MOV     AH, 09H
        INT     21H

        CALL    DEC2BIN                 ; 输入串 -> BX
        CALL    PRINT_HEX               ; 把 BX 按十六进制输出
        CALL    NEWLINE
        RET
DEC2HEX ENDP

;---------------------------------------------------------------
;  DEC2BIN : 把 IN_BUF 里的十进制字符串转成数值 -> BX
;            算法：BX = BX * 10 + 该位
;---------------------------------------------------------------
DEC2BIN PROC
        MOV     CL, IN_BUF+1
        XOR     CH, CH
        MOV     SI, OFFSET IN_BUF+2
        XOR     BX, BX
        JCXZ    D2B_DONE
D2B_LOOP:
        MOV     AL, [SI]
        SUB     AL, '0'                 ; AL = 0..9
        XOR     AH, AH
        PUSH    AX                      ; 先保存这一位（MUL 会破坏 AX）
        MOV     AX, BX
        MOV     DX, 10
        MUL     DX                      ; DX:AX = BX * 10
        MOV     BX, AX
        POP     AX
        ADD     BX, AX                  ; 累加这一位
        INC     SI
        LOOP    D2B_LOOP
D2B_DONE:
        RET
DEC2BIN ENDP

;---------------------------------------------------------------
;  PRINT_HEX : 把 BX 里的数以十六进制输出
;              去掉前导 0；10..15 输出小写 a..f
;---------------------------------------------------------------
PRINT_HEX PROC
        MOV     CX, 4                   ; 16 位 = 4 个十六进制位
        MOV     DI, 0                   ; DI = 0 表示还没输出过有效位
PH_LOOP:
        ROL     BX, 1                   ; 把最高 4 位循环移到最低 4 位
        ROL     BX, 1
        ROL     BX, 1
        ROL     BX, 1
        MOV     DL, BL
        AND     DL, 0FH                 ; DL = 这一位的数值
        CMP     DI, 0
        JNE     PH_SHOW
        CMP     DL, 0                   ; 是前导 0 就跳过不输出
        JNE     PH_SHOW
        CMP     CX, 1                   ; 但最后一位即使是 0 也要输出
        JE      PH_SHOW
        JMP     PH_NEXT
PH_SHOW:
        MOV     DI, 1                   ; 从这里开始都是有效位
        CMP     DL, 9
        JBE     PH_DIG
        ADD     DL, 'a' - 10            ; 10..15 -> a..f
        JMP     PH_PUT
PH_DIG:
        ADD     DL, '0'
PH_PUT:
        MOV     AH, 02H
        INT     21H
PH_NEXT:
        LOOP    PH_LOOP
        RET
PRINT_HEX ENDP

;---------------------------------------------------------------
;  NEWLINE : 输出回车 + 换行
;---------------------------------------------------------------
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
