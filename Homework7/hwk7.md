# 作业七 思路说明：多模块实现输出日历

## 一、题目要求

1. 改写作业 6（输入 1900~2099 年与 1~12 月输出月历），采用**多模块**方式（按逻辑功能至少分为 3 个以上源程序），并在多模块下尝试**过程调用**及**宏汇编（Macro）**机制的实现。
2. 比较单代码段内、多代码段间、多文件间 `CALL` 指令对应的机器码差异，以及执行时 `CS`、`IP` 保存与恢复方式的区别；观察 `CALL` 与 `RET` 前后 `CS`、`IP`、`SP` 及栈内容的变化。

---

## 二、多模块划分与段合并设计

本程序按功能拆分为 **4 个 `.ASM` 源模块 + 1 个共享宏头文件 `MACROS.INC`**，继续保留作业 6 的三种参数传递方式（寄存器、数据段、栈），且输出与作业 6 逐字符一致：

| 文件 | 所属段 | 导出/导入符号（`PUBLIC` / `EXTRN`） | 职责说明 |
|---|---|---|---|
| `MACROS.INC` | — | 宏定义通过 `INCLUDE` 引入 | 共享宏库：`PRINT_S`、`PUT_CH`、`PRINT_NL`、`CHECK_RANGE`、`CALL_DOW`、`EXIT_DOS` |
| `MAIN.ASM` | `STACKS` / `DATAS` / `CODES` | 导出 `NBUF`、`DAYS`、`LEAD`、`OUTVAL`；导入 `IO`/`GRID` 的 `NEAR` 过程与 `CALC` 的 `FAR` 过程 | 程序入口 `START`、输入校验、表头输出、流程调度 |
| `IO.ASM` | `DATAS` / `CODES` | 导入 `NBUF`、`OUTVAL`；导出 `READ_LINE`、`PARSE_NUM`、`PRINT_NUM`、`PRINT_2`、`PRINT_DEC`、`PRINT_STR`、`PUTCH`、`NEWLINE` | 键盘读行、字符串转数值、两位右对齐/十进制/字符输出 |
| `CALC.ASM` | `DATAS` / `CALC` | 私有表 `DAYTAB`、`DOWTAB`；导出 `GET_DAYS:FAR`、`GET_DOW:FAR`（内部私有 `IS_LEAP:NEAR`） | 独立代码段纯计算（寄存器传参求天数、栈传参求星期） |
| `GRID.ASM` | `DATAS` / `CODES` | 导入 `DAYS`、`LEAD`、`OUTVAL`、`PRINT_NUM:NEAR`；导出 `SHOW_GRID:NEAR` | 通过共享变量 `OUTVAL` 调用 `PRINT_NUM` 排布月历网格 |

### 链接后的段排布（`BUILD\CALENDAR.MAP`）

四个模块对 `DATAS` 和 `CODES` 均声明为 `PARA PUBLIC 'DATA'` 与 `PARA PUBLIC 'CODE'`，由 `LINK 3.60` 按模块链接顺序自动合并；`CALC` 声明为独立的 `'CALC'` 类代码段：

```
 Start  Stop   Length Name                   Class
 00000H 007FFH 00800H STACKS                 STACK
 00800H 0093FH 00140H DATAS                  DATA
 00940H 00B84H 00245H CODES                  CODE
 00B90H 00C4BH 000BCH CALC                   CALC

Program entry point at 0094:0000
```

- `MAIN.ASM` 的 `CODES` 占 `0094:0000~0094:00ED`（00EEH 字节），因 `PARA` 对齐，`IO.ASM` 的 `CODES` 从 `0094:00F0` 开始，`GRID.ASM` 的 `CODES` 从 `0094:01C0` 开始，三者同处基址 `0094`（相对装入基址）的同一个 `CODES` 段内。
- `CALC.ASM` 的 `DAYTAB`、`DOWTAB` 同样因 `DATAS` 同名合并而紧跟在 `MAIN` 的数据之后（偏移 `0120H` 起），因此 `CALC` 中直接按 `DS:DATAS` 访问查表数据即可，无需切换 `DS`。

---

## 三、宏汇编（Macro）机制实现与展开分析

`MACROS.INC` 通过 `INCLUDE MACROS.INC` 在 `MAIN.ASM`、`IO.ASM`、`GRID.ASM` 中共用，集中展示了宏的以下机制：

| 宏名 | 参数 | 关键机制 | 使用位置 |
|---|---|---|---|
| `PRINT_S` | `MSG` | 文本代换 + 保护 `AX`/`DX` | `MAIN.ASM` 输出提示串与表头 |
| `PUT_CH` | `CHVAL` | 字符常量/寄存器代换 | `MACROS.INC`、`GRID.ASM` |
| `PRINT_NL` | 无 | **宏嵌套**：内部两次展开 `PUT_CH`（`0DH` 与 `0AH`） | `MAIN.ASM`、`IO.ASM`、`GRID.ASM` |
| `CHECK_RANGE` | `VAL, LO, HI, BAD_LBL` | **`LOCAL OK_LBL` 局部标号**避免重复展开重定义 | `MAIN.ASM` 年份与月份校验 |
| `CALL_DOW` | `YVAR, MVAR, DVAL` | 宏内完成栈传参压栈并 `CALL FAR PTR GET_DOW` | `MAIN.ASM` 求每月 1 号星期 |
| `EXIT_DOS` | `RETCODE` | 封装 DOS 4CH 号功能退出 | `MAIN.ASM` 出口 |

### 1. `LOCAL` 局部标号解决重复展开冲突（实测 `BUILD\MAIN.LST`）

`MAIN.ASM` 先后两次调用 `CHECK_RANGE`。由于宏体内使用了 `LOCAL OK_LBL`，MASM 5.0 在第 1 次与第 2 次展开时自动生成不重复的局部标号 `??0000` 与 `??0001`（列表文件第 2 列为嵌套深度 `1`）：

```asm
; 第 1 次展开（年份 1900..2099）
     202                                CHECK_RANGE YEAR, 1900, 2099, BAD_YEAR
     203 0019  A1 0116 R             1          MOV     AX, YEAR
     204 001C  3D 076C               1          CMP     AX, 1900
     205 001F  72 0B                 1          JB      BAD_YEAR
     206 0021  3D 0833               1          CMP     AX, 2099
     207 0024  76 03                 1          JBE     ??0000
     208 0026  EB 04 90              1          JMP     BAD_YEAR
     209 0029                        1  ??0000:

; 第 2 次展开（月份 1..12）
     235                                CHECK_RANGE MONTH, 1, 12, BAD_MONTH
     236 004E  A1 0118 R             1          MOV     AX, MONTH
     237 0051  3D 0001               1          CMP     AX, 1
     238 0054  72 0B                 1          JB      BAD_MONTH
     239 0056  3D 000C               1          CMP     AX, 12
     240 0059  76 03                 1          JBE     ??0001
     241 005B  EB 04 90              1          JMP     BAD_MONTH
     242 005E                        1  ??0001:
```

### 2. 宏嵌套展开（`PRINT_NL` -> `PUT_CH`）

`MAIN.LST` 中展开 `PRINT_NL` 时，可见嵌套深度标记变为 `2`，即由第一层宏 `PRINT_NL` 展开为两份第二层宏 `PUT_CH`：

```asm
     257                                PRINT_NL
     258 006F  50                    2          PUSH    AX
     259 0070  52                    2          PUSH    DX
     260 0071  B2 0D                 2          MOV     DL, 0DH
     261 0073  B4 02                 2          MOV     AH, 02H
     262 0075  CD 21                 2          INT     21H
     ...
     265 0079  50                    2          PUSH    AX
     266 007A  52                    2          PUSH    DX
     267 007B  B2 0A                 2          MOV     DL, 0AH
     268 007D  B4 02                 2          MOV     AH, 02H
     269 007F  CD 21                 2          INT     21H
```

### 3. 宏与过程的对比

- **宏（Macro）**：汇编期原地展开代码，无 `CALL`/`RET` 开销、可直接带条件跳转标签（如 `CHECK_RANGE`）与立即数参数，但每次调用都会复制一遍指令体（增大代码体积，如 `PRINT_NL` 每次展开占 20 字节，而 `CALL NEWLINE` 仅 3 字节）。
- **过程（Procedure）**：运行期共享同一份代码体，节省空间且易于通过 `PUBLIC`/`EXTRN` 模块化隐藏内部实现，但需要压栈返回地址并遵守参数传递约定。

---

## 四、单代码段内、多代码段间、多文件间 `CALL` 指令机器码对比

对照作业 6（`2026_11_20/Homework6`）与作业 7 的 `.LST`、`.MAP` 及链接后 `.EXE` 二进制机器码，三种场景下的编码本质如下：

| 场景 | 代表指令 | 汇编期 `.LST` 编码 | 链接后 `.EXE` 机器码 | 是否进 EXE 重定位表 | `RET` 编码 | 说明 |
|---|---|---|---|---|---|---|
| **单代码段内（同文件 NEAR）** | `IO.ASM`: `CALL PRINT_2`<br>`CALC.ASM`: `CALL IS_LEAP` | `E8 004B R`<br>`E8 0022 R` | `E8 02 00`（`0094:0136`）<br>`E8 0F 00`（`00B9:0010`） | 否 | `C3` | 目标在本文件同段内，MASM 直接知道目标偏移；`.LST` 显示目标偏移，`OBJ`/`EXE` 写入相对下条指令的 16 位有符号位移 `disp16 = 目标IP - (CALL偏移 + 3)` |
| **多代码段间（作业 6 同文件 FAR）** | `CALENDAR.ASM`:<br>`CALL FAR PTR GET_DAYS`<br>`CALL FAR PTR GET_DOW` | `9A 0000 ---- R`<br>`9A 005E ---- R` | `9A 00 00 AF 00`<br>`9A 5E 00 AF 00` | **是**（段值字节 `AF 00` 所在位置被记录） | `CB`<br>`CA 06 00` | MASM 已确定段内偏移（`0000`/`005E`），但段值 `CALC` 尚未知（`----`）；`LINK` 填入段相对值 `00AF`，并在 MZ 头部重定位表登记段字位置，DOS 装入时加上装入基址 |
| **多文件间 · 同段合并（NEAR）** | `MAIN.ASM`: `CALL READ_LINE`<br>`MAIN.ASM`: `CALL SHOW_GRID`<br>`GRID.ASM`: `CALL PRINT_NUM` | `E8 0000 E`<br>`E8 0000 E`<br>`E8 0000 E` | `E8 DD 00`（`0094:0010`）<br>`E8 D6 00`（`0094:00E7`）<br>`E8 48 FF`（`0094:01E7`） | 否 | `C3` | 目标位于**外部模块**，汇编期偏移未知，`.LST` 填 `0000` 并标记 **`E`（External）**；`LINK` 将各模块 `CODES` 合并后直接算出相对位移并修补（如 `GRID` 向前调 `IO` 的 `PRINT_NUM` 得到负位移 `FF48H = -184`，`01EA + (-00B8) = 0132`），运行期与单代码段内调用完全等价 |
| **多文件间 · 跨段（FAR）** | `MAIN.ASM`:<br>`CALL FAR PTR GET_DAYS`<br>`CALL FAR PTR GET_DOW` | `9A 0000 ---- E`<br>`9A 0000 ---- E` | `9A 00 00 B9 00`<br>`9A 5E 00 B9 00` | **是**（段值位置 `0094:00CE`、`0094:00E2`） | `CB`<br>`CA 06 00` | 汇编期偏移与段值均未知（`0000 ---- E`）；`LINK` 既修补目标段内偏移（`0000` / `005E`）和段相对值（`00B9`），又将段值位置写入 MZ 重定位表；运行期与作业 6 同文件跨段调用完全等价 |

### MZ 头部重定位表实测解析（作业 7 `BUILD\CALENDAR.EXE`）

解析 `BUILD\CALENDAR.EXE`（总长 3660 字节，MZ 头部 512 字节，初始 `CS:IP = 0094:0000`，`SS:SP = 0000:0800`），头部仅有 **3 条**重定位记录：

1. `0094:0001`（原值 `0080`）：`START` 入口 `MOV AX, DATAS`（`B8 80 00`）的数据段段址；
2. `0094:00CE`（原值 `00B9`）：`CALL FAR PTR GET_DAYS`（`9A 00 00 B9 00`）中的目标段值；
3. `0094:00E2`（原值 `00B9`）：`CALL_DOW` 展开的 `CALL FAR PTR GET_DOW`（`9A 5E 00 B9 00`）中的目标段值。

所有同段合并的跨文件 `NEAR CALL`（`E8 DD 00`、`E8 E6 00`、`E8 E1 00`、`E8 E9 00`、`E8 D6 00`、`E8 48 FF`）**均在链接期静态修补完成，不占用任何运行期重定位表项**。

---

## 五、`CALL` / `RET` 执行时 `CS`、`IP`、`SP` 与栈内容变化

### 1. 硬件执行机制对比

| 阶段 | `NEAR CALL` (`E8`) + `RET` (`C3`) | `FAR CALL` (`9A`) + `RET` (`CB`) | `FAR CALL` (`9A`) + `RET 6` (`CA 06 00`) |
|---|---|---|---|
| **调用前** | `CS` 为当前代码段，`SP` 指向栈顶 | 调用前已处于 `CS_caller`、`SP_bef` | 压入 3 个字参数后 `SP_bef = SP_pre - 6` |
| **执行 `CALL`** | 1. `SP ← SP - 2`<br>2. 将返回 `IP` 压入 `SS:[SP]`<br>3. `IP ← IP + disp16`（`CS` 不变） | 1. `SP ← SP - 2`，压入返回 `CS`<br>2. `SP ← SP - 2`，压入返回 `IP`<br>3. `CS ← seg16`，`IP ← off16` | 同左侧 `FAR CALL`（`SP` 再减 4） |
| **被调入口栈帧** | `[SP+0] = ret IP` | `[SP+0] = ret IP`<br>`[SP+2] = ret CS` | `[SP+0] = ret IP`、`[SP+2] = ret CS`<br>`[SP+4] = arg3`、`[SP+6] = arg2`、`[SP+8] = arg1` |
| **执行 `RET`** | 1. 从 `SS:[SP]` 弹出 `IP`<br>2. `SP ← SP + 2`（`CS` 不变） | 1. 弹出 `IP`，`SP ← SP + 2`<br>2. 弹出 `CS`，`SP ← SP + 2` | 1. 弹出 `IP`、`CS`（`SP + 4`）<br>2. `SP ← SP + 6`（共弹出 10 字节，恢复至压参前） |

### 2. 实测验证结果（`CALLDEMO.EXE`）

由于本课程平台未附带 `DEBUG.EXE`，我们专门编写了辅助测试程序（`CALLDEMO.ASM` + `CALLSUB.ASM`，非提交内容），在不提前压栈保存任何现场的前提下，于 `CALL` 前、被调过程首条指令、以及 `RET` 后瞬间抓取 `CS`、`IP`、`SP` 及栈顶单元内容。在 DOSBox 中实测结果（`BUILD\CALLDEMO.OUT`）如下：

```text
=== CALL / RET CS, IP, SP & Stack Observation ===

[1] Same-file NEAR CALL (LOCAL_NEAR):
  BEFORE   CS=01FC  IP=0025  SP=0400
  AT ENTRY CS=01FC  IP=00EE  SP=03FE
  STACK [SP+0..]: 0025 0025
  AFTER    CS=01FC  IP=0025  SP=0400

[2] Cross-file same-seg NEAR CALL (EXT_NEAR):
  BEFORE   CS=01FC  IP=0053  SP=0400
  AT ENTRY CS=01FC  IP=0220  SP=03FE
  STACK [SP+0..]: 0053 0053
  AFTER    CS=01FC  IP=0053  SP=0400

[3] Cross-file cross-seg FAR CALL (EXT_FAR):
  BEFORE   CS=01FC  IP=0083  SP=0400
  AT ENTRY CS=0221  IP=0000  SP=03FC
  STACK [SP+0..]: 0083 01FC
  AFTER    CS=01FC  IP=0083  SP=0400

[4] Cross-file cross-seg FAR CALL + RET 6 (args: 07EA, 000B, 0001):
  PRE-PUSH SP=0400
  BEFORE   CS=01FC  IP=00C3  SP=03FA
  AT ENTRY CS=0221  IP=002B  SP=03F6
  STACK [SP+0..]: 00C3 01FC 0001 000B 07EA
  AFTER    CS=01FC  IP=00C3  SP=0400
```

从实测数据可以直观验证：
- **测试 [1] 与 [2]（同文件 / 跨文件同段 NEAR CALL）**：`CS` 始终维持 `01FC` 不变；`SP` 从 `0400` 降至 `03FE`（-2 字节），栈顶 `[03FE]` 压入返回偏移 `0025` / `0053`（注：紧邻其上的 `SS:[0400]` 已超出 1024 字节栈段并落在紧随其后的 `DATAS:0000` 单元 `TMP_AX` 上）；`RET` 后 `IP` 回到 `0025` / `0053`，`SP` 恢复 `0400`。
- **测试 [3]（跨文件跨段 FAR CALL）**：`CS` 由 `01FC` 切换至 `FARSEG` 的段地址 `0221`、`IP` 变为 `0000`；`SP` 由 `0400` 降至 `03FC`（-4 字节）；栈顶由低地址到高地址依次为返回 `IP (0083)`、返回 `CS (01FC)`；`RET` 后 `CS:IP` 恢复 `01FC:0083`，`SP` 恢复 `0400`。
- **测试 [4]（跨文件跨段 FAR CALL + 栈传 3 参数 + `RET 6`）**：压入 `2026 (07EA)`、`11 (000B)`、`1 (0001)` 后 `SP` 由 `0400` 降至 `03FA`；`CALL FAR PTR EXT_FAR_STK` 再减 4 至 `03F6`，栈顶 `[SP+0..+8]` 依次为 `00C3 (IP)`、`01FC (CS)`、`0001 (日)`、`000B (月)`、`07EA (年)`——正对应 `GET_DOW` 中建立 `BP=SP` 后（`PUSH BP` 占 2 字节）`[BP+6]` 为日、`[BP+8]` 为月、`[BP+10]` 为年的布局；`RET 6` 返回后 `SP` 一步从 `03F6` 回到压参前的 `0400`。

### 3. 若在 MS-DOS `DEBUG` 下单步跟踪的操作参考

若在装有 `DEBUG.EXE` 的环境中运行 `debug BUILD\CALENDAR.EXE`，可按如下步骤单步观察：

1. `-u 0094:0000` 找到 `CALL READ_LINE`（偏移 `0010`）、`CALL FAR PTR GET_DAYS`（偏移 `00CB`）、`CALL FAR PTR GET_DOW`（偏移 `00DF`）；
2. `-g 0094:0010` 停在跨文件同段 `CALL` 前，记录 `CS`、`IP`、`SP`；按 `-t` 单步进入后可见 `SP` 减 2、`-d ss:<SP> L2` 看到 `13 00`（小端 `0013`）；
3. `-g 0094:00DF` 停在 `CALL FAR PTR GET_DOW` 前，输入年份与月份后断在此处；按 `-t` 单步进入 `GET_DOW`，可见 `CS` 变化、`SP` 减 4，`-d ss:<SP> L10` 即可看到栈顶 10 字节依次为返回 `IP`、`CS`、`01 00`、`0B 00`、`EA 07`。

---

## 六、实测结果

4 个模块汇编全部为 **0 Warning Errors / 0 Severe Errors**，链接生成 `BUILD\CALENDAR.EXE`（3660 字节）。在 DOSBox 中使用与作业 6 相同的 10 组测试用例进行自动化重定向对比，作业 7 与作业 6 的输出**全部逐字节完全一致**：

| 测试用例 | 输入 | 与作业 6 对比结果 |
|---|---|---|
| `T01` | `2026 / 11` | 逐字节一致（202 字节） |
| `T02` | `2026 / 09` | 逐字节一致（208 字节） |
| `T03` | `2026 / 02` | 逐字节一致（194 字节） |
| `T04` | `2000 / 02` | 逐字节一致（204 字节） |
| `T05` | `2024 / 02` | 逐字节一致（210 字节） |
| `T06` | `1900 / 01` | 逐字节一致（206 字节） |
| `T07` | `1900 / 02` | 逐字节一致（207 字节） |
| `T08` | `2099 / 12` | 逐字节一致（211 字节） |
| `T09` | `1899` | 逐字节一致（68 字节，年份越界提示） |
| `T10` | `2026 / 13` | 逐字节一致（95 字节，月份越界提示） |

---

## 七、文件清单与编译运行

| 文件 | 说明 |
|---|---|
| `MACROS.INC` | 共享宏库（`PRINT_S`、`PUT_CH`、`PRINT_NL`、`CHECK_RANGE`、`CALL_DOW`、`EXIT_DOS`） |
| `MAIN.ASM` | 主控模块（入口、公共数据/栈段、输入校验与调度） |
| `IO.ASM` | 输入输出模块（行输入、数值解析、十进制与字符输出） |
| `CALC.ASM` | 纯计算模块（独立 `CALC` 代码段，`GET_DAYS`、`IS_LEAP`、`GET_DOW`） |
| `GRID.ASM` | 月历排版输出模块（`SHOW_GRID`） |
| `BUILDALL.BAT` | 多模块一键汇编、链接与交叉引用构建脚本（产物输出到 `BUILD\`） |
| `CALLDEMO.ASM` / `CALLSUB.ASM` / `BUILDPRO.BAT` | 第 2 小问 `CS`/`IP`/`SP`/栈变化实测程序（非提交内容） |
| `hwk7.md` | 本说明文档 |

在平台的 DOSBox 环境中编译与运行：

```dos
C:
CD \ASM\H7
CALL BUILDALL        :: 汇编 4 个模块并链接生成 BUILD\CALENDAR.EXE
BUILD\CALENDAR       :: 运行，按提示输入年份与月份
```
