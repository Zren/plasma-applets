import QtQuick 2.0
import QtQuick.Controls 1.0
import QtQuick.Layouts 1.0
import QtQuick.Dialogs 1.1

import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.components 2.0 as PlasmaComponents
import org.kde.plasma.extras 2.0 as PlasmaExtras
import org.kde.kquickcontrolsaddons 2.0

ConfigPage {
	id: page
	
	property alias cfg_command: command.text
	property alias cfg_waitForCompletion: waitForCompletion.checked
	property alias cfg_interval: interval.value
    property alias cfg_expandedMode: expandedMode.checked
    property string cfg_icon

    IconDialog {
        id: iconDialog
        onIconNameChanged: cfg_icon = iconName || "folder"
    }
	
	ConfigSection {
		label: i18n("Command")
		
		TextField {
			id: command
			Layout.fillWidth: true
		}

		RowLayout {
			Label {
				text: i18n("Run every ")
			}
			SpinBox {
				id: interval
				minimumValue: 50
				stepSize: 500
				maximumValue: 2000000000 // Close enough.
				suffix: "ms"
			}
		}

		RowLayout {
			Label {
				text: i18n("Choose an icon for indicator mode")
			}
            Button {
                PlasmaCore.IconItem {
                    id: iconItem
                    anchors.centerIn: parent
                    width: units.iconSizes.large
                    height: width
                    source: cfg_icon
                }

                onClicked: iconDialog.open()
            }
        }

        CheckBox {
            id: expandedMode
            text: i18n("Expanded Mode")
        }

		CheckBox {
			id: waitForCompletion
			text: i18n("Wait for completion")
			enabled: false
		}
	}
}
