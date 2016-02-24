' ad player (for avod)
sub play_episode_with_ad(episodes as object, index as integer, offset as integer, fromSearch as Boolean)
  if fromSearch <> true
    m.home_y = index
  else
    m.search_x = index
  end if

  episode = episodes[index]

  player_info = get_player_info(episode.id)
  episode.stream = player_info.stream
  episode.StreamFormat = player_info.format
  episode.ads = player_info.ads
  ad = get_ad(episode, offset)

  vast = NWM_VAST()
  episode.preroll = vast.GetPrerollFromURL(ad.url)
  'set the ad being played to true
  ad.played = true

  'tell the episode when to start playing from after the ad (graceful fall back to the beginning)
  if ad.offset <> invalid
    episode.playStart = ad.offset
  else
    episode.playStart = 0
  end if

  'print "******"
  'print episode.playStart
  'print "******"

  canvas = CreateObject("roImageCanvas")
  canvas.SetMessagePort(CreateObject("roMessagePort"))
  canvas.SetLayer(1, {color: "#000000"})
  canvas.Show()

  ' play the pre-roll
  adCompleted = true

  if episode.preroll <> invalid
    adCompleted = ShowPreRoll(canvas, episode.preroll)
  end if

  if adCompleted
    ' if the ad completed without the user pressing UP, play the content
    ShowEpisodeScreen(episodes, index, ad.offset, fromSearch)
  end if

  canvas.Close()
end sub

Function ShowEpisodeScreen(episodes as object, index as integer, offset as integer, fromSearch as Boolean) as void
  episode = episodes[index]
  'print "LEAVING AD, ENTERING PLAYER"
  episode.playStart = offset
  'print episode.playStart
  'print "***"

  port = CreateObject("roMessagePort")

  screen = CreateObject("roVideoScreen")
  screen.SetCertificatesFile("common:/certs/ca-bundle.crt")
  screen.AddHeader("X-Roku-Reserved-Dev-Id", "")
  screen.InitClientCertificates()
  screen.SetContent(episode)
  screen.SetPositionNotificationPeriod(1)
  screen.SetMessagePort(Port)
  screen.show()

  while(true)
    msg = wait(0, port)
    if msg.isScreenClosed()
      exit while
    end if
    if msg.isfullresult()
      'print "episode Completed Playback Normally"
      RegDelete(episode.id)
      'print "deleted bookmark for playback position"
      'print "WILL I GO INTO AUTOPLAY"
      'print m.config.autoplay
      'print "WILL I GO INTO AUTOPLAY"
      if m.config.autoplay
        if (index + 1) < episodes.count()
          screen.close()
          if is_playable(episodes[index + 1])
            play(episodes, index + 1, 0, fromSearch)
          end if
        end if
      end if
    else if msg.isPlaybackPosition()
      nowpos = msg.GetIndex()
      'print "PLAYBACK POSITION"
      'print nowpos
      RegWrite(episode.id, nowpos.toStr())
      ad = get_ad(episode, nowpos)

      if (ad.played = false)
        'print "going to an ad"
        screen.Close()
        play_episode_with_ad(episodes, index, offset)
      end if
    end if
  end while
  screen.close()
end Function

function ShowPreRoll(canvas, ad)
  result = true

  player = CreateObject("roVideoPlayer")
  ' be sure to use the same message port for both the canvas and the player
  player.SetMessagePort(canvas.GetMessagePort())
  player.SetDestinationRect(canvas.GetCanvasRect())
  player.SetPositionNotificationPeriod(1)

  ' set up some messaging to display while the pre-roll buffers
  canvas.SetLayer(2, {text: "Loading Ad ..."})
  canvas.Show()

  player.AddContent(ad)
  player.Play()

  while true
    msg = wait(0, canvas.GetMessagePort())

    if type(msg) = "roVideoPlayerEvent"
      if msg.isFullResult()
        exit while
      else if msg.isPartialResult()
        exit while
      else if msg.isRequestFailed()
        'print "isRequestFailed"
        exit while
      else if msg.isStatusMessage()
        if msg.GetMessage() = "start of play"
          ' once the episode starts, clear out the canvas so it doesn't cover the episode
          canvas.ClearLayer(2)
          canvas.SetLayer(1, {color: "#00000000", CompositionMode: "Source"})
          canvas.Show()
        end if
      else if msg.isPlaybackPosition()
        'print "isPlaybackPosition: " + msg.GetIndex().ToStr()
        for each trackingEvent in ad.trackingEvents
          if trackingEvent.time = msg.GetIndex()
            FireTrackingEvent(trackingEvent)
          end if
        next
      end if
    else if type(msg) = "roImageCanvasEvent"
      if msg.isRemoteKeyPressed()
        index = msg.GetIndex()
        if index = 2 or index = 0  '<UP> or BACK
          for each trackingEvent in ad.trackingEvents
            if trackingEvent.event = "CLOSE"
              FireTrackingEvent(trackingEvent)
            end if
            next
            result = false
          exit while
        end if
      end if
    end if
  end while

  canvas.close()
  player.Stop()
  return result
end function

function FireTrackingEvent(trackingEvent)
  result = true
  timeout = 3000
  timer = CreateObject("roTimespan")
  timer.Mark()
  port = CreateObject("roMessagePort")
  request = CreateObject("roURLTransfer")
  request.SetPort(port)

  if trackingEvent.url.InStr(0, "https") = 0
    request.SetCertificatesFile("common:/certs/ca-bundle.crt")
    request.AddHeader("X-Roku-Reserved-Dev-Id", "")
    request.InitClientCertificates()
  end if

  request.SetURL(trackingEvent.url)
  'print "~~~TRACKING: " + request.GetURL()
  ' have to do this synchronously so that we don't colide with
  ' other tracking events firing at or near the same time
  if request.AsyncGetToString()
    event = wait(timeout, port)

    if event = invalid
      ' we waited long enough, moving on
      request.AsyncCancel()
      result = false
    else
      'print "Req finished: " + timer.TotalMilliseconds().ToStr()
      'print event.GetResponseCode().ToStr()
      'print event.GetFailureReason()
    end if
  end if

  return result
end function

function get_ad(episode, seconds)
  for each ad in episode.ads
    if ad.offset = seconds
      return ad
    end if
  end for

  'there is no ad to be played for this second so return true so player continues playing
  ad = { offset: seconds, played: true }

  return ad
end function
