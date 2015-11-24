'parsers are helper functions that parse results out of api responses

Function parse_thumbnail(input As Object) as string
  thumbnail_url = ""
  for each  thumbnail in input.thumbnails
    if(thumbnail.DoesExist("width"))
      if(thumbnail.width >= 250)
        thumbnail_url = cache_thumbnail(thumbnail.url, input._id)
        print thumbnail_url
        return thumbnail_url
      endif
    endif
  end for
  return thumbnail_url
End Function

Function cache_thumbnail(thumbnail_url As string, name As string) as string
  r = CreateObject("roRegex", ".jpg", "i")

  if r.isMatch(thumbnail_url)
    file_name = "tmp:/" + name + ".jpg"
    ut = CreateObject("roUrlTransfer")
    ut.SetCertificatesFile("common:/certs/ca-bundle.crt")
    ut.AddHeader("X-Roku-Reserved-Dev-Id", "")
    ut.InitClientCertificates()

    ut.SetUrl(thumbnail_url)
    responseCode = ut.GetToFile(file_name)
    if responseCode = 200
      return file_name
      print "success"
    end if
  else
    return thumbnail_url
  end if
End Function

Function parse_rating(input As Object) as string
  if input.subscription_required
    if input.mature_content
      return "Subscription / TV-MA"
    else
      return "Subscription / NR"
    end if
  else
    if input.mature_content
      return "TV-MA"
    else
      return "NR"
    end if
  end if
End Function

Function parse_zobjects(input As Object, ztype as String) as Object
  zobjects = CreateObject("roArray", 1, true)
    if(input.DoesExist("video_zobjects"))
      for each zobject in input.video_zobjects
        if(zobject.DoesExist("zobject_type_title"))
        print zobject.zobject_type_title
        print ztype
        print " "
          if(zobject.zobject_type_title = ztype)
            zobjects.push(zobject.title)
          endif
        endif
      end for
    endif
  return zobjects
End Function
