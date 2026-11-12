;===============================================================
;  FIB.ASM     作业5：递归调用
;              求斐波那契数列第 n 项
;
;      F(0) = 0,  F(1) = 1,  F(n) = F(n-1) + F(n-2)
;      键盘输入 n (1 <= n <= 100)，递归计算并输出 F(n)
;
;  ★ 为什么必须用多精度：
;      F(100) = 354224848179261915075，共 21 位十进制、69 个二进制位。
;      16 位寄存器只够算到 n = 24，32 位只到 n = 47，64 位只到 n = 93。
;      因此本程序把一个大数表示成 5 个 16 位字（共 80 位），足以覆盖 n = 100。
;      存储方式：低位字在前（little-endian）。
;
;  ★ 递归形式：
;      若直接照 F(n)=F(n-1)+F(n-2) 写双重递归，调用次数是 2 的 n 次方级，
;      n = 100 时根本无法算完。因此改用"返回相邻两项"的线性递归：
;
;          FIB2(n)  返回 ( F(n), F(n+1) )
;              若 n = 0 ：返回 ( 0, 1 )
;              若 n > 0 ：先求 (a,b) = FIB2(n-1)，再返回 ( b, a+b )
;
;      其中 a = F(n-1)、b = F(n)，故 b = F(n)、a+b = F(n+1)，符合递推式。
;      递归深度恰为 n，每层工作量是常数，n = 100 时可正常结束。
;
;  编译：BUILDD FIB        运行：BUILD\FIB
;===============================================================
NWORDS  EQU     5                       ; 大数用 5 个 16 位字（80 位）
BNSIZE  EQU     NWORDS*2                ; 一个大数占 10 字节

        .MODEL  SMALL
        .STACK  2000H                   ; 8 KB 栈空间（容量估算见讲解文档）

        .DATA
MSGIN   DB      'Please input n (1-100):', 0DH, 0AH, '$'
MSGF    DB      'F(', '$'
MSGEQ   DB      ') = ', '$'
MSGERR  DB      'n must be in 1..100 !', 0DH, 0AH, '$'

TEN     DW      10                      ; 除法的除数

NVAL    DW      0                       ; 键盘输入的 n
PAIR    DW      2*NWORDS DUP(0)         ; 顶层结果：( F(n), F(n+1) )
WORK    DW      NWORDS DUP(0)           ; 输出十进制时使用的工作副本

        .CODE
START:
        MOV     AX, @DATA
        MOV     DS, AX

        MOV     DX, OFFSET MSGIN
        MOV     AH, 09H
        INT     21H

        CALL    READ_N                  ; 读入 n -> NVAL
        CALL    NEWLINE

        MOV     AX, NVAL                ; 检查 1 <= n <= 100
        CMP     AX, 100
        JA      BAD_N
        CMP     AX, 1
        JB      BAD_N

;---------------------------------------------------------------
;  递归计算 ( F(n), F(n+1) )，写入 PAIR
;---------------------------------------------------------------
        MOV     CX, NVAL                ; CX = n
        MOV     BX, OFFSET PAIR         ; BX = 目标缓冲区
        CALL    FIB2

;---------------------------------------------------------------
;  输出  F(n) = <十进制>
;---------------------------------------------------------------
        MOV     DX, OFFSET MSGF
        MOV     AH, 09H
        INT     21H
        MOV     AX, NVAL
        CALL    PRINT_DEC               ; 括号中的 n
        MOV     DX, OFFSET MSGEQ
        MOV     AH, 09H
        INT     21H
        MOV     SI, OFFSET PAIR         ; PAIR 的前半即 F(n)
        CALL    PRINT_BIG
        CALL    NEWLINE
        JMP     EXIT

BAD_N:
        MOV     DX, OFFSET MSGERR
        MOV     AH, 09H
        INT     21H

EXIT:
        MOV     AX, 4C00H
        INT     21H

;===============================================================
;                          子 程 序
;===============================================================

;---------------------------------------------------------------
;  FIB2 : 递归求 ( F(n), F(n+1) )
;  入口：CX = n，BX = 目标缓冲区地址
;  出口：[BX .. BX+BNSIZE-1]          = F(n)
;        [BX+BNSIZE .. BX+2*BNSIZE-1] = F(n+1)
;  说明：本过程不破坏任何寄存器（含 AX/BX/CX/DX/SI/DI）
;
;  每一层栈帧的构成（共 34 字节）：
;        返回地址        2 字节
;        保存的 6 个寄存器 12 字节   (AX BX CX DX SI DI)
;        局部区          20 字节   (2 个大数，用来接子调用的结果)
;---------------------------------------------------------------
FIB2    PROC
        PUSH    AX
        PUSH    BX
        PUSH    CX
        PUSH    DX
        PUSH    SI
        PUSH    DI

        MOV     DX, BX                  ; DX = 目标缓冲区（FIB2 会保护 DX）
        SUB     SP, 2*BNSIZE            ; 在栈上开辟局部区，接收子结果

        CMP     CX, 0
        JNE     F2_RECUR

;  ---- 递归出口：n = 0，返回 (0, 1) ----
        MOV     DI, DX
        MOV     CX, 2*NWORDS
F2_ZERO:
        MOV     WORD PTR [DI], 0
        ADD     DI, 2
        LOOP    F2_ZERO
        MOV     DI, DX
        ADD     DI, BNSIZE
        MOV     WORD PTR [DI], 1 ; F(1) = 1
        JMP     F2_EXIT

;  ---- 递归步：先求 FIB2(n-1)，再拼出 (F(n), F(n+1)) ----
F2_RECUR:
        MOV     BX, SP                  ; 子调用的结果写到本层局部区
        DEC     CX
        CALL    FIB2                    ; 返回后 [SP..] 为 ( F(n-1), F(n) )

        MOV     SI, SP                  ; ① 目标[0] = 子[1] = F(n)
        ADD     SI, BNSIZE
        MOV     DI, DX
        CALL    BCOPY

        MOV     SI, SP                  ; ② 目标[1] = 子[0] = F(n-1)
        MOV     DI, DX
        ADD     DI, BNSIZE
        CALL    BCOPY

        MOV     SI, SP                  ; ③ 目标[1] += 子[1]  => F(n+1)
        ADD     SI, BNSIZE
        MOV     DI, DX
        ADD     DI, BNSIZE
        CALL    BADD

F2_EXIT:
        ADD     SP, 2*BNSIZE            ; 释放局部区
        POP     DI
        POP     SI
        POP     DX
        POP     CX
        POP     BX
        POP     AX
        RET
FIB2    ENDP

;---------------------------------------------------------------
;  BCOPY : 把 [SI] 处的 NWORDS 个字复制到 [DI]
;  破坏 AX、SI、DI；保护 CX、DX
;---------------------------------------------------------------
BCOPY   PROC
        PUSH    CX
        MOV     CX, NWORDS
BC_LOOP:
        MOV     AX, [SI]
        MOV     [DI], AX
        ADD     SI, 2
        ADD     DI, 2
        LOOP    BC_LOOP
        POP     CX
        RET
BCOPY   ENDP

;---------------------------------------------------------------
;  BADD : [DI] = [DI] + [SI]，按 NWORDS 个字带进位相加
;  破坏 AX、SI、DI；保护 CX、DX
;
;  关键：进位标志 CF 必须连续传递。因此指针只能用 INC 递增
;        （INC 不改变 CF），循环用 LOOP（也不改变 CF），
;        ADC 指令把上一位的进位带进来。
;---------------------------------------------------------------
BADD    PROC
        PUSH    CX
        MOV     CX, NWORDS
        CLC                             ; 最低位无进位
BA_LOOP:
        MOV     AX, [SI]                ; MOV 不改变标志位
        ADC     [DI], AX                ; [DI] = [DI] + AX + CF
        INC     SI
        INC     SI
        INC     DI
        INC     DI
        LOOP    BA_LOOP
        POP     CX
        RET
BADD    ENDP

;---------------------------------------------------------------
;  BDIV10 : 把 [SI] 处的 NWORDS 个字除以 10，商写回 [SI]
;  出口：DX = 余数
;  说明：从最高位字开始逐字做 DIV，余数作为下一个字的高位继续除
;  破坏 AX、BX、DX；保护 CX
;---------------------------------------------------------------
BDIV10  PROC
        PUSH    AX
        PUSH    BX
        PUSH    CX
        MOV     BX, NWORDS
        DEC     BX
        SHL     BX, 1                   ; BX = (NWORDS-1)*2
        ADD     BX, SI                  ; 指向最高位字
        MOV     CX, NWORDS
        XOR     DX, DX                  ; DX = 上一位的余数
BD_LOOP:
        MOV     AX, [BX]
        DIV     WORD PTR [TEN]          ; DX:AX / 10 -> AX=商, DX=余数
        MOV     [BX], AX
        SUB     BX, 2
        LOOP    BD_LOOP
        POP     CX
        POP     BX
        POP     AX
        RET
BDIV10  ENDP

;---------------------------------------------------------------
;  BISZERO : 判断 [SI] 处的 NWORDS 个字是否全为 0
;  出口：ZF = 1 表示全 0（POP 与 RET 均不改变标志位，故结果可靠）
;  保护 AX、CX、SI
;---------------------------------------------------------------
BISZERO PROC
        PUSH    AX
        PUSH    CX
        PUSH    SI
        MOV     CX, NWORDS
BZ_LOOP:
        MOV     AX, [SI]
        OR      AX, AX                  ; 置标志位
        JNZ     BZ_NOTZERO
        ADD     SI, 2
        LOOP    BZ_LOOP
        XOR     AX, AX                  ; 全 0 -> ZF = 1
        JMP     BZ_EXIT
BZ_NOTZERO:
        OR      AX, AX                  ; 非 0 -> ZF = 0
BZ_EXIT:
        POP     SI
        POP     CX
        POP     AX
        RET
BISZERO ENDP

;---------------------------------------------------------------
;  PRINT_BIG : 把 [SI] 处的大数按十进制输出
;  做法：复制到 WORK，然后反复除以 10 取余数，余数压栈；
;        除到 0 之后再逐位弹栈输出（栈的后进先出正好倒序）
;  保护全部寄存器
;---------------------------------------------------------------
PRINT_BIG PROC
        PUSH    AX
        PUSH    CX
        PUSH    DX
        PUSH    SI
        PUSH    DI

        MOV     DI, OFFSET WORK
        CALL    BCOPY                   ; WORK = 待输出的大数

        MOV     CX, 0                   ; CX = 十进制位数
PB_DIV:
        MOV     SI, OFFSET WORK
        CALL    BDIV10                  ; WORK /= 10，DX = 余数
        PUSH    DX
        INC     CX
        MOV     SI, OFFSET WORK
        CALL    BISZERO
        JNZ     PB_DIV                  ; 商不为 0 就继续除

PB_OUT:
        POP     DX
        ADD     DL, '0'
        MOV     AH, 02H
        INT     21H
        LOOP    PB_OUT

        POP     DI
        POP     SI
        POP     DX
        POP     CX
        POP     AX
        RET
PRINT_BIG ENDP

;---------------------------------------------------------------
;  PRINT_DEC : 把 AX 中的无符号数按十进制输出（用于输出 n）
;  保护全部寄存器
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
        PUSH    DX
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
;  READ_N : 从键盘逐字符读入十进制数，结果存入 NVAL
;  用 INT 21H 的 01H 号功能（键盘输入并回显），回车 0DH 结束
;  保护全部寄存器
;---------------------------------------------------------------
READ_N  PROC
        PUSH    AX
        PUSH    BX
        PUSH    DX
        XOR     BX, BX                  ; BX = 累加值
RN_LOOP:
        MOV     AH, 01H
        INT     21H
        CMP     AL, 0DH                 ; 回车 -> 结束
        JE      RN_DONE
        CMP     AL, '0'                 ; 非数字字符一律丢弃
        JB      RN_LOOP
        CMP     AL, '9'
        JA      RN_LOOP
        SUB     AL, '0'
        XOR     AH, AH
        PUSH    AX                      ; 保存这一位（MUL 会破坏 AX）
        MOV     AX, BX
        MOV     DX, 10
        MUL     DX
        MOV     BX, AX
        POP     AX
        ADD     BX, AX                  ; BX = BX*10 + 这一位
        JMP     RN_LOOP
RN_DONE:
        MOV     NVAL, BX
        POP     DX
        POP     BX
        POP     AX
        RET
READ_N  ENDP

;---------------------------------------------------------------
;  NEWLINE : 输出回车换行（保护 AX、DX）
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

        END     START
