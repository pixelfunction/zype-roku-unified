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

                if msg.GetIndex() = 0 then
                  ShowFullDescription(episode)
                    endif

                if msg.GetIndex() = 1 then
                  offset = RegRead(episode.id).toInt()
                  play_episode(episodes, index, offset)
                    refreshShowDetail(screen,episodes,index, categoryName)
                endif

                if msg.GetIndex() = 2 then
                  play_episode(episodes, index, 0)
                    endif

                if msg.GetIndex() = 3 then
                  show_link_modal(episode.title)
                endif

                if msg.GetIndex() = 4
                  print "PAY FOR MONTHLY"
                  purchase_subscription(episode, screen, m.monthly_sub)
                endif

                if msg.GetIndex() = 5
                  print "PAY FOR YEARLY"
                  purchase_subscription(episode, screen, m.yearly_sub)
                endif

                refreshShowDetail(screen,episodes,index, categoryName)
            end if
        else
            print "Unexpected message class: "; type(msg)
        end if
    end while
    return index
End Function


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
        endif
    end while
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

    screen.AddButton(0, "View Full Description")

    if show.SubscriptionRequired <> true OR m.linked = true
      if regread(show.id) <> invalid and regread(show.id).toint() >=30 then
        screen.AddButton(1, "Resume playing")
        screen.AddButton(2, "Play from beginning")
      else
        screen.addbutton(2, m.config.play_button_text)
      end if
    else
      if m.app_type = "UNIVERSAL_SVOD" then
        print "UNI"
        if show.SubscriptionRequired then
          screen.AddButton(3, m.config.subscription_button)
        end if
      else if m.app_type = "NATIVE_SVOD" then
        if m.monthly_sub <> invalid
          screen.AddButton(4, m.monthly_sub.button)
        endif
        if m.yearly_sub <> invalid
          screen.AddButton(5, m.yearly_sub.button)
        end if
      else if m.app_type = "EST" then

      endif
    endif

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

Function prompt_purchase_button(episode as object) as boolean
  print episode.id

  pay_button = false

  'see if video is in the purchase catalog
  for each item in m.store_items
    print item.description
    if item.code = episode.id
      print "***"
      print item.code
      print "***"
      'set the episode order code for payment in next modal
      episode.order_code = item.code
      episode.cost = item.cost
      pay_button = true
    end if
  end for

  if pay_button
    for each purchase in m.user_purchases
      if purchase.code = episode.id
        print "CHANGE PAY BUTTON TO FALSE"
        pay_button = false
      end if
    end for
  end if

  print pay_button
  return pay_button
end function

Function purchase_video(episode, screen) as void
  port = CreateObject("roMessagePort")
  m.store.SetMessagePort(port)

  order = [{code: episode.order_code, qty: 1}]

  m.store.SetOrder(order)
  print m.store.GetOrder()
  result = m.store.DoOrder()

  if(result = true)
    'add the episode as one that has been purchased
    m.user_purchases.push({code: episode.title, code: episode.order_code, description: episode.title})

    'show the success modal
    success_purchase_modal(episode, screen)
  else
    print "ORDER FAILED"
    error_purchase_modal(episode)
  endif
end Function
