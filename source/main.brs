' app starts here
Function Main() as void
  init()

  ' @toberefactored should be configurable from the dashboard.
  home()
End Function

' initializes and configures the app
Function init() as void
  set_api()
  set_dynamic_config()
  set_theme()
  set_device_id()
  set_up_store()
End Function
