;******************************************************************************
;
; HANDS BOX
; HANDS_Synchronize script
;
; COPYRIGHT (C) 2016 BY THE LAKE CUMBERLAND DISTRICT HEALTH DEPARTMENT
; ALL RIGHTS RESERVERD
;
; CODED BY DANIEL MCFEETERS
;
;******************************************************************************

; This small script is simply a connector that launches the sync process.
; This is EXE is installed in a temporary folder, and allows the HANDS box
; to be completely closed during the Sync process, so that it can be updated.

#include <HANDS_Custom.au3>

Func CheckProc()
	If ProcessExists("FreeFileSync.exe") or ProcessExists("FreeFileSync_64.exe") Then
		Return True
	Else
		Return False
	EndIf
EndFunc

FileDelete($syncBatchFile)
FileInstall("Sync Briefcase.ffs_batch",$syncBatchFile)

If CheckProc Then
	MsgBox(0,"HANDS Sync","Sync Already Running. Please wait and try again.")
	Exit 1
EndIf
ShellExecuteWait($syncBatchFile)
Sleep(5)

While CheckProc()
	Sleep(2)
WEnd

ShellExecuteWait($syncBatchFile)
Sleep(5)

While CheckProc()
	Sleep(2)
WEnd

FileDelete($syncBatchFile)

ShellExecute($exePath)