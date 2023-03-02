Function InstallParamCheck	
	#获取安装包的命令行参数，确认是升级安装还是静默安装
	#-fakecmd=1作为占位符，在调用时，请保持，并且保证各个参数的顺序，否则会有解析问题
	#Setup.exe -AutoInstall=1 -AutoOpen=1 -fakecmd=1 /S /D=E:\Software\Test\ 
	#test
	# --updated --force-run
	
	StrCpy $sCmdAutoInstall "0"
	StrCpy $sCmdOpenWhenFinished "0"
	${Getparameters} $R0
	#MessageBox MB_OK|MB_ICONINFORMATION "$INSTDIR"
	#解析参数数据	
	${GetOptions} $R0 "-AutoInstall=" $sCmdAutoInstall
	${GetOptions} $R0 "-AutoOpen=" $sCmdOpenWhenFinished
	
	# 此处处理与Electron相关的参数 
	${StdUtils.TestParameter} $R9 "updated"
	${If} $R9 == true
		StrCpy $sCmdAutoInstall "1"
	${EndIf}
	
	${StdUtils.TestParameter} $R9 "force-run"
	${If} $R9 == true
		StrCpy $sCmdOpenWhenFinished "1"
	${EndIf}
	
FunctionEnd

Function AdjustInstallPath
	#此处判断最后一段，如果已经是与我要追加的目录名一样，就不再追加了，如果不一样，则还需要追加 同时记录好写入注册表的路径  	
	nsNiuniuSkin::StringHelper "$0" "\" "" "trimright"
	pop $0
	nsNiuniuSkin::StringHelper "$0" "\" "" "getrightbychar"
	pop $1	
		
	${If} "$1" == "${INSTALL_APPEND_PATH}"
		StrCpy $INSTDIR "$0"
	${Else}
		StrCpy $INSTDIR "$0\${INSTALL_APPEND_PATH}"
	${EndIf}

FunctionEnd


#判断选定的安装路径是否合法，主要检测硬盘是否存在[只能是HDD]，路径是否包含非法字符 结果保存在$R5中 
Function IsSetupPathIlleagal

	${GetRoot} "$INSTDIR" $R3   ;获取安装根目录  

	StrCpy $R0 "$R3\"  
	StrCpy $R1 "invalid"  
	StrCpy $0 ""  
	${GetDrives} "HDD" "HDDDetection"            ;获取将要安装的根目录磁盘类型
	${If} $R1 == "HDD"              ;是硬盘       
		StrCpy $R5 "1"	 
		${DriveSpace} "$R3\" "/D=F /S=M" $R0           #获取指定盘符的剩余可用空间，/D=F剩余空间， /S=M单位兆字节  
		${If} $R0 < 100                                #400即程序安装后需要占用的实际空间，单位：MB  
			StrCpy $R5 "-1"		#表示空间不足 
		${endif}
	${Else}  
     #0表示不合法 
	 StrCpy $R5 "0"
${endif}

FunctionEnd

Function HDDDetection
	${If} "$R0" == "$9"
	StrCpy $R1 "HDD"
	StrCpy $0 "StopGetDrives"
	${Endif}
	Push $0
FunctionEnd

Function InitCurrentLanguageId
	StrCpy $R8 "0"
	ReadRegStr $R8 SHELL_CONTEXT "Software\${PRODUCT_PATHNAME}" "LanguageID"
	${If} $R8 > 0
		nsNiuniuSkin::SetCurrentLangId $R8
	${Endif}
FunctionEnd

Function un.InitCurrentLanguageId
	StrCpy $R8 "0"
	ReadRegStr $R8 SHELL_CONTEXT "Software\${PRODUCT_PATHNAME}" "LanguageID"
	${If} $R8 > 0
		nsNiuniuSkin::SetCurrentLangId $R8
	${Endif}
FunctionEnd

#获取默认的安装路径 
Function GenerateSetupAddress
	${GetFileName} $EXEFILE $R2
	nsNiuniuSkin::StringHelper "$R2" "" "" "tolower"
	Pop $R2
	#MessageBox MB_OK|MB_ICONINFORMATION "$R2"
	nsNiuniuSkin::StringHelper "${EXE_NAME}" "" "" "tolower"
	
	Pop $R3
	${If} "$R2" == "$R3"
		MessageBox MB_OK|MB_ICONINFORMATION "安装包名称不能与主程序名称相同：${EXE_NAME}"
		Quit # nsNiuniuSkin::ExitDUISetup
		goto endfun
	${EndIf}
	
	#如果指定了路径  
	${If} "$INSTDIR" != "1"	
		goto endfun
	${EndIf}
	
	#读取注册表安装路径  ${INSTALL_LOCATION_KEY}
	SetRegView 32	
	ReadRegStr $0 SHELL_CONTEXT "Software\${PRODUCT_PATHNAME}" "${INSTALL_LOCATION_KEY}"
	${If} "$0" != ""		#路径不存在，则重新选择路径  	
		#路径读取到了，直接使用 
		#再判断一下这个路径是否有效 
		nsNiuniuSkin::StringHelper "$0" "\\" "\" "replace"
		Pop $0
		StrCpy $INSTDIR "$0"
		Call InitCurrentLanguageId
	${EndIf}
	
	#如果从注册表读的地址非法，则还需要写上默认地址      
	Call IsSetupPathIlleagal
	${If} $R5 == "0"
		StrCpy $INSTDIR "${INSTALL_DEFALT_SETUPPATH}"		
	${EndIf}	
endfun:	
FunctionEnd


#====================获取默认安装的要根目录 结果存到$R5中 
Function GetDefaultSetupRootPath
#先默认到D盘 
${GetRoot} "D:\" $R3   ;获取安装根目录  
StrCpy $R0 "$R3\"  
StrCpy $R1 "invalid"  
${GetDrives} "HDD" "HDDDetection"            ;获取将要安装的根目录磁盘类型
${If} $R1 == "HDD"              ;是硬盘  
     #检查空间是否够用
	 StrCpy $R5 "D:\" 2 0
	 ${DriveSpace} "$R3\" "/D=F /S=M" $R0           #获取指定盘符的剩余可用空间，/D=F剩余空间， /S=M单位兆字节  
	 ${If} $R0 < 300                                #400即程序安装后需要占用的实际空间，单位：MB  
	    StrCpy $R5 "C:"
     ${endif}
${Else}  
     #此处需要设置C盘为默认路径了 
	 StrCpy $R5 "C:"
${endif}
FunctionEnd

Function GetNetFrameworkVersion
  Push $1
  Push $0
  ReadRegDWORD $0 HKLM "SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full" "Install"
  ReadRegDWORD $1 HKLM "SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full" "Version"
  StrCmp $0 1 KnowNetFrameworkVersion +1
  ReadRegDWORD $0 HKLM "SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Client" "Install"
  ReadRegDWORD $1 HKLM "SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Client" "Version"
  StrCmp $0 1 KnowNetFrameworkVersion +1
  ReadRegDWORD $0 HKLM "SOFTWARE\Microsoft\NET Framework Setup\NDP\v3.5" "Install"
  ReadRegDWORD $1 HKLM "SOFTWARE\Microsoft\NET Framework Setup\NDP\v3.5" "Version"
  StrCmp $0 1 KnowNetFrameworkVersion +1
  ReadRegDWORD $0 HKLM "SOFTWARE\Microsoft\NET Framework Setup\NDP\v3.0\Setup" "InstallSuccess"
  ReadRegDWORD $1 HKLM "SOFTWARE\Microsoft\NET Framework Setup\NDP\v3.0\Setup" "Version"
  StrCmp $0 1 KnowNetFrameworkVersion +1
  ReadRegDWORD $0 HKLM "SOFTWARE\Microsoft\NET Framework Setup\NDP\v2.0.50727" "Install"
  ReadRegDWORD $1 HKLM "SOFTWARE\Microsoft\NET Framework Setup\NDP\v2.0.50727" "Version"
  StrCmp $1 "" +1 +2
  StrCpy $1 "2.0.50727.832"
  StrCmp $0 1 KnowNetFrameworkVersion +1
  ReadRegDWORD $0 HKLM "SOFTWARE\Microsoft\NET Framework Setup\NDP\v1.1.4322" "Install"
  ReadRegDWORD $1 HKLM "SOFTWARE\Microsoft\NET Framework Setup\NDP\v1.1.4322" "Version"
  StrCmp $1 "" +1 +2
  StrCpy $1 "1.1.4322.573"
  StrCmp $0 1 KnowNetFrameworkVersion +1
  ReadRegDWORD $0 HKLM "SOFTWARE\Microsoft\.NETFramework\policy\v1.0" "Install"
  ReadRegDWORD $1 HKLM "SOFTWARE\Microsoft\.NETFramework\policy\v1.0" "Version"
  StrCmp $1 "" +1 +2
  StrCpy $1 "1.0.3705.0"
  StrCmp $0 1 KnowNetFrameworkVersion +1
  StrCpy $1 "not .NetFramework"
  KnowNetFrameworkVersion:
  Pop $0
  Exch $1
FunctionEnd

# 生成卸载入口 
Function CreateUninstall
	#写入注册信息 
	SetRegView 32
	WriteRegStr SHELL_CONTEXT "Software\${PRODUCT_PATHNAME}" "${INSTALL_LOCATION_KEY}" "$INSTDIR"
	
	nsNiuniuSkin::SetCurrentLanguage $0
	Pop $0
	WriteRegStr SHELL_CONTEXT "Software\${PRODUCT_PATHNAME}" "LanguageID" $0

	# 只有当宏指定是要自动生成卸载程序时，才自动释放 
!ifdef AUTO_WRITE_UNINSTALL_FILE
	WriteUninstaller "$INSTDIR\${UNINST_FILE_NAME}"
!endif

	# 添加卸载信息到控制面板
	WriteRegStr SHELL_CONTEXT "Software\Microsoft\Windows\CurrentVersion\Uninstall\${PRODUCT_PATHNAME}" "DisplayName" "$PRODUCT_NAME"
	WriteRegStr SHELL_CONTEXT "Software\Microsoft\Windows\CurrentVersion\Uninstall\${PRODUCT_PATHNAME}" "UninstallString" "$INSTDIR\${UNINST_FILE_NAME}"
	WriteRegStr SHELL_CONTEXT "Software\Microsoft\Windows\CurrentVersion\Uninstall\${PRODUCT_PATHNAME}" "DisplayIcon" "$INSTDIR\${EXE_NAME}"
	WriteRegStr SHELL_CONTEXT "Software\Microsoft\Windows\CurrentVersion\Uninstall\${PRODUCT_PATHNAME}" "Publisher" "${PRODUCT_PUBLISHER}"
	WriteRegStr SHELL_CONTEXT "Software\Microsoft\Windows\CurrentVersion\Uninstall\${PRODUCT_PATHNAME}" "DisplayVersion" "${PRODUCT_VERSION}"
FunctionEnd


# ========================= 安装步骤 ===============================
Function CreateAppShortcut
  CreateDirectory "$SMPROGRAMS\$PRODUCT_NAME"
  CreateShortCut "$SMPROGRAMS\$PRODUCT_NAME\$PRODUCT_NAME.lnk" "$INSTDIR\${EXE_NAME}"
  CreateShortCut "$SMPROGRAMS\$PRODUCT_NAME\$UNINSTALL_NAME$PRODUCT_NAME.lnk" "$INSTDIR\${UNINST_FILE_NAME}"
FunctionEnd

#下载安装包的7z文件
Function DownloadFile
	SetOutPath "$INSTDIR"
	#路径、回调函数 
	GetFunctionAddress $0 OnDownloadFileProcessCallback
	nsNiuniuSkin::BindCallBack $hInstallDlg "nsis_download_process_callback_name" $0
	StrCpy $R2 "${INSTALL_DOWNLOAD_BASEURL}"
	${If} ${INSTALL_DOWNLOAD_IGNOREMD5} == 1                               #400即程序安装后需要占用的实际空间，单位：MB  
	   StrCpy $R2 "${INSTALL_DOWNLOAD_BASEURL}${INSTALL_DOWNLOAD_SERVERFILENAME}"
	   nsNiuniuSkin::SetDownloadMode 1 ${INSTALL_DOWNLOAD_INITSIZE}
    ${endif} 
	nsNiuniuSkin::DownloadAppFile "$R2" "$INSTDIR" "${INSTALL_DOWNLOAD_CONFIG}" "${INSTALL_7Z_NAME}"
FunctionEnd

Function ExtractFunc
	#安装文件的7Z压缩包
	SetOutPath $INSTDIR
	#当定义了释放${UNINST_FILE_NAME}的宏后，即不再打包其他文件
!ifndef BUILD_FOR_GENERATE_UNINST
	!ifdef INSTALL_DOWNLOAD_7Z
		#确定是否要增加一些额外的操作  比如杀掉升级进程
		GetFunctionAddress $R9 ExtractCallback
		nsis7zU::ExtractWithCallback "$INSTDIR\${INSTALL_7Z_NAME}" $R9
		Delete "$INSTDIR\${INSTALL_7Z_NAME}"
		!include "..\app.nsh"
	!else
		#根据宏来区分是否走非NSIS7Z的进度条  
		!ifdef INSTALL_WITH_NO_NSIS7Z
			!include "..\app.nsh"
		!else
			File "${INSTALL_7Z_PATH}"
			GetFunctionAddress $R9 ExtractCallback
			nsis7zU::ExtractWithCallback "$INSTDIR\${INSTALL_7Z_NAME}" $R9
			Delete "$INSTDIR\${INSTALL_7Z_NAME}"
		!endif
	!endif
!endif

	
FunctionEnd

Function TestSyncHttpRequest
	nsNiuniuSkin::HttpInvoke "http://www.ggniu.cn/test/test.html" "Content-Type: application/x-www-form-urlencoded;charset=utf-8" "param1=11&param2=22" 0
	pop $R0
	pop $R1
	MessageBox MB_OK|MB_ICONINFORMATION "retval: $R0, retstr: $R1"
FunctionEnd

Function un.DeleteShotcutAndInstallInfo
	SetRegView 32
	DeleteRegKey SHELL_CONTEXT "Software\${PRODUCT_PATHNAME}"	
	DeleteRegKey SHELL_CONTEXT "Software\Microsoft\Windows\CurrentVersion\Uninstall\${PRODUCT_PATHNAME}"
	DeleteRegValue SHELL_CONTEXT "Software\Microsoft\Windows\CurrentVersion\Run" "$PRODUCT_NAME"
	; 删除快捷方式
	
	Delete "$SMPROGRAMS\$PRODUCT_NAME\$PRODUCT_NAME.lnk"
	Delete "$SMPROGRAMS\$PRODUCT_NAME\$UNINSTALL_NAME$PRODUCT_NAME.lnk"
	RMDir "$SMPROGRAMS\$PRODUCT_NAME\"	
	Delete "$DESKTOP\$PRODUCT_NAME.lnk"
	
	#删除开机启动  
    Delete "$SMSTARTUP\$PRODUCT_NAME.lnk"
FunctionEnd
