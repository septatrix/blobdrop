import QtQuick
import QtTest
import "../../src/qml" as Local

TestCase {
	name: "DragArea"
	when: windowShown
	visible: true
	width: 240
	height: 240
	Rectangle {
		id: preview
		width: 64
		height: 64
		color: "green"
	}
	Local.DragArea {
		id: area
		anchors.fill: parent
		target: preview
		dragUri: "file:///tmp/test.txt"
	}
	SignalSpy { id: beforeDrag; target: area; signalName: "preDragStarted" }
	SignalSpy { id: started; target: area; signalName: "dragStarted" }
	SignalSpy { id: finished; target: area; signalName: "dragFinished" }
	function test_rejected_drag_reports_ignore_action() {
		mousePress(area, 10, 10);
		tryCompare(beforeDrag, "count", 1);
		wait(100);
		mouseMove(area, 100, 100, 20, Qt.LeftButton);
		wait(100);
		mouseMove(area, 150, 150, 20, Qt.LeftButton);
		wait(100);
		mouseRelease(area, 150, 150);
		tryCompare(started, "count", 1);
		tryCompare(finished, "count", 1);
		compare(finished.signalArguments[0][0], Qt.IgnoreAction);
	}
}
