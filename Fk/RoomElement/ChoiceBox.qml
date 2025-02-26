// SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick
import QtQuick.Layouts
import Fk.Pages

GraphicsBox {
  property var options: []
  property string skill_name: ""
  property int result

  id: root
  title.text: Backend.translate("$Choice").arg(Backend.translate(skill_name))
  width: Math.max(140, body.width + 20)
  height: body.height + title.height + 20

  function processPrompt(prompt) {
    const data = prompt.split(":");
    let raw = Backend.translate(data[0]);
    const src = parseInt(data[1]);
    const dest = parseInt(data[2]);
    if (raw.match("%src")) raw = raw.replace("%src", Backend.translate(getPhoto(src).general));
    if (raw.match("%dest")) raw = raw.replace("%dest", Backend.translate(getPhoto(dest).general));
    if (raw.match("%arg")) raw = raw.replace("%arg", Backend.translate(data[3]));
    if (raw.match("%arg2")) raw = raw.replace("%arg2", Backend.translate(data[4]));
    return raw;
  }

  GridLayout {
    id: body
    x: 10
    y: title.height + 5
    flow: GridLayout.TopToBottom
    rows: 8
    columnSpacing: 10

    Repeater {
      model: options

      MetroButton {
        Layout.fillWidth: true
        text: processPrompt(modelData)

        onClicked: {
          result = index;
          root.close();
        }
      }
    }
  }
}
