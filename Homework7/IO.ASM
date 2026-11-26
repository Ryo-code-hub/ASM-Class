;===============================================================
;  IO.ASM         作业7 模块2：输入与输出基础过程模块
;
;  导出过程（均位于公共代码段 CODES，供同段跨文件 NEAR 调用）：
;      READ_LINE   读入一行到 NBUF
;      PARSE_NUM   将 NBUF 解析为无符号整数 -> AX
;      PRINT_NUM   输出数据段变量 OUTVAL（右对齐两位）
;      PRINT_2     将 AX (0~99) 右对齐两位输出
;      PRINT_DEC   将 AX 按十进制输出
;      PRINT_STR   输出 DS:DX 所指 '$' 结尾字符串
;      PUTCH       输出 DL 中的字符
;      NEWLINE     输出回车换行
;===============================================================

        INCLUDE MACROS.INC

DATAS   SEGMENT PARA PUBLIC 'DATA'
        EXTRN   NBUF:BYTE, OUTVAL:WORD
DATAS   ENDS

CODES   SEGMENT PARA PUBLIC 'CODE'
        ASSUME  CS:CODES, DS:DATAS
        PUBLIC  READ_LINE, PARSE_NUM, PRINT_NUM, PRINT_2
        PUBLIC  PRINT_DEC, PRINT_STR, PUTCH, NEWLINE

;---------------------------------------------------------------
;  READ_LINE : 用 DOS 0AH 号功能读入一行到 NBUF
;---------------------------------------------------------------
READ_LINE PROC  NEAR
        PUSH    AX
        PUSH    DX
        MOV     DX, OFFSET NBUF
        MOV     AH, 0AH
        INT     21H
        POP     DX
        POP     AX
        RET
READ_LINE ENDP

;---------------------------------------------------------------
;  PARSE_NUM : 把 NBUF 中的十进制数字串转成数值
;  出口：AX = 数值（非数字字符忽略）
;---------------------------------------------------------------
PARSE_NUM PROC  NEAR
        PUSH    BX
        PUSH    CX
        PUSH    DX
        PUSH    SI
        XOR     BX, BX                  ; BX = 累加值
        MOV     CL, NBUF+1              ; 实际输入长度
        XOR     CH, CH
        MOV     SI, OFFSET NBUF+2
        JCXZ    PN_DONE
PN_LOOP:
        MOV     AL, [SI]
        CMP     AL, '0'
        JB      PN_SKIP
        CMP     AL, '9'
        JA      PN_SKIP
        SUB     AL, '0'
        XOR     AH, AH
        PUSH    AX                      ; 保存本位（MUL 破坏 AX）
        MOV     AX, BX
        MOV     DX, 10
        MUL     DX
        MOV     BX, AX
        POP     AX
        ADD     BX, AX                  ; BX = BX*10 + 本位
PN_SKIP:
        INC     SI
        LOOP    PN_LOOP
PN_DONE:
        MOV     AX, BX
        POP     SI
        POP     DX
        POP     CX
        POP     BX
        RET
PARSE_NUM ENDP

;---------------------------------------------------------------
;  PRINT_NUM : 输出 OUTVAL 中的数（数据段传参），右对齐两位
;---------------------------------------------------------------
PRINT_NUM PROC  NEAR
        PUSH    AX
        MOV     AX, OUTVAL
        CALL    PRINT_2                 ; 同文件同段 NEAR CALL
        POP     AX
        RET
PRINT_NUM ENDP

;---------------------------------------------------------------
;  PRINT_2 : 把 AX (0~99) 右对齐两位输出
;---------------------------------------------------------------
PRINT_2 PROC    NEAR
        PUSH    AX
        PUSH    BX
        PUSH    CX
        PUSH    DX
        MOV     BX, 10
        XOR     DX, DX
        DIV     BX                      ; AX = 十位, DX = 个位
        MOV     CX, DX                  ; CX = 个位
        CMP     AX, 0
        JNE     P2_TENS
        MOV     DL, ' '                 ; 十位为 0 则输出空格
        CALL    PUTCH
        JMP     P2_UNIT
P2_TENS:
        MOV     DX, AX
        ADD     DL, '0'
        CALL    PUTCH
P2_UNIT:
        MOV     DX, CX
        ADD     DL, '0'
        CALL    PUTCH
        POP     DX
        POP     CX
        POP     BX
        POP     AX
        RET
PRINT_2 ENDP

;---------------------------------------------------------------
;  PRINT_DEC : 把 AX 按十进制输出（不限位数）
;---------------------------------------------------------------
PRINT_DEC PROC  NEAR
        PUSH    AX
        PUSH    BX
        PUSH    CX
        PUSH    DX
        MOV     BX, 10
        MOV     CX, 0
PD_DIV:
        XOR     DX, DX
        DIV     BX
        PUSH    DX                      ; 余数压栈，稍后倒序输出
        INC     CX
        CMP     AX, 0
        JNE     PD_DIV
PD_OUT:
        POP     DX
        ADD     DL, '0'
        MOV     AH, 02H
        INT     21H
        LOOP    PD_OUT
        POP     DX
        POP     CX
        POP     BX
        POP     AX
        RET
PRINT_DEC ENDP

;---------------------------------------------------------------
;  PRINT_STR : 输出 DS:DX 所指的以 '$' 结尾的字符串
;---------------------------------------------------------------
PRINT_STR PROC  NEAR
        PUSH    AX
        MOV     AH, 09H
        INT     21H
        POP     AX
        RET
PRINT_STR ENDP

;---------------------------------------------------------------
;  PUTCH : 输出 DL 中的字符（保护 AX）
;---------------------------------------------------------------
PUTCH   PROC    NEAR
        PUSH    AX
        MOV     AH, 02H
        INT     21H
        POP     AX
        RET
PUTCH   ENDP

;---------------------------------------------------------------
;  NEWLINE : 输出回车换行（使用宏）
;---------------------------------------------------------------
NEWLINE PROC    NEAR
        PRINT_NL
        RET
NEWLINE ENDP

CODES   ENDS
        END
