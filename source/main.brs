'entry point
Function Main() as void
  'initialize our environment
  init()

  'do authentication if Channel requires authentication
  if m.config.use_authentication
    authenticate()
  else
    m.linked = true 'anyone can access subscription content
    home_screen()
  endif
End Function
