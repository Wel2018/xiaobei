@echo off
chcp 65001 >nul
echo Testing parse_config.py...
python parse_config.py boot_items.yaml test_output.txt
if errorlevel 1 (
    echo [ERROR] Parse failed
    exit /b 1
)
echo.
echo Generated launch list:
type test_output.txt
echo.
del test_output.txt
echo Test completed successfully!
pause
