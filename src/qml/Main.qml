import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Shapes
import org.kde.kirigami as Kirigami

import Backend

Kirigami.AbstractApplicationWindow {
	id: root
	visible: Settings.needsGui
	flags: Qt.Dialog | (Settings.alwaysOnTop ? Qt.WindowStaysOnTopHint : 0) | (Settings.alwaysOnBottom ? Qt.WindowStaysOnBottomHint : 0) | (Settings.frameless ? Qt.FramelessWindowHint : 0)
	title: Stdin.closed ? qsTr("Blobdrop") : qsTr("Reading from stdin...")
	width: Settings.iconOnly ? Settings.thumbnailSize + Kirigami.Units.iconSizes.small + 3 * Kirigami.Units.largeSpacing : Kirigami.Units.gridUnit * 24
	height: Math.max(Kirigami.Units.gridUnit * 3, Math.min(Kirigami.Units.gridUnit * 40, pathView.count ? pathView.contentHeight + 2 * Kirigami.Units.smallSpacing : Kirigami.Units.gridUnit * 20))
	Component.onCompleted: {
		if (Settings.spawnOnCursor) {
			root.x = Backend.get_mouse_pos().x - width / 2;
			root.y = Backend.get_mouse_pos().y - height / 2;
		}
	}
	Shortcut {
		sequences: [StandardKey.Quit, StandardKey.Cancel, "Q"]
		onActivated: Qt.quit();
	}
	DropArea {
		id: incomingDropArea
		anchors.fill: parent
		anchors.margins: 2 * Kirigami.Units.gridUnit
		enabled: !pathView.dragActive
		onDropped: drop => Backend.handle_dropped_urls(drop.urls)
	}
	Item {
		anchors.fill: incomingDropArea
		z: 1
		visible: incomingDropArea.containsDrag
		enabled: false

		Rectangle {
			anchors.fill: parent
			color: Kirigami.Theme.backgroundColor
			opacity: 0.9
		}
		Shape {
			id: dropBorder
			anchors.fill: parent
			ShapePath {
				strokeColor: Kirigami.Theme.highlightColor
				strokeWidth: 2
				strokeStyle: ShapePath.DashLine
				dashPattern: [4, 3]
				fillColor: "transparent"
				startX: 1
				startY: 1
				PathLine { x: dropBorder.width - 1; y: 1 }
				PathLine { x: dropBorder.width - 1; y: dropBorder.height - 1 }
				PathLine { x: 1; y: dropBorder.height - 1 }
				PathLine { x: 1; y: 1 }
			}
		}
		Kirigami.PlaceholderMessage {
			anchors.centerIn: parent
			width: parent.width - 4 * Kirigami.Units.largeSpacing
			type: Kirigami.PlaceholderMessage.Type.Actionable
			icon.name: "document-import"
			text: qsTr("Drop files here")
		}
	}
	Welcome {
		anchors.centerIn: parent
		width: parent.width - 4 * Kirigami.Units.largeSpacing
		visible: pathView.count === 0
	}
	QQC2.ScrollView {
		anchors.fill: parent
		anchors.margins: Kirigami.Units.smallSpacing
		visible: pathView.count > 0
		contentItem: PathView {
			id: pathView
			clip: true
		}
	}
}
