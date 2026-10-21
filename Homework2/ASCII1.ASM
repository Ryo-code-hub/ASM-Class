;===============================================================
;  ASCII1.ASM   作业2 第(1)问
;  用 LOOP 指令打印 ASCII 表中的小写字母，每行 13 个字符
;
;  双重循环结构：
;        外层循环  2 次      -> CX = 2      控制行数
;        内层循环  13 次     -> CX = 13     控制每行的字符数
;
;  ★ 关键点：外层和内层都要用 CX 计数，而 LOOP 指令会不停地把
;    CX 减到 0。所以进入内层之前必须先用 PUSH CX 把外层的计数
;    保存起来，内层结束后再 POP CX 恢复，否则外层循环只能走一趟。
;
;  编译：  BUILD ASCII1        运行：  ASCII1
;===============================================================
        .MODEL  SMALL
        .STACK  100H

        .DATA
LETTER  DB      'a'                     ; 当前要输出的字符，从 'a' 开始

        .CODE
START:
        MOV     AX, @DATA
        MOV     DS, AX                  ; 让 DS 指向数据段

        MOV     CX, 2                   ; 外层循环：一共 2 行

LINE_LOOP:
        PUSH    CX                      ; ★ 保存外层计数（2 或 1）

        MOV     CX, 13                  ; 内层循环：每行 13 个字符

CHAR_LOOP:
        MOV     DL, LETTER              ; DL = 当前字符
        MOV     AH, 02H                 ; DOS 功能调用 02H：显示单个字符
        INT     21H                     ; 输出字母

        MOV     DL, ' '                 ; 再输出一个空格
        MOV     AH, 02H
        INT     21H

        INC     LETTER                  ; 指向下一个字母
        LOOP    CHAR_LOOP               ; 内层 CX-1，不为 0 就继续

        POP     CX                      ; ★ 恢复外层计数
                                        ;   （内层 LOOP 已经把 CX 减成 0 了）

        MOV     DL, 0DH                 ; 回车 CR
        MOV     AH, 02H
        INT     21H
        MOV     DL, 0AH                 ; 换行 LF
        MOV     AH, 02H
        INT     21H

        LOOP    LINE_LOOP               ; 外层 CX-1，不为 0 就再来一行

        MOV     AX, 4C00H               ; 功能 4CH：带返回码结束程序
        INT     21H                     ; 返回码 AL = 00H
        END     START
