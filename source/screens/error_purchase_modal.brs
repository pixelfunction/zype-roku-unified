Function error_purchase_modal(episode) As Object
    port = CreateObject("roMessagePort")
    dialog = CreateObject("roMessageDialog")
    dialog.SetMessagePort(port)
    dialog.SetTitle("Transaction cancelled")
    dialog.SetText("If you would like to purchase this video, please try again.")

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
