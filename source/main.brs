' app starts here
Function Main() as void
  init()

  m.nested = true
  if m.nested = true
    nested_home()
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
