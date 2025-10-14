''' Disables all the task triggers in the Task Scheduler.

''' USAGE:
'''   disable_tasksched_triggers.vbs <TaskPath>

Function IsNothing(obj)
  If IsEmpty(obj) Then
    IsNothing = True
    Exit Function
  End If
  If obj Is Nothing Then
    IsNothing = True
  Else
    IsNothing = False
  End If
End Function

Function IsEmptyArg(args, index)
  ''' Based on: https://stackoverflow.com/questions/4466967/how-can-i-determine-if-a-dynamic-array-has-not-be-dimensioned-in-vbscript/4469121#4469121
  On Error Resume Next
  Dim args_ubound : args_ubound = UBound(args)
  If Err = 0 Then
    If args_ubound >= index Then
      ' CAUTION:
      '   Must be a standalone condition.
      '   Must be negative condition in case of an invalid `index`
      If Not (Len(args(index)) > 0) Then
        IsEmptyArg = True
      Else
        IsEmptyArg = False
      End If
    Else
      IsEmptyArg = True
    End If
  Else
    ' Workaround for `WScript.Arguments`
    Err.Clear
    Dim num_args : num_args = args.count
    If Err = 0 Then
      If index < num_args Then
        ' CAUTION:
        '   Must be a standalone condition.
        '   Must be negative condition in case of an invalid `index`
        If Not (Len(args(index)) > 0) Then
          IsEmptyArg = True
        Else
          IsEmptyArg = False
        End If
      Else
        IsEmptyArg = True
      End If
    Else
      IsEmptyArg = True
    End If
  End If
  On Error Goto 0
End Function

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
  WScript.stdout.WriteLine str
  If err = 5 Then ' Access is denied
    WScript.stdout.WriteLine FixStrToPrint(str)
  ElseIf err = &h80070006& Then
    WScript.Echo str
  End If
  On Error Goto 0
End Sub

Sub PrintOrEchoErrorLine(str)
  On Error Resume Next
  WScript.stderr.WriteLine str
  If err = 5 Then ' Access is denied
    WScript.stderr.WriteLine FixStrToPrint(str)
  ElseIf err = &h80070006& Then
    WScript.Echo str
  End If
  On Error Goto 0
End Sub

ReDim cmd_args(WScript.Arguments.Count - 1)

Dim arg
Dim j : j = 0

For i = 0 To WScript.Arguments.Count-1 : Do ' empty `Do-Loop` to emulate `Continue`
  arg = WScript.Arguments(i)

  ' read command line flags here...

  cmd_args(j) = arg

  j = j + 1
Loop While False : Next

ReDim Preserve cmd_args(j - 1)

' MsgBox Join(cmd_args, " ")

If IsEmptyArg(cmd_args, 0) Then
  PrintOrEchoErrorLine WScript.ScriptName & ": error: <TaskPath> argument is not defined."
  WScript.Quit 1
End If

Dim TaskPath : TaskPath = cmd_args(0)

Dim objFS : Set objFS = CreateObject("Scripting.FileSystemObject")
Dim objSS : Set objSS = CreateObject("Schedule.Service")

objSS.Connect()

Dim TaskParentFolder : TaskParentFolder = objFS.GetParentFolderName(TaskPath)
Dim objTaskParentFolder : If Len(TaskParentFolder) > 0 Then Set objTaskParentFolder = objSS.GetFolder(TaskParentFolder)

If IsNothing(objTaskParentFolder) Then
  PrintOrEchoErrorLine _
    WScript.ScriptName & ": error: task parent folder is undefined." & vbCrLf & _
    WScript.ScriptName & ": info: TaskParentFolder=`" & TaskParentFolder & "`"
  WScript.Quit 128
End If

Dim TaskName : TaskName = objFS.GetFileName(TaskPath)
Dim objTask : Set objTask = objTaskParentFolder.GetTask(TaskName)

If IsNothing(objTask) Then
  PrintOrEchoErrorLine _
    WScript.ScriptName & ": error: task is not found." & vbCrLf & _
    WScript.ScriptName & ": info: TaskPath=`" & TaskPath & "`"
  WScript.Quit 129
End If

Dim objTaskDefinition : Set objTaskDefinition = objTask.Definition

If IsNothing(objTaskDefinition) Then
  PrintOrEchoErrorLine _
    WScript.ScriptName & ": error: task definition is undefined." & vbCrLf & _
    WScript.ScriptName & ": info: TaskPath=`" & TaskPath & "`"
  WScript.Quit 130
End If

For i = 1 To objTaskDefinition.Triggers.Count
  objTaskDefinition.Triggers.Item(i).Enabled = vbFalse
Next

' Update task
objTaskParentFolder.RegisterTaskDefinition TaskName, objTaskDefinition, 4, "", "", 0, ""
