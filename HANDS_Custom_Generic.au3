;******************************************************************************
;
; HANDS BOX
; Customizations File
; Modify this with specific settings for your environment
;
;******************************************************************************

#include <GUIConstantsEx.au3>
#include <WindowsConstants.au3>
#include <Constants.au3>
#include <File.au3>
#include <WinAPISys.au3>

;******************************************************************************
;                          GLOBAL VARIABLES
;******************************************************************************

dim $handsAppData = @AppDataDir & "\HANDSBox\"
dim $iniFile = $handsAppData & "hands_config.ini"
dim $iniDefaults = @ScriptDir & "\hands_defaults.ini"


; Change to reference your own organization
dim $CustomHANDSBoxVersion = getIni('CustomHANDSBoxVersion',"Generic 1.2")

; Adjust this as needed, for example, by referencing your internal IT department and specifing any copyrighted software included.
dim $HANDSBoxCopyright = "Software Distributed under the GNU GPL." & @CRLF & @CRLF & "For the latest version, see" & @CRLF & "https://github.com/LCDHD/handsbox"

; Paths, adjust for your environment

dim $rootPath = getIni("rootPath","%userprofile%\Documents\HANDS Briefcase\")
dim $webRoot = getIni("webRoot",$rootPath)
dim $formsPath = getIni("formsPath","HANDS Documents\Forms")
dim $supervisionFormsPath = getIni("supervisionFormsPath","HANDS Documents\Supervision Forms")
dim $chartsPath = getIni("chartsPath","Charts.*")
dim $homevisitorPath = getIni("homevisitorPath",$rootPath)
dim $homevisitorWildcard = getIni("homevisitorWildcard","Working.*")
dim $workBase = getIni("workBase","Working.%username%\")


dim $workingPath = getIni("workingPath","Work In Progress")
dim $queueToChart = getIni("queueToChart","Queue To Chart")
dim $todataPath = getIni("todataPath","To Data Processing")
dim $tosupervisorPath = getIni("tosupervisorPath","To Supervisor")
dim $correctionPath = getIni("correctionPath","Needs Correction")
dim $trackingPath = getIni("trackingPath","Tracking Form")
dim $labelsPath = getIni("labelsPath","Labels")
dim $logPath = getIni("logPath","Logs")
dim $showSyncButtons = getIni("showSyncButtons","Both")

dim $handsBoxHeight = 550
if $showSyncButtons = "Sync" or $showSyncButtons = "Both" Then
    $handsBoxHeight = 593
EndIf

dim $syncScript = getIni("syncScript",@ScriptDir & "\Sync HANDS Box.ffs_batch")
dim $advancedSyncScript = getIni("advancedSyncScript",@ScriptDir & "\Sync HANDS Box.ffs_batch")
dim $advancedSyncScriptVerb = getIni("advancedSyncScriptVerb","edit")
dim $setupScript = getIni("setupScript","")
dim $initScript = getIni("initScript","")
dim $updateInstallScript = getIni("updateInstallScript",@ScriptDir & "\updateinstall.cmd")

dim $supervisionPath = getIni("supervisionPath","Supervision")
dim $labelsSelectPath = getIni("labelsSelectPath",$rootPath & $workBase & $labelsPath)
dim $checkUpdateFile1 = getIni("checkUpdateFile1",$iniDefaults)
dim $checkUpdateFile2 = getIni("checkUpdateFile2",$rootPath & "HANDS Documents\Software\hands_defaults.ini")


; Field names that should be replaced with values from label
; Adjust these ONLY if you are using different field names in your labels.
; If you are using forms from LCDHD, leave these as is.
dim $labelFieldsNames[10] = ["_LCDHD_FSW", "_LCDHD_SSN", "_LCDHD_CLID", "_LCDHD_DOB", "_LCDHD_LNAME", "_LCDHD_FNAME", "_LCDHD_MI", "_LCDHD_BILLING", "_LCDHD_NAME", "_LCDHD_FORMDATE"]

; Name of blank PDF file, referenced in the label FDF files
dim $blankLabelName = "000 - Blank Label.pdf"

; Processes which, if running, should prevent the Sync from firing
dim $checkProcessStr = getIni('checkProcess','Acrobat.exe,Acrord32.exe,Excel.exe,FoxitReader.exe')
dim $checkPDFProcess = StringSplit($checkProcessStr,',',$STR_NOCOUNT)


If Not FileExists($pdftk) Then
    $pdftk = @ScriptDir & "\pdftk.exe"
EndIf

$pdftk = getIni("pdftk",$pdftk)



;******************************************************************************
;                          HANDS FOLDER SETUP FUNCTIONS
;******************************************************************************

Func getIni($key,$default)
	$val = IniRead($iniFile,"General",$key,$default)
	$val = IniRead($iniDefaults,"General",$key,$val)
	return _WinAPI_ExpandEnvironmentStrings($val)
EndFunc

Func SetupHANDS()
	; A great place to put any scripts that should be run on every machine to set up the HANDS box in your envionment
	If MsgBox($MB_YESNO, "HANDS Setup", "This procedure will set up the necessary folders and mapped drive(s) for the HANDS staff. Would you like to continue?") = $IDNO Then
		Return 1
	EndIf

	if $setupScript <> "" Then
	    RunWait(@ComSpec & ' /c "' & $setupScript & '"',@WorkingDir)
	EndIf

	;Create a basic folder structure
	DirCreate($handsAppData)

    CreateUserFolders()

	If Not FileExists($rootPath & $formsPath & "\English") Then
		CreateTemplateFolders()
		MsgBox(0,"HANDS Box","Please Re-Open the HANDS Box to continue.")
		Exit
	EndIf

EndFunc   ;==>SetupHANDS

Func RunHelp()
	; Make this link to your own internal help page
	ShellExecute("https://github.com/LCDHD/handsbox")
EndFunc

Func HANDSInit()

	DirCreate($handsAppData)

	; Do custom start-up functions
	if $initScript <> "" Then
	    RunWait(@ComSpec & ' /c "' & $initScript & '"',@WorkingDir,@SW_HIDE)
	EndIf

    If $checkUpdateFile1 <> "" and $checkUpdateFile2 <> "" Then
		If FileGetTime($checkUpdateFile1,0,1) <> FileGetTime($checkUpdateFile2,0,1) Then
			If MsgBox($MB_YESNO,"HANDS Box Updater","There is an update to the HANDS Box. Would you like to install it now?")  = $IDYES Then
				UpdateInstall()
			EndIf
		EndIf
	EndIf

EndFunc

Func HANDSSetupScreen()
	; Add your own custom buttons to the setup screen

	GUICtrlCreateButton("Setup Folders", 50, 100, 300, 50)
	GUICtrlSetOnEvent(-1, "SetupHANDS")

	GUICtrlCreateButton("Update/Install HANDS Box", 50, 150, 300, 50)
	GUICtrlSetOnEvent(-1, "UpdateInstall")


EndFunc

Func UpdateInstall()
	Run(@ComSpec & " /c " & $updateInstallScript)
	Exit 1
EndFunc

Func HANDSBoxBottomButtons()

    if $showSyncButtons = "Sync" or $showSyncButtons = "Both" Then
		GUICtrlCreateButton("Synchronize", 1, 550, 180, 40)
		GUICtrlSetOnEvent(-1, "RunSynchronize")
	EndIf

    if $showSyncButtons = "Both" Then
		GUICtrlCreateButton("Advanced Compare/Sync", 600, 550, 195, 40)
		GUICtrlSetOnEvent(-1, "EditSynchronize")
	EndIf

EndFunc

Func RunSynchronize()
    If ProcessCheck() Then
		Return 1
	EndIf
	HANDSLog("Sync","")
	ShellExecute($syncScript)
EndFunc

Func EditSynchronize()
    If ProcessCheck() Then
		Return 1
	EndIf
	HANDSLog("EditSync","")
	ShellExecute($advancedSyncScript,"","",$advancedSyncScriptVerb)
	Exit 1
EndFunc