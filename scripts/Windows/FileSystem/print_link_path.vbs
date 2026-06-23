''' Prints file system link target path

''' USAGE:
'''   print_link_path.vbs <path>

''' CAUTION:
'''   The `WScript.std[out|err].WriteLine STR` functions has issue with the
'''   last line desynchronization between streams.
'''   To workaround use `WScript.std[out|err].Write STR & vbCrLf` instead.

Function FixStrToPrint(str)
  Dim new_str : new_str = ""
  Dim i, Char, CharAsc

  For i = 1 To Len(str)
    Char = Mid(str, i, 1)
    CharAsc = Asc(Char)

    ' NOTE:
    '   `&H3F` - is not printable unicode origin character which can not pass through the stdout redirection.
    If CharAsc <> &H3F Then
      new_str = new_str & Char
    Else
      new_str = new_str & "?"
    End If
  Next

  FixStrToPrint = new_str
End Function

Sub PrintOrEchoLine(str)
  On Error Resume Next
  WScript.stdout.Write str & vbCrLf
  If err = 5 Then ' Access is denied
    WScript.stdout.Write FixStrToPrint(str) & vbCrLf
  ElseIf err = &h80070006& Then
    WScript.Echo str
  End If
  On Error Goto 0
End Sub

On Error Resume Next

Dim LinkPath : LinkPath = WScript.Arguments(0)

Dim objFS : Set objFS = CreateObject("Scripting.FileSystemObject")
Dim objShellApp : Set objShellApp = CreateObject("Shell.Application")

Dim ParentPath : ParentPath = objFS.GetParentFolderName(LinkPath)

Dim objNamespace, objFile

If Len(ParentPath) > 0 Then
  Set objNamespace = objShellApp.Namespace(ParentPath)
  Set objFile = objNamespace.ParseName(objFS.GetFileName(LinkPath))
Else
  Set objNamespace = objShellApp.Namespace(LinkPath)
  Set objFile = objNamespace.Self
End If

If InStr(objNamespace.GetDetailsOf(objFile, 6), "L") > 0 Then ' `Attributes`
  If InStr(objNamespace.GetDetailsOf(objFile, 6), "D") > 0 Then ' `Attributes`
    PrintOrEchoLine objNamespace.GetDetailsOf(objFile, 182) ' `Folder path`
  Else
    PrintOrEchoLine objNamespace.GetDetailsOf(objFile, 194) ' `Link target`
  End If
End If
