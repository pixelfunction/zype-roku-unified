' in app purchases related functions
Function set_up_store() As Void
  m.store = CreateObject("roChannelStore")
  'fake out store for right now
  'm.store.FakeServer(true)
  m.store_items = []
  m.user_purchases_dict = CreateObject("roAssociativeArray")
  get_channel_catalog()
  get_user_purchases()
End Function

' @refactored get IAP items
Function get_channel_catalog() as void
  port = CreateObject("roMessagePort")
  m.store.SetMessagePort(port)
  m.store.GetCatalog()
  while(true)
    msg = wait(0, port)
    if (type(msg) = "roChannelStoreEvent")
      if (msg.isRequestSucceeded())
        for each video in msg.GetResponse()
          ' @desc the video object defined on the Roku Accoune end.
          m.store_items.push({name: video.name, cost: video.cost, code: video.code, description: video.description, productType: video.productType})
        end for
        for each item in m.store_items
          if item.productType = "MonthlySub"
            m.monthly_sub = item
            if len(m.config.subscription_button_text) > 0
              m.monthly_sub.button = item.cost + " " + m.config.subscription_button_text
            else
              m.monthly_sub.button = item.cost + " " + item.name
            end if
          endif
          if item.productType = "YearlySub"
            m.yearly_sub = item
            if m.config.subscription_button_text
              m.yearly_sub.button = item.cost + " " + m.config.subscription_button_text
            else
              m.yearly_sub.button = item.cost + " " + item.name
            end if
          endif
        end for
        exit while
      else if (msg.isRequestFailed())
        'print "***** Failure: " + msg.GetStatusMessage() + " Status Code: " + stri(msg.GetStatus()) + " *****"
        exit while
      end if
    end if
  end while
End Function

' retrieve purchased items
Function get_user_purchases() as void
  port = CreateObject("roMessagePort")
  m.store.SetMessagePort(port)
  m.store.GetPurchases()
  while(true)
    msg = wait(0, port)
    if (type(msg) = "roChannelStoreEvent")
      if (msg.isRequestSucceeded())
        for each purchase in msg.GetResponse()
          if purchase.productType = "MonthlySub" OR purchase.productType = "YearlySub"
            ' Add SubToken to indentify that a user has a subscription
            m.user_purchases_dict.AddReplace("SubToken", purchase.productType)
          else
            m.user_purchases_dict.AddReplace(purchase.code, purchase.productType)
          end if
        end for
        exit while
      else if (msg.isRequestFailed())
        'print "***** Failure: " + msg.GetStatusMessage() + " Status Code: " + stri(msg.GetStatus()) + " *****"
        exit while
      end if
    end if
  end while
End Function

' @refactored checks if the user is SUBSCRIBED (native svod)
Function is_subscribed() as object
  if m.user_purchases_dict.DoesExist("SubToken")
    return true
  end if
  return false
End Function

' @refactored make subscription purchase
Function subscribe(episode as object, item as object) as boolean
  port = CreateObject("roMessagePort")
  m.store.SetMessagePort(port)
  order = [{code: item.code, qty: 1}]
  m.store.SetOrder(order)
  result = m.store.DoOrder()
  return result
end Function

' @refactored check if the item was bought
Function is_purchased(episode as object) as boolean
  if m.user_purchases_dict.DoesExist(episode.id)
    return true
  end if
  return false
End Function

' @refactored purchase an item (EST)
Function purchase_item(episode as object) as Boolean
  port = CreateObject("roMessagePort")
  m.store.SetMessagePort(port)
  order = [{code: episode.id, qty: 1}]
  m.store.SetOrder(order)
  result = m.store.DoOrder()
  if result = true
    'add the episode as one that has been purchased
    m.user_purchases_dict.AddReplace(episode.code, episode.productType)
    return true
  else
    return false
  end if
end Function
