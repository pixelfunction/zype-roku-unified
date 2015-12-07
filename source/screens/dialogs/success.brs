Function success_dialog(episode as object, screen as object, item=invalid) as object
  port = CreateObject("roMessagePort")
  dialog = CreateObject("roMessageDialog")
  dialog.SetMessagePort(port)
  dialog.SetTitle("Success")

  if item <> invalid
    dialog.SetText("You have successfully purchased " + item.name + " " + for + item.cost + " per subscription interval.")
  else
    dialog.SetText("You have successfully purchased " + episode.title + "!")
  end if

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
End Function
