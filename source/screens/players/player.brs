Function play(episodes as object, index as integer, offset as integer, fromSearch as Boolean)
  if show_ads(episodes[index]) = true
    play_episode_with_ad(episodes, index, offset, fromSearch)
  else
    play_episode_ad_free(episodes, index, offset, fromSearch)
  end if
End Function

Function show_ads(episode as object) as boolean
  if m.config.force_ads = true
    return true
  end if
  if m.config.avod = true
    if m.config.in_app_purchase = true
      if is_subscribed() or is_purchased(episode)
        return false
      else
        return true
      end if
    else if m.config.device_linking = true
      if is_linked()
        return false
      else
        return true
      end if
    else
      return true
    end if
  else
    return false
  end if
End Function

' ad free player (for svod)
Function play_episode_ad_free(episodes as object, index as integer, offset as integer, fromSearch as Boolean) as void
  if fromSearch <> true
    m.home_y = index
  else
    m.search_x = index
  end if
  episode = episodes[index]

  if type(episode) <> "roAssociativeArray"
      print "invalid data passed to showVideoScreen"
      return
  end if

  'get the stream information right before I play it
  player_info = get_player_info(episode.id)
  episode.stream = player_info.stream
  episode.StreamFormat = player_info.format
  episode.ads = player_info.ads
  episode.playStart = offset

  port = CreateObject("roMessagePort")
  screen = CreateObject("roVideoScreen")
  screen.SetCertificatesFile("common:/certs/ca-bundle.crt")
  screen.AddHeader("X-Roku-Reserved-Dev-Id", "")
  screen.InitClientCertificates()
  screen.SetMessagePort(port)

  screen.SetPositionNotificationPeriod(30)
  screen.SetContent(episode)
  screen.Show()

  'PrintAA(episode)

  while true
      msg = wait(0, port)

      if type(msg) = "roVideoScreenEvent" then
          'print "showHomeScreen | msg = "; msg.getMessage() " | index = "; msg.GetIndex()
          if msg.isfullresult()
          	'print "Video Completed Playback Normally"
          	RegDelete(episode.id)
            'print "WILL I GO INTO AUTOPLAY"
            'print m.config.autoplay
            'print "WILL I GO INTO AUTOPLAY"
            if m.config.autoplay
              if (index + 1) < episodes.count()
                screen.close()
                if is_playable(episodes[index + 1])
                  play(episodes, index + 1, 0, fromSearch)
                end if
              endif
            endif
          	'print "deleted bookmark for playback position"
          else if msg.isScreenClosed()
              'print "Screen closed"
              exit while
          else if msg.isRequestFailed()
              'print "Video request failure: "; msg.GetIndex(); " " msg.GetData()
              exit while
          else if msg.isStatusMessage()
              'print "Video status: "; msg.GetIndex(); " " msg.GetData()
          else if msg.isButtonPressed()
              'print "Button pressed: "; msg.GetIndex(); " " msg.GetData()
          else if msg.isPlaybackPosition()
              nowpos = msg.GetIndex()
              RegWrite(episode.id, nowpos.toStr())
          else
              'print "Unexpected event type: "; msg.GetType()
          end if
      else
          'print "Unexpected message class: "; type(msg)
      end if
  end while
  screen.close()
End Function
