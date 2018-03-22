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

;******************************************************************************
;                          GLOBAL VARIABLES
;******************************************************************************

dim $handsAppData = @AppDataDir & "\HANDSBox\"

;To embed PDFTk, uncomment the following 4 LINES,
;and copy the referenced files into the source directory:

;DirCreate($handsAppData)
;FileInstall("pdftk.exe",$handsAppData & "\pdftk.exe")
;FileInstall("libiconv2.dll",$handsAppData & "\libiconv2.dll")
;$pdftk = $handsAppData & "\pdftk.exe"

; Change to reference your own organization
dim $CustomHANDSBoxVersion = "Generic 1.1"

; Adjust this as needed, for example, by referencing your internal IT department and specifing any copyrighted software included.
dim $HANDSBoxCopyright = "Software Distributed under the GNU GPL." & @CRLF & @CRLF & "For the latest version, see" & @CRLF & "https://github.com/LCDHD/handsbox"

; Paths, adjust for your environment

dim $rootPath = @UserProfileDir & "\Documents\HANDS Briefcase\"
dim $webRoot = $rootPath
dim $formsPath = "HANDS Documents\Forms"
dim $supervisionFormsPath = "HANDS Documents\Supervision Forms"
dim $chartsPath = "Charts.*"
dim $homevisitorPath = $rootPath
dim $homevisitorWildcard = "Working.*"
dim $workBase = "Working." & @UserName & "\"


dim $workingPath = "Work In Progress"
dim $queueToChart = "Queue To Chart"
dim $todataPath = "To Data Processing"
dim $tosupervisorPath = "To Supervisor"
dim $correctionPath = "Needs Correction"
dim $trackingPath = "Tracking Form"
dim $labelsPath = "Labels"
dim $logPath = "Logs"
dim $handsBoxHeight = 550

dim $supervisionPath = "Supervision"
dim $iniFile = $handsAppData & "hands_config.ini"
dim $labelsSelectPath = $rootPath & $workBase & $labelsPath
dim $newSoftwarePath = $rootPath & "HANDS Documents\Software\HANDS Box.exe"
dim $softwareInstallPath = $handsAppData & "HANDS Box.exe"

; Field names that should be replaced with values from label
; Adjust these ONLY if you are using different field names in your labels.
; If you are using forms from LCDHD, leave these as is.
dim $labelFieldsNames[10] = ["_LCDHD_FSW", "_LCDHD_SSN", "_LCDHD_CLID", "_LCDHD_DOB", "_LCDHD_LNAME", "_LCDHD_FNAME", "_LCDHD_MI", "_LCDHD_BILLING", "_LCDHD_NAME", "_LCDHD_FORMDATE"]

; Name of blank PDF file, referenced in the label FDF files
dim $blankLabelName = "000 - Blank Label.pdf"

; Processes which, if running, should prevent the Sync from firing
dim $checkPDFProcess = ["NitroPDF.exe","Acrobat.exe","Acrord32.exe","Excel.exe","FoxitReader.exe"]

; Set this to a random string for increase security
dim $encConstant = "CHANGE ME" ; For encrypting the saved access key



;******************************************************************************
;                          HANDS FOLDER SETUP FUNCTIONS
;******************************************************************************

Func SetupHANDS()
	; A great place to put any scripts that should be run on every machine to set up the HANDS box in your envionment
	If MsgBox($MB_YESNO, "HANDS Setup", "This procedure will set up the necessary folders and mapped drive(s) for the HANDS staff. Would you like to continue?") = $IDNO Then
		Return 1
	EndIf


	;Set up mapped drives here
	;RunWait(@ComSpec & " /c net use H: \\server\HANDS")

	;Create a basic folder structure

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
	; ; Do custom start-up functions

	; ; For example, you could make sure Nextcloud sync is running

	;If Not ProcessExists('nextcloud.exe') Then
	;	Run("C:\Program Files (x86)\Nextcloud\nextcloud.exe")
	;EndIf

	; ; For example, have the HANDS Box install itself into a sensible
	; ; location. This can prevent errors in nextcloud sync

	;If FileGetTime($newSoftwarePath) <> FileGetTime($softwareInstallPath) Then
	;	FileDelete($softwareInstallPath & ".old")
	;	FileMove($softwareInstallPath,$softwareInstallPath & ".old")
	;	FileCopy($newSoftwarePath,$softwareInstallPath)
	;EndIf

	; ; For example, install a desktop shortcut:
	; FileInstall("HANDS Box.lnk",@UserProfileDir & "\Desktop\")

EndFunc

Func HANDSSetupScreen()
	; Add your own custom buttons to the setup screen

	GUICtrlCreateButton("Setup...", 50, 100, 300, 50)
	GUICtrlSetOnEvent(-1, "SetupHANDS")


EndFunc

Func HANDSBoxBottomButtons()


EndFunc
