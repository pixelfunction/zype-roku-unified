Function error_dialog(episode as object) As Void
    port = CreateObject("roMessagePort")
    dialog = CreateObject("roMessageDialog")
    dialog.SetMessagePort(port)
    dialog.SetTitle("Transaction cancelled or failed")
    dialog.SetText("Please, try again to subscribe or make a purchase.")

    dialog.AddButton(1, "Go back")
    dialog.EnableBackButton(true)
    dialog.Show()
    While True
      dlgMsg = wait(0, dialog.GetMessagePort())
      If type(dlgMsg) = "roMessageDialogEvent"
        if dlgMsg.isButtonPressed()
          if dlgMsg.GetIndex() = 1
            exit while
          end if
          else if dlgMsg.isScreenClosed()
            exit while
          end if
        end if
    end while
    dialog.close()
End Function
