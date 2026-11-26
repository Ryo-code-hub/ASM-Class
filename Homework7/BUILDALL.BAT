@echo off
rem ============================================================
rem  BUILDALL.BAT   Multi-module build for Homework 7
rem  Assembles MAIN, IO, CALC, GRID into BUILD\ and links into
rem  BUILD\CALENDAR.EXE + BUILD\CALENDAR.MAP + BUILD\*.REF
rem ============================================================

if not exist BUILD md BUILD

if exist BUILD\MAIN.obj del BUILD\MAIN.obj
if exist BUILD\IO.obj del BUILD\IO.obj
if exist BUILD\CALC.obj del BUILD\CALC.obj
if exist BUILD\GRID.obj del BUILD\GRID.obj
if exist BUILD\CALENDAR.exe del BUILD\CALENDAR.exe

echo.
echo === [1/5] MASM MAIN.ASM ===
masm MAIN.ASM,BUILD\MAIN.OBJ,BUILD\MAIN.LST,BUILD\MAIN.CRF;
if errorlevel 1 goto failed

echo.
echo === [2/5] MASM IO.ASM ===
masm IO.ASM,BUILD\IO.OBJ,BUILD\IO.LST,BUILD\IO.CRF;
if errorlevel 1 goto failed

echo.
echo === [3/5] MASM CALC.ASM ===
masm CALC.ASM,BUILD\CALC.OBJ,BUILD\CALC.LST,BUILD\CALC.CRF;
if errorlevel 1 goto failed

echo.
echo === [4/5] MASM GRID.ASM ===
masm GRID.ASM,BUILD\GRID.OBJ,BUILD\GRID.LST,BUILD\GRID.CRF;
if errorlevel 1 goto failed

echo.
echo === [5/5] LINK 4 modules into BUILD\CALENDAR.EXE ===
link BUILD\MAIN+BUILD\IO+BUILD\CALC+BUILD\GRID,BUILD\CALENDAR.EXE,BUILD\CALENDAR.MAP;
if errorlevel 1 goto failed

echo.
echo === CREF cross-reference files ===
cref BUILD\MAIN.CRF BUILD\MAIN.REF
cref BUILD\IO.CRF BUILD\IO.REF
cref BUILD\CALC.CRF BUILD\CALC.REF
cref BUILD\GRID.CRF BUILD\GRID.REF

echo.
echo === BUILDALL SUCCEEDED : BUILD\CALENDAR.EXE ===
goto end

:failed
echo.
echo === BUILDALL FAILED - check error messages above ===

:end
