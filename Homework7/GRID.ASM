;===============================================================
;  GRID.ASM       作业7 模块4：月历网格排版输出模块
;
;  导出过程（位于公共代码段 CODES，供 MAIN 跨文件同段 NEAR 调用）：
;      SHOW_GRID   按全局数据段变量 LEAD 与 DAYS 输出月历网格
;===============================================================

        INCLUDE MACROS.INC

DATAS   SEGMENT PARA PUBLIC 'DATA'
        EXTRN   DAYS:WORD, LEAD:WORD, OUTVAL:WORD
DATAS   ENDS

CODES   SEGMENT PARA PUBLIC 'CODE'
        ASSUME  CS:CODES, DS:DATAS
        PUBLIC  SHOW_GRID
        EXTRN   PRINT_NUM:NEAR

;---------------------------------------------------------------
;  SHOW_GRID : 按 LEAD 与 DAYS 输出月历网格
;      每格宽 2，格间一个空格；每行 7 格
;      通过共享变量 OUTVAL 向 IO 模块的 PRINT_NUM 传参（数据段传参）
;---------------------------------------------------------------
SHOW_GRID PROC  NEAR
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
        PUT_CH  ' '                     ; 宏：输出分隔空格
GRID_NOSP:
        CMP     BX, 0
        JNE     GRID_BLANK
        MOV     OUTVAL, SI              ; 通过数据段变量传参
        CALL    PRINT_NUM               ; 跨文件同段 NEAR CALL (IO.ASM)
        INC     SI
        JMP     GRID_CELLDONE
GRID_BLANK:
        PUT_CH  ' '
        PUT_CH  ' '
        DEC     BX
GRID_CELLDONE:
        INC     DI
        CMP     DI, 7
        JB      GRID_NOTEND             ; 未满 7 格
        PRINT_NL                        ; 宏：换行
        XOR     DI, DI
GRID_NOTEND:
        CMP     SI, DAYS
        JBE     GRID_NEXT               ; 还有日期
        CMP     DI, 0
        JE      GRID_DONE
        PRINT_NL                        ; 末行不满则补换行
GRID_DONE:
        POP     DI
        POP     SI
        POP     DX
        POP     CX
        POP     BX
        POP     AX
        RET
SHOW_GRID ENDP

CODES   ENDS
        END
