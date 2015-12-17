' @toberefactored Should be set by values returned from the API
' these are the hard coded keys/initialization variables
' @NOTE
' rename api_config.tmpl.brs to api_config.brs
' rename set_api_tmpl() to set_api()
Function set_api_tmpl() as void
  m.api = {
    key: "<API Key>",
    app: "<App Key>",
    endpoint: "<End Point URL>",
    player_endpoint: "<Player End Point URL>",
    version: "0.0.1"
  }
End Function
