' version info
' GIT DESCRIPTION: <GIT_DESCRIPTION>

' these are the hard coded keys/initialization variables
Function _set_api() as void
  m.api = {
    app: "<APPKEY>",
    endpoint: "https://api.zype.com/",
    player_endpoint: "https://player.zype.com/",
    client_id: "<CLIENT_ID>",
    client_secret: "<CLIENT_SECRET>"
    version: "0.0.1"
  }
End Function
