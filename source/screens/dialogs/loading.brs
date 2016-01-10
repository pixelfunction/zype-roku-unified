'*********************************************************************'
'*  ShowPleaseWait - put up a please wait screen                     *'
'*********************************************************************'
Function ShowPleaseWait(title As dynamic, text As dynamic) As Object
    if not isstr(title) title = ""
    if not isstr(text) text = ""

    port = CreateObject("roMessagePort")
    dialog = invalid

    REM the OneLineDialog renders a single line of text better
    REM than the MessageDialog.
    if text = ""
        dialog = CreateObject("roOneLineDialog")
    else
        dialog = CreateObject("roMessageDialog")
        dialog.SetText(text)
    endif

    dialog.SetMessagePort(port)
    dialog.SetTitle(title)
    dialog.ShowBusyAnimation()
    dialog.Show()
    return dialog
End Function
