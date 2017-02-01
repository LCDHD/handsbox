;******************************************************************************
;
; FDF Libraries, for working with PDF Form Data Files
;
; COPYRIGHT (C) 2016-2017
; BY THE LAKE CUMBERLAND DISTRICT HEALTH DEPARTMENT (www.lcdhd.org)
; ORIGINAL CODE BY DANIEL MCFEETERS (www.fiforms.net)
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

#include <Array.au3>

dim $masterFDFTemplate[5]


$masterFDFTemplate[0] = '%FDF-1.2' & chr(13) & '%' & _
		chr(226) & chr(227) & chr(207) & chr(211) & @CRLF & _
		'1 0 obj' & @CRLF & _
		'<</Type /Catalog' & @CRLF & _
		'/FDF <</F ('

$masterFDFTemplate[1] =	')' & @CRLF & _
		'/Fields ['

$masterFDFTemplate[2] = _
		']' & @CRLF & _
		'>>' & @CRLF & _
		'>>' & @CRLF & _
		'endobj' & @CRLF

$masterFDFTemplate[3] = _
		'xref' & @CRLF & _
		'0 2' & @CRLF & _
		'0000000000 65535 f' & @CRLF & _
		'0000000016 00000 n' & @CRLF & _
		'trailer' & @CRLF & _
		'<</Root 1 0 R' & @CRLF & _
		'/Size 2' & @CRLF & _
		'>>' & @CRLF & _
		'startxref' & @CRLF

$masterFDFTemplate[4] = _
		@CRLF & _
		'%%EOF' & @CRLF

Func FDFSearchReplace($fdfdata,$type,$search,$replace)
	$fdfdata = StringReplace($fdfdata,"/" & $type & " (" & $search & ")","/" & $type & " (" & $replace & ")")

    ; At the bottom part of the FDF file, we expect there to be a line starting with "xref". We cut the file off here,
	; and replace it with our built-in template, calculating the length of the top portion so the FDF file is valid

	$fdfdata = StringMid($fdfdata, 1, StringInStr($fdfdata, @CRLF & "xref") + 1)
    $fdfdata = $fdfdata & $masterFDFTemplate[3] & StringLen($fdfdata) & $masterFDFTemplate[4]
    return $fdfdata
EndFunc


Func CreateFDF($pdfFile,$aFields,$aValues)
	$innerFDF = $masterFDFTemplate[0] & $pdfFile & $masterFDFTemplate[1]
	$i = 0
	While $i < UBound($aFields)
		    $innerFDF = $innerFDF & _
				'<</T (' & $aFields[$i] & ')' & @CRLF & _
				'/V (' & $aValues[$i] & ')' & @CRLF & _
				'>> '
		$i += 1
	Wend
	$innerFDF = $innerFDF & $masterFDFTemplate[2]

	$fullFDF = $innerFDF & $masterFDFTemplate[3] & StringLen($innerFDF) & $masterFDFTemplate[4]
	return $fullFDF
EndFunc

Func ParseFDF($fdfdata, ByRef $aFields, ByRef $aValues)
	$rslt = StringRegExp($fdfdata,"(?Uis)<<(.*)>>",$STR_REGEXPARRAYGLOBALFULLMATCH,StringInStr($fdfdata,@CRLF & "/Fields"))
	if @error Then
		return @error
	EndIf
	For $r in $rslt
	    $field = StringRegExp($r[1],"\/([TV])\s\((.*)\)",$STR_REGEXPARRAYGLOBALFULLMATCH)
		if @error or UBound($field) < 1 Then
			ContinueLoop
		EndIf
		$fname = ""
		$fvalue = ""
        For $element in $field
			if $element[1] = "T" Then
				$fname = $element[2]
			EndIf
			if $element[1]= "V" Then
				$fvalue = $element[2]
			EndIf
		Next
		if not $fname = "" Then
			_ArrayAdd($aFields,$fname)
			_ArrayAdd($aValues,$fvalue)
		EndIf
	Next
	if UBound($aFields) > 0 Then
		return 0
	Else
	    return -1
	EndIf





EndFunc
