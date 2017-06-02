@ECHO OFF

CD /D %~dp0
powershell -File ".\DoDeployment_Part01.ps1"

ECHO.
PAUSE
