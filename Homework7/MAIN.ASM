;===============================================================
;  MAIN.ASM       作业7 模块1：主控模块与公共数据/栈段
;
;  功能：读入并校验年份 (1900~2099) 与月份 (1~12)，输出月历表头，
;        通过跨模块 FAR/NEAR 调用完成天数、星期计算与月历排布。
;
;  多模块协作方式：
;      1. 引入 MACROS.INC 共享宏库（PRINT_S, PRINT_NL, CHECK_RANGE 等）
;      2. STACKS / DATAS / CODES 与其它模块同名同类别分段，由 LINK 合并
;      3. 与 IO.ASM / GRID.ASM 之间为"跨文件同段 NEAR 调用"
;      4. 与 CALC.ASM 之间为"跨文件跨段 FAR 调用"
;===============================================================

        INCLUDE MACROS.INC

;---- 跨文件、跨段（CALC 段）的远过程声明 ----
        EXTRN   GET_DAYS:FAR, GET_DOW:FAR

;---------------------- 栈 段 ----------------------------------
STACKS  SEGMENT PARA STACK 'STACK'
        DW      400H DUP(0)
STACKS  ENDS

;---------------------- 数据 段 ---------------------------------
DATAS   SEGMENT PARA PUBLIC 'DATA'
        PUBLIC  NBUF, DAYS, LEAD, OUTVAL

MSG_Y   DB      'Please input year (1900-2099): ', '$'
MSG_M   DB      'Please input month (1-12): ', '$'
MSG_EY  DB      0DH, 0AH, 'year must be in 1900..2099 !', 0DH, 0AH, '$'
MSG_EM  DB      0DH, 0AH, 'month must be in 1..12 !', 0DH, 0AH, '$'
TWO_SP  DB      '  ', '$'
WEEKHDR DB      'Su Mo Tu We Th Fr Sa', 0DH, 0AH, '$'

; 月名表：每条固定 10 字节（名称 + '$' 补足）
MNAMES  DB      'January$$$'
        DB      'February$$'
        DB      'March$$$$$'
        DB      'April$$$$$'
        DB      'May$$$$$$$'
        DB      'June$$$$$$'
        DB      'July$$$$$$'
        DB      'August$$$$'
        DB      'September$'
        DB      'October$$$'
        DB      'November$$'
        DB      'December$$'

NBUF    DB      8, 0, 8 DUP(0)          ; DOS 0AH 输入缓冲区
YEAR    DW      0
MONTH   DW      0
DAYS    DW      0                       ; 本月天数（共享给 GRID 模块）
LEAD    DW      0                       ; 1 号前空列数（共享给 GRID 模块）
OUTVAL  DW      0                       ; 数据段传参变量（共享给 IO/GRID）
DATAS   ENDS

;====================== 主代码段（CODES）=======================
CODES   SEGMENT PARA PUBLIC 'CODE'
        ASSUME  CS:CODES, DS:DATAS, SS:STACKS

;---- 跨文件、同段（CODES 段合并）的近过程声明 ----
        EXTRN   READ_LINE:NEAR, PARSE_NUM:NEAR
        EXTRN   PRINT_DEC:NEAR, PRINT_STR:NEAR
        EXTRN   SHOW_GRID:NEAR

START:
        MOV     AX, DATAS
        MOV     DS, AX                  ; 建立数据段寻址

;  ---- 输入并校验年份 ----
        PRINT_S MSG_Y
        CALL    READ_LINE               ; 跨文件同段 NEAR CALL (IO.ASM)
        CALL    PARSE_NUM               ; 跨文件同段 NEAR CALL (IO.ASM)
        MOV     YEAR, AX
        CHECK_RANGE YEAR, 1900, 2099, BAD_YEAR
        JMP     YEAR_OK
BAD_YEAR:
        PRINT_S MSG_EY
        JMP     EXIT
YEAR_OK:

;  ---- 输入并校验月份 ----
        PRINT_S MSG_M
        CALL    READ_LINE
        CALL    PARSE_NUM
        MOV     MONTH, AX
        CHECK_RANGE MONTH, 1, 12, BAD_MONTH
        JMP     MONTH_OK
BAD_MONTH:
        PRINT_S MSG_EM
        JMP     EXIT
MONTH_OK:

;  ---- 输出空行及表头 "2026  November" ----
        PRINT_NL
        MOV     AX, YEAR
        CALL    PRINT_DEC               ; 跨文件同段 NEAR CALL (IO.ASM)
        PRINT_S TWO_SP
        MOV     AX, MONTH
        DEC     AX
        MOV     BX, 10
        MUL     BX                      ; AX = (月份-1)*10
        MOV     DX, OFFSET MNAMES
        ADD     DX, AX
        CALL    PRINT_STR               ; 跨文件同段 NEAR CALL (IO.ASM)
        PRINT_NL

        PRINT_S WEEKHDR                 ; "Su Mo Tu We Th Fr Sa"

;  ---- 取本月天数（寄存器传参，跨文件跨段 FAR 调用 CALC.ASM）----
        MOV     AX, YEAR
        MOV     BX, MONTH
        CALL    FAR PTR GET_DAYS        ; 跨文件跨段 FAR CALL
        MOV     DAYS, AX

;  ---- 取 1 号的星期（栈传参，宏封装跨文件跨段 FAR 调用）----
        CALL_DOW YEAR, MONTH, 1         ; 宏内压参并 CALL FAR PTR GET_DOW
        MOV     LEAD, AX

;  ---- 打印月历网格（数据段传参，跨文件同段 NEAR 调用 GRID.ASM）----
        CALL    SHOW_GRID               ; 跨文件同段 NEAR CALL

EXIT:
        EXIT_DOS 0

CODES   ENDS
        END     START
