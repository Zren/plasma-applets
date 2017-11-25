import QtQuick 2.0
import QtQuick.Controls 1.0
import QtQuick.Layouts 1.0

import ".."
import "../lib"

ConfigPage {
	id: page
	showAppletVersion: true

	ConfigSection {
		label: i18n("Size")

		RowLayout{
			ConfigSpinBox {
				configKey: "width"
				suffix: i18n("px")
				
			}
			Label {
				text: i18n(" by ")
			}
			ConfigSpinBox {
				configKey: "height"
				suffix: i18n("px")
			}
		}
		
	}

	
	ConfigSection {
		label: i18n("Options")

		ConfigCheckBox {
			configKey: "showInPopup"
			text: i18n("Show In Popup")
		}

		ConfigCheckBox {
			configKey: "volumeChangeFeedback"
			text: i18n("Volume Feedback: Play popping noise when changing the volume.")
		}
	}
}
