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
  screen.show()

  print episode

  while (true)
    msg = wait(0, port)
    if type(msg) = "roSpringboardScreenEvent"
      if (msg.isScreenClosed())
        return -1
      else if (msg.isButtonPressed())
        episode.stream = get_stream_url(episode.id)

        'move the ad parsing to a different place!
        episode.ads = []

        preroll_ad = {
            offset: 0,
            url: "http://ad3.liverail.com/?LR_PUBLISHER_ID=1331&LR_CAMPAIGN_ID=229&LR_SCHEMA=vast2",
            played: false
        }

        episode.ads.push(preroll_ad)

        second_ad = {
          offset: 15,
          url: "http://ad3.liverail.com/?LR_PUBLISHER_ID=1331&LR_CAMPAIGN_ID=229&LR_SCHEMA=vast2",
          played: false
        }

        episode.ads.push(second_ad)

        third_ad = {
          offset: 20,
          url: "http://ad3.liverail.com/?LR_PUBLISHER_ID=1331&LR_CAMPAIGN_ID=229&LR_SCHEMA=vast2",
          played: false
        }

        episode.ads.push(third_ad)
        'end ad parsing

        print episode.stream
        ad = get_ad(episode, 0)

        play_episode(episode, ad)
      endif
    endif
  end while

End Function
