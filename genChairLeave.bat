set APPNAME=chair_leave
mkdir Apps\%APPNAME%
copy Wiced-Smart\bleapp\app\bleprox.c Apps\%APPNAME%\%APPNAME%.c
vim -u NONE --noplugin Apps\%APPNAME%\%APPNAME%.c -s %~dp0\genChairLeave.vim
echo ENTRY "PMU Crystal Warm up Time">Apps\%APPNAME%\app.cgs
echo {>>Apps\%APPNAME%\app.cgs
echo   "Crystal warm up time" = 5000>>Apps\%APPNAME%\app.cgs
echo }>>Apps\%APPNAME%\app.cgs
echo APP_SRC = %APPNAME%.c>Apps\%APPNAME%\makefile.mk
echo CGS_LIST += $(DIR)/app.cgs>>Apps\%APPNAME%\makefile.mk
