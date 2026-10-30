import QtQuick
import QtQml
import org.kde.plasma.plasmoid
import org.kde.plasma.private.kicker as Kicker

PlasmoidItem {
    id: root
    property bool ready: true
    property int refreshes: 0
    property int inserts: 0
    property int removals: 0
    property int changes: 0
    function reconnect() { root.ready = true; }
    Kicker.RootModel {
        id: catalog
        autoPopulate: true
        flat: false
        showAllApps: false
        showRecentApps: false
        showRecentDocs: false
        showPowerSession: false
    }
    Connections {
        target: catalog
        function onModelAboutToBeReset() { root.ready = false; }
        function onModelReset() { Qt.callLater(root.reconnect); }
        function onRefreshed() {
            root.ready = false;
            root.refreshes++;
            Qt.callLater(root.reconnect);
        }
    }
    // Eager delegates inspect all top-level categories, independent of viewport.
    Repeater {
        id: categories
        model: root.ready ? catalog : null
        delegate: Item {
            id: category
            required property int index
            required property var model
            property var submodel: catalog.modelForRow(index)
            property alias appDelegates: entries
            property string categoryName: String(model.display ?? "")
            Connections {
                target: category.submodel
                function onRowsInserted() { root.inserts++; }
                function onRowsRemoved() { root.removals++; }
                function onDataChanged() { root.changes++; }
            }
            Repeater {
                id: entries
                model: category.submodel
                delegate: Item {
                    required property var model
                    property string entryName: String(model.display ?? "")
                }
            }
        }
    }
    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: {
            let a = [], b = [];
            let complete = root.ready && catalog.count > 0 && categories.count === catalog.count;
            for (let i = 0; i < categories.count; ++i) {
                const c = categories.itemAt(i);
                if (!c || !c.submodel || c.appDelegates.count !== c.submodel.count) {
                    complete = false;
                    continue;
                }
                for (let j = 0; j < c.appDelegates.count; ++j) {
                    const e = c.appDelegates.itemAt(j);
                    if (!e) { complete = false; continue; }
                    if (e.entryName === "ZZ Plasma Launcher Auto A") a.push(c.categoryName);
                    if (e.entryName === "ZZ Plasma Launcher Auto B") b.push(c.categoryName);
                }
            }
            console.log("CATALOG_PROBE " + JSON.stringify({
                time: Date.now(), complete: complete, a: a, b: b,
                refreshed: root.refreshes, inserted: root.inserts,
                removed: root.removals, changed: root.changes
            }));
        }
    }
    fullRepresentation: Item {
        implicitWidth: 420
        implicitHeight: 100
        Text { anchors.centerIn: parent; text: "Diagnóstico automático do catálogo — não fechar" }
    }
}
