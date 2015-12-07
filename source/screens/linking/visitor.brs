Library "v30/bslDefender.brs"

Function visitor_screen() as object
  canvas = CreateObject("roImageCanvas")
  port = CreateObject("roMessagePort")

  set_screen_size_variables()

  posArray = GetPositions()
  background = []
  buttons = []
  active_on = []
  hover_on = []
  selectedIndex = 0

  canvas.SetMessagePort(port)
  canvasRect = canvas.GetCanvasRect()

  background.Push({
    url: m.config.visitor_background_img,
    CompositionMode: "Source"
    TargetRect: {x: m.config.target_rect_x_visitor_screen, y: m.config.target_rect_y_visitor_screen}
  })

  active_on.Push({
      url: "pkg:/images/activate_hover.jpg"
      TargetRect: posArray[0]
  })
  active_on.Push({
      url: "pkg:/images/browse.png"
      TargetRect: posArray[1]
  })

  hover_on.Push({
      url: "pkg:/images/activate.png"
      TargetRect: posArray[0]
  })
  hover_on.Push({
      url: "pkg:/images/browse_hover.jpg"
      TargetRect: posArray[1]
  })

  canvas.SetLayer(0, {Color: m.config.visitor_background_color, CompositionMode:"Source"})
  canvas.SetLayer(1, background)
  canvas.SetLayer(2, active_on)
  canvas.Show()

  while true
      event = wait(0, port)
      if (event <> invalid)
        if (event.isRemoteKeyPressed())
          index = event.GetIndex()
          print index
          if (index = 0) then
            return -1
          else if (index = 2) OR (index = 3) OR (index = 4) OR (index = 5)'any arrow then
            if selectedIndex = 0 then
              canvas.SetLayer(2, hover_on)
              selectedIndex = 1
            else
              canvas.SetLayer(2, active_on)
              selectedIndex = 0
            end if
        else if (index = 6) 'OK
          if selectedIndex = 0
            pin_screen()
          else if selectedIndex = 1
            home()
          end if
        endif
      endif
    endif
  end while
End Function

'position of the two images
Function GetPositions() as object
  posArray = []
  posArray.Push({x: m.config.activate_button_x, y: m.config.activate_button_y}) 'position of first button
  posArray.Push({x: m.config.browse_button_x, y: m.config.browse_button_y}) 'position of second button
  return posArray
End Function

'logic for determining which sd or hd assets to use
Function set_screen_size_variables() as void
  aspect_ratio = CreateObject("roDeviceInfo").GetDisplayAspectRatio()

  if aspect_ratio = "4x3"
    m.config.visitor_background_img = m.config.visitor_background_img_sd
    m.config.activate_button_x = m.config.activate_button_x_sd
    m.config.activate_button_y = m.config.activate_button_y_sd
    m.config.browse_button_x = m.config.browse_button_x_sd
    m.config.browse_button_y = m.config.browse_button_y_sd
  else
    m.config.visitor_background_img = m.config.visitor_background_img_hd
    m.config.activate_button_x = m.config.activate_button_x_hd
    m.config.activate_button_y = m.config.activate_button_y_hd
    m.config.browse_button_x = m.config.browse_button_x_hd
    m.config.browse_button_y = m.config.browse_button_y_hd
  endif
end Function
