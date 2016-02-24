' The parsers parse the API call responses

' returns URL for a thumbnail
' @refactored
Function parse_thumbnail(input As Object) as string
  thumbnail_url = ""

  ' if a client uploads his/her own poster kind thumbnails
  ' the app should use that
  if input.DoesExist("images")
    for each  thumbnail in input.images
      if(thumbnail.DoesExist("title"))
        if(thumbnail.title = "film-poster")
          thumbnail_url = cached_thumbnail_path(thumbnail.url, input._id)
          return thumbnail_url
        endif
      endif
    end for
  else
    ' otherwise, we use default
    for each  thumbnail in input.thumbnails
      if(thumbnail.DoesExist("width"))
        if(thumbnail.width >= 250)
          thumbnail_url = cached_thumbnail_path(thumbnail.url, input._id)
          return thumbnail_url
        endif
      endif
    end for
  end if

  ' URL is not available
  return thumbnail_url
End Function

Function cached_thumbnail_path(url as string, name as string) as string
  r = CreateObject("roRegex", "(\.png|\.jpg|\.gif|\.jpeg)", "i")
  if r.isMatch(url)
    r_ext = CreateObject("roRegex", "[\w:]+\.(jpe?g|png|gif)", "i")
    ext = r_ext.Match(url)[1]
    file_name = "tmp:/thumbnail-" + name + "." + ext

    fs = CreateObject( "roFileSystem" )
    if fs.exists(file_name)
      'print "Returning cached files"
      return file_name
    else
      'print "nope"
    end if

    request = CreateObject("roURLTransfer")
    if url.InStr(0, "https") = 0
      request.SetCertificatesFile("common:/certs/ca-bundle.crt")
      request.AddHeader("X-Roku-Reserved-Dev-Id", "")
      request.InitClientCertificates()
    end if
    print url
    request.setUrl(url)
    respCode = request.getToFile(file_name)

    if respCode = 200
      return file_name
    else
      'print 'Not cached'
      return url
    end if
  else
    'print 'Not cached'
    return url
  end if
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
