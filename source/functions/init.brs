'initialization functions

'master initialization function
Function init() as void
  set_api()
  get_dynamic_config()
  init_theme()

  if app_type = "SVOD" then
    'SVOD'
    'read channel registry to see if there is a unique device id, if not set it to be unique with device id and time set
    'uncomment out the RegDelete if want to wipe out the token in dev
    'RegDelete("RegToken", "Authentication555ef22569702d048c9d0e00")
    print "checking registry token"
    if RegRead("RegToken", "Authentication555ef22569702d048c9d0e00") <> invalid
      print "REGISTRY TOKEN IS ALREADY WRITTEN"
      m.device_id = RegRead("RegToken", "Authentication555ef22569702d048c9d0e00")
    else
      'first time channel is loaded (or deleted and reloaded), so need to create the unique id
      print "WRITING A NEW REGISTRY TOKEN"
      date = CreateObject("roDateTime")
      timestamp = date.AsSeconds().ToStr()
  
      device = CreateObject("roDeviceInfo")
  
      uniqueId = device.GetDeviceUniqueId() + date.AsSeconds().ToStr()
  
      RegWrite("RegToken", uniqueId, "Authentication555ef22569702d048c9d0e00")
  
      m.device_id = RegRead("RegToken", "Authentication555ef22569702d048c9d0e00")
    endif
    print m.device_id
  end if


  'preconfiguring to true for alpha testing
  m.linked = false 'as linked is false, once authenticated linked = true
  'SVOD'

  m.loading_offset = 1 'how many categories to load at start
  m.loading_group = 2 'how many categories to grab at a time when scrolling

  'stores where the x,y position are in the home screen for every time you go back it maintains position
  m.home_x = 0
  m.home_y = 0
  m.previous_home_x = 0
  m.previous_home_y = 0

  'determine autoplay
  m.config.autoplay = false
End Function

'pull and setup configuration from api
Function get_dynamic_config() as void
  url = m.api.endpoint + "/app/?api_key=" + m.api.key + "&app_key=" + m.api.app
  res = call_api(url)
  m.config = res

  'true for avod and non-linked svod
  m.config.play_ads = true

  m.config.per_page = Str(m.config.per_page).Trim()
  m.config.info = {
        header: "About"
        paragraphs: [
            "All about the Roku Channel.",
            ""
        ]
    }

    if app_type = "UNIVERSAL_SVOD" then
      ' SVOD '
      'hardcoding the authentication variables for now, will be dynamic from the Zype API
       m.config.use_authentication = true 'whether or not to use authentication
       m.config.visitor_background_img_hd = "pkg:/images/splash_screen_hd.jpg"
       m.config.activate_button_x_hd = 275
       m.config.activate_button_y_hd = 575
       m.config.browse_button_x_hd = 700
       m.config.browse_button_y_hd = 575
       m.config.visitor_background_img_sd = "pkg:/images/splash_screen_sd.jpg"
       m.config.activate_button_x_sd = 190
       m.config.activate_button_y_sd = 375
       m.config.browse_button_x_sd = 380
       m.config.browse_button_y_sd = 375
       m.config.target_rect_x_visitor_screen = 0
       m.config.target_rect_y_visitor_screen = 0
       m.config.visitor_background_color = "#000000"
       m.config.device_link_url = "www.example.com/link"
       m.config.subscription_button = "Subscription Required"
      'end hardcoding of authentication variables
      
       ' SVOD'
    end if

  cache_images(m.config.app_images)
End Function

'cache theme images in temporary storage
Function cache_images(images As Object) as void
  cached_images = CreateObject("roAssociativeArray")
  for each image in images
    for each key in image
      if image[key] = invalid
      else
        print "caching: " + image[key]
        file = "tmp:/" + key + ".png"
        ut = CreateObject("roUrlTransfer")
        ut.SetUrl(image[key])
        responseCode = ut.GetToFile(file)
        if responseCode = 200
          cached_images[key] = file
          print "success"
        end if
      end if
    end for
  end for
  m.images = cached_images
End Function

'initialize the theme variables
Function init_theme() as void
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

  print theme
  app.SetTheme(theme)
end Function
