;******************************************************************************
;
; HANDS BOX
; Customizations File
; Modify this with specific settings for your environment
;
; COPYRIGHT (C) 2016 BY THE LAKE CUMBERLAND DISTRICT HEALTH DEPARTMENT
; ORIGINAL CODE BY DANIEL MCFEETERS (www.fiforms.net)
; LATEST VERSION AVAILABLE FROM https://oss.lcdhd.org
;
; This program is free software; you can redistribute it and/or
; modify it under the terms of the GNU General Public License
; as published by the Free Software Foundation; either version 2
; of the License.
;
; This program is distributed in the hope that it will be useful,
; but WITHOUT ANY WARRANTY; without even the implied warranty of
; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
; GNU General Public License for more details.
;
; You should have received a copy of the GNU General Public License
; along with this program; if not, write to the Free Software
; Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
;
; These license terms may also be modified by the LOCAL DISTRIBUTION EXCEPTION
; described in the accompanying LICENSE.txt file.
;
;******************************************************************************

#include <GUIConstantsEx.au3>
#include <WindowsConstants.au3>
#include <Constants.au3>
#include <LCDHDSaveKey.au3>
#include <File.au3>

;******************************************************************************
;                          GLOBAL VARIABLES
;******************************************************************************

dim $CustomHANDSBoxVersion = "Generic 1.0"

dim $HANDSBoxCopyright = "Copyright 2016-2017 by the Lake Cumberland District Health Department" & @CRLF & @CRLF & "All Rights Reserved. Unauthorized Distribution Prohibited." & @CRLF & "For information, call 1 (800) 928-4416, extension 1400."

;dim $syncBatchFile = @TempDir & "\Sync Briefcase.ffs_batch"

dim $rootPath = @UserProfileDir & "\Documents\HANDS Briefcase\"
dim $formsPath = "HANDS Documents\Forms"
dim $supervisionFormsPath = "HANDS Documents\Supervision Forms"

dim $chartsFullPath = "H:\Charts"

dim $homevisitorPath = "H:\Working Folders"

dim $handsDocumentsPath = "H:\HANDS Documents"

dim $workBase = "Working\"

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


dim $exePath = $rootPath & $formsPath & "\" & "HANDS Box.exe"

; Field names that should be replaced with values from label
dim $labelFieldsNames[10] = ["_LCDHD_FSW", "_LCDHD_SSN", "_LCDHD_CLID", "_LCDHD_DOB", "_LCDHD_LNAME", "_LCDHD_FNAME", "_LCDHD_MI", "_LCDHD_BILLING", "_LCDHD_NAME", "_LCDHD_FORMDATE"]

; Name of blank PDF file, referenced in the label FDF files
dim $blankLabelName = "000 - Blank Label.pdf"

dim $checkPDFProcess = ["NitroPDF.exe","Acrobat.exe","Acrord32.exe","Excel.exe"]

dim $encConstant = "CHANGE ME" ; For encrypting the saved access key

global $pdftk = @ProgramFilesDir & '\PDFtk\bin\pdftk.exe'


;******************************************************************************
;                          HANDS FOLDER SETUP FUNCTIONS
;******************************************************************************

Func SetupHANDS()
	If MsgBox($MB_YESNO, "HANDS Setup", "This procedure will set up the necessary folders and mapped drive(s) for the HANDS staff. Would you like to continue?") = $IDNO Then
		Return 1
	EndIf

	;FIXME
	;Set up mapped drives here

	DirCreate($rootPath & $workBase & $workingPath)
	DirCreate($rootPath & $workBase & $correctionPath)
	DirCreate($rootPath & $workBase & $trackingPath)
	DirCreate($rootPath & $workBase & $labelsPath)
	DirCreate($rootPath & $workBase & $tosupervisorPath)
	DirCreate($rootPath & $workBase & $todataPath)
	DirCreate($rootPath & $formsPath)

EndFunc   ;==>SetupHANDS


Func RunHelp()
	ShellExecute("https://secure.lcdhd.org/wiki/index.php/HANDS_EMR")
EndFunc

Func HANDSInit()
	; Do custom start-up functions
EndFunc

Func HANDSSetupScreen()
	GUICtrlCreateButton("Setup...", 50, 100, 300, 50)
	GUICtrlSetOnEvent(-1, "SetupHANDS")

EndFunc

Func HANDSBoxBottomButtons()
    ; Synchronize
	GUICtrlCreateButton("Synchronize", 1, 550, 180, 40)
	GUICtrlSetOnEvent(-1, "RunSynchronize")
	GUICtrlCreateButton("Advanced Compare/Sync", 600, 550, 195, 40)
	GUICtrlSetOnEvent(-1, "EditSynchronize")

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
	;If FileExists($handsAppData & "editsync.lock") Then
	;    FileDelete($handsAppData & "editsync.lock")
	;Else
	;    ; Copy Logs from AppData to Local Briefcase
	;    FileCopy($handsAppData & "Logs\*.csv",$rootPath & $workBase & $logPath & "\",$FC_OVERWRITE + $FC_CREATEPATH)
	;EndIf
	;FileDelete(@tempDir & "\HANDS_Synchronize.exe")
	;FileInstall("HANDS_Synchronize.exe",@TempDir & "\HANDS_Synchronize.exe")
	;ShellExecute(@TempDir & "\HANDS_Synchronize.exe")
	;Exit 1

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
	;FileDelete($syncBatchFile)
	;FileInstall("Sync Briefcase.ffs_batch",$syncBatchFile)
	;ShellExecute($syncBatchFile,"","",$SHEX_EDIT)
	;$f = FileOpen($handsAppData & "editsync.lock",$FO_OVERWRITE)
	;FileWrite($f,"TRUE")
	;FileClose($f)
	;Exit 1
	FileInstall("sync_working_folder.ffs_batch",@TempDir & "\sync_working_folder.ffs_batch",$FC_OVERWRITE)
	ShellExecute(@TempDir & "\sync_working_folder.ffs_batch","","",$SHEX_EDIT)

EndFunc   ;==>EditSynchronize
