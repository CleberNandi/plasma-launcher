import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.plasmoid

PlasmoidItem {
    id: root

    property string selectedCategory: "Favoritos"
    readonly property var applications: [{
        "name": "Firefox",
        "category": "Internet",
        "icon": "internet-web-browser"
    }, {
        "name": "Dolphin",
        "category": "Sistema",
        "icon": "system-file-manager"
    }, {
        "name": "Konsole",
        "category": "Sistema",
        "icon": "utilities-terminal"
    }, {
        "name": "Kate",
        "category": "Desenvolvimento",
        "icon": "accessories-text-editor"
    }, {
        "name": "Gwenview",
        "category": "Gráficos",
        "icon": "view-preview"
    }]

    function visibleApplications() {
        if (selectedCategory === "Favoritos")
            return applications.slice(0, 3);

        if (selectedCategory === "Todos")
            return applications;

        return applications.filter((app) => {
            return app.category === selectedCategory;
        });
    }

    Plasmoid.icon: "start-here-kde"
    toolTipMainText: "Plasma Launcher Lab"

    fullRepresentation: Item {
        id: popupView

        Layout.minimumWidth: 700
        Layout.preferredWidth: 700
        Layout.minimumHeight: 460
        Layout.preferredHeight: 460

        ColumnLayout {
            id: mainLayout

            anchors.fill: parent
            anchors.margins: 16
            spacing: 12

            RowLayout {
                Layout.fillWidth: true

                Kirigami.Icon {
                    source: "user-identity"
                    implicitWidth: 36
                    implicitHeight: 36
                }

                PlasmaComponents.Label {
                    text: "Plasma Launcher Lab"
                    font.bold: true
                    Layout.fillWidth: true
                }

            }

            PlasmaComponents.Label {
                text: "Protótipo de interface — dados simulados"
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 16

                ColumnLayout {
                    id: categorySidebar

                    Layout.minimumWidth: 190
                    Layout.preferredWidth: 190
                    Layout.maximumWidth: 190
                    Layout.fillWidth: false
                    Layout.fillHeight: true
                    spacing: 6

                    Repeater {
                        model: ["Favoritos", "Todos", "Desenvolvimento", "Internet", "Gráficos", "Sistema"]

                        delegate: PlasmaComponents.Button {
                            required property string modelData

                            text: modelData
                            Layout.fillWidth: true
                            onClicked: {
                                root.selectedCategory = modelData;
                            }
                        }

                    }

                    Item {
                        Layout.fillHeight: true
                    }

                }

                ColumnLayout {
                    id: applicationArea

                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.minimumWidth: 0
                    Layout.maximumWidth: Number.POSITIVE_INFINITY
                    spacing: 12

                    PlasmaComponents.Label {
                        text: root.selectedCategory
                        font.bold: true
                    }

                    GridLayout {
                        columns: 3
                        columnSpacing: 20
                        rowSpacing: 20

                        Repeater {
                            model: root.visibleApplications()

                            delegate: ColumnLayout {
                                required property var modelData

                                Kirigami.Icon {
                                    source: modelData.icon
                                    implicitWidth: 48
                                    implicitHeight: 48
                                    Layout.alignment: Qt.AlignHCenter
                                }

                                PlasmaComponents.Label {
                                    text: modelData.name
                                    Layout.alignment: Qt.AlignHCenter
                                }

                            }

                        }

                    }

                    Item {
                        Layout.fillHeight: true
                    }

                }

            }

        }

    }

}
