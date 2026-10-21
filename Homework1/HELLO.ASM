;===============================================================
;  HELLO.ASM     第一次作业：helloworld
;
;  传统方式：源代码 -> 汇编 -> 链接
;      汇编：MASM HELLO.ASM;      （生成 HELLO.OBJ 和 HELLO.LST）
;      链接：LINK HELLO.OBJ;      （生成 HELLO.EXE）
;  运行：HELLO
;
;  源码采用讲义《hello剖析》里的"源码一"，用 LEA 取偏移地址，
;  方便和讲义中的 debug -u 反汇编结果逐条对照。
;===============================================================
        .MODEL  SMALL
        .STACK  100H

        .DATA
Hello   DB      'Hello world!', 0DH, 0AH, '$'
        ;  0DH,0AH = 回车换行；'$' 是 DOS 09H 号功能约定的字符串结束符

        .CODE
START:
        MOV     AX, @DATA               ; @DATA = 数据段的段地址
        MOV     DS, AX                  ; 让 DS 指向数据段

        LEA     DX, Hello               ; DX = Hello 的偏移地址
        MOV     AH, 09H                 ; 09H 号功能：显示以 '$' 结尾的字符串
        INT     21H

        MOV     AX, 4C00H               ; 4CH 号功能：结束程序，AL = 返回码 0
        INT     21H
        END     START
