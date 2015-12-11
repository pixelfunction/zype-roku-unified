Function displayShowDetailScreen(category as Object, index as Integer) As Integer
    if validateParam(category, "roAssociativeArray", "displayShowDetailScreen") = false return -1
    shows = category.episodes
    screen = preShowDetailScreen(category.name, shows[index].Title)
    showDetailScreen(screen, shows, index, category.name)
    return 1
End Function

Function preShowDetailScreen(breadA=invalid, breadB=invalid) As Object
    port=CreateObject("roMessagePort")
    screen = CreateObject("roSpringboardScreen")

    screen.SetDescriptionStyle(m.config.springboard_description_style)
    screen.SetDisplayMode(m.config.scale_mode)
    screen.SetStaticRatingEnabled(false)
    screen.SetPosterStyle(m.config.springboard_poster_style)
    screen.SetBreadcrumbEnabled(m.config.springboard_breadcrumb_enabled)

    screen.SetMessagePort(port)
    if breadA<>invalid and breadB<>invalid then
        screen.SetBreadcrumbText(breadA, breadB)
    end if
    return screen
End Function

'***************************************************************
'** The show detail screen (springboard) is where the user sees
'** the details for a show and is allowed to select a show to
'** begin playback.  This is the main event loop for that screen
'** and where we spend our time waiting until the user presses a
'** button and then we decide how best to handle the event.
'***************************************************************
Function showDetailScreen(screen As Object, episodes As Object, index as Integer, categoryName as String) As Integer

    if validateParam(screen, "roSpringboardScreen", "showDetailScreen") = false return -1
    if validateParam(episodes, "roArray", "showDetailScreen") = false return -1

    if m.home_y = invalid
      m.home_y = index
    end if

    refreshShowDetail(screen, episodes, m.home_y, categoryName)

    'remote key id's for left/right navigation
    remoteKeyLeft  = 4
    remoteKeyRight = 5

    while true
        msg = wait(0, screen.GetMessagePort())
        if type(msg) = "roSpringboardScreenEvent" then
            if msg.isScreenClosed()
                exit while
            else if msg.isRemoteKeyPressed()
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
                end if
            else if msg.isButtonPressed()
              episode = episodes[index]

              if msg.GetIndex() = 0 then
                ShowFullDescription(episode)
              end if

              if msg.GetIndex() = 1 then
                offset = RegRead(episode.id).toInt()
                play(episodes, m.home_y, offset)
              end if

              if msg.GetIndex() = 2 then
                play(episodes, m.home_y, 0)
              end if

              if msg.GetIndex() = 3 then
                show_link_modal(episode.title)
              end if

              if msg.GetIndex() = 4
                res = subscribe(episode, m.monthly_sub)
                if res
                  success_dialog(episode, m.monthly_sub)
                else
                  error_dialog(episode)
                end if
              end if

              if msg.GetIndex() = 5
                res = subscribe(episode, m.yearly_sub)
                if res
                  success_dialog(episode, m.yearly_sub)
                else
                  error_dialog(episode)
                end if
              end if

              if msg.GetIndex() = 6
                res = purchase_item(episode)
                if res
                  success_dialog(episode)
                else
                  error_dialog(episode)
                end if
              end if

              refreshShowDetail(screen, episodes, m.home_y, categoryName)
            end if
        else
            print "Unexpected message class: "; type(msg)
            exit while
        end if
    end while
    screen.close()
    return 1
End Function

'**************************************************************
'** Refresh the contents of the show detail screen. This may be
'** required on initial entry to the screen or as the user moves
'** left/right on the springboard.  When the user is on the
'** springboard, we generally let them press left/right arrow keys
'** to navigate to the previous/next show in a circular manner.
'** When leaving the screen, the should be positioned on the
'** corresponding item in the poster screen matching the current show
'**************************************************************
Function refreshShowDetail(screen As Object, episodes As Object, index as Integer, categoryName as String) As Integer
  if validateParam(screen, "roSpringboardScreen", "refreshShowDetail") = false return -1
  if validateParam(episodes, "roArray", "refreshShowDetail") = false return -1

  ' @refactored this force to dump the old port with needless clicks, and etc.
  ' it creates a new MessagePort object and binds it to the screen object.
  ' then we force the garbage collector to remove the previous port.
  port=CreateObject("roMessagePort")
  screen.SetMessagePort(port)
  RunGarbageCollector()

  if m.home_y = invalid
    m.home_y = index
  end if

  show = episodes[index]
  'print show
  screen.SetBreadcrumbText(categoryName, show.title)

  screen.ClearButtons()
  screen.AddButton(0, "View Full Description")

  if is_playable(show) = true
    if regread(show.id) <> invalid and regread(show.id).toint() >=30 then
      screen.AddButton(1, "Resume playing")
      screen.AddButton(2, "Play from beginning")
    else
      screen.addbutton(2, m.config.play_button_text)
    end if
  else:
    if m.config.monetization_type = "USVOD"
      screen.AddButton(3, m.config.subscription_button)
    else if m.config.monetization_type = "NSVOD"
      if m.monthly_sub <> invalid
        screen.AddButton(4, m.monthly_sub.button)
      end if
      if m.yearly_sub <> invalid
        screen.AddButton(5, m.yearly_sub.button)
      end if
    else if m.config.monetization_type = "EST"
      screen.AddButton(6, "Purchase for " + show.cost + "!")
    end if
  end if

  screen.SetContent(show)
  screen.Show()
  return 1
End Function

'******************************************************
' Can play the video?
'******************************************************
' @toberefactored
Function is_playable(episode as object) as Boolean
  if m.config.monetization_type = "AVOD"
     return true
  else if m.config.monetization_type = "USVOD"
    if episode.SubscriptionRequired = true and is_linked() <> true
      return false
    else
      return true
    end if
  else if m.config.monetization_type = "NSVOD"
    if episode.SubscriptionRequired = true and is_subscribed() <> true
      return false
    else
      return true
    end if
  else if m.config.monetization_type = "EST"
    print episode
    if episode.PurchaseRequired = true and is_purchased(episode) <> true
      return false
    else
      return true
    end if
  else
    return false
  end if
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

    show = episodes[nextIndex]
    if validateParam(show, "roAssociativeArray", "getNextShow") = false return -1

    m.home_y = nextIndex

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

    show = episodes[prevIndex]
    if validateParam(show, "roAssociativeArray", "getPrevShow") = false return -1

    m.home_y = prevIndex

    return prevIndex
End Function

' show screen with full description
Function ShowFullDescription(episode as Object) As Void
  port = CreateObject("roMessagePort")
  screen = CreateObject("roParagraphScreen")
  screen.SetMessagePort(port)
  screen.SetTitle("Full Description")
  screen.AddHeaderText(episode.title)
  screen.AddParagraph(episode.description)
  screen.Show()
  while true
      dlgMsg = wait(0, screen.GetMessagePort())
      If type(dlgMsg) = "roParagraphScreenEvent"
          if dlgMsg.isScreenClosed()
              exit while
          end if
      end if
  end while
  screen.close()
End Function
