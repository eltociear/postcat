
# ===================== 外部插件以及宏 =============================
!include "StrFunc.nsh"
!include "WordFunc.nsh"
${StrRep}
${StrStr}
!include "LogicLib.nsh"
!include "nsDialogs.nsh"
!include "common.nsh"
!include "x64.nsh"
!include "MUI.nsh"
!include "WinVer.nsh" 
!include "nsOpenUrl.nsh" 
!include "StdUtils.nsh"

# ====================== 安装过程中的控制变量 ==============================
Var hInstallDlg					#安装窗口句柄
Var hInstallSubDlg				#子窗口句柄
Var sCmdAutoInstall				#是否自动启动安装
Var sCmdOpenWhenFinished        #完成后是否自动打开主程序
Var sIsSilent					#是否是静默安装 

Var sCmdFlag
Var sCmdSetupPath
Var sSetupPath 
Var sReserveData   #卸载时是否保留数据 
Var InstallState   #是在安装中还是安装完成 
Var UnInstallValue  #卸载的进度 
Var PRODUCT_NAME    #用于记录产品名称，接下来要使用
Var UNINSTALL_NAME  #用于开始菜单的卸载入口

!include "..\commonfunc.nsh"
!include "..\skinpwd.nsh"
!include "..\language.nsh"




# ===================== 安装包版本 =============================
VIProductVersion             		"${PRODUCT_VERSION}"
VIAddVersionKey "ProductVersion"    "${PRODUCT_VERSION}"
VIAddVersionKey "ProductName"       "${PRODUCT_NAME}"
VIAddVersionKey "CompanyName"       "${PRODUCT_PUBLISHER}"
VIAddVersionKey "FileVersion"       "${PRODUCT_VERSION}"
VIAddVersionKey "InternalName"      "${EXE_NAME}"
VIAddVersionKey "FileDescription"   "${PRODUCT_NAME}"
VIAddVersionKey "LegalCopyright"    "${PRODUCT_LEGAL}"

# ======================= DUILIB 自定义页面序号 =========================
!define INSTALL_PAGE_CONFIG 			0
!define INSTALL_PAGE_LICENSE 			1
!define INSTALL_PAGE_PROCESSING 		2
!define INSTALL_PAGE_FINISH 			3
!define INSTALL_PAGE_UNISTCONFIG 		4
!define INSTALL_PAGE_UNISTPROCESSING 	5
!define INSTALL_PAGE_UNISTFINISH 		6

# 自定义页面
Page custom DUIPage

# 卸载程序显示进度
UninstPage custom un.DUIPage

# ======================= DUILIB 自定义页面 =========================



Function DUIPage	
	# 指定是安装到所有用户还是当前用户，将会影响注册表写入以及开始菜单，桌面快捷方式等
	SetShellVarContext ${INSTALL_MODE_ALL_USERS}
    StrCpy $InstallState "0"	#设置未安装完成状态
	StrCpy $sIsSilent "0"
	InitPluginsDir
	SetOutPath "$PLUGINSDIR"
	Call InstallParamCheck

	
	File "licence_2052.rtf"
	File "licence_1033.rtf"
    File "${INSTALL_RES_PATH}"
	File /oname=logo.ico "${INSTALL_ICO}" 		#此处的目标文件一定是logo.ico，否则控件将找不到文件 
	nsNiuniuSkin::InitEngine
	nsNiuniuSkin::EnableDpi 1 1 0 0
	
	#如果定义了生成卸载程序的宏，则不再做其他操作，而是直接生成unist.exe，然后退出
!ifdef BUILD_FOR_GENERATE_UNINST
	WriteUninstaller "$EXEDIR\${UNINST_FILE_NAME}"
	Quit # nsNiuniuSkin::ExitDUISetup
!endif	

	# 单实例运行
	nsNiuniuSkin::OnlyOneInstance "${PRODUCT_PATHNAME}"
	Pop $0
	${If} $0 == "1"
		Quit # nsNiuniuSkin::ExitDUISetup
	${EndIf}
	nsNiuniuSkin::InitSkinPage "$PLUGINSDIR\" "${SKINZIP_PWD}" #指定插件路径及协议文件名称
    Pop $hInstallDlg
   	
	#生成安装路径，包含识别旧的安装路径  
    Call GenerateSetupAddress
	
	#设置控件显示安装路径 
    nsNiuniuSkin::SetControlAttribute $hInstallDlg "editDir" "text" "$INSTDIR\"
	Call OnRichEditTextChange
	#设置安装包的标题及任务栏显示  
	
	nsNiuniuSkin::ShowPageItem $hInstallDlg "wizardTab" ${INSTALL_PAGE_CONFIG}
	
	Call SetDefaultValues	
	
	Call InitLanguageInfo
	Call ResetUIByLanguage
    Call BindUIControls	
	Call CustomizeInit

	${If} $sCmdAutoInstall == "1"	
		GetFunctionAddress $0 OnBtnInstall
		nsNiuniuSkin::ShowPage $0	
	${Else}
		nsNiuniuSkin::ShowPage 0	
	${Endif}	
   
FunctionEnd

Function un.DUIPage
	StrCpy $InstallState "0"
    InitPluginsDir
	SetOutPath "$PLUGINSDIR"
    File "${INSTALL_RES_PATH}"
	
	
	File /oname=logo.ico "${UNINSTALL_ICO}" 		#此处的目标文件一定是logo.ico，否则控件将找不到文件 

	nsNiuniuSkin::InitEngine
	nsNiuniuSkin::EnableDpi 1 1 0 0
	#单实例运行 
	nsNiuniuSkin::OnlyOneInstance "${PRODUCT_PATHNAME}_Uninstall"
	Pop $0
	${If} $0 == "1"
		Quit # nsNiuniuSkin::ExitDUISetup
	${EndIf}
	nsNiuniuSkin::InitSkinPage "$PLUGINSDIR\" "${SKINZIP_PWD}"
    Pop $hInstallDlg
	nsNiuniuSkin::ShowPageItem $hInstallDlg "wizardTab" ${INSTALL_PAGE_UNISTCONFIG}
	Call un.InitCurrentLanguageId
	Call un.InitLanguageInfo
	Call un.BindUnInstUIControls
	Call un.ResetUIByLanguage
	Call un.CustomizeUnInit	
	


    nsNiuniuSkin::ShowPage 0
	
FunctionEnd

#绑定卸载的事件 
Function un.BindUnInstUIControls
	GetFunctionAddress $0 un.ExitDUISetup
    nsNiuniuSkin::BindCallBack $hInstallDlg "btnUninstalled" $0
	
	GetFunctionAddress $0 un.onUninstall
    nsNiuniuSkin::BindCallBack $hInstallDlg "btnUnInstall" $0
	
	GetFunctionAddress $0 un.ExitDUISetup
    nsNiuniuSkin::BindCallBack $hInstallDlg "btnClose" $0
	
	GetFunctionAddress $0 un.OnBtnMin
    nsNiuniuSkin::BindCallBack $hInstallDlg "btnMin" $0
	
FunctionEnd


#绑定安装的界面事件 
Function BindUIControls
	# License页面
    GetFunctionAddress $0 OnExitDUISetup
    nsNiuniuSkin::BindCallBack $hInstallDlg "btnLicenseClose" $0
    
    GetFunctionAddress $0 OnBtnMin
    nsNiuniuSkin::BindCallBack $hInstallDlg "btnMin" $0
    	
	GetFunctionAddress $0 OnBtnLicenseClick
    nsNiuniuSkin::BindCallBack $hInstallDlg "btnAgreement" $0
	
    #目录选择页面
    
    GetFunctionAddress $0 OnBtnSelectDir
    nsNiuniuSkin::BindCallBack $hInstallDlg "btnSelectDir" $0
        	
        
    GetFunctionAddress $0 OnBtnInstall
    nsNiuniuSkin::BindCallBack $hInstallDlg "btnInstall" $0
	nsNiuniuSkin::BindCallBack $hInstallDlg "btnInstall_Short" $0
	nsNiuniuSkin::BindCallBack $hInstallDlg "btnInstall_Short2" $0
    	
    
    # 安装完成 页面
    GetFunctionAddress $0 OnFinished
    nsNiuniuSkin::BindCallBack $hInstallDlg "btnRun" $0
        
    GetFunctionAddress $0 OnExitDUISetup
    nsNiuniuSkin::BindCallBack $hInstallDlg "btnClose" $0
	
	GetFunctionAddress $0 OnCheckLicenseClick
    nsNiuniuSkin::BindCallBack $hInstallDlg "chkAgree" $0
	GetFunctionAddress $0 OnCheckLicenseClick1
    nsNiuniuSkin::BindCallBack $hInstallDlg "chkAgree1" $0
	
	#绑定窗口通过alt+f4等方式关闭时的通知事件 
	GetFunctionAddress $0 OnSysCommandCloseEvent
    nsNiuniuSkin::BindCallBack $hInstallDlg "syscommandclose" $0
	
	#绑定路径变化的通知事件 
	GetFunctionAddress $0 OnRichEditTextChange
    nsNiuniuSkin::BindCallBack $hInstallDlg "editDir" $0
	
	GetFunctionAddress $0 OnShowMoreConfig
    nsNiuniuSkin::BindCallBack $hInstallDlg "btnShowMore" $0
	
	GetFunctionAddress $0 OnHideMoreConfig
    nsNiuniuSkin::BindCallBack $hInstallDlg "btnCancelMore" $0
	
	
	GetFunctionAddress $0 OnBtnBackClick
    nsNiuniuSkin::BindCallBack $hInstallDlg "btnBack" $0
	
	GetFunctionAddress $0 OnLanguageChanged
    nsNiuniuSkin::BindCallBack $hInstallDlg "comboLanguageSelect" $0
	
	
FunctionEnd


Function SetDefaultValues
	#根据默认值来设置界面显示，后续将根据界面选中情况控制安装流程
	${If} ${INSTALL_DEFAULT_AUTORUN} == 1
		nsNiuniuSkin::SetControlAttribute $hInstallDlg "chkAutoRun" "selected" "true"
	${Else}
		nsNiuniuSkin::SetControlAttribute $hInstallDlg "chkAutoRun" "selected" "false"
	${EndIf}
	
	#根据默认值来设置界面显示，后续将根据界面选中情况控制安装流程
	${If} ${INSTALL_DEFAULT_SHOTCUT} == 1
		nsNiuniuSkin::SetControlAttribute $hInstallDlg "chkShotcut" "selected" "true"
	${Else}
		nsNiuniuSkin::SetControlAttribute $hInstallDlg "chkShotcut" "selected" "false"
	${EndIf}
	
	#读取注册表，如果有值，则按注册表中的值来初始化
	SetRegView 32	
	ReadRegStr $0 SHELL_CONTEXT "Software\${PRODUCT_PATHNAME}" "shortcut"
	${If} "$0" != ""		#路径不存在，则重新选择路径 
		nsNiuniuSkin::SetControlAttribute $hInstallDlg "chkShotcut" "selected" "$0"
	${EndIf}
	ReadRegStr $0 SHELL_CONTEXT "Software\${PRODUCT_PATHNAME}" "autorun"
	${If} "$0" != ""		#路径不存在，则重新选择路径 
		nsNiuniuSkin::SetControlAttribute $hInstallDlg "chkAutoRun" "selected" "$0"
	${EndIf}
		
	nsNiuniuSkin::SetControlAttribute $hInstallDlg "chkAgree" "selected" "true"
	nsNiuniuSkin::SetControlAttribute $hInstallDlg "chkAgree1" "selected" "true"
FunctionEnd

Function OnBtnLicenseClick
	nsNiuniuSkin::ShowPageItem $hInstallDlg "wizardTab" ${INSTALL_PAGE_LICENSE}
FunctionEnd


Function OnBtnBackClick
	nsNiuniuSkin::ShowPageItem $hInstallDlg "wizardTab" ${INSTALL_PAGE_CONFIG}
FunctionEnd

# 设置语言，非常重要 
Function ResetUIByLanguage
	nsNiuniuSkin::GetCurrentLangId
	Pop $0
	nsNiuniuSkin::ResetLicenseFile $hInstallDlg "licence_$0.rtf"
	#通过插件得到当前真实的产品名称，后续写注册表，添加快捷方式等会要用到
	nsNiuniuSkin::TranslateMsg "[msg.productname]"
	Pop $PRODUCT_NAME
	nsNiuniuSkin::TranslateMsg "[msg.uninstall_ex]"
	Pop $UNINSTALL_NAME
	
	nsNiuniuSkin::AutoChangeControlTextByLanguage

	#设置一些在开始界面要修改的功能项 
	nsNiuniuSkin::SetControlAttribute $hInstallDlg "instinfo" "text" "[msg.productname]"
	nsNiuniuSkin::SetControlAttribute $hInstallDlg "welcomeinfo" "text" "[msg.welcome][msg.productname]"
	nsNiuniuSkin::SetControlAttribute $hInstallDlg "title" "text" "[msg.productname]"
	nsNiuniuSkin::SetWindowTitle $hInstallDlg "[msg.title]"
	
	Call ResetUIByLanguageEx
FunctionEnd

# 设置语言，非常重要 
Function un.ResetUIByLanguage	
	nsNiuniuSkin::TranslateMsg "[msg.productname]"
	Pop $PRODUCT_NAME
	nsNiuniuSkin::TranslateMsg "[msg.uninstall_ex]"
	Pop $UNINSTALL_NAME
	
	nsNiuniuSkin::AutoChangeControlTextByLanguage

	nsNiuniuSkin::SetControlAttribute $hInstallDlg "thanksinfo" "text" "[msg.welcomeback][msg.productname]"
	nsNiuniuSkin::SetControlAttribute $hInstallDlg "uninstinfo" "text" "[msg.uninstall_ex][msg.productname]"
	nsNiuniuSkin::SetControlAttribute $hInstallDlg "title" "text" "[msg.productname]"
	#设置安装包的标题及任务栏显示  
	nsNiuniuSkin::SetWindowTitle $hInstallDlg "[msg.productname] [msg.uninstall]"
FunctionEnd

Function OnLanguageChanged
	nsNiuniuSkin::GetControlAttribute $hInstallDlg "comboLanguageSelect" "text"
    Pop $0
	
	# get old language 
	nsNiuniuSkin::GetCurrentLangId
	Pop $1
	
	# get new languageid
	nsNiuniuSkin::SetCurrentLanguage $0
	Pop $0
	
	# check if the language changed
	${If} $0 == $1
	${Else}
		Call ResetUIByLanguage
    ${EndIf}
	
FunctionEnd

Function OnShowMoreConfig	
	nsNiuniuSkin::SetControlAttribute $hInstallDlg "btnInstall" "visible" "false"
	nsNiuniuSkin::SetControlAttribute $hInstallDlg "btnShowMore" "visible" "false"
	nsNiuniuSkin::SetControlAttribute $hInstallDlg "morelayer" "visible" "true"
	nsNiuniuSkin::SetControlAttribute $hInstallDlg "moreinfo" "visible" "true"	
	nsNiuniuSkin::SetControlAttribute $hInstallDlg "license_layer" "visible" "false"
FunctionEnd	


Function OnHideMoreConfig	
	nsNiuniuSkin::SetControlAttribute $hInstallDlg "btnInstall" "visible" "true"
	nsNiuniuSkin::SetControlAttribute $hInstallDlg "btnShowMore" "visible" "true"
	nsNiuniuSkin::SetControlAttribute $hInstallDlg "morelayer" "visible" "false"
	nsNiuniuSkin::SetControlAttribute $hInstallDlg "moreinfo" "visible" "false"
	nsNiuniuSkin::SetControlAttribute $hInstallDlg "license_layer" "visible" "true"	
FunctionEnd


#此处是路径变化时的事件通知 
Function OnRichEditTextChange
	#可在此获取路径，判断是否合法等处理 
	nsNiuniuSkin::GetControlAttribute $hInstallDlg "editDir" "text"
    Pop $0	
	StrCpy $INSTDIR "$0"
	
	Call IsSetupPathIlleagal
	${If} $R5 == "0"
		nsNiuniuSkin::SetControlAttribute $hInstallDlg "local_space" "text" "[msg.illegalpath]"
		nsNiuniuSkin::SetControlAttribute $hInstallDlg "local_space" "textcolor" "#ffff0000"
		nsNiuniuSkin::SetControlAttribute $hInstallDlg "btnInstall" "enabled" "false"
		goto TextChangeAbort
    ${EndIf}
	
	#Call AdjustInstallPath
	#nsNiuniuSkin::SetControlAttribute $hInstallDlg "editDir" "text" "$INSTDIR\"
	
	nsNiuniuSkin::SetControlAttribute $hInstallDlg "local_space" "textcolor" "#FFBBBBBB"
	${If} $R0 > 1024                               #400即程序安装后需要占用的实际空间，单位：MB  	    
		IntOp $R1  $R0 % 1024	
		IntOp $R0  $R0 / 1024;		
		nsNiuniuSkin::SetControlAttribute $hInstallDlg "local_space" "text" "[msg.spaceneed]110MB           [msg.spaceleft]$R0.$R1GB"
	${Else}
		nsNiuniuSkin::SetControlAttribute $hInstallDlg "local_space" "text" "[msg.spaceneed]110MB           [msg.spaceleft]$R0.$R1MB"
     ${endif}
	
	nsNiuniuSkin::SetControlAttribute $hInstallDlg "btnInstall" "enabled" "true"
	
TextChangeAbort:
FunctionEnd


#根据选中的情况来控制按钮是否灰度显示 
Function OnCheckLicenseClick
	nsNiuniuSkin::GetControlAttribute $hInstallDlg "chkAgree" "selected"
	Pop $0
	${If} $0 == "0"
		nsNiuniuSkin::SetControlAttribute $hInstallDlg "chkAgree1" "selected" "true"
		nsNiuniuSkin::SetControlAttribute $hInstallDlg "btnInstall" "enabled" "true"
		nsNiuniuSkin::SetControlAttribute $hInstallDlg "btnInstall_Short" "enabled" "true"
	${Else}
		nsNiuniuSkin::SetControlAttribute $hInstallDlg "chkAgree1" "selected" "false"
		nsNiuniuSkin::SetControlAttribute $hInstallDlg "btnInstall" "enabled" "false"
		nsNiuniuSkin::SetControlAttribute $hInstallDlg "btnInstall_Short" "enabled" "false"
    ${EndIf}
FunctionEnd

#根据选中的情况来控制按钮是否灰度显示 
Function OnCheckLicenseClick1
	
	nsNiuniuSkin::GetControlAttribute $hInstallDlg "chkAgree1" "selected"
    Pop $0
	${If} $0 == "0"
		nsNiuniuSkin::SetControlAttribute $hInstallDlg "chkAgree" "selected" "true"
		nsNiuniuSkin::SetControlAttribute $hInstallDlg "btnInstall" "enabled" "true"
		nsNiuniuSkin::SetControlAttribute $hInstallDlg "btnInstall_Short" "enabled" "true"
	${Else}
		nsNiuniuSkin::SetControlAttribute $hInstallDlg "chkAgree" "selected" "false"
		nsNiuniuSkin::SetControlAttribute $hInstallDlg "btnInstall" "enabled" "false"
		nsNiuniuSkin::SetControlAttribute $hInstallDlg "btnInstall_Short" "enabled" "false"
    ${EndIf}
FunctionEnd


# 添加一个静默安装的入口
Section "silentInstallSec" SEC01
	SetShellVarContext ${INSTALL_MODE_ALL_USERS}
    StrCpy $InstallState "0"	#设置未安装完成状态
	InitPluginsDir   	
	SetOutPath "$PLUGINSDIR"
	
	Call InstallParamCheck
	
    File "${INSTALL_RES_PATH}"
	File /oname=logo.ico "${INSTALL_ICO}" 		#此处的目标文件一定是logo.ico，否则控件将找不到文件 
	nsNiuniuSkin::InitEngine
    nsNiuniuSkin::InitSkinPage "$PLUGINSDIR\" "${SKINZIP_PWD}" #指定插件路径及协议文件名称
    Pop $hInstallDlg
   	Call GenerateSetupAddress
	nsNiuniuSkin::SetControlAttribute $hInstallDlg "editDir" "text" "$INSTDIR\"
	
	Call SetDefaultValues
	Call InitLanguageInfo
	Call ResetUIByLanguage
	Call CustomizeInit

	StrCpy $sIsSilent "1"
	StrCpy $sCmdAutoInstall "1"
	Call OnBtnInstall
SectionEnd

Function CreateLinks
	SetOutPath $INSTDIR
	#根据复选框的值来决定是否添加桌面快捷方式  
	nsNiuniuSkin::GetControlAttribute $hInstallDlg "chkShotcut" "selected"
	Pop $R0	
	${If} $R0 == "1"	
		#添加到桌面快捷方式的动作 在此添加
		CreateShortCut "$DESKTOP\$PRODUCT_NAME.lnk" "$INSTDIR\${EXE_NAME}"
		WriteRegStr SHELL_CONTEXT "Software\${PRODUCT_PATHNAME}" "shortcut" "true"
		System::Call 'Shell32::SHChangeNotify(i 0x8000000, i 0, i 0, i 0)'
		
	${Else}
		Delete "$DESKTOP\$PRODUCT_NAME.lnk"
		SetRegView 32
		WriteRegStr SHELL_CONTEXT "Software\${PRODUCT_PATHNAME}" "shortcut" "false"
	${EndIf}
	
	#开机启动   
	nsNiuniuSkin::GetControlAttribute $hInstallDlg "chkAutoRun" "selected"
	Pop $R0	
	${If} $R0 == "1"	
		SetRegView 32
		StrCpy $0 "$INSTDIR"
		nsNiuniuSkin::StringHelper "$0" "\\" "\" "replace"
		Pop $0
		StrCpy $INSTDIR "$0"
		WriteRegStr SHELL_CONTEXT "Software\Microsoft\Windows\CurrentVersion\Run" "$PRODUCT_NAME" '"$INSTDIR\${EXE_NAME}" -autoRun'
		
		WriteRegStr SHELL_CONTEXT "Software\${PRODUCT_PATHNAME}" "autorun" "true"
	${Else}
		SetRegView 32
		DeleteRegValue SHELL_CONTEXT "Software\Microsoft\Windows\CurrentVersion\Run" "$PRODUCT_NAME"
		WriteRegStr SHELL_CONTEXT "Software\${PRODUCT_PATHNAME}" "autorun" "false"
	${EndIf}
	
	
	Call CreateAppShortcut
	Call CreateUninstall
FunctionEnd

# 开始安装
Function OnBtnInstall
    nsNiuniuSkin::GetControlAttribute $hInstallDlg "chkAgree" "selected"
    Pop $0
	StrCpy $0 "1"
		
	#如果未同意，直接退出 
	StrCmp $0 "0" InstallAbort 0
	
	${If} $sCmdAutoInstall == "1"	
		#循环杀进程，同时检测，增加灵活性
		${For} $R1 0 10
		    nsNiuniuSkin::ProcessEvent 1 "${EXE_NAME}"
			Sleep 200
			nsProcess::_FindProcess "${EXE_NAME}"
			Pop $R0
			${If} $R0 != 0
				goto start_install
			${EndIf}
		${Next}
	${Endif}
	
	#此处检测当前是否有程序正在运行，如果正在运行，提示先卸载再安装 
	nsProcess::_FindProcess "${EXE_NAME}"
	Pop $R0
	
	${If} $R0 == 0
        StrCpy $R8 "$PRODUCT_NAME [msg.alreadyrunwarn]"
		StrCpy $R7 "0"
		Call ShowMsgBox
		goto InstallAbort
    ${EndIf}		

start_install:
	nsNiuniuSkin::GetControlAttribute $hInstallDlg "editDir" "text"
    Pop $0
	
    StrCmp $0 "" InstallAbort 0
	
	#校正路径（追加）  
	Call AdjustInstallPath
	StrCpy $sSetupPath "$INSTDIR"	
	
	Call IsSetupPathIlleagal
	${If} $R5 == "0"
		StrCpy $R8 "[msg.illegalpath1]"
		StrCpy $R7 "0"
		Call ShowMsgBox
		goto InstallAbort
    ${EndIf}	
	${If} $R5 == "-1"
		StrCpy $R8 "[msg.spacenotenough]"
		StrCpy $R7 "0"
		Call ShowMsgBox
		goto InstallAbort
    ${EndIf}
	nsNiuniuSkin::SetControlAttribute $hInstallDlg "comboLanguageSelect" "visible" "false"
	nsNiuniuSkin::SetControlAttribute $hInstallDlg "title" "visible" "true"
	nsNiuniuSkin::SetControlAttribute $hInstallDlg "btnClose" "enabled" "false"
	nsNiuniuSkin::ShowPageItem $hInstallDlg "wizardTab" ${INSTALL_PAGE_PROCESSING}
		
    # 将这些文件暂存到临时目录
    #Call BakFiles
    
!ifdef INSTALL_DOWNLOAD_7Z
    #在线安装包
	nsNiuniuSkin::SetControlAttribute $hInstallDlg "slrProgress" "value" "0"
	nsNiuniuSkin::SetControlAttribute $hInstallDlg "progress_pos" "text" ""	
	nsNiuniuSkin::SetControlAttribute $hInstallDlg "progress_tip" "text" "[msg.downloading]"
	#开始下载在线数据包
	GetFunctionAddress $0 DownloadFile
    BgWorker::CallAndWait
	Pop $R4	
	#取回下载的结果，判断是否下载成功且校验通过  
	${If} "$R4" != "0"		
		Pop $R5
		StrCpy $R5 "[msg.downloadfailed]: $R5"
		nsNiuniuSkin::SetControlAttribute $hInstallDlg "progress_tip" "text" "$R5"
		nsNiuniuSkin::SetControlAttribute $hInstallDlg "progress_tip" "textcolor" "#fff43a3a"
		nsNiuniuSkin::SetControlAttribute $hInstallDlg "btnClose" "enabled" "true"
		StrCpy $InstallState "2"
		goto InstallAbort
  ${EndIf}
!endif
    #重置进度条，开始进行安装
	nsNiuniuSkin::SetControlAttribute $hInstallDlg "slrProgress" "value" "0"
	nsNiuniuSkin::SetControlAttribute $hInstallDlg "progress_pos" "text" ""	
	nsNiuniuSkin::SetControlAttribute $hInstallDlg "progress_tip" "text" "[msg.installing]"
    
    #启动一个低优先级的后台线程
    GetFunctionAddress $0 ExtractFunc
    BgWorker::CallAndWait

    Call CreateLinks	
    		
	nsNiuniuSkin::SetControlAttribute $hInstallDlg "btnClose" "enabled" "true"		
	StrCpy $InstallState "1"
	#如果不想完成立即启动的话，需要屏蔽下面的OnFinished的调用，并且打开显示INSTALL_PAGE_FINISH
	#Call OnFinished
	
	${If} $sCmdOpenWhenFinished == "1"	
		Call OnFinished
	${Else}
		${If} $sCmdAutoInstall == "1"	
			Quit # nsNiuniuSkin::ExitDUISetup	
		${Endif}	
	${Endif}	
	#以下这行如果打开，则是跳转到完成页面 
	nsNiuniuSkin::ShowPageItem $hInstallDlg "wizardTab" ${INSTALL_PAGE_FINISH}
InstallAbort:
FunctionEnd

Function OnDownloadFileProcessCallback
	#路径、回调函数 	
	Pop $R2     #速度  KB / S
	Pop $R1     #总大小
	Pop $R0		#已下载大小    
	Pop $0      #进度 
	#MessageBox MB_OK "提示: $R2,  $R1, $R0, $0!"
	#通知速度 
	nsNiuniuSkin::SetControlAttribute $hInstallDlg "progress_tip" "text" "[msg.downloading1]$R2/S [msg.totalsize]$R1"	
	nsNiuniuSkin::SetControlAttribute $hInstallDlg "slrProgress" "value" "$0"
	nsNiuniuSkin::SetControlAttribute $hInstallDlg "progress_pos" "text" ""	
FunctionEnd

Function ExtractCallback
    Pop $R7
    Pop $R8
    System::Int64Op $R7 * 100
    Pop $R9
    System::Int64Op $R9 / $R8
    Pop $R6
	nsNiuniuSkin::SetControlAttribute $hInstallDlg "slrProgress" "value" "$R6"
	nsNiuniuSkin::SetControlAttribute $hInstallDlg "progress_pos" "text" "$R6%"	
    ${If} $R8 == $R7  
		nsNiuniuSkin::SetControlAttribute $hInstallDlg "progress_pos" "text" "99%"
    ${EndIf}
	
	#此为示例暂停，实际项目中，请将其拿掉 
!ifdef TEST_SLEEP	
	${If} ${TEST_SLEEP} == 1  
		Sleep 30
	${EndIf}
!endif
	
FunctionEnd

#CTRL+F4关闭时的事件通知 
Function OnSysCommandCloseEvent
	${If} $InstallState != "1"			
		goto endfun
	${EndIf}
	Quit # nsNiuniuSkin::ExitDUISetup
endfun:  
FunctionEnd

#安装界面点击退出，给出提示 
Function OnExitDUISetup
	${If} $InstallState != "1"	
	${AndIf} $InstallState != "2"		
		StrCpy $R8 "[msg.installnotfinish]"
		StrCpy $R7 "1"
		Call ShowMsgBox
		pop $1
		${If} $1 == 0
			goto endfun
		${EndIf}
	${EndIf}
	Quit # nsNiuniuSkin::ExitDUISetup
endfun:    
FunctionEnd

Function OnBtnMin
    SendMessage $hInstallDlg ${WM_SYSCOMMAND} 0xF020 0
FunctionEnd

Function un.OnBtnMin
    SendMessage $hInstallDlg ${WM_SYSCOMMAND} 0xF020 0
FunctionEnd

Function OnFinished	
	#先隐藏当前窗口
	nsNiuniuSkin::ShowHide $hInstallDlg 0
	#立即启动
	${StdUtils.ExecShellAsUser} $0 "$INSTDIR\${EXE_NAME}" "open" ""
	StrCpy $InstallState "1"
    Call OnExitDUISetup
FunctionEnd

Function OnBtnSelectDir
    nsNiuniuSkin::SelectInstallDirEx $hInstallDlg "[msg.browsetitle]"
    Pop $0
	${Unless} "$0" == ""
		nsNiuniuSkin::SetControlAttribute $hInstallDlg "editDir" "text" $0
	${EndUnless}
FunctionEnd


Function ShowMsgBox
	nsNiuniuSkin::InitSkinSubPage "msgBox.xml" "btnOK" "btnCancel,btnClose"  ; "[msg.notice]" "$PRODUCT_NAME [msg.alreadyrunwarn]" 0
	Pop $hInstallSubDlg
	nsNiuniuSkin::SetControlAttribute $hInstallSubDlg "lblTitle" "text" "[msg.notice]"
	nsNiuniuSkin::SetControlAttribute $hInstallSubDlg "lblMsg" "text" "$R8"
	${If} "$R7" == "1"
		nsNiuniuSkin::SetControlAttribute $hInstallSubDlg "btnCancel" "visible" "true"
	${Else}
		nsNiuniuSkin::SetControlAttribute $hInstallSubDlg "btnCancel" "visible" "false"
	${EndIf}
	nsNiuniuSkin::SetControlAttribute $hInstallSubDlg "btnCancel" "text" "[msg.cancel]"
	nsNiuniuSkin::SetControlAttribute $hInstallSubDlg "btnOK" "text" "[msg.ok]"
	nsNiuniuSkin::ShowSkinSubPage 0 
FunctionEnd

Function un.ExitDUISetup
	${If} $InstallState == "0"		
		StrCpy $R8 "[msg.uninstallnotfinish]"
		StrCpy $R7 "1"
		Call un.ShowMsgBox
		pop $0
		${If} $0 == 0
			goto endfun
		${EndIf}
	${EndIf}
	Quit # nsNiuniuSkin::ExitDUISetup
endfun:
FunctionEnd


# 添加一个静默卸载的入口 
Section "un.silentInstallSec" SEC02
    #MessageBox MB_OK|MB_ICONINFORMATION "Test silent install. you can add your silent uninstall code here."
	SetShellVarContext ${INSTALL_MODE_ALL_USERS}
	StrCpy $InstallState "0"
    InitPluginsDir
	SetOutPath "$PLUGINSDIR"
    File "${INSTALL_RES_PATH}"
	
	
	File /oname=logo.ico "${UNINSTALL_ICO}" 		#此处的目标文件一定是logo.ico，否则控件将找不到文件 
	nsNiuniuSkin::InitEngine
	nsNiuniuSkin::InitSkinPage "$PLUGINSDIR\" "${SKINZIP_PWD}" 
    Pop $hInstallDlg
	nsNiuniuSkin::ProcessEvent 1 "${EXE_NAME}"
	StrCpy $sIsSilent "1"
	StrCpy $sCmdAutoInstall "1"

	Call un.InitCurrentLanguageId
	Call un.InitLanguageInfo
	Call un.ResetUIByLanguage
	Call un.CustomizeUnInit	
	Call un.onUninstall
	
SectionEnd

#执行具体的卸载 
Function un.onUninstall
	# 指定是安装到所有用户还是当前用户，将会影响注册表写入以及开始菜单，桌面快捷方式等
	SetShellVarContext ${INSTALL_MODE_ALL_USERS}
	nsNiuniuSkin::GetControlAttribute $hInstallDlg "chkReserveData" "selected"
    Pop $0
	StrCpy $sReserveData $0
		
	#此处检测当前是否有程序正在运行，如果正在运行，提示先卸载再安装 
	nsProcess::_FindProcess "${EXE_NAME}"
	Pop $R0
	
	${If} $R0 == 0
		StrCpy $R8 "$PRODUCT_NAME [msg.alreadyrunwarn]"
		StrCpy $R7 "0"
		Call un.ShowMsgBox
		goto InstallAbort
    ${EndIf}
	nsNiuniuSkin::SetControlAttribute $hInstallDlg "title" "visible" "true"
    
    
	nsNiuniuSkin::SetControlAttribute $hInstallDlg "btnClose" "enabled" "false"
	nsNiuniuSkin::ShowPageItem $hInstallDlg "wizardTab" ${INSTALL_PAGE_UNISTPROCESSING}
	
	nsNiuniuSkin::SetControlAttribute $hInstallDlg "footer" "visible" "false"
	
	nsNiuniuSkin::SetControlAttribute $hInstallDlg "slrUnInstProgress" "min" "0"
	nsNiuniuSkin::SetControlAttribute $hInstallDlg "slrUnInstProgress" "max" "100"
	IntOp $UnInstallValue 0 + 1
	
	# 进入卸载过程的额外操作
	Call un.OnCustomizeUnInstall
	
	#删除文件 
	GetFunctionAddress $0 un.RemoveFiles
    BgWorker::CallAndWait
	${If} $sCmdAutoInstall == "1"	
		Quit # nsNiuniuSkin::ExitDUISetup	
	${Endif}
	#删除快捷方式 
	InstallAbort:
FunctionEnd

#在线程中删除文件，以便显示进度 
Function un.RemoveFiles
	Call un.DeleteShotcutAndInstallInfo
	IntOp $UnInstallValue $UnInstallValue + 8
    
	${Locate} "$INSTDIR" "/G=0 /M=*.*" "un.onDeleteFileFound"
	IntOp $R8 $UnInstallValue + 0
	${ForEach} $UnInstallValue $R8 99 + 2
		IntOp $UnInstallValue $UnInstallValue + 2
		${If} $UnInstallValue > 100
			IntOp $UnInstallValue 100 + 0
			nsNiuniuSkin::SetControlAttribute $hInstallDlg "slrUnInstProgress" "value" "100"
		${Else}
			nsNiuniuSkin::SetControlAttribute $hInstallDlg "slrUnInstProgress" "value" "$UnInstallValue"
			#此为示例暂停 
			Sleep 200
		${EndIf}	
	${Next}
	
		
	StrCpy $InstallState "1"
	nsNiuniuSkin::SetControlAttribute $hInstallDlg "btnClose" "enabled" "true"
	nsNiuniuSkin::SetControlAttribute $hInstallDlg "slrUnInstProgress" "value" "100"	
	Sleep 100
	nsNiuniuSkin::ShowPageItem $hInstallDlg "wizardTab" ${INSTALL_PAGE_UNISTFINISH}
FunctionEnd


#卸载程序时删除文件的流程，如果有需要过滤的文件，在此函数中添加  
Function un.onDeleteFileFound
    ; $R9    "path\name"
    ; $R8    "path"
    ; $R7    "name"
    ; $R6    "size"  ($R6 = "" if directory, $R6 = "0" if file with /S=)
    
	
	#是否过滤删除  
			
	Delete "$R9"
	RMDir /r "$R9"
    RMDir "$R9"
	
	
	IntOp $UnInstallValue $UnInstallValue + 2
	${If} $UnInstallValue > 100
		IntOp $UnInstallValue 100 + 0
		nsNiuniuSkin::SetControlAttribute $hInstallDlg "slrUnInstProgress" "value" "100"
	${Else}
		nsNiuniuSkin::SetControlAttribute $hInstallDlg "slrUnInstProgress" "value" "$UnInstallValue"
		Sleep 200
	${EndIf}	
	undelete:
	Push "LocateNext"	
FunctionEnd




Function un.ShowMsgBox
	nsNiuniuSkin::InitSkinSubPage "msgBox.xml" "btnOK" "btnCancel,btnClose"  ; "[msg.notice]" "$PRODUCT_NAME [msg.alreadyrunwarn]" 0
	Pop $hInstallSubDlg
	nsNiuniuSkin::SetControlAttribute $hInstallSubDlg "lblTitle" "text" "[msg.notice]"
	nsNiuniuSkin::SetControlAttribute $hInstallSubDlg "lblMsg" "text" "$R8"
	${If} "$R7" == "1"
		nsNiuniuSkin::SetControlAttribute $hInstallSubDlg "btnCancel" "visible" "true"
	${Else}
		nsNiuniuSkin::SetControlAttribute $hInstallSubDlg "btnCancel" "visible" "false"
	${EndIf}
	nsNiuniuSkin::SetControlAttribute $hInstallSubDlg "btnCancel" "text" "[msg.cancel]"
	nsNiuniuSkin::SetControlAttribute $hInstallSubDlg "btnOK" "text" "[msg.ok]"
	nsNiuniuSkin::ShowSkinSubPage 0
FunctionEnd