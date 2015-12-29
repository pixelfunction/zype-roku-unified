' Getters calls specific APIs

' calls the api with a specific URL
Function call_api(url As String) as Object
  'print "API call "; url
  request = CreateObject("roUrlTransfer")
  port = CreateObject("roMessagePort")
  request.SetPort(port)

  request.SetCertificatesFile("common:/certs/ca-bundle.crt")
  request.AddHeader("X-Roku-Reserved-Dev-Id", "")
  request.InitClientCertificates()
  request.SetUrl(url)
  if(request.AsyncGetToString())
    while(true)
      msg = wait(0, port)
      if(type(msg) = "roUrlEvent")
        code = msg.GetResponseCode()
        if(code = 200)
          res = ParseJSON(msg.GetString())
          return res.response
        end if
      else if(event = invalid)
        request.AsyncCancel()
        exit while
      end if
    end while
  end if

  return invalid
End Function

' returns a list of videos.
Function get_videos(url As String, short As Boolean) as object
  episodes = CreateObject("roArray", 1, true)
  res = call_api(url)

  'print "Loading videos..."
  'timer = CreateObject("roTimespan")
  'timer.Mark()

  for each item in res
    if item.description = invalid
      item.description = ""
    end if
    if item.short_description = invalid
      item.description = ""
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
      Description: item.short_description,
      FullDescription: item.description,
      SubscriptionRequired: item.subscription_required,
      PassRequired: item.pass_required,
      PurchaseRequired: item.purchase_required,
      RentalRequired: item.rental_required,
      SwitchingStrategy: m.config.switching_strategy,
      Cost: 0,
      ProductType: "none"
    }

    top_validation = valid_top_zobject()
    bottom_validation = valid_bottom_zobject()

    if top_validation = "true"
      episode.Actors = parse_zobjects(item, m.config.top_description_zobject)
    end if

    if bottom_validation = "true"
      episode.Categories = parse_zobjects(item, m.config.bottom_description_zobject)
    end if

    if (short = true)
      episode.ShortDescriptionLine1 = item.title
      episode.ShortDescriptionLine2 = rating
    end if

    episodes.push(episode)
  end for

  ' @toberefactored
  for each ep in episodes
    for each el in m.store_items
      if el.code = ep.id
        ep.cost = el.cost
        ep.productType = el.productType
      end if
    end for
  end for

  'print "Loading vidoes finished "; timer.TotalSeconds()
  return episodes
End Function

' (for nested home)
Function get_series() as object
  url = m.api.endpoint + "/zobjects/?api_key=" + m.api.key + "&zobject_type=channels&per_page=100&sort=priority&order=asc"
  series = CreateObject("roArray", 1, true)
  res = call_api(url)
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
  url = m.api.endpoint + "/playlists/" + playlist_id + "/videos/?api_key=" + m.api.key + "&per_page=" + m.config.per_page
  episodes = get_videos(url, false)
  if(episodes.count() > 0)
    featured = {name: get_playlist_name(playlist_id), episodes: episodes}
  else
    url = m.api.endpoint + "/videos/?api_key=" + m.api.key + "&per_page=10&dpt=true"
    featured = {name: "New Releases", episodes: get_videos(url, false)}
  end if
  return featured
End Function

' returns a list of videos filtered by a query
Function get_search_results(query As String) as object
  url = m.api.endpoint + "/videos/?api_key=" + m.api.key + "&per_page=" + m.config.per_page + "&q=" + HttpEncode(query) + "&dpt=true"
  episodes = get_videos(url, true)
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
    url = m.api.endpoint + "/playlists/" + m.config.featured_playlist_id + "/videos/?api_key=" + m.api.key + "&per_page=" + m.config.per_page
    episodes = get_videos(url, false)
    if(episodes.count() > 0)
      featured = {name: get_playlist_name(m.config.featured_playlist_id), episodes: episodes}
    else
      url = m.api.endpoint + "/videos/?api_key=" + m.api.key + "&per_page=10&dpt=true"
      featured = {name: "New Releases", episodes: get_videos(url, false)}
    end if
  else
    url = m.api.endpoint + "/videos/?api_key=" + m.api.key + "&per_page=10&dpt=true"
    featured = {name: "New Releases", episode: get_videos(url, false)}
  end if
  return featured
End Function

' returns the playlist's name.
Function get_playlist_name(playlist_id As String) as string
  name = ""
  url = m.api.endpoint + "/playlists/" + playlist_id + "?api_key=" + m.api.key + "&per_page=" + m.config.per_page
  res = call_api(url)
  if res.DoesExist("title")
    name = res.title
  end if
  return name
End Function

' returns the player's info
Function get_player_info(id As String) as Object
  player_info = {}
  scheduled_ads = []
  url = m.api.player_endpoint + "/embed/" + id + "/?api_key=" + m.api.key
  res = call_api(url)
  if(res.DoesExist("body"))
    if(res.body.DoesExist("outputs"))
      for each output in res.body.outputs
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
      if(res.body.DoesExist("advertising"))
        for each advertising in res.body.advertising
          if (advertising = "schedule")
            for each ad in res.body.advertising.schedule
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
  url = m.api.endpoint + "/videos?api_key=" + m.api.key + "&category%5B" + HttpEncode(category_name) + "%5D=" + HttpEncode(category_value) + "&dpt=true&per_page=" + m.config.per_page + "&sort=episode&order=asc"
  episodes = get_videos(url, false)
  if(episodes.count() > 0)
    playlist = {name: category_value, episodes: episodes}
  else
    url = m.api.endpoint + "/videos/?api_key=" + m.api.key + "&per_page=6&dpt=true"
    playlist = {name: category_value, episodes: get_videos(url, false)}
  end if
  return playlist
End Function

' return a "All Videos" playlist.
Function get_all_videos_playlist() as Object
  playlis= {}
  url = m.api.endpoint + "/videos?api_key=" + m.api.key + "&dpt=true&per_page=" + m.config.per_page
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

  request.SetCertificatesFile("common:/certs/ca-bundle.crt")
  request.AddHeader("X-Roku-Reserved-Dev-Id", "")
  request.InitClientCertificates()

  url = m.api.endpoint + "/categories/" + category_id + "/?api_key=" + m.api.key
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
