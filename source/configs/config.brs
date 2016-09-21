' pull and setup configuration from the API
Function set_dynamic_config() as void
  url = m.api.endpoint + "/app/?app_key=" + m.api.app
  res = call_api(url).response

  m.oauth = {
    access_token: invalid,
    token_type: invalid,
    expires_in: invalid,
    refresh_token: invalid,
    scope: invalid,
    created_at: invalid
  }


  '@toberefactored the following config fields should be added to the zype-core.
  m.config = {}
  m.config = res

  ' Nielsen DAR settings
  ' Should be integrated in the API
  m.config.NielsenAppId = "<Nielsen App ID>"
  m.config.enableNielsenDAR = false

  m.adIface = Roku_Ads()
  m.adIface.setAdPrefs(true, 2) ' 1: use Roku Ad Framework as fallback 2: # re-tries
  m.adIface.setDebugOutput(true)
  ' print m.config.enableNielsenDAR
  m.adIface.enableNielsenDAR(m.config.enableNielsenDAR)
  ' Nielesen App Id
  ' print m.config.NielsenAppId
  m.adIface.setNielsenAppId(m.config.NielsenAppId)
  ' Content Genre
  m.adIface.setContentGenre("<ROKU CONTENT GENRE>")

  m.config.per_page = Str(m.config.per_page).Trim()
  m.config.info = {
    header: m.config.info_title,
    paragraphs: [
      m.config.info_description
    ]
  }

  ' Switch for View Full Description. Assuming that a video has the desc field available
  m.config.view_full_description = true

  ' Dealing with an empty response (for now)
  if m.config.subscription_button_text = invalid
    m.config.subscription_button_text = ""
  end if

  ' SVOD Visitor Screen Settings
  m.config.visitor_background_img_hd = "pkg:/images/splash_screen_hd.png"
  m.config.activate_button_x_hd = 275
  m.config.activate_button_y_hd = 575
  m.config.browse_button_x_hd = 700
  m.config.browse_button_y_hd = 575
  m.config.visitor_background_img_sd = "pkg:/images/splash_screen_sd.png"
  m.config.activate_button_x_sd = 190
  m.config.activate_button_y_sd = 375
  m.config.browse_button_x_sd = 380
  m.config.browse_button_y_sd = 375
  m.config.target_rect_x_visitor_screen = 0
  m.config.target_rect_y_visitor_screen = 0
  m.config.visitor_background_color = "#000000"

  ' stores where the x,y position are in the home screen for every time you go back it maintains position
  m.home_x = 0
  m.home_y = 0
  m.previous_home_x = 0
  m.previous_home_y = 0
  m.search_x = 0
  m.previous_search_x = 0

  ' stores where the x,y position are in the nested home screen for every time you go back it maintains position
  m.nested_x = 0
  m.nested_y = 0
  m.previous_nested_x = 0
  m.previous_nested_y = 0

  ' how many categories to load at start
  m.loading_offset = 1
  ' how many categories to grab at a time when scrolling
  m.loading_group = 2

  cache_images(m.config.app_images)
End Function

' initialize the theme variables
Function set_theme() as void
  app = CreateObject("roAppManager")
  theme={
    'colors
    BackgroundColor: m.config.color_background,
    CounterSeparator: m.config.color_dark,
    CounterTextLeft: m.config.color_dark,
    CounterTextRight: m.config.color_dark,
    BreadcrumbTextLeft: m.config.color_light,
    BreadcrumbTextRight: m.config.color_light,
    BreadcrumbDelimiter: m.config.color_light,
    SpringboardActorColor: m.config.color_muted,
    SpringboardGenreColor: m.config.color_muted,
    SpringboardRuntimeColor: m.config.color_muted,
    SpringboardSynopsisColor: m.config.color_dark,
    SpringboardTitleText: m.config.color_dark,
    ButtonMenuHighlightText: m.config.color_brand,
    ButtonMenuNormalText: m.config.color_muted,
    ButtonHighlightColor: m.config.color_brand,
    ButtonMenuNormalOverlayText: m.config.color_brand,
    ButtonNormalColor: m.config.color_muted,
    EpisodeSynopsisText: m.config.color_dark,
    PosterScreenLine1Text: m.config.color_dark,
    PosterScreenLine2Text: m.config.color_muted,
    ParagraphBodyText: m.config.color_muted,
    ParagraphHeaderText: m.config.color_dark,
    GridScreenBackgroundColor: m.config.color_background,
    GridScreenListNameColor: m.config.color_dark,
    GridScreenDescriptionDateColor: m.config.color_muted,
    GridScreenDescriptionRuntimeColor: m.config.color_muted,
    GridScreenDescriptionSynopsisColor: m.config.color_dark,
    GridScreenDescriptionTitleColor: m.config.color_dark,
    'images
    OverhangSliceHD: m.images.slice_hd,
    OverhangPrimaryLogoHD: m.images.logo_hd,
    OverhangSliceSD: m.images.slice_sd,
    OverhangPrimaryLogoSD: m.images.logo_sd,
    GridScreenDescriptionImageHD: m.images.grid_description_image_hd,
    GridScreenDescriptionImageSD: m.images.grid_description_image_sd,
    GridScreenFocusBorderHD: m.images.grid_border_image_hd,
    GridScreenFocusBorderSD: m.images.grid_border_image_sd,
    GridScreenOverhangSliceHD: m.images.slice_hd
    GridScreenLogoHD: m.images.logo_hd,
    GridScreenOverhangSliceSD: m.images.slice_sd,
    GridScreenLogoSD: m.images.logo_sd,
    'offsets
    OverhangPrimaryLogoOffsetHD_X: m.config.logo_offset_hd_x,
    OverhangPrimaryLogoOffsetHD_Y: m.config.logo_offset_hd_y,
    OverhangPrimaryLogoOffsetSD_X: m.config.logo_offset_sd_x,
    OverhangPrimaryLogoOffsetSD_Y: m.config.logo_offset_sd_y,
    GridScreenDescriptionOffsetHD: m.config.grid_description_image_offset_hd,
    GridScreenDescriptionOffsetSD: m.config.grid_description_image_offset_sd,
    GridScreenBorderOffsetHD: m.config.grid_border_offset_hd,
    GridScreenBorderOffsetSD: m.config.grid_border_offset_sd,
    GridScreenOverhangHeightHD: m.config.grid_overhang_height_hd,
    GridScreenOverhangHeightSD: m.config.grid_overhang_height_sd,
    GridScreenLogoOffsetHD_X: m.config.grid_logo_offset_hd_x,
    GridScreenLogoOffsetHD_Y: m.config.grid_logo_offset_hd_y,
    GridScreenLogoOffsetSD_X: m.config.grid_logo_offset_sd_x,
    GridScreenLogoOffsetSD_Y: m.config.grid_logo_offset_sd_y
  }
  app.SetTheme(theme)
End Function

' cache theme images in temporary storage
Function cache_images(images As Object) as void
  cached_images = CreateObject("roAssociativeArray")
  for each image in images
    for each key in image
      if image[key] <> invalid
        r_ext = CreateObject("roRegex", "[\w:]+\.(jpe?g|png|gif)", "i")
        ext = r_ext.Match(image[key])[1]
        file = "tmp:/app-" + key + ext


        fs = CreateObject( "roFileSystem" )
        if fs.exists(file)
          cached_images[key] = file
        end if

        url = image[key]

        request = CreateObject("roUrlTransfer")

        if url.InStr(0, "https") = 0
          request.SetCertificatesFile("common:/certs/ca-bundle.crt")
          request.AddHeader("X-Roku-Reserved-Dev-Id", "")
          request.InitClientCertificates()
        end if

        request.SetUrl(url)

        responseCode = request.GetToFile(file)
        if responseCode = 200
          cached_images[key] = file
        end if
      end if
    end for
  end for
  m.images = cached_images
End Function
