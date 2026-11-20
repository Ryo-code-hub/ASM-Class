;===============================================================
;  CALENDAR.ASM     作业6：输出日历
;
;  输入年份 (1900~2099) 与月份 (1~12)，输出该月的月历。
;
;  本程序刻意采用"多段"结构，以练习段间调用与跳转：
;
;      STACKS  栈段
;      DATAS   数据段（变量、月名表、各类常量表）
;      CODES   第一代码段：输入、校验、输出、日历排版
;      CALC    第二代码段：纯计算过程（闰年判断、某月天数、1 号星期）
;
;  CODES 调用 CALC 中的过程一律用 FAR CALL（跨段），
;  CALC 内部的调用用 NEAR CALL（同段）。
;
;  参数的三种传递方式都用到：
;      GET_DAYS   寄存器传参   （AX=年, BX=月 -> AX=天数）
;      GET_DOW    栈传参       （压入 年、月、日 -> AX=星期）
;      PRINT_NUM  数据段传参   （变量 OUTVAL -> 输出两位十进制）
;
;  编译：BUILDD CALENDAR      运行：BUILD\CALENDAR
;===============================================================

;---------------------- 栈 段 ----------------------------------
STACKS  SEGMENT PARA STACK 'STACK'
        DW      400H DUP(0)
STACKS  ENDS

;---------------------- 数据 段 ---------------------------------
DATAS   SEGMENT PARA PUBLIC 'DATA'
MSG_Y   DB      'Please input year (1900-2099): ', '$'
MSG_M   DB      'Please input month (1-12): ', '$'
MSG_EY  DB      0DH, 0AH, 'year must be in 1900..2099 !', 0DH, 0AH, '$'
MSG_EM  DB      0DH, 0AH, 'month must be in 1..12 !', 0DH, 0AH, '$'
TWO_SP  DB      '  ', '$'
WEEKHDR DB      'Su Mo Tu We Th Fr Sa', 0DH, 0AH, '$'

; 月名表：每条固定 10 字节（名称 + 若干 '$' 补足），便于用 (月份-1)*10 定位
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

; 每月天数（二月先按 28 天，闰年再单独修正）
DAYTAB  DB      31,28,31,30,31,30,31,31,30,31,30,31

; 求星期用的修正表（Sakamoto 法），下标为 月份-1
DOWTAB  DB      0,3,2,5,0,3,5,1,4,6,2,4

NBUF    DB      8, 0, 8 DUP(0)          ; DOS 0AH 输入缓冲区
YEAR    DW      0
MONTH   DW      0
DAYS    DW      0                       ; 本月天数
LEAD    DW      0                       ; 1 号之前的空格数（0=周日）
OUTVAL  DW      0                       ; 供 PRINT_NUM 取用的输出值
DATAS   ENDS

;====================== 第一代码段 ==============================
CODES   SEGMENT PARA PUBLIC 'CODE'
        ASSUME  CS:CODES, DS:DATAS, SS:STACKS

;---------------------------------------------------------------
;  主程序
;---------------------------------------------------------------
START:
        MOV     AX, DATAS
        MOV     DS, AX                  ; 建立数据段寻址

;  ---- 输入年份 ----
        MOV     DX, OFFSET MSG_Y
        CALL    PRINT_STR
        CALL    READ_LINE
        CALL    PARSE_NUM               ; AX = 输入值
        MOV     YEAR, AX
        CMP     AX, 1900
        JB      BAD_YEAR
        CMP     AX, 2099
        JBE     YEAR_OK
BAD_YEAR:
        MOV     DX, OFFSET MSG_EY
        CALL    PRINT_STR
        JMP     EXIT
YEAR_OK:

;  ---- 输入月份 ----
        MOV     DX, OFFSET MSG_M
        CALL    PRINT_STR
        CALL    READ_LINE
        CALL    PARSE_NUM
        MOV     MONTH, AX
        CMP     AX, 1
        JB      BAD_MONTH
        CMP     AX, 12
        JBE     MONTH_OK
BAD_MONTH:
        MOV     DX, OFFSET MSG_EM
        CALL    PRINT_STR
        JMP     EXIT
MONTH_OK:

;  ---- 空一行，再输出表头 "2026  November" ----
        CALL    NEWLINE                 ; 示例中月份输入后有一个空行
        MOV     AX, YEAR
        CALL    PRINT_DEC               ; 年份
        MOV     DX, OFFSET TWO_SP
        CALL    PRINT_STR               ; 两个空格
        MOV     AX, MONTH
        DEC     AX
        MOV     BX, 10
        MUL     BX                      ; AX = (月份-1)*10
        MOV     DX, OFFSET MNAMES
        ADD     DX, AX
        CALL    PRINT_STR               ; 月名
        CALL    NEWLINE

        MOV     DX, OFFSET WEEKHDR
        CALL    PRINT_STR               ; "Su Mo Tu We Th Fr Sa"

;  ---- 取本月天数（寄存器传参，跨段调用）----
        MOV     AX, YEAR
        MOV     BX, MONTH
        CALL    FAR PTR GET_DAYS                ; FAR CALL -> AX = 天数
        MOV     DAYS, AX

;  ---- 取 1 号的星期（栈传参，跨段调用）----
        PUSH    YEAR
        PUSH    MONTH
        MOV     AX, 1
        PUSH    AX                      ; 压入日 = 1
        CALL    FAR PTR GET_DOW                 ; FAR CALL；过程内用 RET 6 清栈
        MOV     LEAD, AX

;  ---- 打印月历网格 ----
        CALL    SHOW_GRID

EXIT:
        MOV     AX, 4C00H
        INT     21H

;---------------------------------------------------------------
;  SHOW_GRID : 按 LEAD 与 DAYS 输出月历网格
;     每格宽 2，格间一个空格；每行 7 格
;---------------------------------------------------------------
SHOW_GRID PROC
        PUSH    AX
        PUSH    BX
        PUSH    CX
        PUSH    DX
        PUSH    SI
        PUSH    DI

        MOV     SI, 1                   ; SI = 当前日
        MOV     BX, LEAD                ; BX = 还要空出的格数
        XOR     DI, DI                  ; DI = 当前列 (0..6)

GRID_NEXT:
        CMP     DI, 0                   ; 非行首则先输出一个分隔空格
        JE      GRID_NOSP
        MOV     DL, ' '
        CALL    PUTCH
GRID_NOSP:
        CMP     BX, 0
        JNE     GRID_BLANK
        MOV     OUTVAL, SI              ; 通过数据段变量传参
        CALL    PRINT_NUM               ; 输出右对齐两位日期
        INC     SI
        JMP     GRID_CELLDONE
GRID_BLANK:
        MOV     DL, ' '
        CALL    PUTCH
        MOV     DL, ' '
        CALL    PUTCH
        DEC     BX
GRID_CELLDONE:
        INC     DI
        CMP     DI, 7
        JB      GRID_NOTEND             ; 未满 7 格
        CALL    NEWLINE
        XOR     DI, DI
GRID_NOTEND:
        CMP     SI, DAYS
        JBE     GRID_NEXT               ; 还有日期
        CMP     DI, 0
        JE      GRID_DONE
        CALL    NEWLINE                 ; 末行不满则补换行
GRID_DONE:
        POP     DI
        POP     SI
        POP     DX
        POP     CX
        POP     BX
        POP     AX
        RET
SHOW_GRID ENDP

;---------------------------------------------------------------
;  READ_LINE : 用 DOS 0AH 号功能读入一行到 NBUF（自动回显并换行）
;---------------------------------------------------------------
READ_LINE PROC
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
PARSE_NUM PROC
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
PRINT_NUM PROC
        PUSH    AX
        MOV     AX, OUTVAL
        CALL    PRINT_2
        POP     AX
        RET
PRINT_NUM ENDP

;---------------------------------------------------------------
;  PRINT_2 : 把 AX (0~99) 右对齐两位输出
;---------------------------------------------------------------
PRINT_2 PROC
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
PRINT_DEC PROC
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
PRINT_STR PROC
        PUSH    AX
        MOV     AH, 09H
        INT     21H
        POP     AX
        RET
PRINT_STR ENDP

;---------------------------------------------------------------
;  PUTCH : 输出 DL 中的字符（保护 AX）
;---------------------------------------------------------------
PUTCH   PROC
        PUSH    AX
        MOV     AH, 02H
        INT     21H
        POP     AX
        RET
PUTCH   ENDP

;---------------------------------------------------------------
;  NEWLINE : 输出回车换行
;---------------------------------------------------------------
NEWLINE PROC
        PUSH    AX
        PUSH    DX
        MOV     DL, 0DH
        MOV     AH, 02H
        INT     21H
        MOV     DL, 0AH
        MOV     AH, 02H
        INT     21H
        POP     DX
        POP     AX
        RET
NEWLINE ENDP

CODES   ENDS

;====================== 第二代码段 ==============================
;  只放纯计算过程，不涉及输入输出，故不需要保存 DS。
CALC    SEGMENT PARA PUBLIC 'CALC'
        ASSUME  CS:CALC, DS:DATAS, SS:STACKS

;---------------------------------------------------------------
;  GET_DAYS : 求某年某月的天数
;  参数传递方式：【寄存器】
;      入口：AX = 年，BX = 月 (1~12)
;      出口：AX = 天数
;  跨段调用（FAR）
;---------------------------------------------------------------
GET_DAYS PROC FAR
        PUSH    BX
        PUSH    CX
        PUSH    DX
        PUSH    SI

        MOV     SI, BX
        DEC     SI                      ; SI = 月份-1
        MOV     DL, DAYTAB[SI]          ; 先取平年天数
        CMP     SI, 1                   ; 是二月吗
        JNE     GD_RET
        CALL    IS_LEAP                 ; 入口 AX = 年，出口 AL = 1 闰年
        CMP     AL, 1
        JNE     GD_RET
        MOV     DL, 29
GD_RET:
        XOR     DH, DH
        MOV     AX, DX

        POP     SI
        POP     DX
        POP     CX
        POP     BX
        RET
GET_DAYS ENDP

;---------------------------------------------------------------
;  IS_LEAP : 判断闰年
;      入口：AX = 年     出口：AL = 1 闰年 / 0 平年
;  同段调用（NEAR）
;---------------------------------------------------------------
IS_LEAP PROC NEAR
        PUSH    BX
        PUSH    CX
        PUSH    DX
        PUSH    SI
        MOV     SI, AX                  ; SI = 年

        MOV     AX, SI                  ; 能被 4 整除？
        MOV     BX, 4
        XOR     DX, DX
        DIV     BX
        CMP     DX, 0
        JNE     IL_NO
        MOV     AX, SI                  ; 能被 100 整除？
        MOV     BX, 100
        XOR     DX, DX
        DIV     BX
        CMP     DX, 0
        JNE     IL_YES
        MOV     AX, SI                  ; 能被 400 整除？
        MOV     BX, 400
        XOR     DX, DX
        DIV     BX
        CMP     DX, 0
        JNE     IL_NO
IL_YES:
        MOV     AL, 1
        JMP     IL_EXIT
IL_NO:
        MOV     AL, 0
IL_EXIT:
        POP     SI
        POP     DX
        POP     CX
        POP     BX
        RET
IS_LEAP ENDP

;---------------------------------------------------------------
;  GET_DOW : 求某日是星期几（Sakamoto 法，0 = 周日）
;  参数传递方式：【栈】
;      调用者依次压入：年、月、日（最后压入日）
;      因此进入过程后（FAR 调用，BP+4 为返回的 CS）：
;              [BP+10]  年
;              [BP+8]  月
;              [BP+6] 日
;      出口：AX = 0~6 (0 = 周日)
;      过程内用 RET 6 返回，顺带弹出 3 个参数（被调用者清栈）
;---------------------------------------------------------------
GET_DOW PROC FAR
        PUSH    BP
        MOV     BP, SP
        PUSH    BX
        PUSH    CX
        PUSH    DX
        PUSH    SI
        PUSH    DI

        MOV     AX, [BP+10]              ; 年
        MOV     BX, [BP+8]              ; 月
        MOV     DI, [BP+6]             ; 日
        CMP     BX, 3
        JAE     GD_W_NOADJ
        DEC     AX                      ; 1、2 月按上一年计算
GD_W_NOADJ:
        MOV     SI, AX                  ; SI = 调整后的年

        MOV     CX, SI                  ; CX = 年
        MOV     AX, SI                  ; + 年/4
        MOV     BX, 4
        XOR     DX, DX
        DIV     BX
        ADD     CX, AX
        MOV     AX, SI                  ; - 年/100
        MOV     BX, 100
        XOR     DX, DX
        DIV     BX
        SUB     CX, AX
        MOV     AX, SI                  ; + 年/400
        MOV     BX, 400
        XOR     DX, DX
        DIV     BX
        ADD     CX, AX

        MOV     BX, [BP+8]              ; + DOWTAB[月-1]
        DEC     BX
        MOV     AL, DOWTAB[BX]
        XOR     AH, AH
        ADD     CX, AX

        ADD     CX, DI                  ; + 日

        MOV     AX, CX                  ; 对 7 取余
        XOR     DX, DX
        MOV     BX, 7
        DIV     BX
        MOV     AX, DX

        POP     DI
        POP     SI
        POP     DX
        POP     CX
        POP     BX
        POP     BP
        RET     6                       ; 返回并弹出 3 个参数
GET_DOW ENDP

CALC    ENDS

        END     START
