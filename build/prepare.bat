@echo "generate language and skin zip"
del ".\SetupScripts\%1\skin.zip"
del ".\SetupScripts\skinpwd.nsh"
del ".\SetupScripts\language.nsh"
.\Helper\NSISHelper.exe --project="%1" --mode="run" --type="all"