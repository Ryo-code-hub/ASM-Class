/*================================================================
 *  CALENDAR.C     作业6 第 7) 小问
 *  与 CALENDAR.ASM 功能相同：输入年（1900~2099）与月（1~12），
 *  输出该月月历。
 *
 *  编译：cl /nologo /TC /Od /c CALENDAR.C
 *  运行：CALENDAR.EXE
 *
 *  反汇编结果与逐条注释见同目录的 DISASM.TXT
 *================================================================*/
#include <stdio.h>

static const char *MON[12] = {
    "January",  "February", "March",     "April",
    "May",      "June",     "July",      "August",
    "September","October",  "November",  "December"
};

/*---- 闰年判断 ----*/
static int is_leap(int y)
{
    return (y % 4 == 0 && y % 100 != 0) || (y % 400 == 0);
}

/*---- 某年某月的天数（对应汇编中的 GET_DAYS）----*/
static int get_days(int y, int m)
{
    static const int t[12] = {31,28,31,30,31,30,31,31,30,31,30,31};
    if (m == 2 && is_leap(y))
        return 29;
    return t[m - 1];
}

/*---- 某日星期几，0 = 周日（对应汇编中的 GET_DOW，Sakamoto 法）----*/
static int get_dow(int y, int m, int d)
{
    static const int t[12] = {0,3,2,5,0,3,5,1,4,6,2,4};
    if (m < 3)
        y--;                                  /* 1、2 月按上一年计算 */
    return (y + y / 4 - y / 100 + y / 400 + t[m - 1] + d) % 7;
}

/*---- 输出月历网格（对应汇编中的 SHOW_GRID）----*/
static void show_grid(int lead, int days)
{
    int d, col = 0;
    for (d = 1; d <= lead + days; d++) {
        if (col)                              /* 非行首先输出分隔空格 */
            putchar(' ');
        if (d <= lead)
            printf("  ");                     /* 1 号之前的空格 */
        else
            printf("%2d", d - lead);          /* 右对齐两位 */
        if (++col == 7) {
            putchar('\n');
            col = 0;
        }
    }
    if (col)
        putchar('\n');
}

int main(void)
{
    int y, m;

    printf("Please input year (1900-2099): ");
    if (scanf("%d", &y) != 1)
        return 1;
    if (y < 1900 || y > 2099) {
        printf("year must be in 1900..2099 !\n");
        return 1;
    }

    printf("Please input month (1-12): ");
    if (scanf("%d", &m) != 1)
        return 1;
    if (m < 1 || m > 12) {
        printf("month must be in 1..12 !\n");
        return 1;
    }

    printf("\n%d  %s\n", y, MON[m - 1]);
    printf("Su Mo Tu We Th Fr Sa\n");

    show_grid(get_dow(y, m, 1), get_days(y, m));
    return 0;
}
