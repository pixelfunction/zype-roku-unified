'all the authentication functions

Function authenticate() as object
  'check to see if device is linked
  if is_linked()
    print "you are already linked"
    home_screen()
  else
    print "you are not linked"
    visitor_screen()
  endif
end Function


Function is_linked() as boolean
  'if you are hardcoded as linked, you go free :)
  if m.linked = true
    m.config.play_ads = false
    return true
  end if

  request = CreateObject("roUrlTransfer")
  port = CreateObject("roMessagePort")
  request.SetPort(port)

  request.SetCertificatesFile("common:/certs/ca-bundle.crt")
  request.AddHeader("X-Roku-Reserved-Dev-Id", "")
  request.InitClientCertificates()

  url = m.api.endpoint + "/pin/status/?api_key=" + m.api.key + "&linked_device_id=" + m.device_id
  print url
  request.SetUrl(url)

  if(request.AsyncGetToString())
    while(true)
      msg = wait(0, port)
      if(type(msg) = "roUrlEvent")
        code = msg.GetResponseCode()
        print code
        if(code = 200)
          res = ParseJSON(msg.GetString())
          response = res.response
          m.linked = response.linked
          if m.linked
            'if you are linked, go ads free :)
            m.config.play_ads = false
          end if
          return response.linked
        else if (code = 404)
          return false
        endif
      else if(event = invalid)
        request.AsyncCancel()
        return false
      endif
    end while
  endif
End Function

Function acquire_pin() as object
  request = CreateObject("roUrlTransfer")
  port = CreateObject("roMessagePort")
  request.SetPort(port)

  request.SetCertificatesFile("common:/certs/ca-bundle.crt")
  request.AddHeader("X-Roku-Reserved-Dev-Id", "")
  request.InitClientCertificates()

  url = "https://api.zype.com/pin/acquire/?api_key=" + m.api.key
  request.SetUrl(url)
  print url

  pin_request = "linked_device_id=" + m.device_id + "&type=roku"

  if(request.AsyncPostFromString(pin_request))
    while(true)
      msg = wait(0, port)
      if(type(msg) = "roUrlEvent")
        code = msg.GetResponseCode()
        print code
        if(code = 201)
          res = ParseJSON(msg.GetString())
          response = res.response
          m.pin = response.pin
          timer = CreateObject("roTimespan")
          timer.Mark()
          m.pin_expiration = timer
          return response.pin
        else if (code = 404)
          return "ERROR"
        endif
      else if(event = invalid)
        request.AsyncCancel()
        return "ERROR"
      endif
    end while
  endif
End Function

Function refresh_pin_screen() as Object
  if is_linked()
    print "you are already linked"
    home_screen()
  else

    if update_pin()
      pin = acquire_pin()
    else
      pin = m.pin
    endif

    pin_screen(pin)
  endif
end Function

Function update_pin() as Boolean
  pin = m.pin

  if pin = invalid
    return true
  else
    'need to reaquire pin every 30 minutes or it expires (refresh every ~25 minutes)
    if m.pin_expiration.TotalSeconds() > 1500
      return true
    else
      return false
    endif
  endif
End Function

' native svod utils

'all the authentication functions
' the native svod validation
Function authenticate_native_svod() as object
    check_subscription()
    home_screen()
end Function

Function check_subscription() as object
  print "Checking if there is a subscription in the catalogue"
  set_up_shopping()

  for each item in m.user_purchases
    if item.productType = "MonthlySub" OR item.productType = "YearlySub"
      m.linked = true
      print "CONGRATS, YOU ARE SUBSCRIBED NATIVELY"
    endif
  endfor

  for each item in m.store_items
    if item.productType = "MonthlySub"
      m.monthly_sub = item
      m.monthly_sub.button = item.cost + " " + item.name
    endif

    if item.productType = "YearlySub"
      m.yearly_sub = item
      m.yearly_sub.button = item.cost + " " + item.name
  endif
  endfor
end Function

Function set_up_shopping() as void
  m.store = CreateObject("roChannelStore")
  'fake out store for right now
  'm.store.FakeServer(true)

  m.store_items = []
  m.user_purchases = []

  get_channel_catalog()
  set_user_purchases()
end function


Function get_channel_catalog() as void
  port = CreateObject("roMessagePort")
  m.store.SetMessagePort(port)
  m.store.GetCatalog()

    while(true)
      msg = wait(0, port)
    if (type(msg) = "roChannelStoreEvent")
      if (msg.isRequestSucceeded())
        m.store_items = msg.GetResponse()
        exit while
        endif
      endif
    end while
End Function


Function set_user_purchases() as void
  port = CreateObject("roMessagePort")

  m.store.SetMessagePort(port)
  m.store.GetPurchases()

    while(true)
      msg = wait(0, port)
    if (type(msg) = "roChannelStoreEvent")
      if (msg.isRequestSucceeded())
        m.user_purchases = msg.GetResponse()
        exit while
        endif
      endif
    end while
end Function

' native svod some extra function for subscription transactions

'move this somewhere better
Function purchase_subscription(episode, screen, item) as void
  port = CreateObject("roMessagePort")
  m.store.SetMessagePort(port)

  order = [{code: item.code, qty: 1}]

  m.store.SetOrder(order)
  print m.store.GetOrder()
  result = m.store.DoOrder()

  if(result = true)
    'add the episode as one that has been purchased
    m.user_purchases.push(m.store.GetOrder())

    'set linked to true because you have a subscription
    m.linked = true

    'show the success modal
    success_purchase_modal(episode, screen, item)
  else
    print "ORDER FAILED"
    error_purchase_modal(episode)
  endif
end Function

Function success_purchase_modal(episode, screen, item) as object
  port = CreateObject("roMessagePort")
  dialog = CreateObject("roMessageDialog")
  dialog.SetMessagePort(port)
  dialog.SetTitle("Success!")
  dialog.SetText("You have successfully purchased " + item.name + " " + for + item.cost + " per subscription interval.")
  m.linked = true

  dialog.AddButton(1, "OK")
  dialog.Show()

  While True
    dlgMsg = wait(0, dialog.GetMessagePort())
    if type(dlgMsg) = "roMessageDialogEvent"
      if dlgMsg.isButtonPressed()
        if dlgMsg.GetIndex() = 1
          screen.ClearButtons()
          screen.AddButton(2, m.config.play_button_text)
          screen.show()
          return -1
          exit while
        end if
      end if
    end if
  end while
end Function

Function error_purchase_modal(episode) As Object
    port = CreateObject("roMessagePort")
    dialog = CreateObject("roMessageDialog")
    dialog.SetMessagePort(port)
    dialog.SetTitle("Transaction cancelled")
    dialog.SetText("If you would like to purchase this subscription, please try again.")

    dialog.AddButton(1, "Go back")
    dialog.EnableBackButton(true)
    dialog.Show()
    While True
      dlgMsg = wait(0, dialog.GetMessagePort())
      If type(dlgMsg) = "roMessageDialogEvent"
        if dlgMsg.isButtonPressed()
          if dlgMsg.GetIndex() = 1
            return -1
            exit while
          end if
          else if dlgMsg.isScreenClosed()
            return -1
            exit while
          end if
        end if
    end while
End Function
