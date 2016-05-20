'@refactored checks if the device is linked
Function is_linked() As Boolean
  ' uncomment to test the device linking feature
  'return true
  request = CreateObject("roUrlTransfer")
  port = CreateObject("roMessagePort")
  request.SetPort(port)

  url = m.api.endpoint + "/pin/status/?app_key=" + m.api.app + "&linked_device_id=" + m.device_id
  if url.InStr(0, "https") = 0
    request.SetCertificatesFile("common:/certs/ca-bundle.crt")
    request.AddHeader("X-Roku-Reserved-Dev-Id", "")
    request.InitClientCertificates()
  end if
  request.SetUrl(url)

  if(request.AsyncGetToString())
    while(true)
      msg = wait(0, port)
      if(type(msg) = "roUrlEvent")
        code = msg.GetResponseCode()
        if(code = 200)
          res = ParseJSON(msg.GetString())
          response = res.response
          
          if response.linked = true and m.pin <> invalid
            RequestToken()
          end if

          return response.linked
        else if (code = 404)
          ClearOAuth()
          return false
        end if
      else if(event = invalid)
        request.AsyncCancel()
        return false
      end if
    end while
  end if
End Function

function ClearOAuth()
  RegDelete("access_token", "Authentication")
  RegDelete("token_type", "Authentication")
  RegDelete("expires_in", "Authentication")
  RegDelete("refresh_token", "Authentication")
  RegDelete("scope", "Authentication")
  RegDelete("created_at", "Authentication")
end function

function RequestToken()
  ' print m.access_token
  ' print m.token_type
  ' print m.expires_in
  ' print m.refresh_token
  ' print m.scope
  ' print m.created_at
  if m.access_token = invalid or m.token_type = invalid or m.expires_in = invalid or m.refresh_token = invalid or m.scope = invalid or m.created_at = invalid
    data = CreateObject("roAssociativeArray")
    data.AddReplace("client_id", m.api.client_id)
    data.AddReplace("client_secret", m.api.client_secret)
    data.AddReplace("linked_device_id", m.device_id)
    data.AddReplace("pin", m.pin)
    data.AddReplace("grant_type", "password")
    ' print data
    print "creating OAuth"
    res = RetrieveToken(data)
    if res <> invalid
      AddOAuth(res)
    end if
  else
  end if
end function

function AddOAuth(data as object)
  print "writing OAuth"
  ' print data.access_token
  ' print data.created_at
  ' print data.expires_in
  ' print data.refresh_token
  ' print data.scope
  ' print data.token_type

  RegWrite("access_token", data.access_token, "Authentication")
  m.access_token = RegRead("access_token", "Authentication")

  RegWrite("token_type", data.token_type, "Authentication")
  m.token_type = RegRead("token_type", "Authentication")

  RegWrite("expires_in", data.expires_in.toStr().Trim(), "Authentication")
  m.expires_in = RegRead("expires_in", "Authentication")

  RegWrite("refresh_token", data.refresh_token, "Authentication")
  m.refresh_token = RegRead("refresh_token", "Authentication")

  RegWrite("scope", "consumer", "Authentication")
  m.scope = RegRead("scope", "Authentication")

  RegWrite("created_at", data.created_at.toStr().Trim(), "Authentication")
  m.created_at = RegRead("created_at", "Authentication")
end function

' generates the pin for device linking.
Function acquire_pin() as object
  request = CreateObject("roUrlTransfer")
  port = CreateObject("roMessagePort")
  request.SetPort(port)

  request.SetCertificatesFile("common:/certs/ca-bundle.crt")
  request.AddHeader("X-Roku-Reserved-Dev-Id", "")
  request.InitClientCertificates()

  url = m.api.endpoint + "/pin/acquire/?app_key=" + m.api.app

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
