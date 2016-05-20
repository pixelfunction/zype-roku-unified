function RetrieveToken(params as object) as object
    url = "https://login.zype.com/oauth/token"
    req = RequestPost(url, params)
    return req
end function

function RetrieveTokenStatus(params as object) as object
    url = "https://login.zype.com/oauth/token/info"
    req = RequestPost(url, params)
end function

function RefreshToken(params as dynamic) as object
    url = "https://login.zype.com/oauth/token"
    req = RequestPost(url, params)
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
