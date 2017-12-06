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


;To embed PDFTk, uncomment the following 4 LINES,
;and copy the referenced files into the source directory:

;DirCreate($handsAppData)
;FileInstall("pdftk.exe",$handsAppData & "\pdftk.exe")
;FileInstall("libiconv2.dll",$handsAppData & "\libiconv2.dll")
;$pdftk = $handsAppData & "\pdftk.exe"

; Change to reference your own organization
dim $CustomHANDSBoxVersion = "Generic 1.0"

; Adjust this as needed, for example, by referencing your internal IT department and specifing any copyrighted software included.
dim $HANDSBoxCopyright = "Software Distributed under the GNU GPL." & @CRLF & @CRLF & "For the latest version, see" & @CRLF & "https://github.com/LCDHD/handsbox"

; Paths, adjust for your environment

dim $rootPath = @UserProfileDir & "\Documents\HANDS Briefcase\"
dim $formsPath = "HANDS Documents\Forms"
dim $supervisionFormsPath = "HANDS Documents\Supervision Forms"
dim $chartsFullPath = "H:\Charts"
dim $homevisitorPath = "H:\Working Folders"
dim $handsDocumentsPath = "H:\HANDS Documents"
dim $workBase = "Working\"
dim $webRoot = "H:\"

dim $workingPath = "Work In Progress"
dim $queueToChart = "Queue To Chart"
dim $todataPath = "To Data Processing"
dim $tosupervisorPath = "To Supervisor"
dim $correctionPath = "Needs Correction"
dim $trackingPath = "Tracking Form"
dim $labelsPath = "Labels"
dim $logPath = "Logs"

dim $supervisionPath = "Supervision"
dim $handsAppData = @AppDataDir & "\HANDSBox\"
dim $iniFile = $handsAppData & "hands_config.ini"
dim $labelsSelectPath = $rootPath & $workBase & $labelsPath

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

	DirCreate($rootPath & $workBase & $workingPath)
	DirCreate($rootPath & $workBase & $correctionPath)
	DirCreate($rootPath & $workBase & $trackingPath)
	DirCreate($rootPath & $workBase & $labelsPath)
	DirCreate($rootPath & $workBase & $tosupervisorPath)
	DirCreate($rootPath & $workBase & $todataPath)
	DirCreate($rootPath & $formsPath)

EndFunc   ;==>SetupHANDS


Func RunHelp()
	; Make this link to your own internal help page
	ShellExecute("https://github.com/LCDHD/handsbox")
EndFunc

Func HANDSInit()
	; Do custom start-up functions
EndFunc

Func HANDSSetupScreen()
	; Add your own custom buttons to the setup screen

	GUICtrlCreateButton("Setup...", 50, 100, 300, 50)
	GUICtrlSetOnEvent(-1, "SetupHANDS")

EndFunc

Func HANDSBoxBottomButtons()
    ; Synchronize
	GUICtrlCreateButton("Synchronize", 1, 550, 180, 40)
	GUICtrlSetOnEvent(-1, "RunSynchronize")
	GUICtrlCreateButton("Advanced Compare/Sync", 600, 550, 195, 40)
	GUICtrlSetOnEvent(-1, "EditSynchronize")

	; Add more custom buttons to the bottom of the screen

EndFunc

Func CheckProc()
	If ProcessExists("FreeFileSync.exe") or ProcessExists("FreeFileSync_64.exe") Then
		Return True
	Else
		Return False
	EndIf
EndFunc

Func RunSynchronize()
    If ProcessCheck() Then
		Return 1
	EndIf
	HANDSLog("Sync","")

	FileInstall("sync_working_folder.ffs_batch",@TempDir & "\sync_working_folder.ffs_batch",$FC_OVERWRITE)
	ShellExecute(@TempDir & "\sync_working_folder.ffs_batch")
	While CheckProc()
		Sleep(2)
	WEnd

	FileInstall("sync_hands_documents.ffs_batch",@TempDir & "\sync_hands_documents.ffs_batch",$FC_OVERWRITE)
	ShellExecute(@TempDir & "\sync_hands_documents.ffs_batch")
	While CheckProc()
		Sleep(2)
	WEnd
EndFunc   ;==>RunSynchronize

Func EditSynchronize()
	HANDSLog("EditSync","")
    If ProcessCheck() Then
		Return 1
	EndIf

	FileInstall("sync_working_folder.ffs_batch",@TempDir & "\sync_working_folder.ffs_batch",$FC_OVERWRITE)
	ShellExecute(@TempDir & "\sync_working_folder.ffs_batch","","",$SHEX_EDIT)

EndFunc   ;==>EditSynchronize
