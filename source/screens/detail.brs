' logic to show/refresh detail page based on category selected

Function displayShowDetailScreen(category as Object, index as Integer) As Integer

    if validateParam(category, "roAssociativeArray", "displayShowDetailScreen") = false return -1

    shows = category.episodes

    screen = preShowDetailScreen(category.name, shows[index].Title)

    index = showDetailScreen(screen, shows, index, category.name)

    return index
End Function

Function showDetailScreen(screen As Object, episodes As Object, index as Integer, categoryName as String) As Integer

    if validateParam(screen, "roSpringboardScreen", "showDetailScreen") = false return -1
    if validateParam(episodes, "roArray", "showDetailScreen") = false return -1

    refreshShowDetail(screen, episodes, index, categoryName)

    'remote key id's for left/right navigation
    remoteKeyLeft  = 4
    remoteKeyRight = 5

    while true
        msg = wait(0, screen.GetMessagePort())

        if type(msg) = "roSpringboardScreenEvent" then
            if msg.isScreenClosed()
                print "SETTING HOME Y"
                print m.home_y
                print "Screen closed"
                exit while
            else if msg.isRemoteKeyPressed()
                print "Remote key pressed"
                if msg.GetIndex() = remoteKeyLeft then
                        index = getPrevShow(episodes, index)
                        if index <> -1
                            refreshShowDetail(screen, episodes, index, categoryName)
                        end if
                else if msg.GetIndex() = remoteKeyRight
                    index = getNextShow(episodes, index)
                        if index <> -1
                           refreshShowDetail(screen, episodes, index, categoryName)
                        end if
                endif
            else if msg.isButtonPressed()
                episode = episodes[index]
                if msg.GetIndex() = 1
                  print "PRESS BUTTON 1"
                    '1st button pressed
                    print "THERE WILL BE ADS!"
                    offset = RegRead(episode.id).toInt()

                    play_episode_with_ad(episodes, index, offset)
                    refreshShowDetail(screen,episodes,index, categoryName)
                endif
                if msg.GetIndex() = 2
                    '2nd button pressed (play video from start)
                    print "THERE WILL BE ADS!"
                    'play episode with the ad offset
                    play_episode_with_ad(episodes, index, 0)
                endif
                print "Button pressed: "; msg.GetIndex(); " " msg.GetData()
                refreshShowDetail(screen,episodes,index, categoryName)
            end if
        else
            print "Unexpected message class: "; type(msg)
        end if
    end while

    return index

End Function

Function refreshShowDetail(screen As Object, episodes As Object, index as Integer, categoryName as String) As Integer
    if m.home_y = invalid
      m.home_y = index
    endif

    show = episodes[m.home_y]

    screen.SetBreadcrumbText(categoryName, show.title)
    if validateParam(screen, "roSpringboardScreen", "refreshShowDetail") = false return -1
    if validateParam(episodes, "roArray", "refreshShowDetail") = false return -1

    screen.ClearButtons()

    if regread(show.id) <> invalid and regread(show.id).toint() >=30 then
      screen.AddButton(1, "Resume playing")
      screen.AddButton(2, "Play from beginning")
    else
      screen.addbutton(2, m.config.play_button_text)
    end if

    screen.SetContent(show)
    screen.Show()
End Function

'********************************************************
'** Get the next item in the list and handle the wrap
'** around case to implement a circular list for left/right
'** navigation on the springboard screen
'********************************************************
Function getNextShow(episodes As Object, index As Integer) As Integer
    if validateParam(episodes, "roArray", "getNextShow") = false return -1

    nextIndex = index + 1
    if nextIndex >= episodes.Count() or nextIndex < 0 then
       nextIndex = 0
    end if

    m.home_y = nextIndex

    show = episodes[nextIndex]
    if validateParam(show, "roAssociativeArray", "getNextShow") = false return -1

    return nextIndex
End Function

Function getPrevShow(episodes As Object, index As Integer) As Integer
    if validateParam(episodes, "roArray", "getPrevShow") = false return -1

    prevIndex = index - 1
    if prevIndex < 0 or prevIndex >= episodes.Count() then
        if episodes.Count() > 0 then
            prevIndex = episodes.Count() - 1
        else
            return -1
        end if
    end if

    m.home_y = prevIndex

    show = episodes[prevIndex]
    if validateParam(show, "roAssociativeArray", "getPrevShow") = false return -1

    return prevIndex
End Function

Function preShowDetailScreen(breadA=invalid, breadB=invalid) As Object
    port=CreateObject("roMessagePort")
    screen = CreateObject("roSpringboardScreen")

    'set the Zype configs for the detail screen
    screen.SetDescriptionStyle(m.config.springboard_description_style)
    screen.SetDisplayMode(m.config.scale_mode)
    screen.SetStaticRatingEnabled(false)
    screen.SetPosterStyle(m.config.springboard_poster_style)

    screen.SetMessagePort(port)
    if breadA<>invalid and breadB<>invalid then
        screen.SetBreadcrumbText(breadA, breadB)
    end if

    return screen
End Function
