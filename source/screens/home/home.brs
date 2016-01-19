Function home() as void

  if m.config.nested = true
    'print "Nested"
    nested_home()
    return
  end if

  screen = CreateObject("roGridScreen")
  port = CreateObject("roMessagePort")
  screen.SetMessagePort(port)

  screen.SetBreadcrumbText(m.config.home_name, "")
  screen.setGridStyle(m.config.grid_layout)
  screen.SetDisplayMode(m.config.scale_mode)
  screen.SetBreadcrumbEnabled(m.config.home_breadcrumb_enabled)

  row_titles = CreateObject("roArray", 1, true)
  m.categories = CreateObject("roArray", 1, true)

  'get all featured info
  featured = get_featured_playlist()

  'add featured playlist title
  row_titles.push(featured.name)

  'get category titles
  category_titles = CreateObject("roArray", 1, true)
  if m.config.category_id <> invalid
    category_info = get_category_info(m.config.category_id)
  else
    'there is no category_id so create a fake category
    category_info = {name: "", values: ["All Videos"]}
  end if
  category_name = category_info.name
  category_titles = category_info.values
  category_value_size = category_titles.count()

  for each title in category_titles
    if m.config.prepend_category_name = true
      row_titles.push(category_name + " " + title)
    else
      row_titles.push(title)
    end if
  end for

  'get toolbar info
  toolbar = grid_toolbar()
  row_titles.push(toolbar.name)

  'set up the rows and titles of the rows on the screen
  total_rows = row_titles.count()
  screen.SetupLists(total_rows)
  screen.SetListNames(row_titles)

  'set up the first row for featured playlists
  screen.SetContentList(0, featured.episodes)

  for preset=1 to m.loading_offset step 1
    load_category_row(row_titles, category_titles, preset, category_name, screen)
  end for

  screen.SetContentList(total_rows-1, toolbar.tools)
  screen.SetFocusedListItem(0,0)

  screen.show()

  while(true)
    msg = wait(0, port)

    'change the focused list item if m.home_x, or m.home_y position has changed via user interactions
    if m.previous_home_x <> m.home_x OR m.previous_home_y <> m.home_y
      screen.SetFocusedListItem(m.home_x, m.home_y)
      'set the m.previous_home_x and m.previous_home_y to current status
      m.previous_home_x = m.home_x
      m.previous_home_y = m.home_y
    end if

    current_row = msg.GetIndex()
    row_to_load = current_row + m.loading_group

    if (row_to_load > m.loading_offset)
      'need to iterate through all rows to make sure fast scrolling does not miss one
      for i=m.loading_offset to row_to_load step 1
        if m.categories[i] = invalid AND i < (total_rows - 1)
          load_category_row(row_titles, category_titles, i, category_name, screen)
        end if
      end for
    end if

    if type(msg) = "roGridScreenEvent"
      if (msg.isListItemSelected())
        row = msg.GetIndex()
        m.home_y = msg.GetData()
        m.home_x = row

        if(row = 0)
          displayShowDetailScreen(featured, msg.GetData(), false)
        else if(row = row_titles.count()-1)
          toolbar.tools[msg.GetData()].function_name()
        else
          if row > m.loading_offset
            category = m.categories[msg.GetIndex()]
          else
            category = m.categories[msg.GetIndex()-1]
          end if
          displayShowDetailScreen(category, msg.GetData(), false)
        end if

        ' prevent multiple button presses
        port=CreateObject("roMessagePort")
        screen.SetMessagePort(port)
        RunGarbageCollector()
      end if
      if (msg.isScreenClosed())
        exit while
      end if
    end if
  end while

  ' should be reachable only on Exit Event
  screen.close()
End Function

' **************************************************
' Home - Poster Screen (Category based only)
' @tobedone Fix SetFocusedListItem()
' **************************************************
Function home_posterscreen() as void
  mPort = CreateObject("roMessagePort")
  poster = CreateObject("roPosterScreen")
  poster.SetMessagePort(mPort)
  poster.SetListStyle("flat-episodic-16x9")

  'get category titles
  category_titles = CreateObject("roArray", 1, true)
  if m.config.category_id <> invalid
    category_info = get_category_info(m.config.category_id)
  else
    'there is no category_id so create a fake category
    category_info = {name: "", values: ["All Videos"]}
  end if
  category_name = category_info.name
  category_titles = category_info.values
  category_value_size = category_titles.count()

  row_titles = CreateObject("roArray", 1, true)

  for each title in category_titles
    row_titles.push(title)
  end for

  'get toolbar info
  toolbar = grid_toolbar()
  row_titles.push(toolbar.name)

  poster.SetListNames(row_titles)

  m.home_y = 0
  m.home_x = 0

  categoryItems = getDetails(category_name, category_titles[m.home_x]).episodes
  poster.SetContentList(categoryItems)
  poster.Show()

  while true
    msg = wait(0, poster.GetMessagePort())

    if m.previous_home_x <> m.home_x OR m.previous_home_y <> m.home_y
      'set the m.previous_home_x and m.previous_home_y to current status
      m.previous_home_x = m.home_x
      m.previous_home_y = m.home_y
    end if

    'change the focused list item if m.home_x, or m.home_y position has changed via user interactions

    if type(msg) = "roPosterScreenEvent"
      if msg.isListFocused()
        'print "Category Index= "; msg.GetIndex()
        m.home_x = msg.GetIndex()
      else if msg.isListSelected()
        m.home_x = msg.GetIndex()
        poster.SetContentList([])
        if m.home_x = row_titles.count() - 1
          categoryItems = toolbar.tools
        else
          categoryItems = getDetails(category_name, category_titles[m.home_x]).episodes
        endif
        poster.SetContentList(categoryItems)
        poster.SetFocusedListItem(0)
      else if msg.isListItemFocused()
        m.home_y = msg.GetIndex()
        'print"Category Index= "; m.home_x
        'print"Category Item index = "; msg.GetIndex()
      else if msg.isListItemSelected()
        m.home_y = msg.GetIndex()
        'print"You have selected"
        'print"Category Index= "; m.home_y
        'print"Category Item index = "; msg.GetIndex()
        if m.home_x = row_titles.count() - 1
          category = toolbar.tools[m.home_y].function_name()
        else
          category = getDetails(category_name, category_titles[m.home_x])
          displayShowDetailScreen(category, m.home_y)
        endif
      else if msg.isScreenClosed()
        exit while
        poster.close()
      end if
    end if
  end while
End Function

Function getDetails(category_name as string, title as string) as object
  if m.config.category_id <> invalid
    category = get_category_playlist(category_name, title, m.config.category_id)
  else
    category = get_category_playlist(category_name, title, "*")
  end if
  return category
End Function

' launches the nested home screen
Function nested_home() as void
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

       if m.previous_nested_x <> m.nested_x OR m.previous_nested_y <> m.nested_y
         print "changing focused list to"
         print m.nested_x
         print m.nested_y

         grid.SetFocusedListItem(m.nested_x, m.nested_y)

         'set the m.previous_home_x and m.previous_home_y to current status
         m.previous_nested_x = m.nested_x
         m.previous_nested_y = m.nested_y
       end if

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
              category_home(series[index_position])
            end if

            ' prevent multiple button presses
            port=CreateObject("roMessagePort")
            grid.SetMessagePort(port)
            RunGarbageCollector()
         end if
       end if
     end while

     grid.close()
End Function

' **************************************************
' Nested Categories - Poster Screen
' **************************************************

Function nested_home_posterscreen() as void
  port = CreateObject("roMessagePort")
  poster = CreateObject("roPosterScreen")
  poster.SetBreadcrumbText(m.config.home_name, "")
  poster.SetMessagePort(port)
  poster.SetListStyle("flat-category")
  poster.SetListDisplayMode("scale-to-fill")

  series = get_series()
  total_rows = Int(series.count())
  list = CreateObject("roArray", total_rows, true)

  for i = 0 to total_rows - 1
    if series[i] <> invalid
      o = CreateObject("roAssociativeArray")
      o.ContentType = "episode"
      o.Title = series[i].title
      o.Description = ""
      o.Description = series[i].description
      o.ShortDescriptionLine2 = series[i].title
      o.SDPosterUrl = series[i].image
      o.HDPosterUrl = series[i].image
      list.Push(o)
    end if
  end for

  poster.SetContentList(list)
  poster.Show()

  while true
    msg = wait(0, port)
    if type(msg) = "roPosterScreenEvent" then
      if msg.isScreenClosed() then
        exit while
        poster.close()
      elseif msg.isListItemFocused()
        print "msg: ";msg.GetMessage();"idx: ";msg.GetIndex()
      elseif msg.isListItemSelected()
        index_position = msg.GetIndex()
        category_home(series[index_position])
      end if
    end if
  end while
End Function

Function category_home(series as object) as void
  screen = CreateObject("roGridScreen")
  port = CreateObject("roMessagePort")
  screen.SetMessagePort(port)

  screen.SetBreadcrumbText("", series.title)
  screen.SetBreadcrumbEnabled(m.config.category_home_breadcrumb_enabled)
  screen.setGridStyle(m.config.grid_layout)
  screen.SetDisplayMode(m.config.scale_mode)

  row_titles = CreateObject("roArray", 1, true)
  m.categories = CreateObject("roArray", 1, true)

  'get all featured info
  featured = get_playlist(series.playlist_id)

  'add featured playlist title
  row_titles.push(featured.name)

  'get category titles
  category_titles = CreateObject("roArray", 1, true)
  raw_category_titles = CreateObject("roArray", 1, true)

  if series.category_id <> invalid
    category_info = get_category_info(series.category_id)
  else
    'there is no category_id so create a fake category
    category_info = {name: "", values: ["All Videos"]}
  end if

  category_name = category_info.name
  category_titles = category_info.values

  category_value_size = category_titles.count()

  for each title in category_titles
    if m.config.prepend_category_name = true
      row_titles.push(category_name + " " + title)
    else
      row_titles.push(title)
    end if
  end for

  'get toolbar info
  toolbar = grid_toolbar()
  row_titles.push(toolbar.name)

  'set up the rows and titles of the rows on the screen
  total_rows = row_titles.count()

  screen.SetupLists(total_rows)
  screen.SetListNames(row_titles)

  'set up the first row for featured playlists
  screen.SetContentList(0, featured.episodes)

  for preset=1 to m.loading_offset step 1
    load_category_row(row_titles, category_titles, preset, category_name, screen)
  endfor

  screen.SetContentList(total_rows-1, toolbar.tools)

  'show screen once featured playlist and tools are ready
  screen.show()

  while(true)
    msg = wait(0, port)

      'change the focused list item if m.home_x, or m.home_y position has changed via user interactions
      if m.previous_home_x <> m.home_x OR m.previous_home_y <> m.home_y
        screen.SetFocusedListItem(m.home_x, m.home_y)
        'set the m.previous_home_x and m.previous_home_y to current status
        m.previous_home_x = m.home_x
        m.previous_home_y = m.home_y
      end if

      current_row = msg.GetIndex()
      row_to_load = current_row + m.loading_group

      if (row_to_load > m.loading_offset)
        'need to iterate through all rows to make sure fast scrolling does not miss one
        for i=m.loading_offset to row_to_load step 1
          'print m.categories[i]
          'only load category if row data does not yet exist
          if m.categories[i] = invalid AND i < (total_rows - 1)
            load_category_row(row_titles, category_titles, i, category_name, screen)
          end if
        end for
      end if
    if type(msg) = "roGridScreenEvent"
      if (msg.isListItemSelected())
        row = msg.GetIndex()
        m.home_x = row

        if(row = 0)
          displayShowDetailScreen(featured, msg.GetData(), false)
        else if(row = row_titles.count()-1)
          toolbar.tools[msg.GetData()].function_name()
        else
          if row > m.loading_offset
            category = m.categories[msg.GetIndex()]
          else
            category = m.categories[msg.GetIndex()-1]
          end if
          displayShowDetailScreen(category, msg.GetData(), false)
        end if

        ' prevent multiple button presses
        port=CreateObject("roMessagePort")
        screen.SetMessagePort(port)
        RunGarbageCollector()
      end if
      if (msg.isScreenClosed())
        exit while
      end if
    end if
  end while
  screen.close()
End Function

Function load_category_row(row as Object, titles as Object, position as Integer, category_name as String, screen as Object) as Object
  if row[position] <> invalid
    if row.count() <> position
      title = titles[position - 1]
      if m.config.category_id <> invalid
        category = get_category_playlist(category_name, title, m.config.category_id)
      else
        category = get_category_playlist(category_name, title, "*")
      end if
      m.categories.push({name: category.name, episodes: category.episodes})
      screen.SetContentList(position, category.episodes)
    end if
  end if
end Function
