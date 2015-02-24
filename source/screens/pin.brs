Function pin_screen(pin as String) as object
  ggaa = GetGlobalAA()
  m.config = ggaa.config

  screen = CreateObject("roCodeRegistrationScreen")
  port = CreateObject("roMessagePort")
  screen.SetMessagePort(port)

  screen.SetBreadcrumbText("Activate", "")

  screen.AddHeaderText("Link your Roku Player")
  screen.AddParagraph("1. From your computer, go to demo.zype.com/link")
  screen.AddParagraph("2. Enter Pin:")
  screen.AddFocalText(" ", "spacing-dense")
  screen.SetRegistrationCode(pin)
  screen.AddFocalText(" ", "spacing-dense")
  screen.AddParagraph("3. This screen will automatically update as soon as your activation is complete!")
  screen.AddButton(1, "Back")
  screen.Show()

  while (true)
    msg = wait(5000, port)
    if type(msg) = "roCodeRegistrationScreenEvent"
      'exit if user wants it
      if msg.isScreenClosed()
        print "Screen closed"
        return -1
      elseif msg.isButtonPressed()
        print "Button pressed: "; msg.GetIndex(); " " msg.GetData()
        if msg.GetIndex() = 1
          return -1
        end if
      endif
    endif
    'check if linked
    refresh_pin_screen()
  end while
End Function
