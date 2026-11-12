/*================================================================
 *  FIB.C     作业5 第 7) 小问
 *  用 C 语言递归求斐波那契数列第 n 项（1 <= n <= 100）
 *
 *  F(100) = 354224848179261915075，共 69 个二进制位，
 *  超出 64 位无符号整数范围（64 位只够到 n = 93）。
 *  因此这里与汇编版本一致，用"5 个 16 位字"表示一个大数。
 *
 *  编译：cl /nologo /Od /c FIB.C
 *  运行：FIB.EXE
 *
 *  反汇编结果与逐条注释见同目录的 DISASM.TXT
 *================================================================*/
#include <stdio.h>

#define NW  5                       /* 每个大数用 5 个 16 位字（共 80 位） */

typedef unsigned short bignum[NW];

/*---- 把 a 清零 ----*/
static void bzero_(bignum a)
{
    int i;
    for (i = 0; i < NW; i++) a[i] = 0;
}

/*---- a = b ----*/
static void bcopy_(bignum a, const bignum b)
{
    int i;
    for (i = 0; i < NW; i++) a[i] = b[i];
}

/*---- a = a + b，按 16 位字带进位相加 ----*/
static void badd_(bignum a, const bignum b)
{
    unsigned long carry = 0;
    int i;
    for (i = 0; i < NW; i++) {
        unsigned long s = (unsigned long)a[i] + b[i] + carry;
        a[i] = (unsigned short)(s & 0xFFFFUL);
        carry = s >> 16;
    }
}

/*---- 递归：求 ( F(n), F(n+1) ) 分别放入 a、b ----*/
static void fib2(int n, bignum a, bignum b)
{
    bignum x, y;                            /* 存放子调用的结果，位于栈上 */

    if (n == 0) {                           /* 递归出口：F(0)=0, F(1)=1 */
        bzero_(a);
        bzero_(b);
        b[0] = 1;
        return;
    }
    fib2(n - 1, x, y);                      /* x = F(n-1), y = F(n) */
    bcopy_(a, y);                           /* F(n)   = y        */
    bcopy_(b, x);
    badd_(b, y);                            /* F(n+1) = x + y    */
}

/*---- 按十进制输出一个大数 ----*/
static void print_big(const bignum v)
{
    bignum w;
    char buf[32];
    int n = 0, i;

    bcopy_(w, v);
    for (;;) {
        unsigned long carry = 0;
        int zero = 1;
        for (i = NW - 1; i >= 0; i--) {     /* 从最高位字开始逐字除以 10 */
            unsigned long cur = (carry << 16) | w[i];
            w[i] = (unsigned short)(cur / 10);
            carry = cur % 10;
        }
        buf[n++] = (char)('0' + carry);     /* 余数即当前最低位 */
        for (i = 0; i < NW; i++)            /* 商为 0 则结束 */
            if (w[i]) { zero = 0; break; }
        if (zero) break;
    }
    while (n > 0) putchar(buf[--n]);        /* 倒序输出 */
}

int main(void)
{
    int n;
    bignum a, b;

    printf("Please input n (1-100):\n");
    if (scanf("%d", &n) != 1) return 1;
    if (n < 1 || n > 100) {
        printf("n must be in 1..100 !\n");
        return 1;
    }

    fib2(n, a, b);                          /* a = F(n), b = F(n+1) */
    printf("F(%d) = ", n);
    print_big(a);
    putchar('\n');
    return 0;
}
