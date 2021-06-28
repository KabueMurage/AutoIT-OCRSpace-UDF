; #include <array.au3>
#include-once
#include "Json.au3"

; =========================================================
; Title ...............: _OCRSpace_UDF.au3
; Author ..............: Kabue Murage
; AutoIt Version ......: 3.3.14.5
; UDF Version .........: v1.0
; OCRSpace API Version : V3.50
; Language ............: English
; Description .........: Convert image to text using the OCRSpace API version 3.50
; Forums ..............: Mr.Km
; Contact .............: dennisk@zainahtech.com
; Remarks .............: To view all documentation go to https://ocr.space/OCRAPI
; Resources ...........: https://ocr.space/OCRAPI
; =========================================================



; #CURRENT# =====================================================================================================================
;_OCRSpace_SetUpOCR
;_OCRSpace_ImageGetText
; ===============================================================================================================================


; #FUNCTION# ================================================================================================================================
; Name...........:  _OCRSpace_SetUpOCR()
; Author ........:  Kabue Murage
; Description ...:  Validates and Sets up the OCR settings in retrospect.
;
; Syntax.........:  _OCRSpace_SetUpOCR($s_APIKey , $i_OCREngineID = 1 , $b_IsTable = False, $b_DetectOrientation = True, $s_LanguageISO = "eng", $b_IsOverlayRequired = False, $b_AutoScaleImage = False, $b_IsSearchablePdfHideTextLayer = False)
;
; Parameters ....:
; $s_APIKey              - [Required] The key provided by OCRSpace. (http://eepurl.com/bOLOcf)
; $i_OCREngineID         - [Optional] The OCR Engine to use. Can either be 1 or 2 (DEFAULT : 1)
;               Features of OCR Engine 1:
;                        - Supports more languages (including Asian languages like Chinese, Japanese and Korean)
;                        - Faster.
;                        - Supports larger images.
;                        - Multi-Page TIFF scan support.
;               Features of OCR Engine 2:
;                        - Western Latin Character languages only (English, German, French,...)
;                        - Language auto-detect. It does not matter what OCR language you select, as long as it uses Latin characters
;                          Usually better at single number OCR, single character OCR and alphanumeric OCR in general
;                          (e. g. SUDOKO, Dot Matrix OCR, MRZ OCR, Single digit OCR, Missing 1st letter after OCR, ... )
;                        - Usually better at special characters OCR like @+-...
;                        - Usually better with rotated text (Forum: Detect image spam)
;                        - Image size limit 5000px width and 5000px height
;
; $b_IsTable             - [Optional] True or False (DEFAULT : False)
;                          If set to true, the OCR logic makes sure that the parsed text result is always returned line by line. This switch
;                          is recommended for table OCR, receipt OCR, invoice processing and all other type of input documents that have a table
;                          like structure.
;
; $b_DetectOrientation   - [Optional] True or False (DEFAULT : True)
;                          If set to true, the image is correctly rotated the TextOrientation parameter is
;                          returned in the JSON response. If the image is not rotated, then TextOrientation=0
;                          otherwise it is the degree of the rotation, e. g. "270".
;
; $s_LanguageISO         - [Optional] (DEFAULT : eng)
;                          Language used for OCR. If no language is specified, English eng is taken as default.
;                          IMPORTANT: The API uses an ISO 639-2 Code, so it's explictly limited to 3 characters, never less!
;               Engine 1:
;                          Arabic=ara, Bulgarian=bul, Chinese(Simplified)=chs, Chinese(Traditional)=cht, Croatian = hrv, Czech = cze
;                          Danish = dan, Dutch = dut, English = eng, Finnish = fin, French = fre, German = ger, Greek = gre, Hungarian = hun
;                          Korean = kor, Italian = ita, Japanese = jpn, Polish = pol ,Portuguese = por, Russian = rus, Slovenian = slv
;                          Spanish = spa, Swedish = swe, Turkish = tur
;               Engine 2:
;                         Engine2 has automatic Western language detection, so this value will be ignored.
;
; $b_IsOverlayRequired  - [Optional] Default = False.  If true, returns the coordinates of the bounding boxes for each word.
;                         If false, the OCR'ed text is returned only as a
;                         text block (THIS MAKES THE JSON REPONSE SMALLER). Overlay data can be used, for example, to show text over the image.
;
; $b_AutoScaleImage     - [Optional] True or False (DEFAULT : False)
;                         If set to true, the image is upscaled. This can improve the OCR result significantly,
;                         especially for low-resolution PDF scans. The API uses scale=false by default.
;
; $b_IsSearchablePdfHideTextLayer
;                       - [Optional] True or False (DEFAULT : False)
;                         If true, the text layer is hidden (not visible)
;
;
; Return values .: Success : Returns an array to use in _OCRSpace_ImageGetText @error set to 0.
;                : Failure : @error flag set to non zero on failure.
; Modified.......:
; Remarks .......:
; Related .......: _OCRSpace_ImageGetText()
; Link ..........:
; Example .......: 0
; ============================================================================================================================================
Func _OCRSpace_SetUpOCR($s_APIKey, $i_OCREngineID = 1, $b_IsTable = False, $b_DetectOrientation = True, $s_LanguageISO = "eng", $b_IsOverlayRequired = False, $b_AutoScaleImage = False, $b_IsSearchablePdfHideTextLayer = False, $b_IsCreateSearchablePdf = False)
	Local $a_lSetUp[9][2]
	$a_lSetUp[0][0] = "apikey"
	$a_lSetUp[0][1] = $s_APIKey
	$a_lSetUp[1][0] = "detectOrientation"
	$a_lSetUp[1][1] = (IsBool($b_DetectOrientation) ? $b_DetectOrientation : False)
	$a_lSetUp[2][0] = "OCREngine"
	$a_lSetUp[2][1] = ((Int($i_OCREngineID) = 2) ? 2 : 1)
	$a_lSetUp[3][0] = "isOverlayRequired"
	$a_lSetUp[3][1] = (IsBool($b_IsOverlayRequired) ? $b_IsOverlayRequired : False)
	$a_lSetUp[4][0] = "language" ; ISO (632-B Lang Prefix), length 3 ..
	$a_lSetUp[4][1] = (((StringIsAlpha($s_LanguageISO) And StringLen($s_LanguageISO) = 3)) ? $s_LanguageISO : "eng")
	$a_lSetUp[5][0] = "isCreateSearchablePdf"
	$a_lSetUp[5][1] = (IsBool($b_IsCreateSearchablePdf) ? $b_IsCreateSearchablePdf : False)
	$a_lSetUp[6][0] = "isSearchablePdfHideTextLayer"
	$a_lSetUp[6][1] = (IsBool($b_IsSearchablePdfHideTextLayer) ? $b_IsSearchablePdfHideTextLayer : False)
	$a_lSetUp[7][0] = "scale"
	$a_lSetUp[7][1] = (IsBool($b_AutoScaleImage) ? $b_AutoScaleImage : False)
	$a_lSetUp[8][0] = "isTable"
	$a_lSetUp[8][1] = (IsBool($b_IsTable) ? $b_IsTable : False)

	Return SetError(((IsArray($a_lSetUp) = 1) ? 0 : 1), UBound($a_lSetUp), $a_lSetUp)
EndFunc   ;==>_OCRSpace_SetUpOCR

; #FUNCTION# =======================================================================================================================
; Title .........: _OCRSpace_ImageGetText
; Author ........: Kabue Murage
; Description ...: Retrieves text from an image using the OCRSpace API
; Syntax.........:  _OCRSpace_ImageGetText($aOCR_OptionsHandle, $sImage_UrlOrFQPN, $iReturnType = 0, $sURLVar = "")
; Link ..........:
; Parameters ....:  $aOCR_OptionsHandle      - The reference array variable  as created by _OCRSpace_SetUpOCR()
;                :  $sImage_UrlOrFQPN        - A valid : Path to an image you want OCR'ed from your PC or URL to an image you want OCR'ed.
;
; Return values .: Success : Returns the detected text.
;                          -  If a searchable PDF was requested ,its url will be assigned to the string $sURLVar, so to get it evaluate it.
;                          -  @error flag set to 111 if no error occoured.
;                          -  @extended is set to the Processing Time In Milliseconds
;
;                : Failure : Returns "" and @error flag set to non-zero ;
;                :       1 - If $aOCR_OptionsHandle is not an array variable.
;                :       2 - If $sImage_UrlOrFQPN is not a valid Image or URL.
;                :       3 - If an error occurs opening a local file specified.
;                :       4 - If a searchable pdf was requested and a string to declare the result url is undefined.
;                :       5 - An unsupported filetype parsed.
;                        6 - Failed to create http object
;
;
; Remarks .......: - Setup your OCR options beforehand using _OCRSpace_SetUpOCR. Also note that the URL method is easy and fast to use.
;
;                  - StringLeft(@error, 1) shows if OCR Engine completed successfully, partially or failed with error. 
;                        1 - Parsed Successfully (Image / All pages parsed successfully)
;                        2 - Parsed Partially (Only few pages out of all the pages parsed successfully)
;                        3 - Image / All the PDF pages failed parsing (This happens mainly because the OCR engine fails to parse an image)
;                        4 - Error occurred when attempting to parse (This happens when a fatal error occurs during parsing )
;
; ===============================================================================================================================
Func _OCRSpace_ImageGetText($aOCR_OptionsHandle, $sImage_UrlOrFQPN, $iReturnType = 0, $sURLVar = "")
	If Not (IsArray($aOCR_OptionsHandle)) Then Return SetError(1, 0, "")
	Local $s_lExt, $s_lParams__
	Local $i_lAPIRespStatusCode__
	Local $d_ImgBinDat__
	Local $h_lFileOpen__

	; If a ssearchable pdf was requested and the URL string to be set to is undefined.
	If ($aOCR_OptionsHandle[5][1]) Then   ; Searchable pdf url was requested,
		If $sURLVar = "" Then Return SetError(4, 0, "")
	EndIf
	$h_lRequestObj__ = Null

	If (FileExists($sImage_UrlOrFQPN) And StringInStr(FileGetAttrib($sImage_UrlOrFQPN), "D") = 0) Then
		$s_lExt = (StringTrimLeft($sImage_UrlOrFQPN, StringInStr($sImage_UrlOrFQPN, ".", 0, -1)))
        Switch $s_lExt
            Case "PDF", "GIF", "PNG", "JPG", "TIF", "BMP", "PDF"
                ; Supported image file formats are png, jpg (jpeg), gif, tif (tiff) and bmp.
                ; For document ocr, the api supports the Adobe PDF format. Multi-page TIFF files are supported.
            Case Else
                Return SetError(5, 0, "")
        EndSwitch

		$h_lFileOpen__ = FileOpen($sImage_UrlOrFQPN, 16)
		If $h_lFileOpen__ = "-1" Then Return SetError(3, 0, "")
		$d_ImgBinDat__ = FileRead($h_lFileOpen__)
		FileClose($h_lFileOpen__)
		$s_lb64Dat__ = _Base64Encode($d_ImgBinDat__)
		$s_lEncb64Dat__ = __URLEncode_($s_lb64Dat__)

		$h_lRequestObj__ = __POSTObjCreate()
		if $h_lRequestObj__ = "-1" then Return SetError(6, 0 , "")

		$h_lRequestObj__.Open("POST", "https://api.ocr.space/parse/image", False)
		$s_lParams__ = "base64Image=data:image/" & $s_lExt & ";base64," & $s_lEncb64Dat__ & "&"
		; Append all Prameters..
		For $i = 1 To UBound($aOCR_OptionsHandle) - 1
			$s_lParams__ &= $aOCR_OptionsHandle[$i][0] & "=" & StringLower($aOCR_OptionsHandle[$i][1]) & "&"
		Next
		$s_lParams__ = StringTrimRight($s_lParams__, 1)

		$h_lRequestObj__.SetRequestHeader($aOCR_OptionsHandle[0][0], $aOCR_OptionsHandle[0][1])
		$h_lRequestObj__.SetRequestHeader("Content-Type", "application/x-www-form-urlencoded")
		$h_lRequestObj__.Send($s_lParams__)

	ElseIf __IsURL_($sImage_UrlOrFQPN) Then
		; The important limitation of the GET api endpoint is it only allows image and
		; PDF submissions via the URL method as only HTTP POST requests can supply additional
		; data to the server in the message body.
		$s_lExt = (StringTrimLeft($sImage_UrlOrFQPN, StringInStr($sImage_UrlOrFQPN, ".", 0, -1)))
         Switch $s_lExt
            Case "PDF", "GIF", "PNG", "JPG", "BMP", "PDF"
                ; Supported image file formats are png, jpg (jpeg), gif, tif (tiff) and bmp.
                ; For document ocr, the api supports the Adobe PDF format. Multi-page TIFF files are supported.
            Case Else
                Return SetError(5, 0, "")
        EndSwitch

		$h_lRequestObj__ = _GETObjCreate()
		if $h_lRequestObj__ = "-1" then Return SetError(6, 0 , "")

		; Every option for this api call is to be parsed inside the URL! So , all the parameters can
		; be appended to create a valid url. So by design, a GET api cannot support file uploads
		; (file parameter) or BASE64 strings (base64image).
		$s_lParams__ = "https://api.ocr.space/parse/ImageUrl?" & $aOCR_OptionsHandle[0][0] & "=" & $aOCR_OptionsHandle[0][1] & "&url=" & $sImage_UrlOrFQPN & "&"
		For $i = 1 To UBound($aOCR_OptionsHandle) - 1
			$s_lParams__ &= StringLower($aOCR_OptionsHandle[$i][0] & "=" & $aOCR_OptionsHandle[$i][1] & "&")
		Next
		; Trim a trailing appended ampersand.
		$s_lParams__ = StringTrimRight($s_lParams__, 1)

		$h_lRequestObj__.Open("GET", $s_lParams__, False)
		$h_lRequestObj__.Send()
	Else
		; wtf ?+
		Return SetError(2, 0, "")
	EndIf

	$h_lRequestObj__.WaitForResponse()
	$s_lAPIResponseText__ = $h_lRequestObj__.ResponseText
	$i_lAPIRespStatusCode__ = $h_lRequestObj__.Status

	; Release the object.
	$h_lRequestObj__ = Null

	; utf-8 charset? #include <WinAPIConv.au3>
	; $s_lAPIResponseText__ = _WinAPI_WideCharToMultiByte($s_lAPIResponseText__, 65001)

	Switch Int($i_lAPIRespStatusCode__)
		Case 200
			If ($aOCR_OptionsHandle[3][1]) And ($iReturnType <> 0) Then
				; $aOCR_OptionsHandle[3][1] = ..
				; ConsoleWrite("Overlay info requested. Returning the json" & @CRLF )
				Return SetError(0, 0, $s_lAPIResponseText__)
			EndIf
			Local $o_lJson__ = _JSON_Parse($s_lAPIResponseText__)
			If Not @error Then
				$__ErrorCode_ = Null
				; Get the parsed text.
				$s_lDetectedTxt__ = _JSON_Get($o_lJson__, "ParsedResults[0].ParsedText")            ; Returned
				$s_lProcessingTimeInMs = _JSON_Get($o_lJson__, "ProcessingTimeInMilliseconds")      ; Set to @extended.

				; The exit code shows if OCR completed successfully, partially or failed with error.
				$i_lOCREngineExitCode = _JSON_Get($o_lJson__, "OCRExitCode")                     ; Set to 1 if completed all successfully
				$__ErrorCode_ &= $i_lOCREngineExitCode
				; append to errorcode.

				; The exit code returned by the parsing engine. Set to extended..
				$i_lFileParseExitCode = _JSON_Get($o_lJson__, "ParsedResults[0].FileParseExitCode")
				$i_lFileParseExitCode = (StringLeft($i_lFileParseExitCode, 1) = "-") ? StringTrimLeft($i_lFileParseExitCode, 1) : $i_lFileParseExitCode
				$__ErrorCode_ &= $i_lFileParseExitCode
				; 0: File not found
				; 1: Success
				; 10: OCR Engine Parse Error
				; 20: Timeout
				; 30: Validation Error
				; 99: Unknown Error

				$s__lSearchablePDFURL_ = _JSON_Get($o_lJson__, "SearchablePDFURL")
				Assign($sURLVar, $s__lSearchablePDFURL_, 2)

				$i_lErrorOnProcessing = (_JSON_Get($o_lJson__, "IsErroredOnProcessing") ? 0 : 1) ; IsErroredOnProcessing is initially bool.
				$__ErrorCode_ &= $i_lErrorOnProcessing

				Switch $iReturnType
					Case 0
						Return SetError($__ErrorCode_, $s_lProcessingTimeInMs, $s_lDetectedTxt__)
					Case Else
                        ; TODO : Form array for x/y word coordinates if bool isOverlayRequired is True ($aOCR_OptionsHandle[3][1]) 
                        ; TODO : Currently returns a full json if isOverlayRequired
						Return SetError($__ErrorCode_, $s_lProcessingTimeInMs, $s_lDetectedTxt__)
				EndSwitch
			EndIf
		Case Else
	EndSwitch
	Return SetError(1, $i_lAPIRespStatusCode__, $s_lAPIResponseText__)
EndFunc   ;==>_OCRSpace_ImageGetText

; https://www.autoitscript.com/forum/topic/117155-q-islink-function/
Func __IsURL_($sURL)
	$a = StringRegExp($sURL, "^(?#Protocol)(?:(?:ht|f)tp(?:s?)\:\/\/|~/|/)?(?#Username:Password)(?:\w+:\w+@)?(?#Subdomains)(?:(?:[-\w]+\.)+(?#TopLevel Domains)(?:com|org|net|gov|mil|biz|info|mobi|name|aero|jobs|museum|travel|[a-z]{2}))(?#Port)(?::[\d]{1,5})?(?#Directories)(?:(?:(?:/(?:[-\w~!$+|.,=]|%[a-f\d]{2})+)+|/)+|\?|#)?(?#Query)(?:(?:\?(?:[-\w~!$+|.,*:]|%[a-f\d{2}])+=(?:[-\w~!$+|.,*:=]|%[a-f\d]{2})*)(?:&(?:[-\w~!$+|.,*:]|%[a-f\d{2}])+=(?:[-\w~!$+|.,*:=]|%[a-f\d]{2})*)*)*(?#Anchor)(?:#(?:[-\w~!$+|.,*:=]|%[a-f\d]{2})*)?$", 3)
	If @error = 0 Then Return True
	Return False
EndFunc   ;==>__IsURL_

Func __URLEncode_($urlText)
	$url = ""
	For $i = 1 To StringLen($urlText)
		$acode = Asc(StringMid($urlText, $i, 1))
		Select
			Case ($acode >= 48 And $acode <= 57) Or ($acode >= 65 And $acode <= 90) Or ($acode >= 97 And $acode <= 122)
				$url = $url & StringMid($urlText, $i, 1)
			Case $acode = 32
				$url = $url & "+"
			Case Else
				$url = $url & "%" & Hex($acode, 2)
		EndSelect
	Next
	Return $url
EndFunc   ;==>__URLEncode_

Func IsNull($vKeyword)
	Return IsKeyword($vKeyword) = $KEYWORD_NULL
EndFunc   ;==>IsNull

Func _Base64Encode($Data, $LineBreak = 76)
	Local $Opcode = '0x5589E5FF7514535657E8410000004142434445464748494A4B4C4D4E4F505152535455565758595A61626364656' & _
			'66768696A6B6C6D6E6F707172737475767778797A303132333435363738392B2F005A8B5D088B7D108B4D0CE98F0000000FB6' & _
			'33C1EE0201D68A06880731C083F901760C0FB6430125F0000000C1E8040FB63383E603C1E60409C601D68A0688470183F9017' & _
			'6210FB6430225C0000000C1E8060FB6730183E60FC1E60209C601D68A06884702EB04C647023D83F90276100FB6730283E63F' & _
			'01D68A06884703EB04C647033D8D5B038D7F0483E903836DFC04750C8B45148945FC66B80D0A66AB85C90F8F69FFFFFFC6070' & _
			'05F5E5BC9C21000'
	Local $CodeBuffer = DllStructCreate('byte[' & BinaryLen($Opcode) & ']')
	DllStructSetData($CodeBuffer, 1, $Opcode)
	$Data = Binary($Data)
	Local $Input = DllStructCreate('byte[' & BinaryLen($Data) & ']')
	DllStructSetData($Input, 1, $Data)
	$LineBreak = Floor($LineBreak / 4) * 4
	Local $OputputSize = Ceiling(BinaryLen($Data) * 4 / 3)
	$OputputSize = $OputputSize + Ceiling($OputputSize / $LineBreak) * 2 + 4

	Local $Ouput = DllStructCreate('char[' & $OputputSize & ']')
	DllCall('user32.dll', 'none', 'CallWindowProc', 'ptr', DllStructGetPtr($CodeBuffer), _
			'ptr', DllStructGetPtr($Input), _
			'int', BinaryLen($Data), _
			'ptr', DllStructGetPtr($Ouput), _
			'uint', $LineBreak)
	Return DllStructGetData($Ouput, 1)
EndFunc   ;==>_Base64Encode


; Returns a post object handle.
Func __POSTObjCreate()
	Local $o_lHTTP = ObjCreate("winhttp.winhttprequest.5.1")
	Return SetError(@error, 0, ((IsObj($o_lHTTP) = 1) ? $o_lHTTP : -1))
EndFunc   ;==>__POSTObjCreate

; Returns a post object handle.
Func _GETObjCreate()
	Local $o_lHTTP
	$o_lHTTP = ObjCreate("winhttp.winhttprequest.5.1")
	Return SetError(@error, 0, ((IsObj($o_lHTTP) = 1) ? $o_lHTTP : -1))
EndFunc   ;==>_GETObjCreate
