import QtQuick 2.0
import QtQuick.Controls 1.1
import QtQuick.Controls.Styles 1.1
import QtQuick.Layouts 1.1
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.calendar 2.0 as PlasmaCalendar
import org.kde.plasma.components 2.0 as PlasmaComponents
import org.kde.plasma.extras 2.0 as PlasmaExtras

import "shared.js" as Shared
import "../code/WeatherApi.js" as WeatherApi
import "../code/DebugFixtures.js" as DebugFixtures

RowLayout {
    id: agendaListItem
    Layout.fillWidth: true
    anchors.left: parent.left
    anchors.right: parent.right
    spacing: 10
    property date agendaItemDate: model.date
    property bool agendaItemIsToday: false
    function checkIfToday() {
        agendaItemIsToday = timeModel.currentTime && model.date ? Shared.isSameDate(timeModel.currentTime, model.date) : false
        // console.log('checkIfToday()', agendaListItem.agendaItemIsToday, timeModel.currentTime, model.date)
    }
    Component.onCompleted: agendaListItem.checkIfToday()
    Connections {
        target: timeModel
        onLoaded: agendaListItem.checkIfToday()
        onDateChanged: agendaListItem.checkIfToday()
    }
    property bool agendaItemInProgress: agendaItemIsToday

    LinkRect {
        Layout.alignment: Qt.AlignTop

        Column {
            id: itemWeatherColumn
            width: 3 * units.gridUnit
            Layout.alignment: Qt.AlignTop

            FontIcon {
                visible: showWeather && plasmoid.configuration.agenda_weather_show_icon
                color: agendaItemIsToday ? inProgressColor : PlasmaCore.ColorScope.textColor
                source: weatherIcon
                height: plasmoid.configuration.agenda_weather_icon_height
                showOutline: plasmoid.configuration.show_outlines
                anchors {
                    left: parent.left
                    right: parent.right
                }
            }

            Text {
                id: itemWeatherText
                visible: showWeather && plasmoid.configuration.agenda_weather_show_text
                text: weatherText
                color: agendaItemIsToday ? inProgressColor : PlasmaCore.ColorScope.textColor
                opacity: agendaItemIsToday ? 1 : 0.75
                font.weight: agendaItemIsToday ? inProgressFontWeight : Font.Normal
                anchors {
                    left: parent.left
                    right: parent.right
                }
                horizontalAlignment: paintedWidth > parent.width ? Text.AlignLeft  : Text.AlignHCenter
            }

            Text {
                id: itemWeatherTemps
                visible: showWeather
                text: tempHigh + '° | ' + tempLow + '°'
                color: agendaItemIsToday ? inProgressColor : PlasmaCore.ColorScope.textColor
                opacity: agendaItemIsToday ? 1 : 0.75
                font.weight: agendaItemIsToday ? inProgressFontWeight : Font.Normal
                anchors {
                    left: parent.left
                    right: parent.right
                }
                horizontalAlignment: paintedWidth > parent.width ? Text.AlignLeft  : Text.AlignHCenter
            }
        }

        tooltipMainText: weatherDescription
        tooltipSubText: weatherNotes

        onLeftClicked: {
            // console.log('agendaItem.date.clicked', date)
            if (true) {
                // cfg_agenda_weather_clicked == "browser_viewcityforecast"
                WeatherApi.openCityUrl();
            }
        }
    }

    LinkRect {
        Layout.alignment: Qt.AlignTop

        Column {
            id: itemDateColumn
            width: 2.5 * units.gridUnit

            Text {
                id: itemDate
                text: Qt.formatDateTime(date, "MMM d")
                color: agendaItemIsToday ? inProgressColor : PlasmaCore.ColorScope.textColor
                opacity: agendaItemIsToday ? 1 : 0.75
                font.weight: agendaItemIsToday ? inProgressFontWeight : Font.Normal
                anchors {
                    left: parent.left
                    right: parent.right
                }
                horizontalAlignment: Text.AlignRight

                // MouseArea {
                //     anchors.fill: itemDateColumn
                //     onClicked: {
                //         newEventInput.forceActiveFocus()
                //     }
                // }
            }

            Text {
                id: itemDay
                text: Qt.formatDateTime(date, "ddd")
                color: agendaItemIsToday ? inProgressColor : PlasmaCore.ColorScope.textColor
                opacity: agendaItemIsToday ? 1 : 0.5
                font.weight: agendaItemIsToday ? inProgressFontWeight : Font.Normal
                anchors {
                    left: parent.left
                    right: parent.right
                }
                horizontalAlignment: Text.AlignRight
            }
        }

        onLeftClicked: {
            // console.log('agendaItem.date.leftClicked', date)
            if (false) {
                // cfg_agenda_date_clicked == "browser_newevent"
                Shared.openGoogleCalendarNewEventUrl(date);
            } else if (true) {
                // cfg_agenda_date_clicked == "agenda_newevent"
                newEventForm.active = !newEventForm.active
            }
        }
    }

    ColumnLayout {
        Layout.alignment: Qt.AlignTop | Qt.AlignLeft
        spacing: 0
        Item {
            Layout.fillWidth: true
        }

        Loader {
            id: newEventForm
            active: false
            visible: active

            Layout.fillWidth: true
            sourceComponent: Component {

                ColumnLayout {
                    Component.onCompleted: {
                        newEventText.forceActiveFocus()
                        newEventFormOpened(model, newEventCalendarId)
                    }
                    PlasmaComponents.ComboBox {
                        id: newEventCalendarId
                        Layout.fillWidth: true
                        model: ['asdf']
                    }

                    RowLayout {
                        PlasmaComponents.TextField {
                            id: newEventText
                            Layout.fillWidth: true
                            placeholderText: i18n("Eg: 9am-5pm Work")
                            onAccepted: {
                                var calendarId = newEventCalendarId.model[newEventCalendarId.currentIndex]
                                submitNewEventForm(calendarId, date, text)
                                text = ''
                            }
                        }
                    }

                    Item {
                        Layout.fillWidth: true
                        height: 10
                    }
                }
            }
        }
        

        ColumnLayout {
            spacing: 10
            Layout.fillWidth: true

            Repeater {
                model: events

                delegate: LinkRect {
                    id: eventListItem
                    width: undefined
                    Layout.fillWidth: true
                    Layout.preferredHeight: eventColumn.height
                    // height: eventColumn.height
                    property bool eventItemInProgress: false
                    function checkIfInProgress() {
                        eventItemInProgress = start && currentTime && end ? start.dateTime <= currentTime && currentTime <= end.dateTime : false
                        // console.log('checkIfInProgress()', start, currentTime, end)
                    }
                    Connections {
                        target: timeModel
                        onLoaded: eventListItem.checkIfInProgress()
                        onMinuteChanged: eventListItem.checkIfInProgress()
                    }
                    Component.onCompleted: eventListItem.checkIfInProgress()

                    RowLayout {
                        width: parent.width

                        Rectangle {
                            Layout.preferredWidth: 2 * units.devicePixelRatio
                            Layout.preferredHeight: eventColumn.height
                            color: model.backgroundColor
                        }

                        ColumnLayout {
                            id: eventColumn
                            Layout.fillWidth: true

                            Text {
                                id: eventSummary
                                text: summary
                                color: eventItemInProgress ? inProgressColor : PlasmaCore.ColorScope.textColor
                                font.weight: eventItemInProgress ? inProgressFontWeight : Font.Normal
                                visible: !editSummaryForm.active
                                Layout.fillWidth: true
                            }

                            Loader {
                                id: editSummaryForm
                                active: false
                                visible: active
                                Layout.fillWidth: true
                                sourceComponent: Component {
                                    PlasmaComponents.TextField {
                                        id: editEventText
                                        placeholderText: i18n("Event Summary")
                                        text: summary
                                        onAccepted: {
                                            console.log('editEventText.onAccepted', text)
                                        }
                                        Component.onCompleted: {
                                            forceActiveFocus()
                                        }

                                        Keys.onEscapePressed: editSummaryForm.active = false
                                    }
                                }
                            }

                            Text {
                                id: eventDateTime
                                text: {
                                    Shared.formatEventDuration(model, {
                                        relativeDate: agendaItemDate,
                                        clock_24h: plasmoid.configuration.clock_24h,
                                    })
                                }
                                color: eventItemInProgress ? inProgressColor : PlasmaCore.ColorScope.textColor
                                opacity: eventItemInProgress ? 1 : 0.75
                                font.weight: eventItemInProgress ? inProgressFontWeight : Font.Normal
                            }
                        }
                    }
                    
                    onLeftClicked: {
                        // console.log('agendaItem.event.leftClicked', start.date, mouse)
                        if (true) {
                            // cfg_agenda_event_clicked == "browser_viewevent"
                            Qt.openUrlExternally(htmlLink)
                        }
                    }

                    onLoadContextMenu: {
                        var menuItem;

                        menuItem = contextMenu.newMenuItem();
                        menuItem.text = i18n("Edit description");
                        menuItem.enabled = false;
                        menuItem.clicked.connect(function() {
                            editSummaryForm.active = !editSummaryForm.active
                        });
                        contextMenu.addMenuItem(menuItem);

                        menuItem = contextMenu.newMenuItem();
                        menuItem.text = i18n("Edit in browser");
                        menuItem.clicked.connect(function() {
                            Qt.openUrlExternally(model.htmlLink)
                        });
                        contextMenu.addMenuItem(menuItem);
                    }

                }
            }
        }

    }
}
