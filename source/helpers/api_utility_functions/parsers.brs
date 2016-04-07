' The parsers parse the API call responses

' returns URL for a thumbnail
' @refactored
Function parse_thumbnail(input As Object) as string
  ' if a client uploads his/her own poster kind thumbnails
  ' the app should use that
  if input.DoesExist("images") and input.images.count() > 0
    for each  thumbnail in input.images
      if(thumbnail.DoesExist("title"))
        if(thumbnail.title = "film-poster")
          return thumbnail.url
        endif
      endif
    end for
  end if

  ' otherwise, we use default
  for each thumbnail in input.thumbnails
    if(thumbnail.DoesExist("width"))
      if(thumbnail.width >= 250)
        return thumbnail.url
      endif
    endif
  end for

  ' URL is not available
  return ""
End Function

' returns a video content restrictions.
Function parse_rating(input As Object) as string
  if input.mature_content
    return "TV-MA"
  else
    return "NR"
  end if
End Function

' returns zobjets form the input
Function parse_zobjects(input As Object, ztype as String) as Object
  zobjects = CreateObject("roArray", 1, true)
  if(input.DoesExist("video_zobjects"))
    for each zobject in input.video_zobjects
      if(zobject.DoesExist("zobject_type_title"))
        if(zobject.zobject_type_title = ztype)
          zobjects.push(zobject.title)
        endif
      endif
    end for
  endif
  return zobjects
End Function
