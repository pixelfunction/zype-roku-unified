function GetAccessToken()
  oauth = RegReadAccessToken()


  if oauth = invalid
    ResetAccessToken()
    RequestToken()
  else if IsExpired(oauth.created_at.ToInt(), oauth.expires_in.ToInt())
    ResetAccessToken()
    data = {
      "client_id": m.client_id,
      "client_secret": m.client_secret,
      "refresh_token": oauth.refresh_token,
      "grant_type": "refresh_token"
    }
    res = RefreshToken(data)
    if res <> invalid
      RegWriteAccessToken(res)
    end if
  end if
  
  return RegReadAccessToken()
end function

function RegReadAccessToken()
  oauth = CreateObject("roAssociativeArray")

  access_token = RegRead("AccessToken", "OAuth")
  if access_token <> invalid
    oauth.AddReplace("access_token", access_token)
    oauth.AddReplace("token_type", RegRead("TokenType", "OAuth"))
    oauth.AddReplace("expires_in", RegRead("ExpiresIn", "OAuth"))
    oauth.AddReplace("refresh_token", RegRead("RefreshToken", "OAuth"))
    oauth.AddReplace("scope", RegRead("Scope", "OAuth"))
    oauth.AddReplace("created_at", RegRead("CreatedAt","OAuth"))

    return oauth
  end if

  return invalid
end function

function RegWriteAccessToken(data as object)
  ' print data
  access_token = ToString(data.access_token)
  token_type = ToString(data.token_type)
  expires_in = AnyToString(data.expires_in)
  refresh_token = ToString(data.refresh_token)
  scope = ToString(data.scope)
  created_at = AnyToString(data.created_at)

  print expires_in
  print created_at

  RegWrite("AccessToken", access_token, "OAuth")
  RegWrite("TokenType", token_type, "OAuth")
  RegWrite("ExpiresIn", expires_in, "OAuth")
  RegWrite("RefreshToken", refresh_token, "OAuth")
  RegWrite("Scope", scope, "OAuth")
  RegWrite("CreatedAt", created_at, "OAuth")
end function

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
    RegWriteAccessToken(res)
  end if
end function

function IsExpired(created_at as integer, expires_in as integer)
  dt = createObject("roDateTime")
  dt.mark()
  delta = dt.asSeconds() - created_at
  ' print str(delta)
  ' print str(expires_in)
  return delta > expires_in
end function

function ResetAccessToken()
  RegDelete("AccessToken", "OAuth")
  RegDelete("TokenType", "OAuth")
  RegDelete("ExpiresIn", "OAuth")
  RegDelete("RefreshToken", "OAuth")
  RegDelete("Scope", "OAuth")
  RegDelete("CreatedAt", "OAuth")
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
