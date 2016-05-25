
function RequestToken()

  if m.pin = invalid
    print "PIN not available"
    return invalid
  end if

  data = CreateObject("roAssociativeArray")
  data.AddReplace("client_id", m.api.client_id)
  data.AddReplace("client_secret", m.api.client_secret)
  data.AddReplace("linked_device_id", m.device_id)
  data.AddReplace("pin", m.pin)
  data.AddReplace("grant_type", "password")
  print "creating OAuth"
  print m.device_id
  print m.pin
  res = RetrieveToken(data)
  if res <> invalid
    AddOAuth(res)
  end if
end function

function AddOAuth(data as object)
  m.oauth.access_token = data.access_token
  m.oauth.token_type = data.token_type
  m.oauth.expires_in = data.expires_in
  m.oauth.refresh_token = data.refresh_token
  m.oauth.scope = data.scope
  m.oauth.created_at = data.created_at
  print m.oauth
end function

function ClearOAuth()
  m.oauth = {
    access_token: invalid,
    token_type: invalid,
    expires_in: invalid,
    refresh_token: invalid,
    scope: invalid,
    created_at: invalid
  }
end function

function RetrieveToken(params as object) as object
    url = "https://login.zype.com/oauth/token"
    req = RequestPost(url, params)
    return req
end function

function RetrieveTokenStatus(params as object) as object
    url = "https://login.zype.com/oauth/token/info"
    req = RequestPost(url, params)
    return req
end function

function RefreshToken(params as dynamic) as object
    url = "https://login.zype.com/oauth/token"
    req = RequestPost(url, params)
    return req
end function

Function RequestPost(url As String, data As dynamic)
    if validateParam(data, "roAssociativeArray", "RequestPost") = false return -1

    roUrlTransfer = CreateObject("roUrlTransfer")
    port = CreateObject("roMessagePort")
    roUrlTransfer.SetPort(port)

    if url.InStr(0, "https") = 0
      roUrlTransfer.SetCertificatesFile("common:/certs/ca-bundle.crt")
      roUrlTransfer.AddHeader("X-Roku-Reserved-Dev-Id", "")
      roUrlTransfer.InitClientCertificates()
    end if

    roUrlTransfer.SetUrl(url)
    roUrlTransfer.AddHeader("Content-Type", "application/json")
    roUrlTransfer.AddHeader("Accept", "application/json")
    json = FormatJson(data)
    ' print "Posting to " + roUrlTransfer.GetUrl() + ": " + json

    if(roUrlTransfer.AsyncPostFromString(json))
      while(true)
        msg = wait(0, port)
        if(type(msg) = "roUrlEvent")
          code = msg.GetResponseCode()
          if(code = 200)
            res = ParseJSON(msg.GetString())
            ' print "result: "; res
            return res
          else if code = 401
            ' print "401"
            return invalid
          end if
        else if(event = invalid)
          roUrlTransfer.AsyncCancel()
          exit while
        end if
      end while
    end if
    return invalid
End Function
