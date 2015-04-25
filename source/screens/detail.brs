Function displayShowDetailScreen(category as Object, showIndex as Integer) As Integer

    'if validateParam(category, "roAssociativeArray", "displayShowDetailScreen") = false return -1

    shows = category.episodes

    screen = preShowDetailScreen("Home", shows[showIndex].Title)

    showIndex = showDetailScreen(screen, shows, showIndex)

    return showIndex
End Function

Function showDetailScreen(screen As Object, showList As Object, showIndex as Integer) As Integer

    'if validateParam(screen, "roSpringboardScreen", "showDetailScreen") = false return -1
    'if validateParam(showList, "roArray", "showDetailScreen") = false return -1

    refreshShowDetail(screen, showList, showIndex)

    'remote key id's for left/right navigation
    remoteKeyLeft  = 4
    remoteKeyRight = 5

    while true
        msg = wait(0, screen.GetMessagePort())

        if type(msg) = "roSpringboardScreenEvent" then
            if msg.isScreenClosed()
                print "Screen closed"
                exit while
            else if msg.isRemoteKeyPressed()
                print "Remote key pressed"
                if msg.GetIndex() = remoteKeyLeft then
                        showIndex = getPrevShow(showList, showIndex)
                        if showIndex <> -1
                            refreshShowDetail(screen, showList, showIndex)
                        end if
                else if msg.GetIndex() = remoteKeyRight
                    showIndex = getNextShow(showList, showIndex)
                        if showIndex <> -1
                           refreshShowDetail(screen, showList, showIndex)
                        end if
                endif
            else if msg.isButtonPressed()
                print "ButtonPressed"
                print "ButtonPressed"
                episode = showList[showIndex]
                if msg.GetIndex() = 1
                  print "PRESS BUTTON 1"
                    '1st button pressed
                    if m.config.play_ads = true
                      offset = RegRead(episode.id).toInt()
                      print "!******!"
                      print offset
                      print "!******!"

                      ad = get_ad(episode, offset)
                      play_episode_with_ad(episode, ad)
                    else
                      offset = RegRead(episode.id).toInt()
                      play_episode(episode, offset)
                    endif
                    refreshShowDetail(screen,showList,showIndex)
                endif
                if msg.GetIndex() = 2
                  print "PRESS BUTTON 2"
                    '2nd button pressed (play video from start)
                    if m.config.play_ads = true
                      'play episode with the ad offset
                      ad = get_ad(episode, 0)
                      play_episode_with_ad(episode, ad)
                    else
                      'play episode at 0
                      play_episode(episode, 0)
                    endif
                endif
                if msg.GetIndex() = 3
                endif
                print "Button pressed: "; msg.GetIndex(); " " msg.GetData()
            end if
        else
            print "Unexpected message class: "; type(msg)
        end if
    end while

    return showIndex

End Function

Function refreshShowDetail(screen As Object, showList As Object, showIndex as Integer) As Integer

    if validateParam(screen, "roSpringboardScreen", "refreshShowDetail") = false return -1
    if validateParam(showList, "roArray", "refreshShowDetail") = false return -1

    show = showList[showIndex]

    player_info = get_player_info(show.id)
    show.stream = player_info.stream
    print show.stream
    show.StreamFormat = player_info.format
    show.ads = player_info.ads
    print show.StreamFormat
    print show.stream
    print "REFRESHING STREAM URL"

    'Uncomment this statement to dump the details for each show
    'PrintAA(show)

    screen.ClearButtons()
    if regread(show.id) <> invalid and regread(show.id).toint() >=30 then
    screen.AddButton(1, "Resume playing")
    screen.AddButton(2, "Play from beginning")
    else
    screen.addbutton(2,"Play")
    end if
    screen.SetContent(show)
    screen.Show()



End Function

'********************************************************
'** Get the next item in the list and handle the wrap
'** around case to implement a circular list for left/right
'** navigation on the springboard screen
'********************************************************
Function getNextShow(showList As Object, showIndex As Integer) As Integer
    if validateParam(showList, "roArray", "getNextShow") = false return -1

    nextIndex = showIndex + 1
    if nextIndex >= showList.Count() or nextIndex < 0 then
       nextIndex = 0
    end if

    show = showList[nextIndex]
    if validateParam(show, "roAssociativeArray", "getNextShow") = false return -1

    return nextIndex
End Function


'********************************************************
'** Get the previous item in the list and handle the wrap
'** around case to implement a circular list for left/right
'** navigation on the springboard screen
'********************************************************
Function getPrevShow(showList As Object, showIndex As Integer) As Integer
    if validateParam(showList, "roArray", "getPrevShow") = false return -1

    prevIndex = showIndex - 1
    if prevIndex < 0 or prevIndex >= showList.Count() then
        if showList.Count() > 0 then
            prevIndex = showList.Count() - 1
        else
            return -1
        end if
    end if

    show = showList[prevIndex]
    if validateParam(show, "roAssociativeArray", "getPrevShow") = false return -1

    return prevIndex
End Function


'need to add ad logic in here
Function old_detail_screen(episode As Object, c1 As String, c2 As String) as object
  screen = CreateObject("roSpringboardScreen")
  port = CreateObject("roMessagePort")
  screen.SetMessagePort(port)

  screen.SetDescriptionStyle(m.config.springboard_description_style)
  screen.SetDisplayMode(m.config.scale_mode)
  screen.SetBreadcrumbText(c1, c2)
  screen.SetStaticRatingEnabled(false)
  screen.SetPosterStyle(m.config.springboard_poster_style)

  screen.SetContent(episode)
  screen.ClearButtons()
  screen.AddButton(1, m.config.play_button_text)

  'if there is something is the registry reader for last play position
  if regread(episode.id) <> invalid and regread(episode.id).toint() >=30 then
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
        player_info = get_player_info(episode.id)
        episode.stream = player_info.stream
        print episode.stream
        episode.StreamFormat = player_info.format
        print episode.StreamFormat
        print episode.stream

        if msg.GetIndex() = 1
          if m.config.play_ads = true
            'play episode with the ad offset
            episode.ads = player_info.ads
            ad = get_ad(episode, 0)
            play_episode_with_ad(episode, ad)
          else
            'play episode at 0
            play_episode(episode, 0)
          endif
        else if msg.GetIndex() = 2
          if m.config.play_ads = true
            episode.ads = player_info.ads
            offset = RegRead(episode.id).toInt()
            print "******!"
            print offset
            print "******!"

            ad = get_ad(episode, offset)
            play_episode_with_ad(episode, ad)
          else
            offset = RegRead(episode.id).toInt()
            play_episode(episode, offset)
          endif
        endif
      endif
    endif
  end while

End Function

Function preShowDetailScreen(breadA=invalid, breadB=invalid) As Object
    port=CreateObject("roMessagePort")
    screen = CreateObject("roSpringboardScreen")
    screen.SetDescriptionStyle("video")
    screen.SetMessagePort(port)
    if breadA<>invalid and breadB<>invalid then
        screen.SetBreadcrumbText(breadA, breadB)
    end if

    return screen
End Function
