' in app purchases related functions
Function set_up_store() As Void
  m.store = CreateObject("roChannelStore")
  'fake out store for right now
  m.store.FakeServer(true)
  m.store_items = []
  m.user_purchases = []
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
          m.store_items.push({name: video.name, cost: video.cost, code: video.code, description: video.description, productType: video.productType})
        end for
        for each item in m.store_items
          if item.productType = "MonthlySub"
            m.monthly_sub = item
            m.monthly_sub.button = item.cost + " " + item.name
          endif
          if item.productType = "YearlySub"
            m.yearly_sub = item
            m.yearly_sub.button = item.cost + " " + item.name
          endif
        end for
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
           m.user_purchases.push({name: purchase.name, cost: purchase.cost, code: purchase.code, description: purchase.description, productType: purchase.productType})
        end for
        exit while
      endif
    endif
  end while
End Function

' @refactored checks if the user is SUBSCRIBED (native svod)
Function is_subscribed() as object
  for each item in m.user_purchases
    if item.productType = "MonthlySub" OR item.productType = "YearlySub"
      return true
    endif
  end for
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
  for each item in m.user_purchases
    if item.code = episode.id
      return true
    end if
  end for
  return false
End Function

' @refactored purchase an item (EST)
Function purchase_item(episode as object) as Boolean
  port = CreateObject("roMessagePort")
  m.store.SetMessagePort(port)
  order = [{code: episode.id, qty: 1}]
  m.store.SetOrder(order)
  result = m.store.DoOrder()
  for each item in m.store_items
    if item.code = episode.id
      return true
    end if
  end for
  if result = true
    'add the episode as one that has been purchased
    m.user_purchases.push({name: episode.name, cost: episode.cost, code: episode.id, description: episode.description, productType: episode.productType})
    return true
  else
    return false
  end if
end Function
