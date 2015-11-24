'all the authentication functions

Function authenticate() as object
  'check to see if device is linked
  if is_linked()
    print "you are already linked"
    home_screen()
  else
    print "you are not linked"
    visitor_screen()
  endif
end Function


Function is_linked() as boolean
  'if you are hardcoded as linked, you go free :)
  if m.linked = true
    m.config.play_ads = false
    return true
  end if

  request = CreateObject("roUrlTransfer")
  port = CreateObject("roMessagePort")
  request.SetPort(port)

  request.SetCertificatesFile("common:/certs/ca-bundle.crt")
  request.AddHeader("X-Roku-Reserved-Dev-Id", "")
  request.InitClientCertificates()

  url = m.api.endpoint + "/pin/status/?api_key="+ m.api.key +"&linked_device_id=" + m.device_id
  print url
  request.SetUrl(url)

  if(request.AsyncGetToString())
    while(true)
      msg = wait(0, port)
      if(type(msg) = "roUrlEvent")
        code = msg.GetResponseCode()
        print code
        if(code = 200)
          res = ParseJSON(msg.GetString())
          response = res.response
          m.linked = response.linked
          if m.linked
            'if you are linked, go ads free :)
            m.config.play_ads = false
          end if
          return response.linked
        else if (code = 404)
          return false
        endif
      else if(event = invalid)
        request.AsyncCancel()
        return false
      endif
    end while
  endif
End Function

Function acquire_pin() as object
  request = CreateObject("roUrlTransfer")
  port = CreateObject("roMessagePort")
  request.SetPort(port)

  request.SetCertificatesFile("common:/certs/ca-bundle.crt")
  request.AddHeader("X-Roku-Reserved-Dev-Id", "")
  request.InitClientCertificates()

  url = "https://api.zype.com/pin/acquire/?api_key=" + m.api.key
  request.SetUrl(url)
  print url

  pin_request = "linked_device_id=" + m.device_id + "&type=roku"

  if(request.AsyncPostFromString(pin_request))
    while(true)
      msg = wait(0, port)
      if(type(msg) = "roUrlEvent")
        code = msg.GetResponseCode()
        print code
        if(code = 201)
          res = ParseJSON(msg.GetString())
          response = res.response
          m.pin = response.pin
          timer = CreateObject("roTimespan")
          timer.Mark()
          m.pin_expiration = timer
          return response.pin
        else if (code = 404)
          return "ERROR"
        endif
      else if(event = invalid)
        request.AsyncCancel()
        return "ERROR"
      endif
    end while
  endif
End Function

Function refresh_pin_screen() as Object
  if is_linked()
    print "you are already linked"
    home_screen()
  else

    if update_pin()
      pin = acquire_pin()
    else
      pin = m.pin
    endif

    pin_screen(pin)
  endif
end Function

Function update_pin() as Boolean
  pin = m.pin

  if pin = invalid
    return true
  else
    'need to reaquire pin every 30 minutes or it expires (refresh every ~25 minutes)
    if m.pin_expiration.TotalSeconds() > 1500
      return true
    else
      return false
    endif
  endif
End Function
