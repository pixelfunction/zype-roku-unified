' The parsers parse the API call responses

' returns URL for a thumbnail
' @refactored
Function parse_thumbnail(input As Object) as string
  thumbnail_url = ""
  for each  thumbnail in input.thumbnails
    if(thumbnail.DoesExist("width"))
      if(thumbnail.width >= 250)
        thumbnail_url = cached_thumbnail_path(thumbnail.url, input._id)
        return thumbnail_url
      endif
    endif
  end for
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

    xfer = createObject("roUrlTransfer")
    xfer.setCertificatesFile("common:/certs/ca-bundle.crt")
    xfer.addHeader("X-Roku-Reserved-Dev-Id", "")
    xfer.initClientCertificates()
    xfer.setUrl(url)
    respCode = xfer.getToFile(file_name)

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

' returns a video monitization type and its content restrictions.
Function parse_rating(input As Object) as string
  if input.subscription_required
    if input.mature_content
      return "Subscription / TV-MA"
    else
      return "Subscription / NR"
    end if
  else if input.purchase_required
    if input.mature_content
      return "Purchase / TV-MA"
    else
      return "Purchase / NR"
    end if
  else if input.pass_required
    if input.mature_content
      return "Pass / TV-MA"
    else
      return "Pass / NR"
    end if
  else if input.rental_required
    if input.mature_content
      return "Rental / TV-MA"
    else
      return "Rental / NR"
    end if
  else
    if input.mature_content
      return "TV-MA"
    else
      return "NR"
    end if
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
