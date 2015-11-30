'entry point
Function Main() as void

  'define the app type
  'for example, it may be REGULAR, UNIVERSAL_SVOD, NATIVE_SVOD, EST
  m.app_type = "NATIVE_SVOD"

  'initialize our environment
  init()

  if m.app_type = "REGULAR" then
     home_screen()
  elseif m.app_type = "UNIVERSAL_SVOD" then
     authenticate()
  elseif m.app_type = "NATIVE_SVOD" then
    'statements for native svod
    authenticate_native_svod()
  end if

End Function
