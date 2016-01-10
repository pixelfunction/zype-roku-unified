Function search_results_screen(query As String) as void
  screen = CreateObject("roPosterScreen")
  port = CreateObject("roMessagePort")
  screen.SetMessagePort(port)

  screen.SetBreadcrumbText(m.config.search_title, query)
  screen.SetListStyle(m.config.search_layout)

  search_info = get_search_results(query)
  results = search_info.episodes
  screen.SetContentList(results)

  screen.show()

  while (true)
    if(results.Count() <= 0)
      screen.ShowMessage(m.config.search_error_text)
    endif

    msg = wait(0, port)
    if type(msg) = "roPosterScreenEvent"
      if (msg.isScreenClosed())
        exit while
      else if msg.isListItemSelected()
        if(results.Count() <= 0)
          exit while
        else
          displayShowDetailScreen(search_info, msg.GetIndex())

          ' prevent multiple button presses
          port=CreateObject("roMessagePort")
          screen.SetMessagePort(port)
          RunGarbageCollector()
        endif
      endif
    endif
  end while

  screen.close()
End Function
