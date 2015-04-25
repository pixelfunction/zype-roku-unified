Function play_episode(episode As Object, position as integer)

    if type(episode) <> "roAssociativeArray" then
        print "invalid data passed to showVideoScreen"
        return -1
    endif

    episode.playStart = position

    port = CreateObject("roMessagePort")
    screen = CreateObject("roVideoScreen")
    screen.SetCertificatesFile("common:/certs/ca-bundle.crt")
    screen.AddHeader("X-Roku-Reserved-Dev-Id", "")
    screen.InitClientCertificates()
    screen.SetMessagePort(port)

    screen.SetPositionNotificationPeriod(30)
    screen.SetContent(episode)
    screen.Show()

    PrintAA(episode)

    while true
        msg = wait(0, port)

        if type(msg) = "roVideoScreenEvent" then
            print "showHomeScreen | msg = "; msg.getMessage() " | index = "; msg.GetIndex()
            if msg.isfullresult()
            	print "Video Completed Playback Normally"
            	RegDelete(episode.id)
            	print "deleted bookmark for playback position"
            else if msg.isScreenClosed()
                print "Screen closed"
                exit while
            elseif msg.isRequestFailed()
                print "Video request failure: "; msg.GetIndex(); " " msg.GetData()
            elseif msg.isStatusMessage()
                print "Video status: "; msg.GetIndex(); " " msg.GetData()
            elseif msg.isButtonPressed()
                print "Button pressed: "; msg.GetIndex(); " " msg.GetData()
            elseif msg.isPlaybackPosition()
                nowpos = msg.GetIndex()
                RegWrite(episode.id, nowpos.toStr())
            else
                print "Unexpected event type: "; msg.GetType()
            end if
        else
            print "Unexpected message class: "; type(msg)
        end if
    end while

End Function
