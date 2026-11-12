/*===============================================================
 *  9.C     作业4 第(3)问
 *  用 C 语言输出九九乘法表
 *
 *  编译：cl /nologo /Od /c 9.C
 *        然后 dumpbin /nologo /disasm 9.obj
 *  运行：9.EXE
 *
 *  反汇编结果和逐条注释见同目录的 DISASM.TXT
 *===============================================================*/
#include <stdio.h>

int main(void)
{
    int row;                                /* 行号：9 递减到 1 */
    int col;                                /* 列号：1 递增到 row */

    printf("The 9mul9 table:\n");

    for (row = 9; row >= 1; row--)          /* 外层循环：控制行 */
    {
        for (col = 1; col <= row; col++)    /* 内层循环：本行输出 row 项 */
        {
            printf("%d*%d=%d\t", row, col, row * col);
        }
        putchar('\n');
    }

    return 0;
}
