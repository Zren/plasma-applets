import QtQuick 2.0
import QtQuick.Layouts 1.1
import org.kde.plasma.plasmoid 2.0
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.components 2.0 as PlasmaComponents

import org.kde.plasma.private.volume 0.1

import "../code/sinkcommands.js" as PulseObjectCommands

Item {
	id: main

	QtObject {
		id: config
		property bool showVisualFeedback: false
		property string volumeSliderUrl: plasmoid.file("images", "volumeslider-default.svg")
	}

	//sinkModel.defaultSink
	SinkModel {
		id: sinkModel
	}

	VolumeFeedback {
		id: feedback
	}

	function playFeedback(sinkIndex) {
		// if (!plasmoid.configuration.volumeChangeFeedback) {
		//     return;
		// }
		if (sinkIndex == undefined) {
			sinkIndex = sinkModel.preferredSink.index;
		}
		feedback.play(sinkIndex);
	}

	Plasmoid.preferredRepresentation: Plasmoid.fullRepresentation

	Plasmoid.fullRepresentation: Item {
		Layout.preferredWidth: 120 * units.devicePixelRatio
		Layout.preferredHeight: 40 * units.devicePixelRatio

		VerticalVolumeSlider {
			id: slider

			anchors.fill: parent
			property var pulseObject: sinkModel.defaultSink

			readonly property int volume: pulseObject.volume
			property bool ignoreValueChange: true
			property bool isVolumeBoosted: false

			minimumValue: 0
			maximumValue: slider.isVolumeBoosted ? 98304 : 65536
			showPercentageLabel: false
			orientation: Qt.Horizontal


			stepSize: maximumValue / maxPercentage
			visible: pulseObject.hasVolume
			enabled: typeof pulseObject.volumeWritable === 'undefined' || pulseObject.volumeWritable

			opacity: {
				return enabled && pulseObject.muted ? 0.5 : 1
			}

			onVolumeChanged: {
				var oldIgnoreValueChange = ignoreValueChange;
				if (!slider.isVolumeBoosted && pulseObject.volume > 66000) {
					slider.isVolumeBoosted = true;
				}
				value = pulseObject.volume;
				ignoreValueChange = oldIgnoreValueChange;
			}

			onValueChanged: {
				if (!ignoreValueChange) {
					PulseObjectCommands.setVolume(pulseObject, value);

					if (!pressed) {
						updateTimer.restart();
					}
				}
			}

			property bool playFeedbackOnUpdate: false
			onPressedChanged: {
				if (pressed) {
					playFeedbackOnUpdate = true
				} else {
					// Make sure to sync the volume once the button was
					// released.
					// Otherwise it might be that the slider is at v10
					// whereas PA rejected the volume change and is
					// still at v15 (e.g.).
					updateTimer.restart();
				}
			}

			Timer {
				id: updateTimer
				interval: 200
				onTriggered: {
					slider.value = slider.pulseObject.volume

					// Done dragging, play feedback
					if (slider.playFeedbackOnUpdate) {
						main.playFeedback(slider.pulseObject.index)
					}

					if (!slider.pressed) {
						slider.playFeedbackOnUpdate = false
					}
				}
			}

			// Block wheel events
			MouseArea {
				anchors.fill: parent
				acceptedButtons: Qt.NoButton
				// onWheel: wheel.accepted = true
			}

			Component.onCompleted: {
				ignoreValueChange = false
				slider.isVolumeBoosted = pulseObject.volume > 66000 // 100% is 65863.68, not 65536... Bleh. Just trigger at a round number.
			}
		}
	}

	PlasmaCore.DataSource {
		id: executeSource
		engine: "executable"
		connectedSources: []
		onNewData: {
			disconnectSource(sourceName)
		}
	}
	function exec(cmd) {
		executeSource.connectSource(cmd)
	}

	function action_openTaskManager() {
		exec("ksysguard");
	}

	Component.onCompleted: {
		plasmoid.setAction("openTaskManager", i18n("Start Task Manager"), "utilities-system-monitor");

		// plasmoid.action('configure').trigger() // Uncomment to open the config window on load.
	}
}
