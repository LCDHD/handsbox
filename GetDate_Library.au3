;******************************************************************************
;
; HANDS BOX
; Date Functions
;
; COPYRIGHT (C) 2016-2017
; BY THE LAKE CUMBERLAND DISTRICT HEALTH DEPARTMENT (www.lcdhd.org)
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
#include <Date.au3>
#include <WindowsConstants.au3>

global $GetDate_DateEntered = -1
global $GetDate_Window
global $GetDate_Callback
global $GetDate_Today
global $GetDate_Yesterday
global $GetDate_OtherDateCtrl
global $GetDate_ParentWin

Func GetDate($title,$prompt,$callback,$parent)
	$GetDate_ParentWin = $parent
	GUISetState(@SW_LOCK,$parent)
	$GetDate_Window = GUICreate($title,250,250,-1,-1,$WS_POPUP + $WS_CAPTION + $WS_SYSMENU, $WS_EX_TOPMOST)
	$GETDate_Callback = $callback
	GUISetOnEvent($GUI_EVENT_CLOSE, "GetDateClose", $GetDate_Window)
	GUICtrlCreateLabel($prompt,30,10)
	$today = "Today: " & _DateTimeFormat(_NowCalcDate(),1)
	$GetDate_Today = _NowCalcDate()
	GUICtrlCreateButton($today,5,50,240,30)
	GUICtrlSetOnEvent(-1,"GetDateReturnToday")
	; Yesterday button will become Friday, not Sunday, if today is Monday.
	If StringInStr($today,"Monday") Then
		$yesterday =  _DateTimeFormat(_DateAdd("d",-3,_NowCalcDate()),1)
		$GetDate_Yesterday = _DateAdd("d",-3,_NowCalcDate())
		$otherdate = _DateAdd("d",-4,_NowCalcDate())
	Else
		$yesterday = "Yesterday: " &_DateTimeFormat(_DateAdd("d",-1,_NowCalcDate()),1)
		$GetDate_Yesterday = _DateAdd("d",-1,_NowCalcDate())
		$otherdate = _DateAdd("d",-2,_NowCalcDate())
	EndIf
	GUICtrlCreateButton($yesterday,5,100,240,30)
	GUICtrlSetOnEvent(-1,"GetDateReturnYesterday")

	GUICtrlCreateLabel("Or, choose a different date:",30,155)

	$GetDate_OtherDateCtrl = GUICtrlCreateDate($otherdate,10,175,230,30,$DTS_LONGDATEFORMAT)

	GUICtrlCreateButton("Use Selected Date",5,215,240,30)
	GUICtrlSetOnEvent(-1,"GetDateOK")
	GUISetState(@SW_SHOW, $GetDate_Window)
EndFunc

Func GetDateClose()
	GUIDelete($GetDate_Window)
	GUISetState(@SW_UNLOCK,$GetDate_ParentWin)
EndFunc

Func GetDateFinish()
	GUIDelete($GetDate_Window)
	GUISetState(@SW_UNLOCK,$GetDate_ParentWin)
    If Not $GetDate_DateEntered == -1 AND Not StringRegExp($GetDate_DateEntered, "^\d\d\d\d\-\d\d\-\d\d$") Then
		MsgBox(0, "Error", "Please enter the date as YYYY-MM-DD")
		Return 1
	EndIf
	Call($GetDate_Callback,$GetDate_DateEntered)
EndFunc

Func GetDateReturnToday()
	$GetDate_DateEntered = StringReplace($GetDate_Today, "/", "-")
	GetDateFinish()
EndFunc

Func GetDateReturnYesterday()
	$GetDate_DateEntered = StringReplace($GetDate_Yesterday, "/", "-")
	GetDateFinish()
EndFunc

Func GetDateOK()
	GUICtrlSendMsg($GetDate_OtherDateCtrl, $DTM_SETFORMAT, 0, "y")
	$year = GUICtrlRead($GetDate_OtherDateCtrl)
	GUICtrlSendMsg($GetDate_OtherDateCtrl, $DTM_SETFORMAT, 0, "M")
	$month = GUICtrlRead($GetDate_OtherDateCtrl)
	GUICtrlSendMsg($GetDate_OtherDateCtrl, $DTM_SETFORMAT, 0, "d")
	$day = GUICtrlRead($GetDate_OtherDateCtrl)
	$GetDate_DateEntered =  StringFormat("20%02s-%02s-%02s",$year,$month,$day)
	GetDateFinish()
EndFunc