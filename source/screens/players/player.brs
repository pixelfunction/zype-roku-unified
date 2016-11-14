Function ShowMessageDialog(title as string, msg as string) As Void
    port = CreateObject("roMessagePort")
    dialog = CreateObject("roMessageDialog")
    dialog.SetMessagePort(port)
    dialog.SetTitle(title)
    dialog.SetText(msg)

    dialog.AddButton(1, "OK")
    dialog.EnableBackButton(true)
    dialog.Show()
    While True
        dlgMsg = wait(0, dialog.GetMessagePort())
        If type(dlgMsg) = "roMessageDialogEvent"
            if dlgMsg.isButtonPressed()
                if dlgMsg.GetIndex() = 1
                    exit while
                end if
            else if dlgMsg.isScreenClosed()
                exit while
            end if
        end if
    end while

    dialog.Close()
End Function


function canPlay(ep as Object) as Object
  canPlayBool = true
  message = ""
  auth_type = "app_key"
  auth_key = m.api.app

  if m.config.device_linking = true and (ep.SubscriptionRequired = true or ep.PurchaseRequired = true or ep.PassRequired = true or ep.RentalRequired = true)
    print "Device Linking"
    if is_linked() and PinExist()
      oauth = GetAccessToken()
      if oauth <> invalid
        print "Requesting OAuth"
        if IsEntitled(ep.id, {"access_token": oauth.access_token})
          canPlayBool = true
          message = ""
          auth_type = "access_token"
          auth_key = oauth.access_token
        else
          canPlayBool = false
          message = "You do not have access to this content."
          auth_type = ""
          auth_key = ""
        end if
      else
        canPlayBool = false
        message = "No access token provided."
        auth_type = ""
        auth_key = ""
      end if
    else

      if m.config.subscribe_to_watch_ad_free = true
        canPlayBool = true
        message = ""
        auth_type = "app_key"
        auth_key = m.api.app
      else
        ResetAccessToken()
        RemovePin()
        ResetDeviceID()

        canPlayBool = true
        message = "You do not have access to this content. Device is not linked."
        auth_type = ""
        auth_key = ""
      end if

    end if
  end if

  return {"play": canPlayBool, "message": message, "auth_type": auth_type, "auth_key": auth_key}
end function


Function play(episodes as object, index as integer, offset as integer, fromSearch as Boolean) as void

  if type(episodes[index]) <> "roAssociativeArray"
      print "invalid data passed to showVideoScreen"
      return
  end if

  if m.config.autoplay =  true
    loopedData = CreateObject("roAssociativeArray")

    while True
      if fromSearch <> true
        m.home_y = index
      else
        m.search_x = index
      end if

      ep = episodes[index]

      cPlay = canPlay(ep)

      if cPlay.play = true then
        player_info = invalid
        if loopedData.DoesExist(ep.id) = true then
          print "getting player info from local dict"
          player_info = loopedData[ep.id]
        else

          if cPlay.auth_type = "app_key" then
            player_info = get_player_info(ep.id, {"app_key": cPlay.auth_key})
          else if cPlay.auth_type = "access_token" then
            player_info = get_player_info(ep.id, {"access_token": cPlay.auth_key})
          else
            ShowMessageDialog("", "cPlay: Something went wrong!")
            return
          end if

          loopedData.AddReplace(ep.id, player_info)
        end if

        if player_info <> invalid
          if show_ads(ep) = true
            videoScr = play_episode_with_ad(episodes, index, offset, fromSearch, player_info)
          else
            videoScr = play_episode_ad_free(episodes, index, offset, fromSearch, player_info)
          end if

          print "TEST"
          print videoScr

          if type(videoScr) = "roInt" then
            exit while
          else if type(videoScr) = "roVideoScreen" then
            videoScr.close()
          else
            print "ERROR"
            exit while
          end if

          if index + 1 < episodes.count()
            index = index + 1
          else
            index = 0
          end if

          if is_playable(episodes[index]) = false
            exit while
          end if
        else
          ShowMessageDialog("", "Player Info: Something went wrong!")
          return
        end if
      else
        ShowMessageDialog("", cPlay.message)
        return
      end if
    end while
  else


    ' no autoplay
    ep = episodes[index]

    if fromSearch <> true
      m.home_y = index
    else
      m.search_x = index
    end if

    cPlay = canPlay(ep)
    ' print cPlay
    if cPlay.play = true then
      if cPlay.auth_type = "app_key" then
        player_info = get_player_info(ep.id, {"app_key": cPlay.auth_key})
      else if cPlay.auth_type = "access_token" then
        player_info = get_player_info(ep.id, {"access_token": cPlay.auth_key})
      else
        ShowMessageDialog("", "Something went wrong!")
        return
      end if

      if show_ads(ep) = true
        videoScr = play_episode_with_ad(episodes, index, offset, fromSearch, player_info)
      else
        videoScr = play_episode_ad_free(episodes, index, offset, fromSearch, player_info)
      end if

      if type(videoScr) = "roInt" then
        return
      else if type(videoScr) = "roVideoScreen" then
        videoScr.close()
      end if
    else
      ShowMessageDialog("", cPlay.message)
      return
    end if
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

Function play_episode_ad_free(episodes as object, index as integer, offset as integer, fromSearch as Boolean, player_info as Object) as Object

    print "Ad Free Epsiode"

    episode = episodes[index]

    'get the stream information right before I play it
    episode.stream = player_info.stream
    episode.StreamFormat = player_info.format
    episode.ads = player_info.ads
    episode.playStart = offset

    canvas = CreateObject("roImageCanvas")
    canvas.SetLayer(1, {color: "#000000"})
    canvas.SetLayer(2, {text: "Loading..."})
    canvas.Show()

    videoScreen = PlayVideoContent(episode)

    playContent = true
    while playContent
        videoMsg = wait(0, videoScreen.GetMessagePort())
        if type(videoMsg) = "roVideoScreenEvent"
            if videoMsg.isStreamStarted()
                canvas.ClearLayer(2)
            end if

            if videoMsg.isPlaybackPosition()
                ' cache current playback position for resume after midroll ads
                curPos = videoMsg.GetIndex()
                RegWrite(episode.id, curPos.toStr())
            end if

            if videoMsg.isFullResult()
              RegDelete(episode.id)
              exit while
            end if

            if videoMsg.isScreenClosed()
              playContent = false
              videoScreen.close()
              return -1
            end if

        end if ' roVideoScreenEvent
    end while

    if type(videoScreen) = "roVideoScreen" then
      return videoScreen
    else
      return -1
    end if
End Function

Function play_episode_with_ad(episodes as object, index as integer, offset as integer, fromSearch as Boolean, player_info as Object) as Object

    print "Episode With Ad"

    episode = episodes[index]

    'get the stream information right before I play it
    episode.stream = player_info.stream
    episode.StreamFormat = player_info.format
    episode.ads = player_info.ads
    episode.playStart = offset

    canvas = CreateObject("roImageCanvas")
    canvas.SetLayer(1, {color: "#000000"})
    canvas.SetLayer(2, {text: "Loading..."})
    canvas.Show()

    ' Nielsen Dynamic Settings
    if m.config.enableNielsenDAR = true
      m.adIface.setNielsenGenre(episode.nielsengenre) ' const for now
      m.adIface.setNielsenProgramId(episode.title)
      m.adIface.setContentLength(episode.length)
    end if

    resetAds(episode, offset) ' too late to play
    curPos = offset
    playContent = true

    ' make sure to play preroll ad if it exists
    ad = get_ad(episode, curPos)
    if ad <> invalid
      if ad.url.len() > 0
        print "Provided: "; ad.url
        url = replace(ad.url)
        m.adIface.setAdUrl(url)
      else
        print "Use default Roku Ad"
        m.adIface.setAdUrl()
      end if

      adPods = m.adIface.getAds()
      playContent = m.adIface.showAds(adPods)
      if playContent
        ' resume video playback after ads
        episode.PlayStart = curPos
        videoScreen = PlayVideoContent(episode)
      end if
    else
      videoScreen = PlayVideoContent(episode)
    end if


    ' closingContentScreen = false
    contentDone = false
    while playContent
        videoMsg = wait(0, videoScreen.GetMessagePort())
        if type(videoMsg) = "roVideoScreenEvent"
            if videoMsg.isStreamStarted()
              canvas.ClearLayer(2)
            end if

            if videoMsg.isPlaybackPosition()
              ' cache current playback position for resume after midroll ads
              curPos = videoMsg.GetIndex()
              RegWrite(episode.id, curPos.toStr())

              ad = get_ad(episode, curPos)
              if ad <> invalid
                if ad.url.len() > 0
                  print "Provided: "; ad.url
                  url = replace(ad.url)
                  m.adIface.setAdUrl(url)
                else
                  print "Use default Roku Ad"
                  m.adIface.setAdUrl()
                end if

                videoScreen.close()

                adPods = m.adIface.getAds()
                playContent = m.adIface.showAds(adPods)
                if playContent and not contentDone
                  ' resume video playback after ads
                  episode.PlayStart = curPos
                  videoScreen = PlayVideoContent(episode)
                end if
              end if
            end if

            if videoMsg.isFullResult()
              RegDelete(episode.id)
              exit while
            end if

            if videoMsg.isScreenClosed()
                closingContentScreen = false
                videoScreen.close()
                return -1
            end if

            ' if not closingContentScreen ' don't check for any more ads while waiting for screen close
            '     if videoMsg.isScreenClosed() ' roVideoScreen sends this message last for all exit conditions
            '         playContent = false
            '     else if videoMsg.isFullResult()
            '         contentDone = true ' don't want to resume playback after postroll ads
            '     end if
            '
            '    ' check for midroll/postroll ad pods
            '    adPods = m.adIface.getAds(videoMsg)
            '    if adPods <> invalid and adPods.Count() > 0
            '        ' must completely close content screen before showing ads
            '        ' for some Roku platforms (e.g., RokuTV), calling Close() will not synchronously
            '        ' close the media player and may prevent a new media player from being created
            '        ' until the screen is fully closed (app has received the isScreenClosed() event)
            '        videoScreen.Close()
            '        closingContentScreen = true
            '    end if
            ' else if videoMsg.isScreenClosed()
            '     closingContentScreen = false ' now safe to render ads
            '     videoScreen.close()
            '     return -1
            ' end if ' closingContentScreen
            '
            ' if not closingContentScreen and adPods <> invalid and adPods.Count() > 0
            '     ' now safe to render midroll/postroll ads
            '     playContent = m.adIface.showAds(adPods)
            '     playContent = playContent and not contentDone
            '     if playContent
            '         ' resume video playback after midroll ads
            '         episode.PlayStart = curPos
            '         videoScreen = PlayVideoContent(episode)
            '     end if
            ' end if ' !closingContentScreen
        end if ' roVideoScreenEvent
    end while

    if type(videoScreen) = "roVideoScreen" then
      return videoScreen
    else
      return -1
    end if
End Function

Function PlayVideoContent(content as Object) as Object
    ' roVideoScreen just closes if you try to resume or seek after ad playback,
    ' so just create a new instance of the screen...
    videoScreen = CreateObject("roVideoScreen")
    videoScreen.SetContent(content)
    ' need a reasonable notification period set if midroll/postroll ads are to be
    ' rendered at an appropriate time
    videoScreen.SetPositionNotificationPeriod(1)
    videoScreen.SetMessagePort(CreateObject("roMessagePort"))
    videoScreen.Show()

    return videoScreen
End Function

Function replace(url as string) as string
  r = CreateObject("roRegex", "spotxchange", "i")

  newUrl = url
  if r.IsMatch(newUrl)

    ut = CreateObject("roUrlTransfer")

    r = CreateObject("roRegex", "app\[bundle\]=\[REPLACE_ME\]", "")
    term = ut.escape("app[bundle]") + "=<AppBundle>"
    newUrl = r.Replace(newUrl, term)

    r = CreateObject("roRegex", "app\[name\]=\[REPLACE_ME\]", "")
    term = ut.escape("app[name]") + "=<AppName>"
    newUrl = r.Replace(newUrl, term)

    r = CreateObject("roRegex", "ip_addr=\[REPLACE_ME\]", "")
    di = CreateObject("roDeviceInfo")
    term = "ip_addr=" + di.GetIPAddrs()["eth1"].toStr()
    newUrl = r.Replace(newUrl, term)

    r = CreateObject("roRegex", "device\[ua\]=\[REPLACE_ME\]", "")
    term = ut.escape("device[ua]") + "=Roku" ' Roku by default
    newUrl = r.Replace(newUrl, term)

    ' print newurl
  end if

  return newUrl
End Function

function resetAds(episode as object, offset as integer)
  if offset > 0:
    if episode.ads.count() > 0
      for each ad in episode.ads
        if offset >= ad.offset
          print "This cannot be played. Too late. "; ad.offset
          ad.played = true
        end if
      end for
    end if
  end if
end function


Function get_ad(episode as object, offset as integer)
  if episode.ads.count() > 0
    for each ad in episode.ads
      if ad.played = false
        ' print ad.offset, offset
        ' print Abs(offset - ad.offset)
        if offset >= ad.offset and Abs(offset - ad.offset) < 5
          ad.played = true
          return ad
        end if
      end if
    end for
  end if
  return invalid
End Function
