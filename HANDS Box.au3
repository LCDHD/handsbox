#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Icon=hands-start-icon.ico
#AutoIt3Wrapper_UseX64=n
#AutoIt3Wrapper_Res_Description=HANDS Box - Various Scripts to automate EMR Processing for the HANDS Program
#AutoIt3Wrapper_Res_Fileversion=1.3.8
#AutoIt3Wrapper_Res_LegalCopyright=Free Software under GNU GPL, (c) 2016-2018 by Lake Cumberland District Health Department
#AutoIt3Wrapper_Res_Language=1033
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****
;******************************************************************************
;
; HANDS BOX
;
; COPYRIGHT (C) 2016-2017
; BY THE LAKE CUMBERLAND DISTRICT HEALTH DEPARTMENT (www.lcdhd.org)
; ORIGINAL CODE BY DANIEL MCFEETERS (www.fiforms.net)
; LATEST VERSION AVAILABLE FROM https://github.com/LCDHD/handsbox
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

; AutoIt Includes
#include <EditConstants.au3>
#include <GUIConstantsEx.au3>
#include <WindowsConstants.au3>
#include <GUIListView.au3>
#include <Constants.au3>
#include <Date.au3>
#include <File.au3>
#include <Array.au3>
#include <Crypt.au3>
#include<String.au3>

; Set some sensible default values here
if(@OSArch = "X32") Then
  global $pdftk = EnvGet("programfiles") &'\PDFtk\bin\pdftk.exe'
Else
  global $pdftk = EnvGet("programfiles(x86)") & '\PDFtk\bin\pdftk.exe'
EndIf

; Custom Includes
#include <HANDS_Custom.au3>
#include <FDF_Libraries.au3>
#include <GetDate_Library.au3>

; Global variables
global $labels
global $labelList
global $labelListItems[0]
global $templates
global $templateList
global $templateListItems[0]
global $statusLabel
global $tab2statusLabel
global $visitors
global $visitorlist
global $visitorsListItems[0]
global $mainwindow
global $labelWindow
global $labelFields[10]
global $labelVisitorList
global $HANDSBoxVersion = FileGetVersion(@AutoItExe)
global $labelEdit = ""
global $formsCopied[0]
global $formsCopiedHashes[0]

; Call Main Window
RunMain()



;**************************** HELPER FUNCTIONS ********************************


Func HANDSLogToFile($function,$message,$file,$base,$datetime) ; WRITE ACTIVITY TO A LOG FILE
	$logfile = $base & @ComputerName & "_" & @UserName & "_" & @YEAR & @MON & "_log.csv"
	$line = '"' & $datetime & '","' & $function & '","' & $message & '","' & $file & '","' & @UserName & '"' & @CRLF
	$lf = FileOpen($logfile,$FO_APPEND + $FO_CREATEPATH)
	FileWrite($lf,$line)
	FileClose($lf)
EndFunc

Func HANDSLog($function,$message,$file) ; LOG to two separate log files
	$datetime = @YEAR & "-" & @MON & "-" & @MDAY & " " & @HOUR & ":" & @MIN & ":" & @SEC
	HANDSLogToFile($function,$message,$file,$handsAppData & "Logs\",$datetime)
	HANDSLogToFile($function,$message,$file,$rootPath & $workBase & $logPath & "\",$datetime)
EndFunc

Func countPath($path)       ; COUNT PDF FILES AT A GIVEN PATH
	$list = _FileListToArray($path, "*.pdf")
	if @error > 0 Then
		Return 0
	EndIf
	Return $list[0]
EndFunc   ;==>countPath

Func getPDFList($path, $filter)	; LIST FILES IN $path (WITH SUPPLIED FILTER) AND RETURN IN AN ARRAY
	local $blankArray[1]
	$blankArray[0] = "None"
	$fullpath = $path
	$fArr = _FileListToArray($fullpath, $filter)
	if @error = 1 Then
		ConsoleWrite("Path was invalid: " & $fullpath)
		Return $blankArray
	EndIf
	if @error = 4 Then
		ConsoleWrite("No File Found: " & $fullpath & @CRLF)
		Return $blankArray
	EndIf
	if @error > 0 Then
		ConsoleWrite("Other Error Listing File in: " & $fullpath)
		Return $blankArray
	EndIf
	return $fArr
EndFunc   ;==>getPDFList

Func getFolderList($path,$wildcard,$exclude)  ; LIST FOLDERS IN $path (WITH SUPPLIED FILTER) AND RETURN IN AN ARRAY
	local $blankArray[1]
	$blankArray[0] = "None"
	$fullpath = $path
	$fArr = _FileListToArray($fullpath, $wildcard,$FLTA_FOLDERS)
	if @error = 1 Then
		ConsoleWrite("Path was invalid: " & $fullpath)
		Return $blankArray
	EndIf
	if @error = 4 Then
		ConsoleWrite("No File Found: " & $fullpath)
		Return $blankArray
	EndIf
	if @error > 0 Then
		ConsoleWrite("Other Error Listing File in: " & $fullpath)
		Return $blankArray
	EndIf
	For $i = 1 to UBound($fArr) - 1
		If($fArr[$i] == $exclude) Then
			_ArrayDelete($fArr,$i)
			ExitLoop
		EndIf
	Next
	return $fArr
EndFunc   ;==>getPDFList

Func GetListFirstItemSelected($control)    ; RETURN INDEX OF FIRST SELECTED ITEM IN _GUICtrlListView
	$count = _GUICtrlListView_GetItemCount($control)
	$i = 0
	while $i < $count
		if _GUICtrlListView_GetItemSelected($control, $i) Then
			Return $i
		EndIf
		$i += 1
	WEnd
	Return -1
EndFunc   ;==>GetListFirstItemSelected

Func ParseFormName($t)     ; Parse the filename of a form template into an array containing multiple fields
	Local $parsedName[4]

	$parsedName[0] = StringStripWS(StringLeft($t, StringInStr($t, "-") - 1), $STR_STRIPLEADING + $STR_STRIPTRAILING + $STR_STRIPSPACES)
	$titleStart = StringInStr($t, "-") + 1
	$dateStart = StringInStr($t, "(")
	$sectionStart = StringInStr($t, "[")
	$titleEnd = StringLen($t) - 3
	if $dateStart > 0 or $sectionStart > 0 Then
		if $dateStart > 0 Then
			$titleEnd = $dateStart
		ElseIf $sectionStart > 0 Then
			$titleEnd = $sectionStart
		EndIf
	EndIf
	$parsedName[1] = StringStripWS(StringMid($t, $titleStart, $titleEnd - $titleStart), $STR_STRIPLEADING + $STR_STRIPTRAILING + $STR_STRIPSPACES)
	$parsedName[2] = ""
	if $dateStart > 0 Then
		$dateEnd = StringInStr($t, ")")
		if $dateEnd > 0 Then
			$parsedName[2] = StringStripWS(StringMid($t, $dateStart + 1, $dateEnd - $dateStart - 1), $STR_STRIPLEADING + $STR_STRIPTRAILING + $STR_STRIPSPACES)
		EndIf
	EndIf
	$parsedName[3] = ""
	if $sectionStart > 0 Then
		$parsedName[3] = StringStripWS(StringMid($t, $sectionStart + 1, 1), $STR_STRIPLEADING + $STR_STRIPTRAILING + $STR_STRIPSPACES)
	EndIf
	Return $parsedName
EndFunc   ;==>ParseFormName

Func NormalizeName($name)               ; NORMALIZE A PERSON'S NAME, AND STRIP WHITE SPACE
	$normalizedName = StringReplace($name,",",", ")
	$normalizedName = StringUpper(StringStripWS($normalizedName,$STR_STRIPLEADING + $STR_STRIPTRAILING + $STR_STRIPSPACES))
	$normalizedName = StringReplace($normalizedName," ,",",")
	return $normalizedName
EndFunc

Func CheckFormName($checkname)	; Search for a form name in the normal places. Used to prevent duplicate form names.
	If FileExists($rootPath & $workBase & $workingPath & "\" & $checkname) Then
		Return True
	EndIf
	If FileExists($rootPath & $workBase & $tosupervisorPath & "\" & $checkname) Then
		Return True
	EndIf
	If FileExists($rootPath & $workBase & $todataPath & "\" & $checkname) Then
		Return True
	EndIf
	Return False
EndFunc




;************************* NEW LABEL WINDOW UI FUNCTIONS **********************

Func NewOrEditLabel($edit)   ; CREATE/EDIT LABEL WINDOW
	if $edit Then
		$labelIndexSelected = GetListFirstItemSelected($labelList)
		if $labelIndexSelected < 0 Then
			Return 1
		EndIf
	EndIf

	If WinExists("Create HANDS Family Label") Then
		Return 1
	EndIf

	$labelWindow = GUICreate("Create HANDS Family Label", 340, 360,-1,-1,$WS_POPUP + $WS_CAPTION + $WS_SYSMENU, $WS_EX_TOPMOST)
	GUISetOnEvent($GUI_EVENT_CLOSE, "LabelCLOSEClicked", $labelWindow)
	GUICtrlCreateLabel("Home Visitor: ", 10, 10)
	$labelFields[0] = GUICtrlCreateInput("", 130, 10, 200, 20)
	GUICtrlCreateLabel("Patient ID:", 10, 40)
	$labelFields[1] = GUICtrlCreateInput("", 130, 40, 200, 20)
	GUICtrlCreateLabel("Clinic ID: ", 10, 70)
	$labelFields[2] = GUICtrlCreateInput("", 130, 70, 200, 20)
	GUICtrlCreateLabel("DOB (MM/DD/YYYY): ", 10, 100)
	$labelFields[3] = GUICtrlCreateInput("", 130, 100, 200, 20)
	GUICtrlCreateLabel("Last Name: ", 10, 130)
	$labelFields[4] = GUICtrlCreateInput("", 130, 130, 200, 20)
	GUICtrlCreateLabel("First Name: ", 10, 160)
	$labelFields[5] = GUICtrlCreateInput("", 130, 160, 200, 20)
	GUICtrlCreateLabel("Middle Initial: ", 10, 190)
	$labelFields[6] = GUICtrlCreateInput("", 130, 190, 50, 20)
	GUICtrlSetOnEvent($labelFields[6],"CheckMILength")

	GUICtrlCreateLabel("Billing Code: ", 10, 220)
	$labelFields[7] = GUICtrlCreateCombo("",130,220,200,20)
	;$labelFields[7] = GUICtrlCreateInput("", 130, 220, 50, 20)
	$labelFields[8] = GUICtrlCreateInput("", 220, 410, 20, 20) ; Hidden field for _LCDHD_NAME
	$labelFields[9] = GUICtrlCreateInput("@_LCDHD_FORMDATE", 220, 400, 20, 20) ; Hidden field for _LCDHD_FORMDATE

    if $edit Then
	    GUICtrlCreateButton("Modify Label", 1, 300, 338, 30)
	Else
	    GUICtrlCreateButton("Create Label", 1, 300, 338, 30)
	EndIf
	GUICtrlSetOnEvent(-1, "LabelCreate")
	GUICtrlCreateButton("Cancel", 1, 330, 338, 30)
	GUICtrlSetOnEvent(-1, "LabelCLOSEClicked")

	$billingcodes = FileRead($rootPath & $formsPath & "\billingcodes.txt")
	$billingcodes = StringReplace($billingcodes,@CRLF,"|")
    $billingcodes = StringReplace($billingcodes,@LF,"|")

	if $edit Then
		local $aFields[0]
		local $aValues[0]
	    $labelSelected = $labels[$labelIndexSelected + 1]
		$f = FileOpen($labelsSelectPath & "\" & $labelSelected,$FO_READ)
		$labelEdit = $labelsSelectPath & "\" & $labelSelected
		$fdf = FileRead($f)
		FileClose($f)
		ParseFDF($fdf,$aFields,$aValues)
		local $i = 0
		while $i < UBound($labelFieldsNames)
			$idx = _ArraySearch($aFields,$labelFieldsNames[$i])
			if $idx > -1 Then
				if $i = 7 Then
					GUICtrlSetData($labelFields[$i], $aValues[$idx] & "|" & $billingcodes, $aValues[$idx])
				Else
				    GUICtrlSetData($labelFields[$i],$aValues[$idx])
				EndIf
			EndIf
			$i += 1
		Wend
	Else
		GUICtrlSetData($labelFields[7], $billingcodes, "")
	EndIf
	GUISetState(@SW_SHOW, $labelWindow)

EndFunc  ;==>NewOrEditLabel

func CheckMILength()
	$mi = GUICtrlRead($labelFields[6])
	$mi = StringMid($mi,1,1)
	GUICtrlSetData($labelFields[6],$mi)
EndFunc

Func RunNewLabel()         ; CALL NEW LABEL WINDOW
	$labelEdit = ""
    NewOrEditLabel(false)
EndFunc   ;==>RunNewLabel

Func LabelCLOSEClicked()   ; CLOSE NEW LABEL WINDOW
	GUIDelete($labelWindow)
	RefreshMain()
EndFunc   ;==>LabelCLOSEClicked

Func LabelCreate()
	; Create a label (FDF file) with information from the currently open Label form

	; Delete old label before creating new one
	if Not $labelEdit = "" Then
		HANDSLog("Edit Label","Removing Label " & $labelEdit,$labelEdit)
		FileDelete($labelEdit)
	EndIf
	; GENERATE A NEW FDF FILE (LABEL) WITH DATA ENTERED ON NEW LABEL FORM
	local $i = 0
	local $aFields[0]
	local $aValues[0]
	; Fix Billing Code

	GUICtrlSetData($labelFields[8], GUICtrlRead($labelFields[4]) & ", " & GUICtrlRead($labelFields[5]) & " " & GUICtrlRead($labelFields[6]))
	While $i < UBound($labelFields)
		$v = GUICtrlRead($labelFields[$i])
		if Not $v = "" Then
			_ArrayAdd($aFields,$labelFieldsNames[$i])
			If StringInStr($v,"--") Then
				;ConsoleWriteError("Stripping Dashes: "& StringStripWS(StringMid($v,1,StringInStr($v,"--") - 2),$STR_STRIPTRAILING) & @CRLF);
				_ArrayAdd($aValues,StringStripWS(StringMid($v,1,StringInStr($v,"--") - 2),$STR_STRIPTRAILING))
			Else
			    _ArrayAdd($aValues,$v)
			EndIf
		EndIf
		$i += 1
	WEnd
	$fullFDF = CreateFDF("000 - Blank Label.pdf",$aFields,$aValues)

	$dstFile = $labelsSelectPath & "\" & guictrlRead($labelFields[4]) & ", " & guictrlRead($labelFields[5]) & " " & guictrlRead($labelFields[6]) & ".fdf"
	HANDSLog("Create Label",guictrlRead($labelFields[4]) & ", " & guictrlRead($labelFields[5]) & " " & guictrlRead($labelFields[6]) & ".fdf",$dstFile)
	$f = FileOpen($dstFile, $FO_BINARY + $FO_OVERWRITE)
	If @error > 0 Then
		MsgBox(0, "Error", "There was a problem creating the label.")
	EndIf
	FileWrite($f, $fullFDF)
	FileClose($f)
	;FileInstall("forms_src\000 - Blank Label.pdf",$labelsSelectPath & "\",$FC_OVERWRITE)
	LabelCLOSEClicked()
EndFunc   ;==>LabelCreate




;************************* MAIN WINDOW UI FUNCTIONS ***************************
Func RunMain()             ; MAIN HANDS BOX WINDOW
	; Check if HANDS Box is already running
	$hands_boxes = ProcessList("HANDS Box.exe")
	If Ubound($hands_boxes) > 2 Then
		WinActivate("HANDS Box")
		WinSetState("HANDS Box","",@SW_RESTORE)
		Exit 1
	EndIf


	If Not FileExists($iniFile) Then
		SetOptions()
	EndIf
	$HANDSRole = IniRead($iniFile,"General","Role","Home Visitor")

	HANDSLog("HANDSBox","Open",'')

    HANDSInit()

	$mainwindow = GUICreate("HANDS Box (" & $HANDSRole & ")", 800, $handsBoxHeight)
	Opt("GUIOnEventMode", 1)
	GUISetOnEvent($GUI_EVENT_CLOSE, "CLOSEClicked")

    ; Help
	GUICtrlCreateButton("?",720,1,28,28)
	GUICtrlSetOnEvent(-1, "RunHelp")

	; Refresh Button
	GUICtrlCreateButton("Refresh", 650, 1, 68, 28)
	GUICtrlSetOnEvent(-1, "RefreshMain")

    ; About Button
	GUICtrlCreateButton("About", 750, 1, 48, 28)
	GUICtrlSetOnEvent(-1, "ShowAbout")

    GUICtrlCreateTab(0,10,798,537)
	GUICtrlSetOnEvent(-1, "RefreshMain")

	;**************************************************************************
	; Supervisor or Data Entry tab
	If Not ($HANDSRole = "Home Visitor") Then

		if $HANDSRole = "Data Entry" Then
		    GUICtrlCreateTabItem("Data Entry")
		Else
		    GUICtrlCreateTabItem("Supervisor")
		EndIf
		$visitorlist = GUICtrlCreateListView("Home Visitor                 |" & $todataPath & "|" & $tosupervisorPath & "|" & $correctionPath & "|" & $workingPath & "|" & $labelsPath, 5, 35, 785, 370)

		if $HANDSRole = "Data Entry" Then
			; To Data Processing
			GUICtrlCreateButton("Open 'To Data Processing'", 5, 410, 180, 40)
			GUICtrlSetOnEvent(-1, "ReviewDataProcessing")


			GUICtrlCreateButton("Queue to Filing Queue", 365, 410, 425, 40)
			GUICtrlSetOnEvent(-1, "QueueToFilingQueue")

			; Open Chart Queue
			GUICtrlCreateButton("Open Filing Queue", 365, 450, 200, 40)
			GUICtrlSetOnEvent(-1, "OpenQueueToChart")

			; File Forms to Charts
			GUICtrlCreateButton("File Queued Forms to Charts", 565, 450, 225, 40)
			GUICtrlSetOnEvent(-1, "FileToCharts")

			$tab2statusLabel = GUICtrlCreateLabel(" Not Yet Refreshed ", 400, 500, 160, 40)

		EndIf

		if $HANDSRole = "Supervisor" Then
			; To Supervisor
			GUICtrlCreateButton("Open 'To Supervisor'", 5, 410, 180, 40)
			GUICtrlSetOnEvent(-1, "ReviewSupervisor")

			GUICtrlCreateButton("Queue to Data Processing", 365, 410, 425, 40)
			GUICtrlSetOnEvent(-1, "QueueToDataProcessing")


			; Supervision Form
			GUICtrlCreateButton("New Supervision Form", 185, 490, 180, 40)
			GUICtrlSetOnEvent(-1, "NewSupervision")

		    ; Supervision Form
			GUICtrlCreateButton("Open Supervision Folder", 365, 490, 180, 40)
			GUICtrlSetOnEvent(-1, "OpenSupervision")

		EndIf

		; To Corrections
		GUICtrlCreateButton("Send To Corrections", 185, 410, 180, 40)
		GUICtrlSetOnEvent(-1, "SendToCorrections")
		GUICtrlCreateButton("Open 'Needs Correction'", 185, 450, 180, 40)
		GUICtrlSetOnEvent(-1, "ReviewCorrections")

		; Labels
		GUICtrlCreateButton("Review Logs", 5, 450, 180, 40)
		GUICtrlSetOnEvent(-1, "ReviewLogs")

		; Tracking Form
		GUICtrlCreateButton("Tracking Form", 5, 490, 180, 40)
		GUICtrlSetOnEvent(-1, "ReviewTracking")


        ; Analyze Forms
		GUICtrlCreateButton("Analyze PDF Forms in Excel", 565, 490, 225, 40)
		GUICtrlSetOnEvent(-1, "AnalyzeForms")

	EndIf

    ;**************************************************************************
    ; Home Visitor Tab
	GUICtrlCreateTabItem("Home Visitor")

    global $formLanguageList = GUICtrlCreateCombo("English",170,35,620,25)
	global $formLanguage = "English"
	GUICtrlSetOnEvent(-1,"SelectLanguage")
	GUICtrlSetData($formLanguageList,"Spanish")
    $templateList = GUICtrlCreateListView("Template Form | Title |Date  |Section", 170, 60, 620, 305)
	GUICtrlCreateLabel("Current Status:",10,420,100,20)
	$statusLabel = GUICtrlCreateLabel(" Not Yet Refreshed ", 130, 420, 170, 120)
	$labeloffset = 0
	If FileExists($homevisitorPath) Then
	    $labelVisitorList = GUICtrlCreateCombo("Me",5,35,158,25)
		$labeloffset = 25
		GUICtrlSetOnEvent(-1,"SelectVisitorLabels")
		$hvliststring = ""
		$hvlistarray = getFolderList($homevisitorPath,$homevisitorWildcard,StringMid($workBase,1,StringLen($workBase)-1))
		for $i = 1 to UBound($hvlistarray) - 1
			$hvliststring &=  StringReplace($hvlistarray[$i],StringReplace($homevisitorWildcard,"*",""),"") & "|" ;$hvlistarray[$i] & "|"
		Next
		GUICtrlSetData($labelVisitorList,$hvliststring)
	EndIf
	$labelList = GUICtrlCreateListView("Name                           ", 5, 35+$labelOffset, 160, 295-$labelOffset)


	LoadTemplates()
	RefreshMain()

	; Label Listing Controls
	GUICtrlCreateButton("New Label", 5, 330, 80, 40)
	GUICtrlSetOnEvent(-1, "RunNewLabel")
	GUICtrlCreateButton("Edit Label", 85, 330, 80, 40)
	GUICtrlSetOnEvent(-1, "EditLabel")
	GUICtrlCreateButton("Delete Label", 5, 370, 80, 40)
	GUICtrlSetOnEvent(-1, "DeleteLabel")
	GUICtrlCreateButton("Show Labels", 85, 370, 80, 40)
	GUICtrlSetOnEvent(-1, "ShowLabels")

	GUICtrlCreateButton("Create Form / Packet", 165, 370, 625, 40)
	GUICtrlSetOnEvent(-1, "CreateFormPacket")

	; Work in Progress
	GUICtrlCreateButton("View", 280, 410, 100, 30)
	GUICtrlSetOnEvent(-1, "ViewWorkInProgress")
	GUICtrlCreateButton("Queue to Supervisor", 380, 410, 200, 30)
	GUICtrlSetOnEvent(-1, "QueueToSupervisor")
	GUICtrlCreateButton("Corrections to Supervisor", 380, 495, 200, 30)
	GUICtrlSetOnEvent(-1, "CorrectionsToSupervisor")
	GUICtrlCreateButton("Corrections to Data P.", 580, 495, 200, 30)
	GUICtrlSetOnEvent(-1, "CorrectionsToDataP")

	If $HANDSRole = "Supervisor" Then
		GUICtrlCreateButton("Queue to Data Processing", 580, 410, 200, 30)
		GUICtrlSetOnEvent(-1, "QueueMeToDataProcessing")
	EndIf

	; Supervisor Line Line
	GUICtrlCreateButton("View", 280, 438, 100, 30)
	GUICtrlSetOnEvent(-1, "ViewSupervisor")

	; Data Processing Line
	GUICtrlCreateButton("View", 280, 466, 100, 30)
	GUICtrlSetOnEvent(-1, "ViewDataProcessing")

	; Needs Correction Line
	GUICtrlCreateButton("View", 280, 494, 100, 30)
	GUICtrlSetOnEvent(-1, "ViewNeedsCorrection")

	; Tracking Forms
	GUICtrlCreateButton("My Tracking Forms", 380, 438, 200, 30)
	GUICtrlSetOnEvent(-1, "ViewTrackingForm")

	GUICtrlCreateButton("Create/Open Tracking Form", 580, 438, 200, 30)
	GUICtrlSetOnEvent(-1, "NewTrackingForm")

	; Supervision Forms
	GUICtrlCreateButton("Supervision Folder", 380, 466, 200, 30)
	GUICtrlSetOnEvent(-1, "ViewSupervisionForms")

    ;**************************************************************************
    ;Setup Tab
	GUICtrlCreateTabItem("Setup")
	; Setup

	GUICtrlCreateButton("Select HANDS Box Mode", 50, 50, 300, 50)
	GUICtrlSetOnEvent(-1, "SetOptions")
	HANDSSetupScreen()
	GUICtrlCreateButton("Unlock a PDF", 350, 50, 300, 50)
	GUICtrlSetOnEvent(-1, "UnlockPDF")
	GUICtrlCreateButton("Repair PDF Form", 350, 100, 300, 50)
	GUICtrlSetOnEvent(-1, "FixPDFForm")
	GUICtrlCreateButton("Restore File from Backup", 350, 150, 300, 50)
	GUICtrlSetOnEvent(-1, "RestoreBackupFile")

    ;**************************************************************************
    ;Lower Panel
	GUICtrlCreateTabItem("")

	HANDSBoxBottomButtons()

	; Charts Button
	GUICtrlCreateButton("HANDS Folder", 540, 1, 98, 28)
	GUICtrlSetOnEvent(-1, "ViewCharts")
	;GUICtrlCreateButton("Web Charts", 515, 550, 80, 40)
	;GUICtrlSetOnEvent(-1, "ViewWebCharts")

	; Wait Around
	GUISetState(@SW_SHOW)
	While 1
		Sleep(10)
		$msg = GUIGetMsg()
		If $msg = $GUI_EVENT_CLOSE Then ExitLoop
	WEnd
EndFunc   ;==>RunMain

Func RefreshMain()         ; REFRESH THE MAIN WINDOW AND COUNTERS
	$labels = getPDFList($labelsSelectPath, "*.fdf")
	while UBound($labelListItems) > 0
	    GUICtrlDelete(_ArrayPop($labelListItems))
	WEnd
	$i = 0
	while $i < $labels[0]
		$i = $i + 1
		_ArrayAdd($labelListItems, GUICtrlCreateListViewItem(StringLeft($labels[$i], StringLen($labels[$i]) - 4), $labelList))
	Wend

	; Calculate current status variables
	$stat = ""  ; "Current Status " & @CRLF & @CRLF
	$stat &= $workingPath & ": " & countPath($rootPath & $workBase & $workingPath) & @CRLF & @CRLF
	$stat &= $tosupervisorPath & ": " & countPath($rootPath & $workBase & $tosupervisorPath) & @CRLF & @CRLF
	$stat &= $todataPath & ": " & countPath($rootPath & $workBase & $todataPath) & @CRLF & @CRLF
	$stat &= $correctionPath & ": " & countPath($rootPath & $workBase & $correctionPath) & @CRLF & @CRLF

	$syncTime = FileGetTime($rootPath & "sync.ffs_db")
	if $syncTime Then
	    $stat &= "    Last Sync: " & $syncTime[1] & "/" & $syncTime[2] & "/" & $syncTime[0] & " " & $syncTime[3] & ":" & $syncTime[4]
	EndIf

	GUICtrlSetData($statusLabel, $stat)

	$stat = "Forms in Filing Queue: " & countPath($rootPath & $workBase & $queueToChart)
	GUICtrlSetData($tab2statusLabel,$stat)

	$visitors = getFolderList($homevisitorPath,$homevisitorWildcard, '~~') ; StringMid($workBase,1,StringLen($workBase)-1))
	while UBound($visitorsListItems) > 0
	    GUICtrlDelete(_ArrayPop($visitorsListItems))
	WEnd

	$i = 0
	;_ArrayDisplay($visitors)
	while $i < UBound($visitors) - 1
		$i = $i + 1
		$todata = getPDFList($homevisitorPath & "\" & $visitors[$i] & "\" & $todataPath,"*.pdf")
		$tosup = getPDFList($homevisitorPath & "\" & $visitors[$i] & "\" & $tosupervisorPath,"*.pdf")
		$needscor = getPDFList($homevisitorPath & "\" & $visitors[$i] & "\" & $correctionPath,"*.pdf")
		$inprogress = getPDFList($homevisitorPath & "\" & $visitors[$i] & "\" & $workingPath,"*.pdf")
		$vlabels = getPDFList($homevisitorPath & "\" & $visitors[$i] & "\" & $labelsPath,"*.fdf")
		$visitorname = StringReplace($visitors[$i],StringReplace($homevisitorWildcard,"*",""),"")
		_ArrayAdd($visitorsListItems, GUICtrlCreateListViewItem($visitorname  & "|" & $todata[0] & "|" & $tosup[0] & "|" & $needscor[0] & "|"  & $inprogress[0] & "|" & $vlabels[0],$visitorlist))
	Wend

EndFunc   ;==>RefreshMain

Func LoadTemplates()       ; BUILD MAIN LIST OF FORM TEMPLATES
    $i = 0
	$packets = getPDFList($rootPath & $formsPath & "\" & $formLanguage, "*.txt")

    while UBound($templateListItems) > 0
	    GUICtrlDelete(_ArrayPop($templateListItems))
	WEnd
	; Format File Listing of Group Templates
	while $i < $packets[0]
		$i = $i + 1
		$pn = ParseFormName($packets[$i])
		_ArrayAdd($templateListItems, GUICtrlCreateListViewItem($pn[0] & "|" & $pn[1] & "|" & $pn[2] & "|" & $pn[3], $templateList))
	Wend
	$templates = $packets
    $i = 0
	$ftemplates = getPDFList($rootPath & $formsPath & "\" & $formLanguage, "*.pdf")
	; Format File Listing of Templates
	while $i < $ftemplates[0]
		$i = $i + 1
		$pn = ParseFormName($ftemplates[$i])
		_ArrayAdd($templateListItems, GUICtrlCreateListViewItem($pn[0] & "|" & $pn[1] & "|" & $pn[2] & "|" & $pn[3], $templateList))
		$templates[0] += 1
		_ArrayAdd($templates,$ftemplates[$i])
	Wend
EndFunc

Func SelectLanguage()      ; CHANGE LANGUAGE OF FORMS
	$formLanguage = GUICtrlRead($formLanguageList)
	LoadTemplates()
EndFunc

Func ShowAbout()           ; SHOW ABOUT WINDOW
	MsgBox(0,"About HANDS Box","HANDS Box Version " & $HANDSBoxVersion & @CRLF & _
        "Local Extensions: " & $CustomHANDSBoxVersion & @CRLF & @CRLF & _
		"HANDS Box comes with ABSOLUTELY NO WARRANTY. This is free software," & @CRLF & _
		"and you are welcome to redistribute a form of this software under " & @CRLF & _
		"certain conditions. However, if the words 'DO NOT DISTIBUTE' appear" & @CRLF & _
		"in the Local Extensions above, you MUST NOT distribute this version" & @CRLF & _
		"outside of your immediate organization. See LICENSE.txt for details." & @CRLF & @CRLF & _
		'"Kentucky HANDS" and the HANDS Logo are property of the ' & @CRLF & _
		"Kentucky Cabinet for Health and Family Services." _
		)
EndFunc

Func GetVisitorSelected()  ; RETURN WHICH VISITOR IS SELECTED ON SUPERVISOR/DATA ENTRY SCREEN
	$visitorIndex = GetListFirstItemSelected($visitorlist)
	if $visitorIndex = -1 Then
	    MsgBox(0,"No Home Visitor Selected","Please Select a Home Visitor from the list.")
	    Return Null
	EndIf
	Return $visitors[$visitorIndex + 1]
EndFunc

Func ViewCharts()           ; OPEN THE CHARTS FOLDER
	ShellExecute($rootPath)
EndFunc

Func ProcessCheck()        ; Check if any processes are running that could interfere with sync
	For $pname in $checkPDFProcess
		if ProcessExists($pname) Then
			MsgBox(0,"Please Close Open Forms","It appears that forms may still be open in process " & $pname & ". Please save your work and close all other windows and try again")
			Return True
		EndIf
	Next
	Return False
EndFunc

Func CLOSEClicked()       ; Cleanup and Exit the HANDS Box
	If ProcessCheck() Then
		Return 1
	EndIf
	CheckBlankFiles()
	FileDelete(@TempDir & "\HANDS_FDF_*.fdf")
	HANDSLog("HANDSBox","Close",'')
	Exit
EndFunc   ;==>CLOSEClicked

Func CreateUserFolders()   ; Setup User Folder Structure
	DirCreate($rootPath & $workBase & $workingPath)
	DirCreate($rootPath & $workBase & $correctionPath)
	DirCreate($rootPath & $workBase & $trackingPath)
	DirCreate($rootPath & $workBase & $labelsPath)
	DirCreate($rootPath & $workBase & $tosupervisorPath)
	DirCreate($rootPath & $workBase & $todataPath)
	DirCreate($rootPath & $workBase & $logPath)
	DirCreate($rootPath & $formsPath)

EndFunc

;Func CreateTemplateFolders() ; Setup Master Template Folders
;	DirCopy(@ScriptDir & "\forms",$formsPath)
;	DirCopy(@ScriptDir & "\supervisionforms",$supervisionFormsPath)

;EndFunc


;************************* FOLDER QUEUE FUNCTIONS *****************************

Func getSigName($pdf)
	$f = FileOpen($pdf,$FO_BINARY)
	$cont = FileRead($f)
	FileClose($f)
	return getSigNameInternal($cont,1)
EndFunc

Func getSigNameInternal($cont,$startPos)
	dim $missing = false
	$sigStart = StringInStr($cont,_StringToHex("/adbe.pkcs7.detached"),1,1,$startPos)
	if $sigStart = 0 Then
		ConsoleWrite('No $sigStart')
		Return ''
    EndIf
	$nameStart = StringInStr($cont,_StringToHex('/Name'),0,1,$sigStart)
	if $nameStart = 0 Then
		ConsoleWrite('No $nameStart')
		Return ''
    EndIf
	if BinaryToString(BinaryMid($cont,Floor($nameStart / 2)-2,2)) = "<>" Then
		ConsoleWrite('Possible Missing Signature Found')
		$missing = true
	EndIf
	$parenStart = StringInStr($cont,_StringToHex('('),0,1,$nameStart)
	$parenStart += 2
	$nameEnd = StringInStr($cont,_StringToHex(')'),0,1,$parenStart)
	if $nameEnd = 0 Then
		ConsoleWrite('No $parenEnd')
		Return ''
    EndIf
	$sig = BinaryToString(BinaryMid($cont,Floor($parenStart / 2),Floor(($nameEnd - $parenStart)/2)))
	if $missing Then
		$sig = "MISSING SIGNATURE"
	Endif
	$nextSig = getSigNameInternal($cont,$nameEnd)
	if $nextSig = "" Then
		return $sig
	Else
		return $sig & "," & $nextSig
	EndIf
EndFunc


Func QueueToFolder($src,$dst,$purpose,$selectAll)  ; CREATE WINDOW TO CONFIRM FILE QUEUE
    If ProcessCheck() Then
		Return 1
	EndIf
	If Not FileExists($src) Then
		Return 1
	EndIf
    CheckBlankFiles()
	global $aForms = getPDFList($src,"*.pdf")
	if $aForms[0] = 0 Then
		MsgBox(0,"HANDS Box","There aren't any forms to queue.")
		Return 1
	EndIf
	ProgressOn("HANDS Box","Scanning Forms")


	global $HANDSFolderQueueConfirm = GUICreate("Confirm Queue " & $purpose,760,400,-1,-1,$WS_POPUP+$WS_CAPTION,$WS_EX_TOPMOST)
	GUICtrlCreateLabel("Are you ready to queue the following forms " & $purpose & "?" _
	          & @CRLF & @CRLF & _
			  "Please confirm that you have reviewed and signed every form listed below:",10,10)

	GUICtrlCreateButton("Queue Selected Files",5,360,375,35)
	GUICtrlSetOnEvent(-1,"QueueToFolderFinish")
	GUICtrlCreateButton("Cancel",380,360,375,35)
	GUICtrlSetOnEvent(-1,"QueueToFolderCancel")
	GUICtrlCreateButton("Select All",380,330,100,30)
	GUICtrlSetOnEvent(-1,"QueueToFolderSelectAll")
	GUICtrlCreateButton("Select None",280,330,100,30)
	GUICtrlSetOnEvent(-1,"QueueToFolderSelectNone")

    global $HANDSFolderList = GUICtrlCreateListView("File Name | Modified | Signed",5,50,750,270,-1,$LVS_EX_CHECKBOXES)
    $i = 0
	while $i < $aForms[0]
		ProgressSet($i * 100 / $aForms[0],$aForms[$i])
		$i += 1
		$t = FileGetTime($src & "\" & $aForms[$i])
		$sig = getSigName($src & "\" & $aForms[$i])
		GUICtrlCreateListViewItem($aForms[$i] & "|" & $t[1] & "/" & $t[2] & " at " & $t[3] & ":" & $t[4] & "|" & $sig,$HANDSFolderList)
		If($selectAll) Then
	       _GUICtrlListView_SetItemChecked($HANDSFolderList,$i-1)
		EndIf
		;$strForms = $strForms & $aForms[$i] & @CRLF &  "                   (Modified " & $t[1] & "/" & $t[2] & " at " & $t[3] & ":" & $t[4] & ")" & @CRLF
	WEnd
     _GUICtrlListView_SETColumnWidth($HANDSFolderList,0,$LVSCW_AUTOSIZE)
     _GUICtrlListView_SETColumnWidth($HANDSFolderList,1,$LVSCW_AUTOSIZE)

    global $HANDSFolderQueueSrc = $src
	global $HANDSFolderQueueDst = $dst
	global $HANDSFolderQueuePurpose = $purpose
	ProgressOff()

	GUISetState(@SW_SHOW,$HANDSFolderQueueConfirm)

EndFunc

Func QueueToFolderSelectAll()
    $i = 0
	while $i < $aForms[0]
		_GUICtrlListView_SetItemChecked($HANDSFolderList,$i)
		$i += 1
	WEnd
EndFunc

Func QueueToFolderSelectNone()
    $i = 0
	while $i < $aForms[0]
		_GUICtrlListView_SetItemChecked($HANDSFolderList,$i,False)
		$i += 1
	WEnd
EndFunc

Func QueueToFolderCancel()              ; CANCEL FILE QUEUE

    GUIDelete($HANDSFolderQueueConfirm)

EndFunc

Func QueueToFolderFinish()              ; FINALIZE FILE QUEUE AND MOVE FILES


    $src = $HANDSFolderQueueSrc
	$dst = $HANDSFolderQueueDst
	$purpose = $HANDSFolderQueuePurpose

	$i = 0
	while $i < $aForms[0]
		$i += 1
		If _GUICtrlListView_GetItemChecked($HANDSFolderList,$i-1) Then
			$backupdst = "FormBackup\" & @YEAR & @MON & "\" & $aForms[$i] & "." & @MON & @MDAY & @HOUR & @MIN & @SEC
			HANDSLog('Queue',$purpose & ' (' & $dst & ')',$backupdst)
			FileCopy($src & "\" & $aForms[$i],$handsAppData & $backupdst,$FC_CREATEPATH)
			FileSetAttrib($handsAppData & "FormBackup\" & @YEAR & @MON & "\" & $aForms[$i],"+R")
			If FileMove($src & "\" & $aForms[$i],$dst & "\" & $aForms[$i]) = 0 Then
				MsgBox(0,"HANDS Box","Cannot move " & $aForms[$i])
			EndIf
		EndIf
	WEnd
    GUIDelete($HANDSFolderQueueConfirm)
	RefreshMain()
EndFunc

Func QueueToFilingQueue()               ; INITIATE QUEUE TO DATA PROCESSING FILING QUEUE
	DirCreate($rootPath & $workBase & $queueToChart)
	$src = $homevisitorPath & "\" & GetVisitorSelected() & "\" & $todataPath
	$dst = $rootPath & $workBase & $queueToChart
	QueueToFolder($src,$dst,"from '" & GetVisitorSelected() & "' for filing",True)
EndFunc

Func QueueToDataProcessing()            ; INITIATE QUEUE TO DATA PROCESSING (FOR OTHER HV's)
	If Not GetVisitorSelected() Then
		Return 1
	EndIf
	;Triggered from the supervision screen. Move files over to the Data Processing folder.
	$src = $homevisitorPath & "\" & GetVisitorSelected() & "\" & $tosupervisorPath
	$dst = $homevisitorPath & "\" & GetVisitorSelected() & "\" & $todataPath
	QueueToFolder($src,$dst,"from '" & GetVisitorSelected() & "' to data processing",True)
EndFunc   ;==>QueueToDataProcessing

Func SendToCorrections()            ; INITIATE QUEUE TO CORRECTIONS
	If Not GetVisitorSelected() Then
		Return 1
	EndIf
	;Triggered from the supervision/data screens. Move files over to the Data Processing folder.
	$HANDSRole = IniRead($iniFile,"General","Role","Home Visitor")
    if $HANDSRole = "Data Entry" Then
	    $src = $homevisitorPath & "\" & GetVisitorSelected() & "\" & $todataPath
	Else
	    $src = $homevisitorPath & "\" & GetVisitorSelected() & "\" & $tosupervisorPath
	EndIf
	$dst = $homevisitorPath & "\" & GetVisitorSelected() & "\" & $correctionPath
	QueueToFolder($src,$dst,"from '" & GetVisitorSelected() & "' to corrections",False)
EndFunc   ;==>QueueToDataProcessing

Func QueueMeToDataProcessing()          ; INITIATE QUEUE TO DATA PROCESSING (FROM MY SCREEN)
	;Triggered from the Supervisor's home visitor screen. Move files over to the Data Processing folder.
	$src = $rootPath & $workBase & $workingPath
	$dst = $rootPath & $workBase & $todataPath
	QueueToFolder($src,$dst,"from my work in progress to data processing",True)
EndFunc   ;==>QueueToDataProcessing

Func QueueToSupervisor()                ; INITIATE QUEUE TO SUPERVISOR
	; Triggered from the Home Visitor screen. Move files to the Supervisor folder, and make a backup copy.
	$src = $rootPath & $workBase & $workingPath
	$dst = $rootPath & $workBase & $tosupervisorPath
	QueueToFolder($src,$dst,"to supervisor",True)
	RefreshMain()
EndFunc   ;==>QueueToSupervisor

Func CorrectionsToSupervisor()                ; INITIATE QUEUE TO SUPERVISOR
	; Triggered from the Home Visitor screen. Move files to the Supervisor folder, and make a backup copy.
	$src = $rootPath & $workBase & $correctionPath
	$dst = $rootPath & $workBase & $tosupervisorPath
	QueueToFolder($src,$dst,"to supervisor",True)
	RefreshMain()
EndFunc   ;==>QueueToSupervisor

Func CorrectionsToDataP()                ; INITIATE QUEUE TO Data Processing
	; Triggered from the Home Visitor screen. Move files to the Data Processing folder, and make a backup copy.
	$src = $rootPath & $workBase & $correctionPath
	$dst = $rootPath & $workBase & $todataPath
	QueueToFolder($src,$dst,"to data processing",True)
	RefreshMain()
EndFunc   ;==>QueueToSupervisor

Func FileToCharts()                     ; FILE QUEUED FORMS INTO THE CHARTS, BASED ON MATCHING FILE NAMES

	; The idea here is to extract the patient's name from the file name of each file in the "chart queue"
	; Then, look for a folder with exactly the same name somewhere in the charts, and move the file there.

    If ProcessCheck() Then
		Return 1
	EndIf
	local $chartnames[0]
	local $chartfolders[0]
	ProgressOn("HANDS Supervisor Functions","Filing Forms in Charts","Initializing",10,10,$DLG_MOVEABLE)

	; Check to see if there are any forms in the filing queue
    If countPath($rootPath & $workBase & $queueToChart) = 0 Then
		MsgBox(0,"HANDS Supervisor Functions","There are not forms in the queue. Please open the queue first and put some forms into it.")
		ProgressOff()
		Return 1
	EndIf

	; Make sure that the path to the charts exists and is accessible (helpful when stored on network drives)
	If Not FileExists($webRoot) Then
		MsgBox(0,"HANDS Supervisor Functions","I cannot access the charts at the moment. Please try opening the charts folder first.")
		ProgressOff()
        Return 1
	EndIf

	; Get a listing of all files in the filing queue
	ProgressSet(5,"Scanning Forms to File")
	$formsToFile = _FileListToArray($rootPath & $workBase & $queueToChart)

	; Loop through all "chart sets" specificed by wildcard $chartsPath

	ProgressSet(10,"Scanning Charts")
    Local $charts[0]
	Local $cfolders[0]
	$cfolders = _FileListToArray($webRoot,$chartsPath,$FLTA_FOLDERS,True)

	; Get a recusrive listing of all folders in each "chart set"
	For $i = 1 to Ubound($cfolders) - 1
		$chartssingle = _FileListToArrayRec($cfolders[$i],"*",$FLTA_FOLDERS,-7,$FLTAR_SORT,$FLTAR_FULLPATH)
		_ArrayDelete($chartssingle,0)
		_ArrayConcatenate($charts,$chartssingle)
	Next

	;Build $chartnames and $chartfolders arrays for form destinations
	; The combination of these two arrays will work as an associative array, so we can look up the
	; "chart name" (patient name) in the first array, then reference the folder using the same key
	; on the $chartfolders array

	For $path in $charts
		Local $pathDrive
		Local $pathDirectory
		Local $pathFilename
		Local $pathExtension
		Local $normalizedName
		if StringRight($path,1) = "\" Then
			$trimpath = StringLeft($path,StringLen($path)-1)
		Else
			$trimpath = $path
		EndIf
		_PathSplit($trimpath,$pathDrive,$pathDirectory,$pathFilename,$pathExtension)
		If StringInStr($pathFilename,",") Then
			$normalizedName = NormalizeName($pathFilename)
			If _ArraySearch($chartnames,$normalizedName) = -1 Then
			    _ArrayAdd($chartnames,$normalizedName)
			    _ArrayAdd($chartfolders,$path)
			Else
			    MsgBox(0,"HANDS Supervisor Functions","The name '" & $normalizedName & "' is ambiguous. Forms for this patient will not be filed.",3)
			EndIf
		EndIf
	Next

	;Loop over each form in queue and file it if a match is found
	$chartnum = 0  ; Counting, for progress bar
	$cantfile = 0
	For $path in $formsToFile
        $chartnum += 1
		$pathname = StringMid($path,13)
		if Not StringInStr($pathname,"-") Then
			ContinueLoop
		EndIf
		$pathname = StringMid($pathname,1,StringInStr($pathname,"-")-1)
		$pathname = NormalizeName($pathname)
		$folderindex = _ArraySearch($chartnames,$pathname)
		if $folderindex = -1 Then
			; There is no matching chart folder. We'll count this as un-fileable and move on.
			$cantfile += 1
		Else
			HANDSLog("Chart Filing","Filing: " & $path,$chartfolders[$folderindex])
	        ProgressSet(10+($chartnum*80/$formsToFile[0]),"Filing Form: " & $path)
			If Not FileMove($rootPath & $workBase & $queueToChart & "\" & $path,$chartfolders[$folderindex]) Then
				$err = @error
				$cantfile += 1
				ProgressOff()
				RefreshMain()
			    HANDSLog("Chart Filing Error","Error Filing: " & $path,$chartfolders[$folderindex])
				MsgBox(0,"HANDS Supervisor Functions","Could not move form '" & $path & "' to '" & $chartfolders[$folderindex] & "'. Error: " & $err & @CRLF & "I will stop filing charts now until this is resolved.")
				Return 1
			EndIf
		EndIf
	Next
	ProgressSet(100,"Refreshing...")
	RefreshMain()
	ProgressOff()
	if $cantfile > 0 Then
		HANDSLog("Chart Filing","Could not file " & $cantfile & " to charts",$cantfile)
		MsgBox(0,"HANDS Supervisor Functions","Could not file " & $cantfile & " forms into the charts. Please check to make sure the names match the forms.")
	EndIf
EndFunc

;************************ HOME VISITOR GUI FUNCTIONS **************************

Func SelectVisitorLabels()              ; REFRESH THE LABEL LIST AFTER SELECTING A HOME VISITOR
	$VisitorName = GUICtrlRead($labelVisitorList)
	if $VisitorName = "Me" Then
	    $labelsSelectPath = $rootPath & $workBase & $labelsPath
	Else
		$labelsSelectPath = $homevisitorPath & "\" & StringReplace($homevisitorWildcard,"*","") & $VisitorName & "\" & $labelsPath
	EndIf
	RefreshMain()
EndFunc   ;==>SelectVisitorLabels

Func EditLabel()                        ; TRIGGER LABEL EDIT WINDOW
	NewOrEditLabel(true)
EndFunc

Func DeleteLabel()                      ; DELETE SELECTED LABEL
	$labelIndexSelected = GetListFirstItemSelected($labelList)
	if $labelIndexSelected < 0 Then
		Return 1
	EndIf
	$labelSelected = $labels[$labelIndexSelected + 1]
	If MsgBox($MB_YESNO,"Confirm","Are you sure you want to delete the label: " & $labelSelected & "?") = $IDYes Then
		HANDSLog("Delete Label",$labelSelected,'')
		FileDelete($labelsSelectPath & "\" & $labelSelected)
		RefreshMain()
	EndIf
EndFunc

Func OpenIfExists($path)
	If FileExists($path) Then
		ShellExecute($path)
	EndIf
EndFunc

Func ShowLabels()                       ; OPEN LABELS FOLDER
	OpenIfExists($labelsSelectPath)
EndFunc

Func ViewWorkInProgress()               ; OPEN WORK IN PROGRESS FOLDER
	OpenIfExists($rootPath & $workBase & $workingPath)
EndFunc   ;==>ViewWorkInProgress

Func ViewDataProcessing()               ; OPEN TO DATA PROCESSING FOLDER
	OpenIfExists($rootPath & $workBase & $todataPath)
EndFunc   ;==>ViewDataProcessing

Func ViewNeedsCorrection()              ; OPEN CORRECTIONS FOLDER
	OpenIfExists($rootPath & $workBase & $correctionPath)
EndFunc   ;==>ViewNeedsCorrection

Func ViewSupervisor()                   ; OPEN TO SUPERVISOR FOLDER
	OpenIfExists($rootPath & $workBase & $tosupervisorPath)
EndFunc   ;==>ViewSupervisor

Func ViewTrackingForm()                 ; OPEN TRACKING FORM FOLDER
	OpenIfExists($rootPath & $workBase & $trackingPath)
EndFunc   ;==>ViewTrackingForm

Func NewTrackingForm()                  ; COPY NEW EXCEL TRACKING FORM TEMPLATE FOR CURRENTLY SELECTED FAMILY
	$labelIndexSelected = GetListFirstItemSelected($labelList)
	if $labelIndexSelected < 0 Then
		Return 1
	EndIf
	$labelSelected = $labels[$labelIndexSelected + 1]
	$labelSelected = stringReplace($labelSelected,".fdf","")
	$src = $rootPath & $formsPath & "\" & $formLanguage & "\Family Tracking Form.xlsx"
	$dst = $rootPath & $workBase & $trackingPath & "\" & $labelSelected & " Tracking Form.xlsx"
	FileCopy($src,$dst)
	FileSetAttrib($dst,"-R")
	ShellExecute($dst)
EndFunc   ;==>NewTrackingForm

Func ViewSupervisionForms()             ; OPEN SUPERVISION FOLDER
	DirCreate($rootPath & $workBase & $supervisionPath)
	ShellExecute($rootPath & $workBase & $supervisionPath)
EndFunc   ;==>ViewSupervisionForms





;************************* CREATE FORM FUNCTIONS ******************************

Func RememberFile($filename)        ; Remember the original hash of a template file, so we can delete it if not modified later.
	$hash = _Crypt_HashFile($filename,$CALG_SHA1)
	_ArrayAdd($formsCopied,$filename)
	_ArrayAdd($formsCopiedHashes,$hash)
EndFunc

Func CheckBlankFiles()              ; Check through remembered files for blank files, and delete any blank ones
	If ProcessCheck() Then Return False
	$i = 0
	$confirmed = false
	While $i < UBound($formsCopied)
		$checkhash = _Crypt_HashFile($formsCopied[$i],$CALG_SHA1)
		if $checkhash = $formsCopiedHashes[$i] Then
			If Not $confirmed Then
				If MsgBox(4,"HANDS Box","You have left blank forms in your working folder. Do you want to delete them now?") = 6 Then
					$confirmed = true
			    Else
				    Return False
				EndIf
			EndIf
			HANDSLog("DeleteBlank",'Deleting Blank Form',$formsCopied[$i])
			FileDelete($formsCopied[$i])
		EndIf
		$i += 1
	WEnd
	Return True
EndFunc

Func CreateForm($labelSelected,$templateSelected,$date)   ; CREATE FORM FROM SELECTED TEMPLATE
	; GENERATE A TEMPORARY FDF FILE FROM SELECTED LABEL,
	; WITH @_LCDHD_FORMDATE FILLED IN WITH CURRENT DATE,
	; AND TARGET PDF FILE SET TO THE SELECTED PDF TEMPLATE.
	; THEN SHELL EXEC THE TEMPORARY FDF FILE TO OPEN WITH SYSTEM VIEWER


    CheckPDFTK()

	$formateddate = StringReplace(StringMid($date, 6), "-", "/") & "/" & StringLeft($date, 4)
	$parsedName = ParseFormName($templateSelected)
	$workingFilename = $parsedName[3] & $date & " " & StringStripWS(StringReplace($labelSelected, ".fdf", ""), 7) & " - " & StringStripWS($parsedName[1], 7) & ".pdf"
	$suffix = ""
	While CheckFormName(StringReplace($workingFilename,".pdf",$suffix & ".pdf"))
		$suffix = $suffix + 1
	WEnd
	$oldWorkingFilename = $workingFilename
	$workingFilename = StringReplace($workingFilename,".pdf",$suffix & ".pdf")
	if Not $suffix = "" Then
		If MsgBox($MB_YESNO, "Form Already Exists", "A file named: " & @CRLF & @CRLF & $oldWorkingFilename & @CRLF & @CRLF & " already exists. Would you like to create a new form named: " & @CRLF & @CRLF & $workingFilename) = $IDNO Then
		    Return 1
		EndIf
	EndIf

	$templateFile = $rootPath & $formsPath & "\" & $formLanguage & "\" & $templateSelected
	$finalPDF = $rootPath & $workBase & $workingPath & "\" & $workingFilename

	; Create an FDF file with the information

	$f = FileOpen($labelsSelectPath & "\" & $labelSelected, $FO_READ)
	$FDFTemplate = FileRead($f)
	FileClose($f)

	; Replace bogus date placeholder (@_LCDHD_FORMDATE) in template with today's date
	$FDFTemplate = FDFSearchReplace($FDFTemplate, "V", "@_LCDHD_FORMDATE", $formateddate)

	; Replace bogus date placeholder (@_LCDHD_DATE) in template with today's date
	$FDFTemplate = FDFSearchReplace($FDFTemplate, "V", "@_LCDHD_DATE", $formateddate)

	; Replace filename reference in label template with the new file we just created
	$FDFTemplate = FDFSearchReplace($FDFTemplate, "F",$blankLabelName, StringReplace($rootPath & $workBase & $workingPath & "\" & $workingFilename, "\", "/"))

	; Write out the FDF template file to a temporary file
	$TempFDFName = _TempFile(@TempDir, "HANDS_FDF_", ".fdf")
	$f = FileOpen($TempFDFName, $FO_BINARY + $FO_OVERWRITE)
	FileWrite($f, $FDFTemplate)
	FileClose($f)
	;OpenFDF($TempFDFName,$rootPath & $workBase & $workingPath & "\" & $workingFilename)

	; Create the new PDF file using the FDF file info
	HANDSLog("Create Forms",'Creating New Form',$workingFilename)
	RunWait('"' & $pdftk & '" "' & $templateFile & '" fill_form "' & $TempFDFName & '" output "' & $finalPDF & '"',"",@SW_HIDE)
	FileDelete($TempFDFName)

	; Open the PDF file using the default application
	RememberFile($finalPDF)
	ShellExecute($finalPDF,"",$rootPath & $workBase & $workingPath)

EndFunc

Func CreateFormPacket()
	; Initiate form creation, by opening the date selection window. Calls CreateFormPacketFinish after date is selected.
	If GetListFirstItemSelected($labelList) = -1 Then
		MsgBox(0, "Error", "Please select a name for the label")
		Return 1
	EndIf
	If GetListFirstItemSelected($templateList) = -1 Then
		MsgBox(0, "Error", "Please select a form template")
		Return 1
	EndIf
	$date = GetDate("Service Date", "Please select the date the" & @CRLF & "service was performed:","CreateFormPacketFinish",$mainwindow)
EndFunc

Func CreateFormPacketFinish($date)     ; Creates a form or form packet for the selected date. Called after date selection form.

	Local $aFormList
	Local $i
    if $date = null Then
		Return 1
	EndIf
	$labelIndexSelected = GetListFirstItemSelected($labelList)
	$labelSelected = $labels[$labelIndexSelected + 1]
	$templateIndexSelected = GetListFirstItemSelected($templateList)
	$templateSelected = $templates[$templateIndexSelected + 1]

	; Check if this is a form "packet" listing
	If StringRight($templateSelected,4) = ".txt" Then
	    _FileReadToARray($rootPath & $formsPath & "\" & $formLanguage & "\" & $templateSelected,$aFormList)
		$i = 1
		; Check to be sure all forms exist
		While $i < UBound($aFormList)
			If Not FileExists($rootPath & $formsPath & "\" & $formLanguage & "\" & $aFormList[$i]) Then
				MsgBox(0,"HANDS Box: Problem","There is a problem with this form packet." & @CRLF & "The packet requires '" & $aFormList[$i] & "', but I can't find this file." & @CRLF & "Please contact the forms management staff to correct this problem.")
				Return 1
			EndIf
			$i += 1
		WEnd
		While $i > 1
			$i -= 1
			CreateForm($labelSelected,$aFormList[$i],$date)
			Sleep(2000)
		WEnd
    Else
	    ; This is just a single PDF form, proceed to create it
	    CreateForm($labelSelected,$templateSelected,$date)
	EndIf
EndFunc   ;==>CreateFormPacket


Func CheckPDFTK()
	If Not FileExists($pdftk) Then
		If MsgBox($MB_YESNO,"PDFTk not installed","PDFTk is not installed. Would you like visit the download page to install it?" & @CRLF & @CRLF & "Please see the README file for info on embeding PDFTk into the HANDS Box to avoid this problem.") = $IDYES Then
			ShellExecute("https://www.pdflabs.com/tools/pdftk-the-pdf-toolkit/")
		EndIf
		Exit 1
	EndIf
EndFunc


;********************** SUPERVISOR/DATA GUI FUNCTIONS *************************

Func AnalyzeForms()        ; ANALYZE COLLECTION OF PDF FILES AND OUTPUT DATA TO EXCEL

	; Use PDFTk to extract FDF data from a collection of PDF Files. Then parse the FDF data into an a CSV file and open with Excel.
	local $aFields[0]
	local $aValues[0]
	local $strFields
	local $strValues
	local $strLastFields = ""
	local $fileStart = true

	Local $pathDrive
	Local $pathDirectory
	Local $pathFilename
	Local $pathExtension
	Local $fieldHash = ""
	Local $arrayHashes[0]
	Local $arrayHeaders[0]
	Local $arrayData[0]

    CheckPDFTK()

	$folder = FileSelectFolder("Choose Path to Anaylze",$rootPath)
	if $folder = "" Then
		Return 1
	EndIf
	ProgressOn("HANDS Box","Analyzing Form Data","Scanning Forms",50,10)
	$files = _FileListToArrayRec($folder,"*.*df",$FLTAR_FILES,-10,$FLTAR_SORT,$FLTAR_FULLPATH)
	If Not IsArray($files) Then
		MsgBox(0,"HANDS Forms Analyzer","Could not find any form files to analyze")
		ProgressOff()
		Return 1
	EndIf

	local $i = 2
	While $i < UBound($files)
	    ProgressSet(100*$i / UBound($files),"Analyzing " & $i & " of " & UBound($files) & " forms.")
		ReDim $aFields[0]
		ReDim $aValues[0]
		$strFields = '"File Path","File Name","Parse Errors?",'
		$strValues = ""


		; Parse File Name for Metadata
		_PathSplit($files[$i],$pathDrive,$pathDirectory,$pathFilename,$pathExtension)

		$fdffile = $files[$i]
		if $pathExtension = ".pdf" Then
			$fdffile = _TempFile(@TempDir,"~",".fdf")

			ShellExecuteWait($pdftk,'"' & $files[$i] & '" generate_fdf output "' & $fdffile & '"',"","",@SW_HIDE)
			If Not FileExists($fdffile) Then
				$i += 1
				ContinueLoop
			EndIf
	    elseif Not $pathExtension = ".fdf" Then
			$i += 1
			ContinueLoop
		EndIf

		$sigName = getSigName($files[$i])
		$strFields = $strFields & '"Signatures",'
		$strValues = '"' & StringReplace($sigName,'"','""') & '",'

		; Parse File Data
		$f = FileOpen($fdffile,$FO_READ)
		$fdfdata = FileRead($f)
		FileClose($f)
		$result = ParseFDF($fdfdata,$aFields,$aValues)

		; Optional block - puts label fields in order as first columns
		For $l in $labelFieldsNames
			$strFields = $strFields & '"' & $l & '",'
			$lfID = _ArraySearch($aFields,$l)
			if $lfID > -1 Then
				$strValues = $strValues & '"' & StringReplace($aValues[$lfID],'"','""') & '",'
			Else
				$strValues = $strValues & '"",'
			EndIf
		Next

		; Parse $aFields and $aValues into CSV strings
		$j = 1
		While $j < UBound($aFields)
			$lfID = _ArraySearch($labelFieldsNames,$aFields[$j])
			if $lfID > -1 Then
				$j += 1
				ContinueLoop
			EndIf
			$strFields = $strFields & '"' & StringReplace($aFields[$j],'"','""') & '",'
			$strValues = $strValues & '"' & StringReplace($aValues[$j],'"','""') & '",'
			$j += 1
		Wend
		$fieldHash = _Crypt_HashData($strFields,$CALG_MD5)

		$idx = _ArraySearch($arrayHashes,$fieldHash)
		if $idx = -1 Then
			$idx = UBound($arrayHashes)
			_ArrayAdd($arrayHashes,$fieldHash)
			_ArrayAdd($arrayHeaders,$strFields)
			_ArrayAdd($arrayData,"")
		EndIf

		$arrayData[$idx] = $arrayData[$idx] & ('"' & $pathDrive & $pathDirectory & '","' & $pathFilename & $pathExtension & '","' & $result & '",'	& $strValues & @CRLF)
		if $pathExtension = ".pdf" Then
			FileDelete($fdffile)
		EndIf
		$i += 1
	WEnd
	$csvfile = _TempFile(@TempDir,"HANDSAnalyzeFormData_",".csv")
	$csv = FileOpen($csvfile,$FO_OVERWRITE)
	$i = 0
	ProgressSet(100,"Writing Data")
	While $i < UBound($arrayHeaders)
		FileWrite($csv,$arrayHeaders[$i] & @CRLF)
		FileWrite($csv,$arrayData[$i] & @CRLF & @CRLF)
		$i += 1
	WEnd
	FileClose($csv)
	ProgressOff()
	ShellExecute($csvfile)
EndFunc

Func OpenQueueToChart()    ; OPEN THE CHART QUEUE
	If Not FileExists($rootPath & $workBase & $queueToChart) Then
		DirCreate($rootPath & $workBase & $queueToChart)
	EndIf
	ShellExecute($rootPath & $workBase & $queueToChart)
EndFunc   ;==>OpenQueueToChart

Func ReviewDataProcessing() ; Open "To Data Processing" folder  for the selected home visitor
	OpenIfExists($homevisitorPath & "\" & GetVisitorSelected() & "\" & $todataPath)
EndFunc

Func ReviewSupervisor()     ; Open "To Supervisor" folder for the selected home visitor
	OpenIfExists($homevisitorPath & "\" & GetVisitorSelected() & "\" & $tosupervisorPath)
EndFunc

Func ReviewCorrections()	; Open Corrections folder for the selected home visitor
	OpenIfExists($homevisitorPath & "\" & GetVisitorSelected() & "\" & $correctionPath)
EndFunc

Func ReviewLogs()           ; Open Logs folder  for the selected home visitor
	OpenIfExists($homevisitorPath & "\" & GetVisitorSelected() & "\" & $logPath)
EndFunc

Func ReviewTracking()       ; Open Tracking Form folder  for the selected home visitor
	OpenIfExists($homevisitorPath & "\" & GetVisitorSelected() & "\" & $trackingPath)
EndFunc

Func OpenSupervision()      ; Open the supervision folder for the selected home visitor
	If GetVisitorSelected() Then
		DirCreate($homevisitorPath & "\" & GetVisitorSelected() & "\" & $supervisionPath)
		ShellExecute($homevisitorPath & "\" & GetVisitorSelected() & "\" & $supervisionPath)
	EndIf
EndFunc

Func NewSupervision()       ; Create new supervision form for selected home visitor
	If Not GetVisitorSelected() Then
		Return 1
	EndIf
	FileChangeDir($rootPath & $supervisionFormsPath)
	$file = FileOpenDialog("Select Supervision Form Template",@WorkingDir,"All Files (*.*)")
	If @error = 1 Then
		Return 1
	EndIf
	$sDrive = ""
	$sDir = ""
	$sFileName = ""
	$sExtension = ""
	_PathSplit($file,$sDrive,$sDir,$sFileName,$sExtension)
	$parsedname = ParseFormName($sFileName)
	$dst = $homevisitorPath & "\" & GetVisitorSelected() & "\" & $supervisionPath & "\" & $parsedname[3] & StringReplace(_NowCalcDate(),"/","-") & " " & GetVisitorSelected() & " - " & $parsedname[1] & $sExtension
	DirCreate($homevisitorPath & "\" & GetVisitorSelected() & "\" & $supervisionPath)
    FileCopy($file,$dst)
	FileSetAttrib($dst,"-R")
	ShellExecute($dst)

EndFunc  ;==>NewSupervision




;*************************** SETUP GUI FUNCTIONS ******************************

Func SetOptions()          ; HANDS BOX MODE SETUP
	If MsgBox($MB_YESNO,"HANDS Box Setup","Are you Data Entry Staff?") = $IDYes Then
		$role = 'Data Entry'
	ElseIf MsgBox($MB_YESNO,"HANDS Box Setup","Are you a HANDS Supervisor?") = $IDYes Then
		$role = 'Supervisor'
	Else
		$role = 'Home Visitor'
	EndIf
	DirCreate($handsAppData)
	IniWrite($iniFile,"General","Role",$role)
	MsgBox(0,"HANDS Box","Please Re-Open the HANDS Box to complete setup.")
	Exit
EndFunc


Func UnlockPDF()           ; USE PDFTK TO REMOVE COPY PROTECTION FROM PDF

    CheckPDFTK()

	; Use PDFTk to remove copy protection from a PDF
	If MSGBox($MB_YESNO,"HANDS Box PDF Tool","Sometimes you may need to edit a PDF file that has been locked." & @CRLF  _
	      & "This tool uses an external program, PDFTk, to remove this copy protection lock. " & @CRLF _
		  & "This functionality is only provided for documents which you OWN or have legitimate license to use." & @CRLF _
		  & "Please do not use this functionality to bypass copy protection for documents which you do not own." & @CRLF & @CRLF _
		  & "Do you promise to use this tool legally and judiciously?") = $IDNo Then
		  Return 1
	EndIf
	$fname = FileOpenDialog("Select Locked PDF File",@WorkingDir,"PDF Documents (*.pdf)")
	if @error > 0 Then
		MsgBox(0,"There was a problem","There was an error selecting the file")
		Return 1
	EndIf
	$tfile = _TempFile(@TempDir,"~pdftk_",".pdf")
	FileMove($fname,$tfile)
	ShellExecuteWait($pdftk,'"' & $tfile & '" output "' & $fname & '" drop_xmp drop_xfa',"","",@SW_HIDE)
	ShellExecute($fname)
EndFunc

Func FixPDFForm()             ; Use PdfTk to extract and re-apply form data, to repair glitched files

    CheckPDFTK()

	$fname = FileOpenDialog("Select the PDF Form to Repair",@WorkingDir,"PDF Documents (*.pdf)")
	if @error > 0 Then
		MsgBox(0,"There was a problem","There was an error selecting the file")
		Return 1
	EndIf
	$tfile = _TempFile(@TempDir,"~pdftk_",".pdf")
	$tfdf = _TempFile(@TempDir,"~pdftk_",".fdf")
	FileMove($fname,$tfile)
	ShellExecuteWait($pdftk,'"' & $tfile & '" generate_fdf output "' & $tfdf & '"',"","",@SW_HIDE)
	ShellExecuteWait($pdftk,'"' & $tfile & '" fill_form "' & $tfdf & '" output "' & $fname & '"',"","",@SW_HIDE)
	If Not(FileExists($fname & ".original.pdf")) Then
		FileMove($tfile,$fname & ".original.pdf")
	EndIf
	ShellExecute($fname)


EndFunc

Func RestoreBackupFile()
	; Allow user to select files from hidden backup and restore (copy) them back to the working folder.
	$files = FileOpenDialog("Select File(s) to restore",$handsAppData & "FormBackup\","All Files (*.*)",$FD_FILEMUSTEXIST+$FD_PATHMUSTEXIST+$FD_MULTISELECT)
	If Not $files Then
		Return 1
	EndIf
	dim $aFiles[1]
	$aFiles[0] = $files
	If StringInStr($files,"|") Then
		_ArrayPop($aFiles)
	    $compactFiles = StringSplit($files,"|")
		For $i = 2 To Ubound($compactFiles) - 1
			_ArrayAdd($aFiles,$compactFiles[1] & "\" & $compactFiles[$i])
		Next
	EndIf

	dim $sFilePath = ''
	dim $sDrive = ''
	dim $sDir = ''
	dim $sFileName = ''
	dim $sExtension = ''
	For $i = 0 to Ubound($aFiles) - 1
		_PathSplit($aFiles[$i],$sDrive,$sDir,$sFileName,$sExtension)
		$dst = $rootPath & $workBase & $workingPath & "\" & $sFileName
		if Not StringRegExp($sExtension,"\d") Then
		    $dst = $dst & $sExtension
		EndIf
		If FileCopy($aFiles[$i],$dst) Then
			FileSetAttrib($dst,"-R")
	    Else
			MsgBox(0,"HANDS Box","Could not copy: " & $sFileName)
	    EndIf
	Next
    RefreshMain()
    ShellExecute($rootPath & $workBase & $workingPath)
EndFunc