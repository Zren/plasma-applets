import QtQuick 2.0
import QtQuick.Layouts 1.0

import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.plasmoid 2.0

// Based roughly on:
// https://github.com/KDE/plasma-desktop/blob/master/desktoppackage/contents/applet/CompactApplet.qml

Item {
	id: main

	property var compactItemIcon: 'plasma'

	signal compactItemPressed(var mouse)
	signal compactItemClicked(var mouse)
	signal compactItemWheel(var wheel)

	Plasmoid.onCompactRepresentationItemChanged: {
		Plasmoid.compactRepresentationItem.compactItemPressed.connect(main.compactItemPressed)
		Plasmoid.compactRepresentationItem.compactItemClicked.connect(main.compactItemClicked)
		Plasmoid.compactRepresentationItem.compactItemWheel.connect(main.compactItemWheel)
		dialog.visualParent = Plasmoid.compactRepresentationItem
	}
	Plasmoid.compactRepresentation: Item {
		id: compactItem

		PlasmaCore.FrameSvgItem {
			id: expandedItem
			anchors.fill: parent
			imagePath: "widgets/tabbar"
			visible: fromCurrentTheme && opacity > 0
			prefix: {
				var prefix;
				switch (plasmoid.location) {
					case PlasmaCore.Types.LeftEdge:
						prefix = "west-active-tab";
						break;
					case PlasmaCore.Types.TopEdge:
						prefix = "north-active-tab";
						break;
					case PlasmaCore.Types.RightEdge:
						prefix = "east-active-tab";
						break;
					default:
						prefix = "south-active-tab";
					}
					if (!hasElementPrefix(prefix)) {
						prefix = "active-tab";
					}
					return prefix;
				}
			opacity: main.dialogVisible ? 1 : 0
			Behavior on opacity {
				NumberAnimation {
					duration: units.shortDuration
					easing.type: Easing.InOutQuad
				}
			}
		}

		PlasmaCore.IconItem {
			anchors.fill: parent
			source: main.compactItemIcon
			active: mouseArea.containsMouse
			colorGroup: PlasmaCore.ColorScope.colorGroup
		}

		readonly property bool inPanel: (plasmoid.location == PlasmaCore.Types.TopEdge
			|| plasmoid.location == PlasmaCore.Types.RightEdge
			|| plasmoid.location == PlasmaCore.Types.BottomEdge
			|| plasmoid.location == PlasmaCore.Types.LeftEdge)

		Layout.minimumWidth: {
			switch (plasmoid.formFactor) {
			case PlasmaCore.Types.Vertical:
				return 0;
			case PlasmaCore.Types.Horizontal:
				return height;
			default:
				return units.gridUnit * 3;
			}
		}

		Layout.minimumHeight: {
			switch (plasmoid.formFactor) {
			case PlasmaCore.Types.Vertical:
				return width;
			case PlasmaCore.Types.Horizontal:
				return 0;
			default:
				return units.gridUnit * 3;
			}
		}

		Layout.maximumWidth: inPanel ? units.iconSizeHints.panel : -1
		Layout.maximumHeight: inPanel ? units.iconSizeHints.panel : -1

		signal compactItemPressed(var mouse)
		signal compactItemClicked(var mouse)
		signal compactItemWheel(var wheel)
		MouseArea {
			id: mouseArea
			anchors.fill: parent
			hoverEnabled: true
			acceptedButtons: Qt.LeftButton | Qt.MiddleButton
			onPressed: compactItem.compactItemPressed(mouse)
			onClicked: compactItem.compactItemClicked(mouse)
			onWheel: compactItem.compactItemWheel(wheel)
		}
	}



	property alias dialog: dialog
	property alias dialogVisible: dialog.visible
	property alias dialogContents: dialog.mainItem

	signal dialogOpened(bool usedKeyboard)
	signal dialogClosed(bool usedKeyboard)

	PlasmaCore.Dialog {
		id: dialog
		flags: Qt.WindowStaysOnTopHint
		location: plasmoid.location
		hideOnWindowDeactivate: plasmoid.hideOnWindowDeactivate

		onMainItemChanged: {
			mainItem.Keys.onEscapePressed.connect(main.escapePressed)
		}
	}
	function escapePressed() {
		main.closeDialog(true)
	}
	function openDialog(usedKeyboard) {
		plasmoid.expanded = true
		delayedUnexpandTimer.start()
		dialog.visible = true
		dialogOpened(usedKeyboard)
	}
	function closeDialog(usedKeyboard) {
		dialog.visible = false
		delayedUnexpandTimer.start()
		dialogClosed(usedKeyboard)
	}
	function toggleDialog(usedKeyboard) {
		if (dialog.visible) {
			closeDialog(usedKeyboard)
		} else {
			openDialog(usedKeyboard)
		}
	}



	// NOTE: taken from redshift plasmoid (who took in from colorPicker)
	// This prevents the popup from actually opening, needs to be queued.
	Timer {
		id: delayedUnexpandTimer
		interval: 0
		onTriggered: {
			plasmoid.expanded = false
		}
	}

	Plasmoid.onActivated: {
		toggleDialog(true)
	}
}
