Function success_purchase_modal(episode, screen) as object
  port = CreateObject("roMessagePort")
  dialog = CreateObject("roMessageDialog")
  dialog.SetMessagePort(port)
  dialog.SetTitle("Success")
  dialog.SetText("You have successfully purchased " + episode.title + "!")

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
