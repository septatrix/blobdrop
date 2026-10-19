import QtQuick

MouseArea {
	id: root
	required property Item target
	property string dragUri: ""
	signal preDragStarted()
	signal dragStarted()
	signal dragFinished(var dropAction)

	drag.target: dragItem
	preventStealing: true
	onPressed: {
		preDragStarted();
		const scale = Math.min(1, 64 / target.width, 64 / target.height);
		target.grabToImage(result => {
			dragItem.Drag.imageSource = result.url;
		}, Qt.size(Math.max(1, Math.round(target.width * scale)), Math.max(1, Math.round(target.height * scale))));
	}
	Item {
		id: dragItem
		width: root.width
		height: root.height
		// Defer starting the native drag until MouseArea has processed the event.
		Binding on Drag.active {
			value: root.drag.active
			delayed: true
		}
		Drag.dragType: Drag.Automatic
		Drag.mimeData: ({ "text/uri-list": root.dragUri })
		Drag.onDragStarted: root.dragStarted()
		Drag.onDragFinished: dropAction => {
			x = 0;
			y = 0;
			root.dragFinished(dropAction);
		}
	}
}
