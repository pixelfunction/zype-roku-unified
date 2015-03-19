sub play_episode(video as object, ad as object)
  vast = NWM_VAST()

  video.preroll = vast.GetPrerollFromURL(ad.url)

  'set the ad being played to true
  ad.played = true

  'tell the video when to start playing from after the ad
  video.playStart = ad.offset

	canvas = CreateObject("roImageCanvas")
	canvas.SetMessagePort(CreateObject("roMessagePort"))
	canvas.SetLayer(1, {color: "#000000"})
	canvas.Show()

  ' play the pre-roll
  adCompleted = true

  if video.preroll <> invalid
    adCompleted = ShowPreRoll(canvas, video.preroll)
  end if

  if adCompleted
    ' if the ad completed without the user pressing UP, play the content
    ShowVideoScreen(video)
  end if

	canvas.Close()
end sub

Function ShowVideoScreen(episode as object) as object
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
      return -1
    endif

    if msg.isPlaybackPosition()
    print msg.GetIndex()
    'hardcoding the second ad at fifteen for now
      if msg.GetIndex() = 15
        ad = get_ad(episode, 15)
        if (ad.played = false)
        print "going to an ad"
          screen.Close()
          play_episode(episode, ad)
        end if
      endif

    endif
  end while
end Function

function ShowPreRoll(canvas, ad)
	result = true

	player = CreateObject("roVideoPlayer")
	' be sure to use the same message port for both the canvas and the player
	player.SetMessagePort(canvas.GetMessagePort())
  player.SetDestinationRect(canvas.GetCanvasRect())
  player.SetPositionNotificationPeriod(1)

  ' set up some messaging to display while the pre-roll buffers
  canvas.SetLayer(2, {text: "Your program will begin after this message"})
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
			  print "isRequestFailed"
				exit while
			else if msg.isStatusMessage()
				if msg.GetMessage() = "start of play"
				  ' once the video starts, clear out the canvas so it doesn't cover the video
					canvas.ClearLayer(2)
					canvas.SetLayer(1, {color: "#00000000", CompositionMode: "Source"})
					canvas.Show()
				end if
			else if msg.isPlaybackPosition()
			  print "isPlaybackPosition: " + msg.GetIndex().ToStr()
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

	player.Stop()
	return result
end function

function FireTrackingEvent(trackingEvent)
  result = true
  timeout = 3000
  timer = CreateObject("roTimespan")
  timer.Mark()
  port = CreateObject("roMessagePort")
  xfer = CreateObject("roURLTransfer")
  xfer.SetPort(port)

  xfer.SetURL(trackingEvent.url)
  print "~~~TRACKING: " + xfer.GetURL()
  ' have to do this synchronously so that we don't colide with
  ' other tracking events firing at or near the same time
  if xfer.AsyncGetToString()
    event = wait(timeout, port)

    if event = invalid
      ' we waited long enough, moving on
      xfer.AsyncCancel()
      result = false
    else
      print "Req finished: " + timer.TotalMilliseconds().ToStr()
      print event.GetResponseCode().ToStr()
      print event.GetFailureReason()
    end if
  end if

  return result
end function

function get_ad(video, seconds)
  for each ad in video.ads
    if ad.offset = seconds
      return ad
    end if
  end for
end function
