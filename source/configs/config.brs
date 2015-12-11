' @toberefactored Should be set by values returned from the API
' these are the hard coded keys/initialization variables
Function set_api() as void
  m.api = {
    key: "<API Key>",
    app: "<App Key>",
    endpoint: "https://api.zype.com",
    player_endpoint: "https://player.zype.com",
    version: "0.0.1"
  }
End Function

' pull and setup configuration from the API
Function set_dynamic_config() as void
  url = m.api.endpoint + "/app/?api_key=" + m.api.key + "&app_key=" + m.api.app
  res = call_api(url)

  'AVOD,USVOD,NSVOD,EST
  '@toberefactored the following config fields should be added to the zype-core.
  m.config = {}
  m.config = res
  m.config.monetization_type = "AVOD"
  m.config.nested = false
  m.config.springboard_breadcrumb_enabled = true
  m.config.home_breadcrumb_enabled = true
  m.config.category_home_breadcrumb_enabled = true
  m.config.per_page = Str(m.config.per_page).Trim()
  m.config.info = {
    header: "About",
    paragraphs: [
            "All about the Roku Channel.",
            ""
    ]
  }
  m.config.device_link_url = "www.example.com/link"
  m.config.subscription_button = "Subscription Required"

  ' SVOD Visitor Screen Settings
  ' m.config.visitor_background_img_hd = "pkg:/images/splash_screen_hd.jpg"
  ' m.config.activate_button_x_hd = 275
  ' m.config.activate_button_y_hd = 575
  ' m.config.browse_button_x_hd = 700
  ' m.config.browse_button_y_hd = 575
  ' m.config.visitor_background_img_sd = "pkg:/images/splash_screen_sd.jpg"
  ' m.config.activate_button_x_sd = 190
  ' m.config.activate_button_y_sd = 375
  ' m.config.browse_button_x_sd = 380
  ' m.config.browse_button_y_sd = 375
  ' m.config.target_rect_x_visitor_screen = 0
  ' m.config.target_rect_y_visitor_screen = 0
  ' m.config.visitor_background_color = "#000000"

  ' stores where the x,y position are in the home screen for every time you go back it maintains position
  m.home_x = 0
  m.home_y = 0
  m.previous_home_x = 0
  m.previous_home_y = 0

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

        ut = CreateObject("roUrlTransfer")
        ut.SetUrl(image[key])
        responseCode = ut.GetToFile(file)
        if responseCode = 200
          cached_images[key] = file
        end if
      end if
    end for
  end for
  m.images = cached_images
End Function
