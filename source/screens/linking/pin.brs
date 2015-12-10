Function pin_screen() as void
  ggaa = GetGlobalAA()
  m.config = ggaa.config

  screen = CreateObject("roCodeRegistrationScreen")
  port = CreateObject("roMessagePort")
  screen.SetMessagePort(port)

  screen.SetBreadcrumbText("Activate", "")

  screen.AddHeaderText("Link your Roku Player")
  screen.AddParagraph("1. From your computer or mobile device, go to " + m.config.device_link_url)
  screen.AddParagraph("2. Enter Pin:")
  screen.AddFocalText(" ", "spacing-dense")

  if is_pin_update_required()
    pin = acquire_pin()
  else
    pin = m.pin
  end if
  screen.SetRegistrationCode(pin)

  screen.AddFocalText(" ", "spacing-dense")
  screen.AddParagraph("3. This screen will automatically update as soon as your activation is complete!")
  screen.AddButton(1, "Back")
  screen.Show()

  while (true)
    msg = wait(5000, port)

    if msg = invalid
      if is_linked()
        home()
        exit while
      else
        if is_pin_update_required()
          pin = acquire_pin()
        else
          pin = m.pin
        end if
        screen.SetRegistrationCode(pin)
      end if
    else if type(msg) = "roCodeRegistrationScreenEvent"

      if msg.isScreenClosed()
        exit while
      end if

      if msg.isButtonPressed() OR msg.GetIndex() = 1
        exit while
      end if

    end if
  end while

  screen.Close()

End Function
