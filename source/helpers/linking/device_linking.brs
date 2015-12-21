'@refactored checks if the device is linked
Function is_linked() As Boolean
  ' uncomment to test the device linking feature
  'return true
  request = CreateObject("roUrlTransfer")
  port = CreateObject("roMessagePort")
  request.SetPort(port)

  request.SetCertificatesFile("common:/certs/ca-bundle.crt")
  request.AddHeader("X-Roku-Reserved-Dev-Id", "")
  request.InitClientCertificates()

  url = m.api.endpoint + "/pin/status/?api_key=" + m.api.key + "&linked_device_id=" + m.device_id
  request.SetUrl(url)

  if(request.AsyncGetToString())
    while(true)
      msg = wait(0, port)
      if(type(msg) = "roUrlEvent")
        code = msg.GetResponseCode()
        if(code = 200)
          res = ParseJSON(msg.GetString())
          response = res.response
          return response.linked
        else if (code = 404)
          return false
        end if
      else if(event = invalid)
        request.AsyncCancel()
        return false
      end if
    end while
  end if
End Function

' generates the pin for device linking.
Function acquire_pin() as object
  request = CreateObject("roUrlTransfer")
  port = CreateObject("roMessagePort")
  request.SetPort(port)

  request.SetCertificatesFile("common:/certs/ca-bundle.crt")
  request.AddHeader("X-Roku-Reserved-Dev-Id", "")
  request.InitClientCertificates()

  url = "https://api.zype.com/pin/acquire/?api_key=" + m.api.key
  request.SetUrl(url)
  pin_request = "linked_device_id=" + m.device_id + "&type=roku"

  if (request.AsyncPostFromString(pin_request))
    while(true)
      msg = wait(0, port)
      if(type(msg) = "roUrlEvent")
        code = msg.GetResponseCode()
        if(code = 201)
          res = ParseJSON(msg.GetString())
          response = res.response
          m.pin = response.pin
          if m.timer <> invalid
            m.timer.Mark()
          else
            m.timer = CreateObject("roTimespan")
            m.timer.Mark()
          end if
          return response.pin
        else if (code = 404)
          return "ERROR"
        end if
      else if(event = invalid)
        request.AsyncCancel()
        return "ERROR"
      end if
    end while
  end if
End Function

' updates the pin if it is required
Function is_pin_update_required() As Boolean
  pin = m.pin
  if pin = invalid
    return true
  else
    'need to reaquire pin every 30 minutes or it expires (refresh every ~25 minutes)
    if m.timer <> invalid
      if m.timer.TotalSeconds() > 1500
        return true
      else
        return false
      end if
    end if
  end if
End Function
