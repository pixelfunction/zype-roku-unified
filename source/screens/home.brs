Function home_screen()
  screen = CreateObject("roGridScreen")
  port = CreateObject("roMessagePort")
  screen.SetMessagePort(port)

  screen.SetBreadcrumbText(m.config.home_name, "")
  screen.setGridStyle(m.config.grid_layout)
  screen.SetDisplayMode(m.config.scale_mode)

  row_titles = CreateObject("roArray", 1, true)
  m.categories = CreateObject("roArray", 1, true)

  'get all featured info
  featured = get_featured_playlist()

  'add featured playlist title
  row_titles.push(featured.name)

  'get category titles
  category_titles = CreateObject("roArray", 1, true)
  raw_category_titles = CreateObject("roArray", 1, true)

  if m.config.category_id <> invalid
    category_info = get_category_info(m.config.category_id)
  else
    'there is no category_id so create a fake category
    category_info = {name: "", values: ["All Videos"]}
  endif

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
  screen.SetFocusedListItem(0,0)
  'show screen once featured playlist and tools are ready
  screen.show()

  while(true)
    msg = wait(0, port)

      'change the focused list item if m.home_x, or m.home_y position has changed via user interactions
      if m.previous_home_x <> m.home_x OR m.previous_home_y <> m.home_y
        print "changing focused list to"
        print m.home_x
        print m.home_y

        screen.SetFocusedListItem(m.home_x, m.home_y)

        'set the m.previous_home_x and m.previous_home_y to current status
        m.previous_home_x = m.home_x
        m.previous_home_y = m.home_y
      endif

      current_row = msg.GetIndex()
      row_to_load = current_row + m.loading_group

      if (row_to_load > m.loading_offset)
        'need to iterate through all rows to make sure fast scrolling does not miss one
        for i=m.loading_offset to row_to_load step 1
        print i
        print m.categories[i]
          'only load category if row data does not yet exist
          if m.categories[i] = invalid AND i < (total_rows - 1)
            load_category_row(row_titles, category_titles, i, category_name, screen)
          endif
        end for
      endif
    if type(msg) = "roGridScreenEvent"
      if (msg.isListItemSelected())
        row = msg.GetIndex()
        m.home_y = msg.GetData()
        m.home_x = row

        if(row = 0)
          displayShowDetailScreen(featured, msg.GetData())
        else if(row = row_titles.count()-1)
          toolbar.tools[msg.GetData()].function_name()
        else
          if row > m.loading_offset
            category = m.categories[msg.GetIndex()]
          else
            category = m.categories[msg.GetIndex()-1]
          endif
          displayShowDetailScreen(category, msg.GetData())
        endif
      endif
      if (msg.isScreenClosed())
        return -1
      endif
    endif
  end while

End Function

Function load_category_row(row as Object, titles as Object, position as Integer, category_name as String, screen as Object) as Object
  if row[position] <> invalid
    if row.count() <> position
      title = titles[position - 1]
      if m.config.category_id <> invalid
        category = get_category_playlist(category_name, title, m.config.category_id)
      else
        category = get_category_playlist(category_name, title, "*")
      endif
      m.categories.push({name: category.name, episodes: category.episodes})
      screen.SetContentList(position, category.episodes)
    endif
  endif
end Function
