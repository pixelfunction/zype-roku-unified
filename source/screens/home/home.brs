Function home()
  ' if m.config.nested = true
  '   print "Nested"
  '   channels()
  ' else
  '   print "Flat"
  '   grid()
  ' end if
  playlists_grid()
End Function

function load_playlist_videos(index as integer)
  playlist = m.playlists[index]
  if m.playlists_content[index] = Invalid
    videos = get_playlist_videos(playlist._id)
    m.playlists_content[index] = {
      name: "",
      episodes: videos
    }
  end if
  return m.playlists_content[index].episodes
end function

Function playlists_grid()
    port = CreateObject("roMessagePort")
    grid = CreateObject("roGridScreen")
    grid.SetMessagePort(port)

    grid.setGridStyle(m.config.grid_layout)
    grid.SetDisplayMode(m.config.scale_mode)
    grid.SetBreadcrumbEnabled(m.config.home_breadcrumb_enabled)

    m.playlists = get_playlists()
    m.playlists_content = CreateObject("roArray", m.playlists.count(), true)

    rowTitles = CreateObject("roArray", 1, true)
    for each pl in m.playlists
      rowTitles.push(pl.title)
    end for

    grid.SetupLists(rowTitles.Count())
    grid.SetListNames(rowTitles)

    grid.SetContentListSubset(0, load_playlist_videos(0), 0, 5)
    if m.playlists.count() > 1
      grid.SetContentListSubset(1, load_playlist_videos(1), 0, 5)
    end if

    grid.Show()
    while true
       msg = wait(0, port)

       current_row = msg.GetIndex()
       current_col = msg.GetData()

       grid.SetContentListSubset(current_row, load_playlist_videos(current_row), current_col, 5)

       next_row_1 = current_row + 1
       if next_row_1 < rowTitles.count()
        grid.SetContentListSubset(next_row_1, load_playlist_videos(next_row_1), current_col, 5)
       end if

       if type(msg) = "roGridScreenEvent" then
           if msg.isScreenClosed() then
               exit while
           elseif msg.isListItemFocused()
               print "Focused msg: ";msg.GetMessage();"row: ";msg.GetIndex();
               print " col: ";msg.GetData()
           elseif msg.isListItemSelected()
               print "Selected msg: ";msg.GetMessage();"row: ";msg.GetIndex();
               print " col: ";msg.GetData()

               m.home_y = current_col
               m.home_x = current_row
              '  refresh global item tracking vars
               if m.previous_home_x <> m.home_x OR m.previous_home_y <> m.home_y
                 m.previous_home_x = m.home_x
                 m.previous_home_y = m.home_y
               end if

              '  print m.playlists_content[current_row]
               displayShowDetailScreen(m.playlists_content[current_row], current_col, false)

               ' prevent multiple button presses
               port=CreateObject("roMessagePort")
               grid.SetMessagePort(port)
               RunGarbageCollector()
           endif
       endif
    end while
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

    m.playlist = get_playlist(channel.playlist_id)
    if channel.category_id <> invalid
      m.category = get_category_info(channel.category_id)
    else
      'there is no category_id so create a fake category
      m.category = {name: "", values: ["All Videos"]}
    end if
  end if
  m.toolbar = grid_toolbar()

  ' positions for content
  playlist_position = 0
  toolbar_position = m.category.values.count() + 1
  category_start_position = 1
  category_end_position = m.category.values.count()

  m.row_titles = CreateObject("roArray", 1, true)
  m.row_titles[playlist_position] = m.playlist.name
  m.row_titles[toolbar_position] = m.toolbar.name
  AddCategoryTitles(category_start_position, category_end_position, m.row_titles)

  total_rows = m.row_titles.count()
  screen.SetupLists(total_rows)
  screen.SetListNames(m.row_titles)

  subsetLength = 5
  screen.SetContentListSubset(playlist_position, m.playlist.episodes, 0, subsetLength)
  screen.SetContentList(toolbar_position, m.toolbar.tools)

  m.categories = CreateObject("roArray", 1, true)
  screen.SetContentListSubset(category_start_position, load_data(category_start_position), 0, subsetLength)

  screen.SetFocusedListItem(0,0)
  screen.show()

  while(true)
    msg = wait(0, port)

    current_row = msg.GetIndex()
    current_col = msg.GetData()

    if current_row = playlist_position
      screen.SetContentListSubset(current_row, m.playlist.episodes, current_col, subsetLength)
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
        else if row = toolbar_position
          if m.toolbar.tools[msg.GetData()].appId <> invalid
            m.toolbar.tools[msg.GetData()].function_name(m.toolbar.tools[msg.GetData()].appId)
          else
            m.toolbar.tools[msg.GetData()].function_name()
          end if
        else
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
    if m.config.category_id <> invalid
      category = get_category_playlist(m.category.name, title, m.config.category_id)
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
    if m.config.prepend_category_name = true
      arr[idx] = m.category.name + " " + title
    else
      arr[idx] = title
    end if
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

    grid.SetGridStyle(m.config.grid_layout)
    grid.SetBreadcrumbText(m.config.home_name, "")
    grid.SetBreadcrumbEnabled(m.config.home_breadcrumb_enabled)
    grid.SetCounterVisible(false)
    grid.SetDescriptionVisible(false)
    grid.SetMessagePort(port)

    series = get_series()

    'only want to include 4 tiles per row
    total_rows = (series.count() / 4) + 1
    total_rows = ceiling(total_rows)
    print total_rows

    'need to unhardcode number for rowTitles
    rowTitles = CreateObject("roArray", total_rows, true)

    for j = 0 to total_rows - 1
        rowTitles.Push("")
    end for

    grid.SetupLists(total_rows)

    grid.SetListNames(rowTitles)

    for j = 0 to 3
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
