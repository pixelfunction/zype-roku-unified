Function home()
  if m.config.nested = true
    print "Nested"
    channels()
  else
    print "Flat"
    grid()
  end if
End Function

' this is called if the nested category is false
Function grid(channel=invalid as object) as Void
  screen = CreateObject("roGridScreen")
  port = CreateObject("roMessagePort")
  screen.SetMessagePort(port)

  if channel = invalid
    screen.SetBreadcrumbText(m.config.home_name, "")
    screen.setGridStyle(m.config.grid_layout)
    screen.SetDisplayMode(m.config.scale_mode)
    screen.SetBreadcrumbEnabled(m.config.home_breadcrumb_enabled)

    m.playlist = get_featured_playlist()
    m.category = get_category()
  else
    screen.SetBreadcrumbText("", channel.title)
    screen.SetBreadcrumbEnabled(m.config.category_home_breadcrumb_enabled)
    screen.setGridStyle(m.config.grid_layout)
    screen.SetDisplayMode(m.config.scale_mode)

    if channel.playlist_id <> invalid
      m.playlist = get_playlist(channel.playlist_id)
    else
      m.playlist = get_featured_playlist()
    endif

    if channel.category_id <> invalid
      print m.category
      m.category = get_category_info(channel.category_id)
    else
      'there is no category_id so create a fake category
      m.category = {name: "", values: ["All Videos"]}
    end if

  end if
  m.toolbar = grid_toolbar()

  cross_channels = get_cross_channels()
	
	m.my_videos = invalid
	
  if m.config.device_linking = true
		if is_linked() and PinExist()
    	oauth = GetAccessToken()
    	if oauth <> invalid
				m.my_videos = get_my_library({"per_page": "100", "access_token": oauth.access_token})
			end if
		end if
	end if
	
	if m.my_videos <> invalid and m.my_videos.episodes.count() > 0
	  ' positions for content
		my_videos_position = 0
	  playlist_position = 1
	  category_start_position = 2
	  category_end_position = category_start_position + m.category.values.count() - 1 
	else
	  ' positions for content
		my_videos_position = -1
	  playlist_position = 0
	  category_start_position = 1
	  category_end_position = category_start_position + m.category.values.count() - 1
	end if

  if cross_channels <> invalid
    cross_channels_position = category_end_position + 1
    toolbar_position = cross_channels_position + 1
  else
    cross_channels_position = -1
    toolbar_position = category_end_position + 1
  end if
	

  m.row_titles = CreateObject("roArray", 1, true)
  m.row_titles[playlist_position] = m.playlist.name
  m.row_titles[toolbar_position] = m.toolbar.name
  AddCategoryTitles(category_start_position, category_end_position, m.row_titles)


	if m.my_videos <> invalid and m.my_videos.episodes.count() > 0
		m.row_titles[my_videos_position] = m.my_videos.name
		' print m.my_videos
	endif
	
  if cross_channels <> invalid
    m.row_titles[cross_channels_position] = cross_channels.name
  end if

  total_rows = m.row_titles.count()
  screen.SetupLists(total_rows)

  ' prepend category name to every row title
  if m.config.prepend_category_name = true
    m.row_category_titles = []
    for each t in m.row_titles
      m.row_category_titles.push(m.category.name + " / " + t)
    end for
    screen.SetListNames(m.row_category_titles)
  else
    screen.SetListNames(m.row_titles)
  end if

  subsetLength = 5
  screen.SetContentListSubset(playlist_position, m.playlist.episodes, 0, subsetLength)
  screen.SetContentList(toolbar_position, m.toolbar.tools)

  m.categories = CreateObject("roArray", 1, true)
  screen.SetContentListSubset(category_start_position, load_data(category_start_position), 0, subsetLength)

	if m.my_videos <> invalid and m.my_videos.episodes.count() > 0
		screen.SetContentListSubset(my_videos_position, m.my_videos.episodes, 0, subsetLength)
	endif
	
  if cross_channels <> invalid
    screen.SetContentList(cross_channels_position, cross_channels.channels)
  end if

  screen.SetFocusedListItem(0,0)
  screen.show()

  while(true)
    msg = wait(0, port)

    current_row = msg.GetIndex()
    current_col = msg.GetData()

    if current_row = playlist_position
      screen.SetContentListSubset(current_row, m.playlist.episodes, current_col, subsetLength)
    end if

    if m.my_videos <> invalid and m.my_videos.episodes.count() > 0 and current_row = my_videos_position
      screen.SetContentListSubset(current_row, m.my_videos.episodes, current_col, subsetLength)
    end if
		
    if current_row <= category_end_position and current_row >= category_start_position
      screen.SetContentListSubset(current_row, load_data(current_row), current_col, subsetLength)

      next_row_1 = current_row + 1
      if next_row_1 <= category_end_position
        screen.SetContentListSubset(next_row_1, load_data(next_row_1), current_col, subsetLength)
      end if

      next_row_2 = current_row + 2
      if next_row_2 <= category_end_position
        screen.SetContentListSubset(next_row_2, load_data(next_row_2), current_col, subsetLength)
      end if
    end if

    if type(msg) = "roGridScreenEvent"
      if (msg.isListItemSelected())
        row = msg.GetIndex()
        m.home_y = msg.GetData()
        m.home_x = row

        if row = playlist_position
          displayShowDetailScreen(m.playlist, msg.GetData(), false)
				endif
				
        if row = my_videos_position
					print "CLICK" 
          displayShowDetailScreen(m.my_videos, msg.GetData(), false)
				endif
        
				if row = toolbar_position
            m.toolbar.tools[msg.GetData()].function_name()
        end if
				
				if row = cross_channels_position
            cross_channels.channels[msg.GetData()].function_name(cross_channels.channels[msg.GetData()].appId)
        end if
				
				if row >= category_start_position and row <= category_end_position then
          category = m.categories[current_row]
          displayShowDetailScreen(category, msg.GetData(), false)
        end if

        ' prevent multiple button presses
        port=CreateObject("roMessagePort")
        screen.SetMessagePort(port)
        RunGarbageCollector()

        if m.previous_home_x <> m.home_x OR m.previous_home_y <> m.home_y
          screen.SetFocusedListItem(m.home_x, m.home_y)
          'set the m.previous_home_x and m.previous_home_y to current status
          m.previous_home_x = m.home_x
          m.previous_home_y = m.home_y
        end if
      end if
      if msg.isScreenClosed()
        exit while
      end if
    end if
  end while

  ' should be reachable only on Exit Event
  screen.close()
End Function

Function load_data(index as Integer) as Object
  if m.categories[index] = invalid
    title = m.row_titles[index]
    print title
    print m.category
    if m.category.id <> invalid
      category = get_category_playlist(m.category.name, title, m.category.id)
    else
      category = get_category_playlist(m.category.name, title, "*")
    end if
    m.categories[index] = {name: category.name, episodes: category.episodes}
    return category.episodes
  else
    return m.categories[index].episodes
  end if
End Function

Function AddCategoryTitles(start_idx as integer, end_idx as integer, arr as object)
  idx = start_idx
  for each title in m.category.values
    arr[idx] = title
    idx = idx + 1
  end for
End Function

Function get_category() as object
  category = {}
  if m.config.category_id <> invalid
    category_info = get_category_info(m.config.category_id)
  else
    'there is no category_id so create a fake category
    category_info = {name: "", values: ["All Videos"]}
  end if

  category.AddReplace("name", category_info.name)
  category.AddReplace("values", category_info.values)

  return category
End Function


' launches the nested home screen
Function channels() as void
    port = CreateObject("roMessagePort")
    grid = CreateObject("roGridScreen")

    ' print m.config.grid_layout
    if m.config.grid_layout <> invalid
      grid.SetGridStyle(m.config.grid_layout)
    end if

    if m.config.home_name <> invalid
      grid.SetBreadcrumbText(m.config.home_name, "")
    end if

    if m.config.home_breadcrumb_enabled <> invalid
      grid.SetBreadcrumbEnabled(m.config.home_breadcrumb_enabled)
    end if

    grid.SetMessagePort(port)

    series = get_series()

    'only want to include 4 tiles per row
    ' print series.count()
    total_rows = (series.count() / 4) + 1
    total_rows = ceiling(total_rows)
    ' print total_rows

    'need to unhardcode number for rowTitles
    rowTitles = CreateObject("roArray", total_rows, true)

    for j = 0 to total_rows - 1
        rowTitles.Push("")
    end for

    grid.SetupLists(total_rows)

    grid.SetListNames(rowTitles)

    for j = 0 to total_rows - 1
      list = CreateObject("roArray", total_rows, true)
      'get the pagination
      starting = (j * 4)
      ending = starting + 3
      for i = starting to ending
          if series[i] <> invalid
             o = CreateObject("roAssociativeArray")
             o.ContentType = "episode"
             o.Title = series[i].title
             o.Description = ""
             o.Description = series[i].description
             'o.ShortDescriptionLine1 = series[i].title
             o.ShortDescriptionLine2 = series[i].title
             o.SDPosterUrl = series[i].image
             o.HDPosterUrl = series[i].image
             list.Push(o)
          end if
       end for
       grid.SetContentList(j, list)
     end for

     'get toolbar info
     toolbar = grid_toolbar()
     grid.SetContentList(total_rows-1, toolbar.tools)

     grid.Show()
     grid.SetDescriptionVisible(false)

     while true
       msg = wait(0, port)

       if type(msg) = "roGridScreenEvent" then
         if msg.isScreenClosed() then
          exit while
         else if msg.isListItemFocused()
             'print "Focused msg: ";msg.GetMessage();"row: ";msg.GetIndex();
             'print " col: ";msg.GetData()
         else if msg.isListItemSelected()
            row = msg.GetIndex()
            col = msg.GetData()
            m.nested_y = col
            m.nested_x = row
            if msg.GetIndex() = total_rows - 1
              toolbar.tools[msg.GetData()].function_name()
            else
              index_position = col + (4 * row)
              'print series[index_position].title
              grid(series[index_position])
            end if

            ' prevent multiple button presses
            port=CreateObject("roMessagePort")
            grid.SetMessagePort(port)
            RunGarbageCollector()

            if m.previous_nested_x <> m.nested_x OR m.previous_nested_y <> m.nested_y
              print "changing focused list to"
              print m.nested_x
              print m.nested_y

              grid.SetFocusedListItem(m.nested_x, m.nested_y)

              'set the m.previous_home_x and m.previous_home_y to current status
              m.previous_nested_x = m.nested_x
              m.previous_nested_y = m.nested_y
            end if
         end if
       end if
     end while

     grid.close()
End Function
