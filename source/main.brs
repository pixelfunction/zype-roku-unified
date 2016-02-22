' app starts here
Function Main() as void
  init()

  ' @toberefactored should be configurable from the dashboard.
  if m.config.device_linking = true
    'check if consumer is linked
    if is_linked()
      'if already linked go to home
      home()
    else
      ' otherwise go to visitor screen
      visitor_screen()
    end if
  else
    home()
  end if
End Function

' initializes and configures the app
Function init() as void
  set_api()
  set_dynamic_config()
  set_theme()
  set_device_id()
  set_up_store()
End Function
