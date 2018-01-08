import QtQuick 2.1
import QtQuick.Layouts 1.0
import org.kde.plasma.plasmoid 2.0
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.components 2.0 as PlasmaComponent

Item {
	id: widget

	// https://github.com/KDE/plasma-workspace/blob/master/dataengines/executable/executable.h
	// https://github.com/KDE/plasma-workspace/blob/master/dataengines/executable/executable.cpp
	// https://github.com/KDE/plasma-framework/blob/master/src/declarativeimports/core/datasource.h
	// https://github.com/KDE/plasma-framework/blob/master/src/declarativeimports/core/datasource.cpp
	// https://github.com/KDE/plasma-framework/blob/master/src/plasma/scripting/dataenginescript.cpp
	PlasmaCore.DataSource {
		id: executable
		engine: "executable"
		connectedSources: []
		onNewData: {
			var exitCode = data["exit code"]
			var exitStatus = data["exit status"]
			var stdout = data["stdout"]
			var stderr = data["stderr"]
			exited(exitCode, exitStatus, stdout, stderr)
			disconnectSource(sourceName) // cmd finished
		}
		function exec(cmd) {
			connectSource(cmd)
		}
		signal exited(int exitCode, int exitStatus, string stdout, string stderr)
	}

	PlasmaCore.DataSource {
		id: link_runner
		engine: "executable"
		connectedSources: []
		onNewData: disconnectSource(sourceName)
		function exec(cmd) {
			connectSource(cmd)
		}
	}

	Item {
		id: config
		property bool active: !!command
		property bool waitForCompletion: plasmoid.configuration.waitForCompletion
		property int interval: Math.max(50, plasmoid.configuration.interval)
		property string command: plasmoid.configuration.command || 'sleep 2 && echo "Test: $(date +%s)"'
        property bool expandedMode: plasmoid.configuration.expandedMode
	}

	property string outputText: ''
	Connections {
		target: executable
		onExited: {
			widget.outputText = stdout.replace('\n', ' ').trim()
			if (config.waitForCompletion) {
				timer.restart()
			}
		}
	}

	Timer {
		id: timer
		interval: config.interval
		running: true
		repeat: !config.waitForCompletion
		onTriggered: {
            if(!config.expandedMode && !plasmoid.expanded)
                return;
			//console.log('tick', Date.now())
			executable.exec(config.command)
		}
	}


	Plasmoid.fullRepresentation: Item {
		// Layout.minimumWidth: output.implicitWidth
		Layout.preferredWidth: output.implicitWidth
		// Layout.maximumWidth: output.width
		Layout.preferredHeight: output.implicitHeight

		Text {
			id: output
			//height: parent.height

			text: widget.outputText

			color: theme.textColor
            textFormat: Text.RichText
            onLinkActivated: link_runner.exec(link)

			font.pointSize: -1
			font.pixelSize: 16
			fontSizeMode: Text.Fit
			horizontalAlignment: Text.AlignHCenter
			verticalAlignment: Text.AlignVCenter
		}
	}

    Plasmoid.compactRepresentation: Item {
		Layout.preferredWidth: config.expandedMode ? expandedOutput.implicitWidth : icon.implicitWidth;

		Text {
            id: expandedOutput
            text: widget.outputText
			height: parent.height
			color: theme.textColor
            visible: config.expandedMode

			font.pointSize: -1
			font.pixelSize: 14
			fontSizeMode: Text.Fit
			horizontalAlignment: Text.AlignHCenter
			verticalAlignment: Text.AlignVCenter
        }

        PlasmaCore.IconItem {
            id: icon
            anchors.fill: parent
            source: plasmoid.configuration.icon
            visible: !config.expandedMode
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            onClicked: {
                if(!config.expandedMode) {
                    plasmoid.expanded = !plasmoid.expanded;
                    if(plasmoid.expanded)
                        executable.exec(config.command)
                }
            }
        }
    }
}
