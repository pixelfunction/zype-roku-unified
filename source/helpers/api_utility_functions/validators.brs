Function valid_featured_playlist() as String
  playlist_id = m.config.featured_playlist_id
  if playlist_id = invalid
    return "false"
  else
    return "true"
  endif
End Function

Function valid_category() as String
  category_id = m.config.category_id
  if category_id = invalid
    return "false"
  else
    return "true"
  end if
End Function

Function valid_top_zobject() as String
  zobject = m.config.top_description_zobject
  if zobject = invalid
    return "false"
  else
    return "true"
  end if
End Function

Function valid_bottom_zobject() as String
  zobject = m.config.bottom_description_zobject
  if zobject = invalid
    return "false"
  else
    return "true"
  end if
End Function
