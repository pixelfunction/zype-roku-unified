' app starts here
Function Main() as void
  init()
  'define the app type
  'for example, it may be REGULAR, UNIVERSAL_SVOD, NATIVE_SVOD, EST
  m.app_type = "REGULAR"
  'initialize our environment
  if m.app_type = "REGULAR" then
     home_screen()
  elseif m.app_type = "UNIVERSAL_SVOD" then
     authenticate()
  elseif m.app_type = "NATIVE_SVOD" then
     authenticate_native_svod()
  elseif m.app_type = "EST" then
     set_up_est()
  end if
End Function

' initializes and configures the app
Function init() as void
  set_api()
  get_dynamic_config()
  set_theme()

  ' stores where the x,y position are in the home screen for every time you go back it maintains position
  m.home_x = 0
  m.home_y = 0
  m.previous_home_x = 0
  m.previous_home_y = 0

  ' how many categories to load at start
  m.loading_offset = 1
  ' how many categories to grab at a time when scrolling
  m.loading_group = 2

  '@toberefactored
  if m.app_type = "UNIVERSAL_SVOD" then
    'SVOD'
    'read channel registry to see if there is a unique device id, if not set it to be unique with device id and time set
    'uncomment out the RegDelete if want to wipe out the token in dev
    'RegDelete("RegToken", "Authentication555ef22569702d048c9d0e00")
    print "checking registry token"
    if RegRead("RegToken", "Authentication555ef22569702d048c9d0e00") <> invalid
      'print "REGISTRY TOKEN IS ALREADY WRITTEN"
      m.device_id = RegRead("RegToken", "Authentication555ef22569702d048c9d0e00")
    else
      'first time channel is loaded (or deleted and reloaded), so need to create the unique id
      'print "WRITING A NEW REGISTRY TOKEN"
      date = CreateObject("roDateTime")
      timestamp = date.AsSeconds().ToStr()
      device = CreateObject("roDeviceInfo")
      uniqueId = device.GetDeviceUniqueId() + date.AsSeconds().ToStr()
      RegWrite("RegToken", uniqueId, "Authentication555ef22569702d048c9d0e00")
      m.device_id = RegRead("RegToken", "Authentication555ef22569702d048c9d0e00")
    endif
    print m.device_id
  end if

  '@toberefactored
  'preconfiguring to true for alpha testing
  m.linked = false 'as linked is false, once authenticated linked = true
End Function
