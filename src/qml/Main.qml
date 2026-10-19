import QtQuick
import QtQuick.Controls as QQC2
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
		anchors.fill: parent
		enabled: !pathView.dragActive
		onDropped: drop => Backend.handle_dropped_urls(drop.urls)
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
