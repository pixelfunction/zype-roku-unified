Function show_link_modal(title as String) As Void
    port = CreateObject("roMessagePort")
    dialog = CreateObject("roMessageDialog")
    dialog.SetMessagePort(port)
    dialog.SetTitle("Subscription Required")
    dialog.SetText("To watch " + title + " you need to link your Roku Channel!")

    dialog.AddButton(1, "Link Roku")
    dialog.AddButton(2, "Continue Browsing")
    dialog.EnableBackButton(true)
    dialog.Show()
    While True
      dlgMsg = wait(0, dialog.GetMessagePort())
      If type(dlgMsg) = "roMessageDialogEvent"
        if dlgMsg.isButtonPressed()
          if dlgMsg.GetIndex() = 1
            refresh_pin_screen()
            exit while
          end if
          if dlgMsg.GetIndex() = 2
            exit while
          end if
          else if dlgMsg.isScreenClosed()
            exit while
          end if
        end if
    end while
End Function
