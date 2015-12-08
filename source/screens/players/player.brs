Function play(episodes as object, index as integer, offset as integer)
    if m.app_version = "AVOD"
      'print "going to ad free player"
      play_episode_with_ad(episodes, index, offset)
    else
      'print "going to ad player"
      play_episode_ad_free(episodes, index, offset)
    end if
End Function

' ad free player (for svod)
Function play_episode_ad_free(episodes as object, index as integer, offset as integer)
  m.home_y = index
  episode = episodes[index]
  print "REFRESHING STREAM URL"
  if type(episode) <> "roAssociativeArray" then
      print "invalid data passed to showVideoScreen"
      return -1
  endif

  'get the stream information right before I play it
  player_info = get_player_info(episode.id)
  episode.stream = player_info.stream
  episode.StreamFormat = player_info.format
  episode.ads = player_info.ads
  print episode.StreamFormat
  print episode.stream

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
                play_episode(episodes, index + 1, 0)
              endif
            endif
          	'print "deleted bookmark for playback position"
          else if msg.isScreenClosed()
              'print "Screen closed"
              exit while
          else if msg.isRequestFailed()
              'print "Video request failure: "; msg.GetIndex(); " " msg.GetData()
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

End Function
