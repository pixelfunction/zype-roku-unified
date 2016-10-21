' Getters calls specific APIs


function get_entitled_videos(params=invalid as dynamic) as object
  url = m.api.endpoint + "/consumer/videos" + "?" + format_params(params)
  resp = call_api(url)

  if resp.code = 200
    episodes = CreateObject("roArray", 1, true)
    for each vid in resp.response
      single_video_url = m.api.endpoint + "/videos/" + vid.video_id + "?" + format_params(params)
      item = call_api(single_video_url).response

      short_description = ""
      full_description = ""
      if IsString(item.description) = true and IsString(item.short_description) = true
        if item.description.Trim().Len() > 0 and item.short_description.Trim().Len() > 0
          short_description = item.short_description
          full_description = item.description
        else if item.description.Trim().Len() > 0 and item.short_description.Trim().Len() = 0
          short_description = item.description
          full_description = item.description
        else if item.description.Trim().Len() = 0 and item.short_description.Trim().Len() > 0
          short_description = item.short_description
        end if
      else if IsString(item.description) = true and IsString(item.short_description) = false
        if item.description.Trim().Len() > 0
          short_description = item.description
          full_description = item.description
        end if
      else if IsString(item.description) = false and IsString(item.short_description) = true
        if item.short_description.Trim().Len() > 0
          short_description = item.short_description
        end if
      end if

      r = CreateObject("roRegex", "\s\r|\s\n|\s\r\n|\r|\n", "")
      short_description = r.ReplaceAll(short_description, chr(10))
      full_description = r.ReplaceAll(full_description, chr(10))

      published_at = ""
      if isString(item.published_at) = true
        dt = CreateObject("roDateTime")
        date = left(item.published_at, 23)
        dt.FromISO8601String(date)
        published_at = dt.AsDateString("short-date")
      end if

      thumbnail = parse_thumbnail(item)
      rating = parse_rating(item)
      episode = {
        ID: item._id,
        ContentType: "episode",
        Title: item.title,
        SDPosterUrl: thumbnail,
        HDPosterUrl: thumbnail,
        Length: item.duration,
        Rating: rating,
        ReleaseDate: published_at
        ' The Description field is used for all pages
        Description: short_description,
        FullDescription: full_description,
        SubscriptionRequired: item.subscription_required,
        PassRequired: item.pass_required,
        PurchaseRequired: item.purchase_required,
        RentalRequired: item.rental_required,
        SwitchingStrategy: m.config.switching_strategy,
        Cost: 0,
        ProductType: "none",
        NielsenGenre: "",
        Episode: item.episode,
        Season: item.season
      }

      if m.config.enableNielsenDAR
        if item.DoesExist("categories")
          for each c in item.categories
            if c.title = "Nielsen Genre"
              episode.NielsenGenre = c.value[0]
              exit for
            end if
          end for
        end if
      end if

      top_validation = valid_top_zobject()
      bottom_validation = valid_bottom_zobject()

      if top_validation = true
        episode.Actors = parse_zobjects(item, m.config.top_description_zobject)
      end if

      if bottom_validation = true
        episode.Categories = parse_zobjects(item, m.config.bottom_description_zobject)
      end if

      episodes.push(episode)

    end for

    return episodes
  end if

  return invalid
end function

function get_my_library(params=invalid as dynamic) as object
  videos = get_entitled_videos(params)
  if videos <> invalid
    library = {name: "My Library", episodes: videos}
    return library
  end if
  return invalid
end function


function IsEntitled(id as string, params=invalid as dynamic) as boolean
  url = m.api.endpoint + "/videos/" + id + "/entitled" + "?" + format_params(params)
  resp = call_api(url)

  if resp.code = 422
    print "Does NOT have acccess"
    return false
  else if resp.code = 200
    print "Does have access"
    return true
  end if

end function

function get_playlists() as object
  url = m.api.endpoint + "/playlists?" + "app_key=" + m.api.app + "&sort=priority" + "&order=desc"
  playlists = []

  resp = call_api(url).response

  if type(resp) = "roArray" and resp.count() > 0
    for each pl in resp
      playlists.push(pl)
    end for
  end if

  return playlists
end function

' return videos in a playlist
Function get_playlist_videos(id as string) as Object
  res = []
  url = m.api.endpoint + "/playlists/" + id + "/videos/?app_key=" + m.api.app + "&per_page=" + m.config.per_page
  videos = get_videos(url, false)
  if videos.count() > 0
    for each v in videos
      res.push(v)
    end for
  end if

  return res
End Function


' calls the api with a specific URL
Function call_api(url As String) as Object
  'print "API call "; url
  request = CreateObject("roUrlTransfer")
  port = CreateObject("roMessagePort")
  request.SetPort(port)

  if url.InStr(0, "https") = 0
    request.SetCertificatesFile("common:/certs/ca-bundle.crt")
    request.AddHeader("X-Roku-Reserved-Dev-Id", "")
    request.InitClientCertificates()
  end if
  request.SetUrl(url)

  if(request.AsyncGetToString())
    while(true)
      msg = wait(0, port)
      if(type(msg) = "roUrlEvent")
        code = msg.GetResponseCode()
        if(code = 200)
          res = ParseJSON(msg.GetString())
          return {"code": code, "response": res.response}
        end if
        return {"code": code, "response": invalid}
      else if(event = invalid)
        request.AsyncCancel()
        exit while
      end if
    end while
  end if

  return invalid
End Function

' returns a list of videos.
Function get_videos(url As String, short As Boolean, long=false As Boolean) as object
  episodes = CreateObject("roArray", 1, true)
  res = call_api(url).response

  'print "Loading videos..."
  'timer = CreateObject("roTimespan")
  'timer.Mark()

  for each item in res
    short_description = ""
    full_description = ""
    if IsString(item.description) = true and IsString(item.short_description) = true
      if item.description.Trim().Len() > 0 and item.short_description.Trim().Len() > 0
        short_description = item.short_description
        full_description = item.description
      else if item.description.Trim().Len() > 0 and item.short_description.Trim().Len() = 0
        short_description = item.description
        full_description = item.description
      else if item.description.Trim().Len() = 0 and item.short_description.Trim().Len() > 0
        short_description = item.short_description
      end if
    else if IsString(item.description) = true and IsString(item.short_description) = false
      if item.description.Trim().Len() > 0
        short_description = item.description
        full_description = item.description
      end if
    else if IsString(item.description) = false and IsString(item.short_description) = true
      if item.short_description.Trim().Len() > 0
        short_description = item.short_description
      end if
    end if

    r = CreateObject("roRegex", "\s\r|\s\n|\s\r\n|\r|\n", "")
    short_description = r.ReplaceAll(short_description, chr(10))
    full_description = r.ReplaceAll(full_description, chr(10))

    published_at = ""
    if isString(item.published_at) = true
      dt = CreateObject("roDateTime")
      date = left(item.published_at, 23)
      dt.FromISO8601String(date)
      published_at = dt.AsDateString("short-date")
    end if

    thumbnail = parse_thumbnail(item)
    rating = parse_rating(item)
    episode = {
      ID: item._id,
      ContentType: "episode",
      Title: item.title,
      SDPosterUrl: thumbnail,
      HDPosterUrl: thumbnail,
      Length: item.duration,
      Rating: rating,
      ReleaseDate: published_at
      ' The Description field is used for all pages
      Description: short_description,
      FullDescription: full_description,
      SubscriptionRequired: item.subscription_required,
      PassRequired: item.pass_required,
      PurchaseRequired: item.purchase_required,
      RentalRequired: item.rental_required,
      SwitchingStrategy: m.config.switching_strategy,
      Cost: 0,
      ProductType: "none",
      NielsenGenre: "",
      Episode: item.episode,
      Season: item.season
    }

    if m.config.enableNielsenDAR
      if item.DoesExist("categories")
        for each c in item.categories
          if c.title = "Nielsen Genre"
            episode.NielsenGenre = c.value[0]
            exit for
          end if
        end for
      end if
    end if

    top_validation = valid_top_zobject()
    bottom_validation = valid_bottom_zobject()

    if top_validation = true
      episode.Actors = parse_zobjects(item, m.config.top_description_zobject)
    end if

    if bottom_validation = true
      episode.Categories = parse_zobjects(item, m.config.bottom_description_zobject)
    end if

    if (short = true)
      episode.ShortDescriptionLine1 = item.title
      episode.ShortDescriptionLine2 = rating
    end if

    if long = true then
      videoTitle = ""
      for each it in item.categories
        if it.title = "Show"
          videoTitle = it.value[0]
        end if
      end for
      episode.ShortDescriptionLine1 = item.title
      episode.ShortDescriptionLine2 = videoTitle
    end if

    episodes.push(episode)
    ' print episode
  end for

  ' episodes.SortBy("season", "r")
  ' for each ele in episodes
  '   print ele.Season, ele.Episode
  ' end for

  ' @toberefactored
  if m.config.in_app_purchase = true
    for each ep in episodes
      for each el in m.store_items
        if el.code = ep.id
          ep.cost = el.cost
          ep.productType = el.productType
        end if
      end for
    end for
  end if

  'print "Loading vidoes finished "; timer.TotalSeconds()
  return episodes
End Function

' (for nested home)
Function get_series() as object
  url = m.api.endpoint + "/zobjects/?app_key=" + m.api.app + "&zobject_type=channels&per_page=100&sort=priority&order=asc"
  series = CreateObject("roArray", 1, true)
  res = call_api(url).response
  for each zobject in res
    series.push({ title: zobject.title, playlist_id: zobject.playlist_id, category_id: zobject.category_id, image: get_zobject_thumbnail(zobject), description: zobject.description })
  end for
  return series
end Function

' (for nested home)
Function get_zobject_thumbnail(zobject as object) as object
  if zobject.pictures <> invalid
    return zobject.pictures[0].url
  end if
end Function

' (for nested home)
Function get_playlist(playlist_id as String) as object
  featured = {}
  url = m.api.endpoint + "/playlists/" + playlist_id + "/videos/?app_key=" + m.api.app + "&per_page=" + m.config.per_page
  episodes = get_videos(url, false)
  if(episodes.count() > 0)
    featured = {name: get_playlist_name(playlist_id), episodes: episodes}
  else
    url = m.api.endpoint + "/videos/?app_key=" + m.api.app + "&per_page=10&dpt=true"
    featured = {name: "New Releases", episodes: get_videos(url, false)}
  end if
  return featured
End Function

' returns a list of videos filtered by a query
Function get_search_results(query As String) as object
  url = m.api.endpoint + "/videos/?app_key=" + m.api.app + "&per_page=" + m.config.per_page + "&q=" + HttpEncode(query) + "&dpt=true"
  episodes = get_videos(url, false, true)
  if (episodes.count() > 0)
    search_results = {name: "Search: " + query, episodes: episodes}
  else
    search_results = {name: "Search: " + query, episodes: []}
  end if
  return search_results
End Function

' returns a featured playlist and videos defined in it.
Function get_featured_playlist() as object
  validation = valid_featured_playlist()
  if(validation = "true")
    url = m.api.endpoint + "/playlists/" + m.config.featured_playlist_id + "/videos/?app_key=" + m.api.app + "&per_page=" + m.config.per_page
    episodes = get_videos(url, false)
    if(episodes.count() > 0)
      featured = {name: get_playlist_name(m.config.featured_playlist_id), episodes: episodes}
    else
      url = m.api.endpoint + "/videos/?app_key=" + m.api.app + "&per_page=10&dpt=true"
      featured = {name: "New Releases", episodes: get_videos(url, false)}
    end if
  else
    url = m.api.endpoint + "/videos/?app_key=" + m.api.app + "&per_page=10&dpt=true"
    featured = {name: "New Releases", episode: get_videos(url, false)}
  end if
  return featured
End Function

' returns the playlist's name.
Function get_playlist_name(playlist_id As String) as string
  name = ""
  url = m.api.endpoint + "/playlists/" + playlist_id + "?app_key=" + m.api.app + "&per_page=" + m.config.per_page
  res = call_api(url).response
  if res.DoesExist("title")
    name = res.title
  end if
  return name
End Function


function format_params(data as dynamic) as string
  query_string = ""
  if data <> invalid
    if type(data) = "roAssociativeArray"
      for each key in data
        ' print key
        if query_string.len() > 0
          query_string = query_string + "&"
        end if
        query_string = query_string + key + "=" + data[key]
      end for
    end if
  end if
  return query_string
end function

' returns the player's info
Function get_player_info(id As String, query=invalid as object) as Object
  player_info = {}
  scheduled_ads = []
  url = m.api.player_endpoint + "/embed/" + id + "?" + format_params(query)

  print url

  result = call_api(url).response

  if result = invalid
    return invalid
  end if

  if result.DoesExist("body") = true then
    if result.body.DoesExist("outputs") = true then
      for each output in result.body.outputs
        stream_url = output.url
        player_info.stream =  {url: stream_url}
        if(output.name = "hls")
          player_info.format = "hls"
        end if
        if(output.name = "m3u8")
          player_info.format = "hls"
        end if
        if(output.name = "mp4")
          player_info.format = "mp4"
        end if
      end for

      if result.body.DoesExist("advertising") = true then
        for each advertising in result.body.advertising
          if advertising = "schedule"
            for each ad in result.body.advertising.schedule
              'print "DYNAMIC VAST URL"
              'print ad.tag
              scheduled_ads.push({offset: ad.offset / 1000, url: ad.tag, played: false})
            end for
          end if
        end for
      end  if
    end if
  end if

  player_info.ads = scheduled_ads
  return player_info
End Function

' returns a playlist for a specific category with its videos.
Function get_category_playlist(category_name as string, category_value as string, category_id as string) as Object
  playlist = {}
  url = m.api.endpoint + "/videos?app_key=" + m.api.app + "&category%5B" + HttpEncode(category_name) + "%5D=" + HttpEncode(category_value) + "&dpt=true&per_page=" + m.config.per_page + "&sort=episode&order=asc"
  print url
  episodes = get_videos(url, false)
  if(episodes.count() > 0)
    playlist = {name: category_value, episodes: episodes}
  else
    url = m.api.endpoint + "/videos/?app_key=" + m.api.app + "&per_page=6&dpt=true"
    playlist = {name: category_value, episodes: get_videos(url, false)}
  end if
  return playlist
End Function

' return a "All Videos" playlist.
Function get_all_videos_playlist() as Object
  playlist= {}
  url = m.api.endpoint + "/videos?app_key=" + m.api.app + "&dpt=true&per_page=" + m.config.per_page
  episodes = get_videos(url, false)
  if(episodes.count() > 0)
    playlist = {name: "All Videos", episodes: episodes}
  end if
  return playlist
End Function

' return an info about a specific category.
Function get_category_info(category_id As String) as Object
  request = CreateObject("roUrlTransfer")
  port = CreateObject("roMessagePort")
  request.SetPort(port)

  url = m.api.endpoint + "/categories/" + category_id + "/?app_key=" + m.api.app
  if url.InStr(0, "https") = 0
    request.SetCertificatesFile("common:/certs/ca-bundle.crt")
    request.AddHeader("X-Roku-Reserved-Dev-Id", "")
    request.InitClientCertificates()
  end if
  request.SetUrl(url)

  category_info = {name: "", values: CreateObject("roArray", 1, true)}

  if(request.AsyncGetToString())
    while(true)
      msg = wait(0, port)
      if(type(msg) = "roUrlEvent")
        code = msg.GetResponseCode()
        if(code = 200)
          parsed_res = ParseJSON(msg.GetString())
          res = parsed_res.response
          category_info.id = res._id
          category_info.name = res.title
          category_info.values = res.values
          return category_info
        end if
      else if(event = invalid)
        request.AsyncCancel()
        exit while
      end if
    end while
  end if

  return invalid
End Function




' (cross channels)
function get_cross_channels() as object
    url = m.api.endpoint + "/zobjects/?app_key=" + m.api.app + "&zobject_type=roku_cross_channels"
    cross_channels = {name: "Featured Channels", channels: CreateObject("roArray", 1, true)}

    res = call_api(url)

    if res.code <> 200 or res.response.count() = 0
        return invalid
    end if

    for each zobject in res.response
        cross_channels.channels.push({
            Title: zobject.title,
            HDPosterUrl: get_zobject_thumbnail(zobject),
            AppId: zobject.app_id,
            Description: zobject.description,
            function_name: launchApp
        })
    end for

    return cross_channels
end function


function launchApp(appId as string) as void
  di = CreateObject("roDeviceInfo")
  ip = di.GetIPAddrs()
  xfer = CreateObject("roURLTransfer")


  ipaddress = invalid
  if ip["eth0"] <> invalid
    ipaddress = ip["eth0"]
  else if ip["eth1"] <> invalid
    ipaddress = ip["eth1"]
  end if

  if ipaddress <> invalid
    if IsInstalled(appId) = true
      ECPUrl= "http://" + ipaddress + ":8060/launch/" + appId
    else
      ECPUrl= "http://" + ipaddress + ":8060/install/" + appId
    end if
    xfer.SetURL(ECPUrl)
    result = xfer.AsyncPostFromString("")
  end if
end function

function IsInstalled(appId as string) as boolean
    di = CreateObject("roDeviceInfo")
    ip = di.GetIPAddrs()

    ipaddress = invalid
    if ip["eth0"] <> invalid
      ipaddress = ip["eth0"]
    else if ip["eth1"] <> invalid
      ipaddress = ip["eth1"]
    end if

    if ipaddress <> invalid
      xfer = CreateObject("roURLTransfer")
      ECPUrl= "http://" + ipaddress + ":8060/query/apps"
      xfer.SetURL(ECPUrl)
      result = xfer.GetToString()
      ' print result
    else
      return false
    end if

    return DoesIdExist(appId, result)
end function

function DoesIdExist(appId as string, data as string)
  xml=CreateObject("roXMLElement")
  If xml.Parse(data) then
    for each ele in xml.GetBody()
      if ele.HasAttribute("id")
        if ele.GetAttributes()["id"] = appId
          return true
        end if
      end if
    end for
  End If
  return false
end function

Function get_nielsen_dar() as object
  url = m.api.endpoint + "/zobjects/?app_key=" + m.api.app + "&zobject_type=nielsen_dar"
  res = call_api(url)

  if res.code = 200
    return res.response[0]
  end if

  return invalid
End Function
