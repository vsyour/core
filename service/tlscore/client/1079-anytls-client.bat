@echo off


REM ===== 配置区域 =====
set SERVER=192.168.3.79
set PORT=39997
set PASSWORD=RVwVQber0QK9AKmF
set LOCAL=127.0.0.1:1079
REM ====================

title AnyTLS Client  %SERVER%:%PORT%
echo Starting AnyTLS client...
anytls-client.exe -s %SERVER%:%PORT% -p %PASSWORD% -l %LOCAL%

echo.
echo AnyTLS client exited.
pause
