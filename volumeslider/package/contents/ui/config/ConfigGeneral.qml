import QtQuick 2.0
import QtQuick.Controls 1.0
import QtQuick.Layouts 1.0

import ".."
import "../lib"

ConfigPage {
	id: page
	showAppletVersion: true

	property alias cfg_exampleBool: exampleBool.checked
	property alias cfg_exampleInt: exampleInt.value
	property alias cfg_exampleString: exampleString.text


	ConfigSection {
		label: i18n("SubHeading")

		CheckBox {
			id: exampleBool
			text: i18n("Boolean")
		}
		SpinBox {
			id: exampleInt
			suffix: i18n(" units")
		}
	}

	
	ConfigSection {
		label: i18n("SubHeading")

		ColumnLayout {
			id: content
			Layout.fillWidth: true

			Text {
				text: i18n("SubHeading")
				font.bold: true
			}

			RowLayout {
				Text {
					text: i18n("String")
				}
				TextField {
					id: exampleString
					placeholderText: i18n("String")
				}
			}
		}
	}
}
