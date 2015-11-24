'entry point
Function Main() as void

  'define the app type
  'for example, it may be REGULAR, UNIVERSAL_SVOD, NATIVE_SVOD, EST
  app_type$ = ""

  'initialize our environment
  init()
  
  if app_type = "REGULAR" then
    home_screen()
  elseif app_type = "UNIVERSAL_SVOD" then
    authenticate()
  elseif app_type = "NATIVE_SVOD" then
    `statements for native svod
  end if

End Function
