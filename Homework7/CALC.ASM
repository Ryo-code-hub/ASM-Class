;===============================================================
;  CALC.ASM       作业7 模块3：纯日历计算模块（独立 CALC 代码段）
;
;  导出过程（均位于独立代码段 CALC，供跨段 FAR 调用）：
;      GET_DAYS  求某年某月天数（寄存器传参：AX=年, BX=月 -> AX=天数）
;      GET_DOW   求某日星期几  （栈传参：压入年、月、日 -> AX=0..6）
;
;  模块私有过程：
;      IS_LEAP   判断闰年（仅在 CALC 内部同段 NEAR 调用）
;===============================================================

;---- 本模块私有查表数据（链接时并入公共 DATAS 段）----
DATAS   SEGMENT PARA PUBLIC 'DATA'
DAYTAB  DB      31,28,31,30,31,30,31,31,30,31,30,31
DOWTAB  DB      0,3,2,5,0,3,5,1,4,6,2,4
DATAS   ENDS

;====================== 独立计算代码段（CALC）==================
CALC    SEGMENT PARA PUBLIC 'CALC'
        ASSUME  CS:CALC, DS:DATAS
        PUBLIC  GET_DAYS, GET_DOW

;---------------------------------------------------------------
;  GET_DAYS : 求某年某月的天数
;  参数传递方式：【寄存器】
;      入口：AX = 年，BX = 月 (1~12)
;      出口：AX = 天数
;  跨文件跨段调用（FAR）
;---------------------------------------------------------------
GET_DAYS PROC   FAR
        PUSH    BX
        PUSH    CX
        PUSH    DX
        PUSH    SI

        MOV     SI, BX
        DEC     SI                      ; SI = 月份-1
        MOV     DL, DAYTAB[SI]          ; 先取平年天数
        CMP     SI, 1                   ; 是二月吗
        JNE     GD_RET
        CALL    IS_LEAP                 ; 同文件同段 NEAR CALL
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
;  IS_LEAP : 判断闰年（模块私有过程）
;      入口：AX = 年     出口：AL = 1 闰年 / 0 平年
;---------------------------------------------------------------
IS_LEAP PROC    NEAR
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
;      进入过程后（FAR 调用，BP+4 为返回 CS，BP+2 为返回 IP）：
;          [BP+10] 年
;          [BP+8]  月
;          [BP+6]  日
;      出口：AX = 0~6 (0 = 周日)
;      过程末尾用 RET 6 返回并清栈（CA 06 00）
;---------------------------------------------------------------
GET_DOW PROC    FAR
        PUSH    BP
        MOV     BP, SP
        PUSH    BX
        PUSH    CX
        PUSH    DX
        PUSH    SI
        PUSH    DI

        MOV     AX, [BP+10]             ; 年
        MOV     BX, [BP+8]              ; 月
        MOV     DI, [BP+6]              ; 日
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
        RET     6                       ; 远返回并弹出 3 个字参数
GET_DOW ENDP

CALC    ENDS
        END
