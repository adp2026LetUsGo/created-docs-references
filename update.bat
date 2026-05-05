@echo off
:: Script para actualizar el backup de referencias
title Actualizador de Backup - created-docs-references
echo ===========================================
echo Iniciando sincronizacion con GitHub...
echo ===========================================
:: Obtener fecha y hora
set timestamp=%date% %time%
:: Comandos de Git
git add .
git commit -m "Actualizacion automatica: %timestamp%"
git push origin main
echo.
if %ERRORLEVEL% EQU 0 (
echo [EXITO] Backup actualizado correctamente.
) else (
echo [ERROR] Hubo un problema al subir los cambios.
)
echo ===========================================
pause
¿Por