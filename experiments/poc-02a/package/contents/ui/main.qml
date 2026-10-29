import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.plasmoid
import org.kde.plasma.private.kicker as Kicker

PlasmoidItem {
    id: root

    property int selectedCategoryIndex: 0
    property string launchStatus: "Nenhuma execução solicitada"

    // Contexto persistido observado; não equivale necessariamente ao Kickoff 66.
    readonly property string favoritesClient: "org.kde.plasma.kickoff.favorites.instance-4"
    property bool favoritesInitialized: false
    property string favoritesStatus: "Leitura ainda não solicitada"

    Kicker.KAStatsFavoritesModel {
        id: favoritesProbe
    }

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
        Layout.preferredWidth: 700
        Layout.preferredHeight: 680

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 12

            PlasmaComponents.Label {
                text: "PoC 02D.1 — Catálogo e leitura de favoritos"
                font.bold: true
            }

            PlasmaComponents.Label {
                text: "Entradas no modelo raiz: " + appsModel.count
            }

            PlasmaComponents.Label {
                text: root.launchStatus
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4

                PlasmaComponents.Label {
                    text: "Contexto de favoritos: " + root.favoritesClient
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                }

                RowLayout {
                    Layout.fillWidth: true

                    PlasmaComponents.Button {
                        text: "Ler contexto instance-4"
                        enabled: !root.favoritesInitialized
                        onClicked: {
                            try {
                                favoritesProbe.initForClient(root.favoritesClient);
                                root.favoritesInitialized = true;
                                root.favoritesStatus = "Inicialização solicitada; compare com seu menu atual";
                            } catch (error) {
                                root.favoritesStatus = "Falha na inicialização: " + String(error);
                            }
                        }
                    }

                    PlasmaComponents.Label {
                        text: root.favoritesInitialized
                            ? "Entradas no modelo: " + favoritesProbe.count
                            : "Modelo não inicializado"
                        Layout.fillWidth: true
                    }
                }

                PlasmaComponents.Label {
                    text: root.favoritesStatus
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                }

                ListView {
                    id: favoritesList
                    Layout.fillWidth: true
                    visible: root.favoritesInitialized
                    Layout.minimumHeight: 84
                    Layout.preferredHeight: 84
                    Layout.maximumHeight: 84
                    orientation: ListView.Horizontal
                    boundsBehavior: Flickable.StopAtBounds
                    clip: true
                    spacing: 4
                    model: root.favoritesInitialized ? favoritesProbe : null

                    QQC2.ScrollBar.horizontal: QQC2.ScrollBar {
                        policy: QQC2.ScrollBar.AsNeeded
                    }

                    delegate: ColumnLayout {
                        id: favoriteDelegate
                        required property var model
                        width: 140
                        height: 68
                        spacing: 8

                        Kirigami.Icon {
                            source: favoriteDelegate.model.decoration
                            Layout.alignment: Qt.AlignHCenter
                            implicitWidth: 32
                            implicitHeight: 32
                        }

                        PlasmaComponents.Label {
                            text: String(favoriteDelegate.model.display ?? "")
                            Layout.fillWidth: true
                            horizontalAlignment: Text.AlignHCenter
                            elide: Text.ElideRight
                        }
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 12

                ListView {
                    id: categoryList

                    Layout.minimumWidth: 190
                    Layout.preferredWidth: 190
                    Layout.maximumWidth: 190
                    Layout.fillHeight: true
                    clip: true
                    spacing: 4
                    model: appsModel
                    boundsBehavior: Flickable.StopAtBounds

                    QQC2.ScrollBar.vertical: QQC2.ScrollBar {
                        id: categoryScrollBar
                        policy: QQC2.ScrollBar.AsNeeded
                    }

                    delegate: PlasmaComponents.Button {
                        required property int index
                        required property var model

                        width: categoryList.width - categoryScrollBar.width - 4
                        text: String(model.display ?? "")
                        onClicked: {
                            root.selectedCategoryIndex = index;
                            root.launchStatus = "Nenhuma execução solicitada";
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
                    boundsBehavior: Flickable.StopAtBounds

                    QQC2.ScrollBar.vertical: QQC2.ScrollBar {
                        id: applicationScrollBar
                        policy: QQC2.ScrollBar.AsNeeded
                    }

                    delegate: RowLayout {
                        id: applicationDelegate

                        required property var model
                        required property int index

                        width: applicationList.width - applicationScrollBar.width - 4
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

                        PlasmaComponents.Button {
                            text: "Abrir Kate"
                            visible: String(applicationDelegate.model.display ?? "") === "Kate"
                            enabled: visible
                            onClicked: {
                                const currentModel = applicationList.model;
                                // O índice pertence ao submodelo exibido, não ao RootModel.
                                if (String(applicationDelegate.model.display ?? "") !== "Kate"
                                    || !currentModel
                                    || typeof currentModel.trigger !== "function"
                                    || applicationDelegate.index < 0
                                    || applicationDelegate.index >= currentModel.count) {
                                    root.launchStatus = "Modelo indisponível";
                                    return;
                                }
                                try {
                                    const result = currentModel.trigger(applicationDelegate.index, "", null);
                                    root.launchStatus = "Retorno de Kicker.trigger: " + String(result)
                                        + "; confirme visualmente se Kate abriu";
                                } catch (error) {
                                    root.launchStatus = "Falha ao solicitar abertura pelo Kicker: " + String(error);
                                }
                            }
                        }

                    }

                }

            }

        }

    }

}
