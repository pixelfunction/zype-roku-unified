' these are the hard coded keys/initialization variables
' @NOTE
' rename api_config.tmpl.brs to api_config.brs
' rename set_api_tmpl() to set_api()
Function set_api_tmpl() as void
  m.api = {
    key: "<APIKEY>",
    app: "<APPKEY>",
    endpoint: "https://api.zype.com/",
    player_endpoint: "https://player.zype.com/",
    version: "0.0.1"
  }
End Function
