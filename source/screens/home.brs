Function home_screen()
  screen = CreateObject("roGridScreen")
  port = CreateObject("roMessagePort")
  screen.SetMessagePort(port)
  screen.show()

  screen.SetBreadcrumbText(m.config.home_name, "")
  screen.setGridStyle(m.config.grid_layout)
  screen.SetDisplayMode(m.config.scale_mode)

  row_titles = CreateObject("roArray", 1, true)

  'get all featured info
  featured = get_featured_playlist()

  'add featured playlist
  row_titles.push(featured.name)

  'get category titles
  category_titles = CreateObject("roArray", 1, true)
  category_info = get_category_info(m.config.category_id)
  category_name = category_info.name
  category_titles = category_info.values

  category_value_size = category_titles.count()
  print "CATEGORY VALUE SIZE"
  print category_value_size
  print "****"

  for each title in category_titles
    row_titles.push(title)
  endfor

  'get toolbar info
  toolbar = grid_toolbar()
  row_titles.push(toolbar.name)

  'set up the rows and titles of the rows
  screen.SetupLists(row_titles.count())
  screen.SetListNames(row_titles)

  'set up the first row for featured playlists
  screen.SetContentList(0, featured.episodes)
  screen.SetFocusedListItem(0,0)

  'iterate through each category title and display after api call
  i = 1
  for each title in category_titles
    category = get_category_playlist(category_name ,title, m.config.category_id)
    print "row"
    print i
    screen.SetContentList(i, category.episodes)
    i = i + 1
  end for

  toolbar = grid_toolbar()
  screen.SetContentList(i, toolbar.tools)

  while(true)
    msg = wait(0, port)
    if type(msg) = "roGridScreenEvent"
      if (msg.isListItemSelected())
        if(msg.GetIndex() = 0)
          detail_screen(featured.episodes[msg.GetData()], "Home", featured.episodes[msg.GetData()].title)
        else if(msg.GetIndex() = row_titles.count()-1)
          toolbar.tools[msg.GetData()].function_name()
        else
          detail_screen(categories[msg.GetIndex()-1].episodes[msg.GetData()], "Home", categories[msg.GetIndex()-1].episodes[msg.GetData()].title)
        endif
      endif
    endif
  end while

End Function
