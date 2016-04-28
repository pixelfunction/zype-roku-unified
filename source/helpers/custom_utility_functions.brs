'******************************************************
'Return Escaped Str
'******************************************************
Function HttpEncode(str As String) As String
    o = CreateObject("roUrlTransfer")
    return o.Escape(str)
End Function

'******************************************************
' Set a unique device id
'******************************************************
Function set_device_id() As Void
  ' print "checking registry token"
  m.device_id = ""
  if RegRead("RegToken", "Authentication") <> invalid
    m.device_id = RegRead("RegToken", "Authentication")
  else
    date = CreateObject("roDateTime")
    timestamp = date.AsSeconds().ToStr()
    device = CreateObject("roDeviceInfo")
    uniqueId = device.GetDeviceUniqueId() + date.AsSeconds().ToStr()
    RegWrite("RegToken", uniqueId, "Authentication")
    m.device_id = RegRead("RegToken", "Authentication")
  end if
End Function

'******************************************************
' Set up Tool Bar Items for Home Screen
'******************************************************
Function grid_toolbar() as object
  toolbar = {name: m.config.toolbar_title, tools: []}
  ' @tobedone
  ' We can add extra items to the toolbar if we need
  ' Example
  ' {
  '   Title: "Terms And Conditions",
  '   SDPosterUrl: "",
  '   HDPosterUrl: "",
  '   Description: "Terms And Conditions May Apply",
  '   function_name: terms_screen
  ' }
  toolbar.tools = [
    {
      Title: m.config.search_title,
      SDPosterUrl: m.images.search_poster_sd,
      HDPosterUrl: m.images.search_poster_hd,
      Description: m.config.search_description,
      function_name: search_screen
    },
    {
      Title: m.config.info_title,
      SDPosterUrl: m.images.info_poster_sd,
      HDPosterUrl: m.images.info_poster_hd,
      Description: m.config.info_description,
      function_name: info_screen
    },
  ]
  return toolbar
End Function

'******************************************************
' String Casting
'******************************************************
Function ToString(variable As Dynamic) As String
    If Type(variable) = "roInt" Or Type(variable) = "roInteger" Or Type(variable) = "roFloat" Or Type(variable) = "Float" Then
        Return Str(variable).Trim()
    Else If Type(variable) = "roBoolean" Or Type(variable) = "Boolean" Then
        If variable = True Then
            Return "True"
        End If
        Return "False"
    Else If Type(variable) = "roString" Or Type(variable) = "String" Then
        Return variable
    Else
        Return Type(variable)
    End If
End Function

'******************************************************
' Type Check
'******************************************************

Function IsFunction(value As Dynamic) As Boolean
    Return IsValid(value) And GetInterface(value, "ifFunction") <> invalid
End Function

Function IsBoolean(value As Dynamic) As Boolean
    Return IsValid(value) And GetInterface(value, "ifBoolean") <> invalid
End Function

Function IsInteger(value As Dynamic) As Boolean
    Return IsValid(value) And GetInterface(value, "ifInt") <> invalid And (Type(value) = "roInt" Or Type(value) = "roInteger" Or Type(value) = "Integer")
End Function

Function IsDouble(value As Dynamic) As Boolean
    Return IsValid(value) And (GetInterface(value, "ifDouble") <> invalid Or (Type(value) = "roDouble" Or Type(value) = "roIntrinsicDouble" Or Type(value) = "Double"))
End Function

Function IsArray(value As Dynamic) As Boolean
    Return IsValid(value) And GetInterface(value, "ifArray") <> invalid
End Function

Function IsAssociativeArray(value As Dynamic) As Boolean
    Return IsValid(value) And GetInterface(value, "ifAssociativeArray") <> invalid
End Function

Function IsString(value As Dynamic) As Boolean
    Return IsValid(value) And GetInterface(value, "ifString") <> invalid
End Function

Function IsDateTime(value As Dynamic) As Boolean
    Return IsValid(value) And (GetInterface(value, "ifDateTime") <> invalid Or Type(value) = "roDateTime")
End Function

Function IsValid(value As Dynamic) As Boolean
    Return Type(value) <> "<uninitialized>" And value <> invalid
End Function

'******************************************************
' String Casting
'******************************************************
Function ceiling(x) as Integer
  i = int(x)
  if i < x then i = i + 1
  return i
End Function

'******************************************************
' Truncate a String To the desired length
'******************************************************

Function Truncate(words As String, length As Integer, ellipsis As Boolean) as String
    truncated = ""

    If words.Len() > length
        truncated = left(words, length)

        If ellipsis
            truncated = truncated + "..."
        End If
    Else
        truncated = words
    End If

    Return truncated
End Function
