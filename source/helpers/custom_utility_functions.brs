'******************************************************
'Return Escaped Str
'******************************************************
Function HttpEncode(str As String) As String
    o = CreateObject("roUrlTransfer")
    return o.Escape(str)
End Function
