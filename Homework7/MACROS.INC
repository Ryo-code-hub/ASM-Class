;===============================================================
;  MACROS.INC     作业7：共享宏库（供多模块 INCLUDE 引入）
;
;  包含以下宏定义：
;      PRINT_S      输出 DS 段内以 '$' 结尾的字符串
;      PUT_CH       输出单个字符
;      PRINT_NL     输出回车换行（嵌套调用 PUT_CH 宏）
;      CHECK_RANGE  范围检查（使用 LOCAL 局部标号避免重复定义）
;      CALL_DOW     封装跨段 FAR 调用 GET_DOW（栈传参）
;      EXIT_DOS     带返回码退出 DOS
;===============================================================

;---------------------------------------------------------------
;  PRINT_S : 输出字符串（保护 AX、DX）
;---------------------------------------------------------------
PRINT_S MACRO   MSG
        PUSH    AX
        PUSH    DX
        MOV     DX, OFFSET MSG
        MOV     AH, 09H
        INT     21H
        POP     DX
        POP     AX
ENDM

;---------------------------------------------------------------
;  PUT_CH : 输出单个字符（保护 AX、DX）
;---------------------------------------------------------------
PUT_CH  MACRO   CHVAL
        PUSH    AX
        PUSH    DX
        MOV     DL, CHVAL
        MOV     AH, 02H
        INT     21H
        POP     DX
        POP     AX
ENDM

;---------------------------------------------------------------
;  PRINT_NL : 输出回车换行（演示宏嵌套调用）
;---------------------------------------------------------------
PRINT_NL MACRO
        PUT_CH  0DH
        PUT_CH  0AH
ENDM

;---------------------------------------------------------------
;  CHECK_RANGE : 检查字变量 VAL 是否满足 LO <= VAL <= HI
;      若越界则跳转到 BAD_LBL；使用 LOCAL 声明局部标号 OK_LBL，
;      确保在同一模块内多次展开时不会发生标号重定义冲突。
;---------------------------------------------------------------
CHECK_RANGE MACRO VAL, LO, HI, BAD_LBL
        LOCAL   OK_LBL
        MOV     AX, VAL
        CMP     AX, LO
        JB      BAD_LBL
        CMP     AX, HI
        JBE     OK_LBL
        JMP     BAD_LBL
OK_LBL:
ENDM

;---------------------------------------------------------------
;  CALL_DOW : 压入 年、月、日 参数并跨模块远调用 GET_DOW
;      出口：AX = 星期 (0=周日 .. 6=周六)
;---------------------------------------------------------------
CALL_DOW MACRO  YVAR, MVAR, DVAL
        PUSH    YVAR
        PUSH    MVAR
        MOV     AX, DVAL
        PUSH    AX
        CALL    FAR PTR GET_DOW
ENDM

;---------------------------------------------------------------
;  EXIT_DOS : 通过 DOS 4CH 号功能退出程序
;---------------------------------------------------------------
EXIT_DOS MACRO  RETCODE
        MOV     AH, 4CH
        MOV     AL, RETCODE
        INT     21H
ENDM
