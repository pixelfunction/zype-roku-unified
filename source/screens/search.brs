Function search_screen() as object
  ggaa = GetGlobalAA()
  m.config = ggaa.config

  screen = CreateObject("roKeyboardScreen")
  port = CreateObject("roMessagePort")
  screen.SetMessagePort(port)

  screen.SetTitle(m.config.search_title)
  screen.SetDisplayText(m.config.search_help_text)
  screen.AddButton(1, m.config.search_button_text)
  screen.AddButton(2, "Back")

  screen.show()

  while (true)

    msg = wait(0, port)
    if type(msg) = "roKeyboardScreenEvent"
      if (msg.isScreenClosed())
        return -1
      else if msg.isButtonPressed()
        if msg.GetIndex() = 1
          trimmed_search_text = strTrim(screen.GetText())
          if Len(trimmed_search_text) > 0
            search_results_screen(trimmed_search_text)
          endif
        endif
        if msg.GetIndex() = 2
          return -1
        endif
      endif
    endif
  end while
End Function
