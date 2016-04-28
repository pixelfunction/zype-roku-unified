Function info_screen() as void
  ggaa = GetGlobalAA()
  m.config = ggaa.config

  screen = CreateObject("roParagraphScreen")
  port = CreateObject("roMessagePort")
  screen.SetMessagePort(port)

  screen.SetBreadcrumbText(m.config.info_title, "")
  screen.AddButton(1, "Back")

  screen.AddHeaderText(m.config.info.header)
  for each paragraph in m.config.info.paragraphs
    screen.AddParagraph(paragraph)
  end for

  screen.show()

  while (true)
    msg = wait(0, port)
    if type(msg) = "roParagraphScreenEvent"
      if (msg.isScreenClosed())
        exit while
      endif
      if msg.GetIndex() = 1
        exit while
      endif
    endif
  end while

  screen.close()
End Function

function terms_screen() as void
  port = CreateObject("roMessagePort")
  screen = CreateObject("roTextScreen")
  screen.SetMessagePort(Port)

  screen.SetTitle("Title")
  screen.SetHeaderText("Header Text")
  screen.SetText("Text")

  screen.AddButton(1,"Back")
  screen.Show()

  while true
    msg = wait(0, screen.GetMessagePort())
    if type(msg) = "roTextScreenEvent"
        if msg.isScreenClosed() then
             exit while
        else if msg.isButtonPressed() then
             if msg.GetIndex() = 1 then
                exit while
             endif
        endif
    endif
  end while

  screen.close()
end function

function launchApp(appId as string) as void
  di = CreateObject("roDeviceInfo")
  ip = di.GetIPAddrs()
  xfer = CreateObject("roURLTransfer")
    
  if IsInstalled(appId) = true
    ECPUrl= "http://" + ip["eth1"] + ":8060/launch/" + appId
  else
    ECPUrl= "http://" + ip["eth1"] + ":8060/install/" + appId
  end if

  xfer.SetURL(ECPUrl)
  result = xfer.PostFromString("")
end function

function IsInstalled(appId as string) as boolean
    di = CreateObject("roDeviceInfo")
    ip = di.GetIPAddrs()
    xfer = CreateObject("roURLTransfer")
    ECPUrl= "http://" + ip["eth1"] + ":8060/query/apps"
    xfer.SetURL(ECPUrl)
    result = xfer.GetToString() 
    ' print result
    
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