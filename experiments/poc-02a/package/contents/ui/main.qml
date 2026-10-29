import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.plasmoid
import org.kde.plasma.private.kicker as Kicker

PlasmoidItem {
    id: root

    property int selectedCategoryIndex: 0

    Plasmoid.icon: "applications-all"

    Kicker.RootModel {
        id: appsModel

        autoPopulate: true
        flat: false
        showAllApps: false
        showRecentApps: false
        showRecentDocs: false
        showPowerSession: false
    }

    fullRepresentation: Item {
        Layout.preferredWidth: 520
        Layout.preferredHeight: 440

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 12

            PlasmaComponents.Label {
                text: "PoC 02A — Catálogo KDE"
                font.bold: true
            }

            PlasmaComponents.Label {
                text: "Entradas no modelo raiz: " + appsModel.count
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 12

                ListView {
                    id: categoryList

                    Layout.preferredWidth: 190
                    Layout.minimumWidth: 190
                    Layout.maximumWidth: 190
                    Layout.fillHeight: true
                    clip: true
                    spacing: 4
                    model: appsModel

                    delegate: PlasmaComponents.Button {
                        required property int index
                        required property var model

                        width: categoryList.width
                        text: String(model.display ?? "")
                        onClicked: {
                            root.selectedCategoryIndex = index;
                        }
                    }

                }

                ListView {
                    id: applicationList

                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.maximumWidth: Number.POSITIVE_INFINITY
                    clip: true
                    spacing: 4
                    model: appsModel.count > 0 ? appsModel.modelForRow(root.selectedCategoryIndex) : null

                    delegate: RowLayout {
                        id: applicationDelegate

                        required property var model

                        width: applicationList.width
                        height: 48
                        spacing: 10

                        Kirigami.Icon {
                            source: applicationDelegate.model.decoration
                            implicitWidth: 32
                            implicitHeight: 32
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2

                            PlasmaComponents.Label {
                                text: String(applicationDelegate.model.display ?? "")
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                            }

                            PlasmaComponents.Label {
                                text: String(applicationDelegate.model.description ?? "")
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                                opacity: 0.65
                                font.pointSize: 9
                                visible: text.length > 0
                            }

                        }

                    }

                }

            }

        }

    }

}
