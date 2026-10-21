;===============================================================
;  ASCII2.ASM   作业2 第(2)问
;  用【条件跳转指令】打印 ASCII 表中的小写字母，每行 13 个字符
;  本题不使用 LOOP 指令
;
;  思路：只有一个循环，循环体里做两次条件判断
;        ① 本行已经输出 13 个字符了吗？  -> CMP + JNE
;        ② 字母已经超过 'z' 了吗？       -> CMP + JBE
;
;  编译：  BUILD ASCII2        运行：  ASCII2
;===============================================================
        .MODEL  SMALL
        .STACK  100H

        .DATA
LETTER  DB      'a'                     ; 当前要输出的字符
COUNT   DB      0                       ; 本行已经输出了几个字符

        .CODE
START:
        MOV     AX, @DATA
        MOV     DS, AX

NEXT_CHAR:
        MOV     DL, LETTER              ; 输出当前字母
        MOV     AH, 02H                 ; 功能 02H：显示单个字符
        INT     21H

        MOV     DL, ' '                 ; 输出一个空格
        MOV     AH, 02H
        INT     21H

        INC     LETTER                  ; 指向下一个字母
        INC     COUNT                   ; 本行计数 +1

        CMP     COUNT, 13               ; ① 本行够 13 个字符了吗？
        JNE     NO_NEWLINE              ;    不够 -> 跳过换行
        MOV     DL, 0DH                 ;    够了 -> 输出回车换行
        MOV     AH, 02H
        INT     21H
        MOV     DL, 0AH
        MOV     AH, 02H
        INT     21H
        MOV     COUNT, 0                ;    本行计数清零，准备下一行

NO_NEWLINE:
        CMP     LETTER, 'z'             ; ② 字母还没超过 'z' 吗？
        JBE     NEXT_CHAR               ;    没超过 -> 继续输出
                                        ;    超过了 -> 顺序执行到下面，结束

        MOV     AX, 4C00H               ; 功能 4CH：结束程序
        INT     21H
        END     START
