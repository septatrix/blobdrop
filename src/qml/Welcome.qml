import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

import Backend

Kirigami.PlaceholderMessage {
	icon.name: Settings.intercept ? "edit-paste" : "document-open"
	text: Settings.intercept ? qsTr("Drop files to intercept") : qsTr("No files to drag")
	explanation: Settings.intercept
		? qsTr("Drop an existing drag here to convert it to another frontend.")
		: qsTr("Pass file names as arguments or pipe them to stdin. You can also drop files here to print their paths.")
	QQC2.CheckBox {
		Layout.alignment: Qt.AlignHCenter
		text: qsTr("Keep dropped items")
		checked: Settings.keepDroppedFiles
		onToggled: Settings.keepDroppedFiles = checked
	}
}
