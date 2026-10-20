pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

import Backend

ListView {
	id: pathView
	property bool dragActive: false
	model: PathModel
	Component.onCompleted: PathModel.finish_init()

	header: QQC2.Button {
		id: dragAllButton
		width: pathView.width
		height: visible ? implicitHeight : 0
		visible: pathView.count > 1
		icon.name: "document-multiple"
		text: PathModel.multiSelected
			? qsTr("Drag %1 selected items").arg(PathModel.multiSelected)
			: qsTr("Drag all %1 items").arg(pathView.count)
		DragArea {
			anchors.fill: parent
			target: dragAllButton
			dragUri: PathModel.foldedUriList
			createPortalTransfer: uri => Backend.portal_transfer_data(uri)
			onPreDragStarted: PathModel.refresh_folded_paths()
			onDragStarted: {
				Settings.alwaysOnBottom = true;
				pathView.dragActive = true;
			}
			onDragFinished: dropAction => {
				if (dropAction !== Qt.IgnoreAction) {
					PathModel.taint_all_used();
				}
				Settings.alwaysOnBottom = false;
				pathView.dragActive = false;
			}
		}
	}
	delegate: QQC2.ItemDelegate {
		id: delegate
		required property int index
		required property string path
		required property string uri
		required property string pretty
		required property string iconName
		required property url thumbnail
		required property bool used
		required property bool multiselect
		required property bool exists

		width: ListView.view.width
		text: pretty
		highlighted: multiselect
		onClicked: PathModel.open(index)
		QQC2.ToolTip.text: path + (!exists ? "\n" + qsTr("File does not exist") : used ? "\n" + qsTr("Already dragged") : "")
		QQC2.ToolTip.visible: dragArea.containsMouse
		QQC2.ToolTip.delay: Kirigami.Units.toolTipDelay

		contentItem: RowLayout {
			spacing: Kirigami.Units.smallSpacing
			Item {
				id: preview
				Layout.preferredWidth: Settings.thumbnailSize
				Layout.preferredHeight: Settings.thumbnailSize
				Kirigami.Icon {
					anchors.fill: parent
					source: delegate.iconName
					fallback: "qrc:/blobdrop"
					visible: !thumbnailImage.visible
				}
				Image {
					id: thumbnailImage
					anchors.fill: parent
					source: delegate.thumbnail
					visible: status === Image.Ready
					fillMode: Image.PreserveAspectFit
					sourceSize.width: Settings.thumbnailSize
					sourceSize.height: Settings.thumbnailSize
					asynchronous: true
				}
			}
			QQC2.Label {
				Layout.fillWidth: true
				text: delegate.pretty
				textFormat: Text.PlainText
				elide: Text.ElideRight
				wrapMode: Text.Wrap
				maximumLineCount: 2
				visible: !Settings.iconOnly
			}
			Kirigami.Icon {
				Layout.preferredWidth: Kirigami.Units.iconSizes.small
				Layout.preferredHeight: Kirigami.Units.iconSizes.small
				source: !delegate.exists ? "dialog-warning" : "emblem-ok-symbolic"
				visible: !delegate.exists || delegate.used
			}
		}
		DragArea {
			id: dragArea
			anchors.fill: parent
			target: preview
			dragUri: delegate.uri
			createPortalTransfer: uri => Backend.portal_transfer_data(uri)
			hoverEnabled: true
			acceptedButtons: Qt.LeftButton | Qt.RightButton
			onClicked: ev => {
				if (ev.modifiers & Qt.ControlModifier) {
					PathModel.multiselect(delegate.index);
				} else {
					PathModel.open(delegate.index);
				}
			}
			onDragStarted: {
				Settings.alwaysOnBottom = true;
				pathView.dragActive = true;
			}
			onDragFinished: dropAction => {
				if (dropAction !== Qt.IgnoreAction) {
					PathModel.taint_used(delegate.index);
				}
				Settings.alwaysOnBottom = false;
				pathView.dragActive = false;
			}
		}
	}
}
