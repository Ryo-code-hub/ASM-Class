/*===============================================================
 *  ASCII.C     作业2 第(3)问
 *  用 C 语言打印 ASCII 表中的小写字母，每行 13 个字符
 *  编译后用 dumpbin /disasm 察看反汇编代码（见 ASCII_C_DISASM.txt）
 *
 *  编译（MSVC x86）：  cl /nologo /Od /c ASCII.C
 *  运行：              ASCII.EXE
 *===============================================================*/
#include <stdio.h>

int main(void)
{
    int c;              /* 当前字符 */
    int n = 0;          /* 本行已经输出了几个字母 */

    for (c = 'a'; c <= 'z'; c++)    /* 循环变量就是字符本身，和汇编版一致 */
    {
        putchar(c);                 /* 输出字母   -> 对应 MOV DL,LETTER / INT 21H */
        putchar(' ');               /* 输出空格   -> 对应 MOV DL,' ' / INT 21H   */

        n++;
        if (n == 13)                /* 每满 13 个 -> 对应 CMP COUNT,13 / JNE */
        {
            putchar('\n');          /* 换行       -> 对应 CR + LF */
            n = 0;
        }
    }

    return 0;
}
