function NWM_Utilities()
	this = {
		GetStringFromURL:	NWM_UT_GetStringFromURL
		HTMLEntityDecode:	NWM_UT_HTMLEntityDecode
		StripTags:				NWM_UT_StripTags
		GetTargetTranslation: NWM_UTIL_GetTargettranslation
	}

	return this
end function

function NWM_UT_GetStringFromURL(url, auth = invalid)
	result = ""
	timeout = 10000

  request = CreateObject("roURLTransfer")

	if url.InStr(0, "https") = 0
    request.SetCertificatesFile("common:/certs/ca-bundle.crt")
    request.AddHeader("X-Roku-Reserved-Dev-Id", "")
    request.InitClientCertificates()
  end if

  request.SetPort(CreateObject("roMessagePort"))
  'request.AddHeader("user-agent", "Mozilla/5.0 (iPhone; U; CPU like Mac OS X; en) AppleWebKit/420+ (KHTML, like Gecko) Version/3.0 Mobile/1A543 Safari/419.3")
  if auth <> invalid
    request.AddHeader("Authorization", auth)
  end if
  request.SetURL(url)
  'print "~~~FETCH: " + request.GetURL()
	if request.AsyncGetToString()
		event = wait(timeout, request.GetPort())
		if type(event) = "roUrlEvent"
				'print ValidStr(event.GetResponseCode())
				result = event.GetString()
				'exit while
		elseif event = invalid
				request.AsyncCancel()
				REM reset the connection on timeouts
				'request = CreateURLTransferObject(url)
				'timeout = 2 * timeout
		else
				print "roUrlTransfer::AsyncGetToString(): unknown event"
		endif
	end if

	'print result
	return result
end function

function NWM_UT_HTMLEntityDecode(inStr)
	result = inStr

	rx = CreateObject("roRegEx", "&#39;", "")
	result = rx.ReplaceAll(result, "'")

	rx = CreateObject("roRegEx", "&quot;", "")
	result = rx.ReplaceAll(result, Chr(34))

	rx = CreateObject("roRegEx", "&amp;", "")
	result = rx.ReplaceAll(result, "&")

	rx = CreateObject("roRegEx", "&ndash;", "")
	result = rx.ReplaceAll(result, "-")

	rx = CreateObject("roRegEx", "&rsquo;", "")
	result = rx.ReplaceAll(result, "'")

	return result
end function

function NWM_UT_StripTags(str)
	result = str

	rx = CreateObject("roRegEx", "<.*?>", "")
	result = rx.ReplaceAll(result, "")

	return result
end function

function NWM_UTIL_GetTargetTranslation(x, y, deg)
  result = { x: 0, y: 0 }

  angle1 = Atn(y / x)
  angle2 = angle1 + (deg * 0.01745329)

  hyp = Sqr(x^2 + y^2)
  result.x = Int((Cos(angle1) - Cos(angle2)) * hyp)
  result.y = Int((Sin(angle1) - Sin(angle2)) * hyp)

  return result
end function

' I have only come here seeking knowledge
'	Things they would not teach me of in college
