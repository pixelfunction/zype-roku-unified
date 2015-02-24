Function detail_screen(episode As Object, c1 As String, c2 As String) as object
  screen = CreateObject("roSpringboardScreen")
  port = CreateObject("roMessagePort")
  screen.SetMessagePort(port)

  screen.SetDescriptionStyle(m.config.springboard_description_style)
  screen.SetDisplayMode(m.config.scale_mode)
  screen.SetBreadcrumbText(c1, c2)
  screen.SetStaticRatingEnabled(false)
  screen.SetPosterStyle(m.config.springboard_poster_style)

  screen.SetContent(episode)

  'show different button depending on if user is linked and if subscription is required
  if m.linked
    screen.AddButton(1, m.config.play_button_text)
  else
    if episode.SubscriptionRequired
      screen.AddButton(2, "Subscription Required")
    else
      screen.AddButton(1, m.config.play_button_text)
    endif
  endif

  screen.show()

  print episode

  while (true)
    msg = wait(0, port)
    if type(msg) = "roSpringboardScreenEvent"
      if (msg.isScreenClosed())
        return -1
      else if (msg.isButtonPressed())
        if msg.GetIndex() = 1
          episode.stream = get_stream_url(episode.id)
          print episode.stream
          play_episode(episode)
        else if msg.GetIndex() = 2
          show_link_modal(episode.title)
        endif
      endif
    endif
  end while

End Function
