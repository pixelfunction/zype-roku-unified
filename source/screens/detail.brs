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
  screen.AddButton(1, m.config.play_button_text)

  'if there is something is the registry reader for last play position
  if RegRead(episode.id) <> invalid
    screen.AddButton(2, "Resume Playing")
  endif

  screen.show()

  print episode

  while (true)
    msg = wait(0, port)
    if type(msg) = "roSpringboardScreenEvent"
      if (msg.isScreenClosed())
        return -1
      else if (msg.isButtonPressed())
        stream_info = get_stream_info(episode.id)
        print stream_info
        episode.stream = stream_info.url
        episode.StreamFormat = stream_info.format
        print episode.StreamFormat
        print episode.stream
        'test playing 30 seconds out
        if msg.GetIndex() = 1
          play_episode(episode, 0)
        else if msg.GetIndex() = 2
          offset = RegRead(episode.id).toInt()
          play_episode(episode, offset)
        endif
      endif
    endif
  end while

End Function
