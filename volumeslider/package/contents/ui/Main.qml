import QtQuick 2.0
import QtQuick.Layouts 1.1
import org.kde.plasma.plasmoid 2.0
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.components 2.0 as PlasmaComponents

import org.kde.plasma.private.volume 0.1

import "../code/icon.js" as Icon
import "../code/sinkcommands.js" as PulseObjectCommands

Item {
	id: main

	QtObject {
		id: config
		property bool showVisualFeedback: false
		property string volumeSliderUrl: plasmoid.file("images", "volumeslider-default.svg")
		property int intervalBeforeResetingVolumeBoost: 5000
	}

	SinkModel {
		id: sinkModel
	}

	VolumeFeedback {
		id: feedback
	}

	function playFeedback(sinkIndex) {
		if (!plasmoid.configuration.volumeChangeFeedback) {
			return;
		}
		if (sinkIndex == undefined) {
			sinkIndex = sinkModel.preferredSink.index;
		}
		feedback.play(sinkIndex);
	}

	Plasmoid.preferredRepresentation: plasmoid.configuration.showInPopup ? Plasmoid.compactRepresentation : Plasmoid.fullRepresentation

	Plasmoid.fullRepresentation: Item {
		Layout.preferredWidth: plasmoid.configuration.width * units.devicePixelRatio
		Layout.preferredHeight: plasmoid.configuration.height * units.devicePixelRatio

		VerticalVolumeSlider {
			id: slider

			anchors.fill: parent
			property var pulseObject: sinkModel.defaultSink

			readonly property int volume: pulseObject.volume
			property bool ignoreValueChange: true
			property bool isVolumeBoosted: false

			Timer {
				id: volumeBoostDoneTimer
				interval: config.intervalBeforeResetingVolumeBoost
				onTriggered: slider.isVolumeBoosted = false

				function check() {
					if (slider.isVolumeBoosted && slider.pulseObject.volume <= 66000) {
						volumeBoostDoneTimer.restart()
					}
				}
			}

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
				volumeBoostDoneTimer.check()
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
				volumeBoostDoneTimer.check()
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

		PlasmaCore.ToolTipArea {
			anchors.fill: parent
			mainText: main.Plasmoid.toolTipMainText
			subText: main.Plasmoid.toolTipSubText
		}
	}

	property string displayName: i18nd("plasma_applet_org.kde.plasma.volume", "Audio Volume")
	property string speakerIcon: sinkModel.defaultSink ? Icon.name(sinkModel.defaultSink.volume, sinkModel.defaultSink.muted) : Icon.name(0, true)
	Plasmoid.icon: {
		// if (mpris2Source.hasPlayer && mpris2Source.albumArt) {
		//     return mpris2Source.albumArt;
		// } else {
			return speakerIcon;
		// }
	}
	Plasmoid.toolTipMainText: {
		// if (mpris2Source.hasPlayer && mpris2Source.track) {
		//     return mpris2Source.track;
		// } else {
			return displayName;
		// }
	}
	Plasmoid.toolTipSubText: {
		var lines = [];
		// if (mpris2Source.hasPlayer && mpris2Source.artist) {
		//     if (mpris2Source.isPaused) {
		//         lines.push(mpris2Source.artist ? i18ndc("plasma_applet_org.kde.plasma.mediacontroller", "Artist of the song", "by %1 (paused)", mpris2Source.artist) : i18nd("plasma_applet_org.kde.plasma.mediacontroller", "Paused"));
		//     } else if (mpris2Source.artist) {
		//         lines.push(i18ndc("plasma_applet_org.kde.plasma.mediacontroller", "Artist of the song", "by %1", mpris2Source.artist));
		//     }
		// }
		if (sinkModel.defaultSink) {
			var sinkVolumePercent = Math.round(PulseObjectCommands.volumePercent(sinkModel.defaultSink.volume));
			lines.push(i18nd("plasma_applet_org.kde.plasma.volume", "Volume at %1%", sinkVolumePercent));
			lines.push(sinkModel.defaultSink.description);
		}
		return lines.join('\n');
	}

	Component.onCompleted: {
		
		// plasmoid.action('configure').trigger() // Uncomment to open the config window on load.
	}
}
