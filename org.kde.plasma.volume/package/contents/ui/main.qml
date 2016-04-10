/*
    Copyright 2014-2015 Harald Sitter <sitter@kde.org>

    This program is free software; you can redistribute it and/or
    modify it under the terms of the GNU General Public License as
    published by the Free Software Foundation; either version 2 of
    the License or (at your option) version 3 or any later version
    accepted by the membership of KDE e.V. (or its successor approved
    by the membership of KDE e.V.), which shall act as a proxy
    defined in Section 14 of version 3 of the license.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

import QtQuick 2.0
import QtQuick.Layouts 1.0

import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.components 2.0 as PlasmaComponents
import org.kde.plasma.extras 2.0 as PlasmaExtras
import org.kde.plasma.plasmoid 2.0

import org.kde.plasma.private.volume 0.1

import "../code/icon.js" as Icon

Item {
    id: main

    property int volumeStep: 65536 / 15
    property string displayName: i18n("Audio Volume")

    Layout.minimumHeight: units.gridUnit * 12
    Layout.minimumWidth: units.gridUnit * 12
    Layout.preferredHeight: units.gridUnit * 20
    Layout.preferredWidth: units.gridUnit * 20

    Plasmoid.icon: sinkModel.defaultSink ? Icon.name(sinkModel.defaultSink.volume, sinkModel.defaultSink.muted) : Icon.name(0, true)
    Plasmoid.switchWidth: units.gridUnit * 12
    Plasmoid.switchHeight: units.gridUnit * 12
    Plasmoid.toolTipMainText: displayName
    Plasmoid.toolTipSubText: sinkModel.defaultSink ? i18n("Volume at %1%\n%2", volumePercent(sinkModel.defaultSink.volume), sinkModel.defaultSink.description) : ""

    function bound(value, min, max) {
        return Math.max(min, Math.min(value, max));
    }

    function volumePercent(volume) {
        return Math.round(100 * volume / 65536);
    }

    function increaseVolume(showOsd) {
        if (!sinkModel.defaultSink) {
            return;
        }
        var volume = bound(sinkModel.defaultSink.volume + volumeStep, 0, 65536);
        sinkModel.defaultSink.volume = volume;
        if (showOsd) {
            osd.show(volumePercent(volume));
        }
    }

    function decreaseVolume(showOsd) {
        if (!sinkModel.defaultSink) {
            return;
        }
        var volume = bound(sinkModel.defaultSink.volume - volumeStep, 0, 65536);
        sinkModel.defaultSink.volume = volume;
        if (showOsd) {
            osd.show(volumePercent(volume));
        }
    }

    function muteVolume(showOsd) {
        if (!sinkModel.defaultSink) {
            return;
        }
        var toMute = !sinkModel.defaultSink.muted;
        sinkModel.defaultSink.muted = toMute;
        if (showOsd) {
            osd.show(toMute ? 0 : volumePercent(sinkModel.defaultSink.volume));
        }
    }

    Plasmoid.compactRepresentation: PlasmaCore.IconItem {
        source: plasmoid.icon
        active: mouseArea.containsMouse
        colorGroup: PlasmaCore.ColorScope.colorGroup

        MouseArea {
            id: mouseArea

            property int wheelDelta: 0
            property bool wasExpanded: false

            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton | Qt.MiddleButton
            onPressed: {
                if (mouse.button == Qt.LeftButton) {
                    wasExpanded = plasmoid.expanded;
                } else if (mouse.button == Qt.MiddleButton) {
                    muteVolume();
                }
            }
            onClicked: {
                if (mouse.button == Qt.LeftButton) {
                    plasmoid.expanded = !wasExpanded;
                }
            }
            onWheel: {
                var delta = wheel.angleDelta.y || wheel.angleDelta.x;
                wheelDelta += delta;
                // Magic number 120 for common "one click"
                // See: http://qt-project.org/doc/qt-5/qml-qtquick-wheelevent.html#angleDelta-prop
                while (wheelDelta >= 120) {
                    wheelDelta -= 120;
                    increaseVolume();
                }
                while (wheelDelta <= -120) {
                    wheelDelta += 120;
                    decreaseVolume();
                }
            }
        }
    }

    GlobalActionCollection {
        // KGlobalAccel cannot transition from kmix to something else, so if
        // the user had a custom shortcut set for kmix those would get lost.
        // To avoid this we hijack kmix name and actions. Entirely mental but
        // best we can do to not cause annoyance for the user.
        // The display name actually is updated to whatever registered last
        // though, so as far as user visible strings go we should be fine.
        // As of 2015-07-21:
        //   componentName: kmix
        //   actions: increase_volume, decrease_volume, mute
        name: "kmix"
        displayName: main.displayName
        GlobalAction {
            objectName: "increase_volume"
            text: i18n("Increase Volume")
            shortcut: Qt.Key_VolumeUp
            onTriggered: increaseVolume(true)
        }
        GlobalAction {
            objectName: "decrease_volume"
            text: i18n("Decrease Volume")
            shortcut: Qt.Key_VolumeDown
            onTriggered: decreaseVolume(true)
        }
        GlobalAction {
            objectName: "mute"
            text: i18n("Mute")
            shortcut: Qt.Key_VolumeMute
            onTriggered: muteVolume(true)
        }
    }

    VolumeOSD {
        id: osd
    }

    PlasmaComponents.TabBar {
        id: tabBar

        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
        }

        PlasmaComponents.TabButton {
            id: devicesTab
            text: i18n("Devices")
        }

        PlasmaComponents.TabButton {
            id: streamsTab
            text: i18n("Applications")
        }
    }

    PlasmaExtras.ScrollArea {
        id: scrollView;
        horizontalScrollBarPolicy: Qt.ScrollBarAlwaysOff

        anchors {
            top: tabBar.bottom
            topMargin: units.smallSpacing
            left: parent.left
            right: parent.right
            bottom: parent.bottom
        }

        Item {
            width: streamsView.visible ? streamsView.width : devicesView.width
            height: streamsView.visible ? streamsView.height : devicesView.height

            ColumnLayout {
                id: streamsView
                visible: tabBar.currentTab == streamsTab
                property int maximumWidth: scrollView.viewport.width
                width: maximumWidth
                Layout.maximumWidth: maximumWidth

                Header {
                    Layout.fillWidth: true
                    visible: sinkInputView.count > 0
                    text: i18n("Playback Streams")
                }
                ListView {
                    id: sinkInputView

                    Layout.fillWidth: true
                    Layout.minimumHeight: contentHeight
                    Layout.maximumHeight: contentHeight

                    model: PulseObjectFilterModel {
                        sourceModel: SinkInputModel {}
                    }
                    boundsBehavior: Flickable.StopAtBounds;
                    delegate: StreamListItem {}
                }

                Header {
                    Layout.fillWidth: true
                    visible: sourceOutputView.count > 0
                    text: i18n("Capture Streams")
                }
                ListView {
                    id: sourceOutputView

                    Layout.fillWidth: true
                    Layout.minimumHeight: contentHeight
                    Layout.maximumHeight: contentHeight

                    model: PulseObjectFilterModel {
                        sourceModel: SourceOutputModel {}
                    }
                    boundsBehavior: Flickable.StopAtBounds;
                    delegate: StreamListItem {}
                }
            }

            ColumnLayout {
                id: devicesView
                visible: tabBar.currentTab == devicesTab
                property int maximumWidth: scrollView.viewport.width
                width: maximumWidth
                Layout.maximumWidth: maximumWidth

                Header {
                    Layout.fillWidth: true
                    visible: sinkView.count > 0
                    text: i18n("Playback Devices")
                }
                ListView {
                    id: sinkView

                    Layout.fillWidth: true
                    Layout.minimumHeight: contentHeight
                    Layout.maximumHeight: contentHeight

                    model: SinkModel {
                        id: sinkModel
                    }
                    boundsBehavior: Flickable.StopAtBounds;
                    delegate: SinkListItem {}
                }

                Header {
                    Layout.fillWidth: true
                    visible: sourceView.count > 0
                    text: i18n("Capture Devices")
                }
                ListView {
                    id: sourceView

                    Layout.fillWidth: true
                    Layout.minimumHeight: contentHeight
                    Layout.maximumHeight: contentHeight

                    model: SourceModel {
                        id: sourceModel
                    }
                    boundsBehavior: Flickable.StopAtBounds;
                    delegate: SourceListItem {}
                }
            }
        }
    }
}
