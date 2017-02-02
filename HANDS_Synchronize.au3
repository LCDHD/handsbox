;******************************************************************************
;
; HANDS BOX
; HANDS_Synchronize script
;
;
; COPYRIGHT (C) 2016 BY THE LAKE CUMBERLAND DISTRICT HEALTH DEPARTMENT
; ORIGINAL CODE BY DANIEL MCFEETERS (www.fiforms.net)
; LATEST VERSION AVAILABLE FROM https://oss.lcdhd.org/handsbox/
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