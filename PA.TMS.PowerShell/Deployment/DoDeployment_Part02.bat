@ECHO OFF

CD /D %~dp0
powershell -File ".\DoDeployment_Part02.ps1"

ECHO.
PAUSE
