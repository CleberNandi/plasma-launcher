pragma ComponentBehavior: Bound

import QtQuick
import QtQml
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.plasmoid
import org.kde.plasma.private.kicker as Kicker

PlasmoidItem {
    id: root

    property bool catalogReady: true
    property int catalogRevision: 0
    property int catalogResetCount: 0
    property string catalogStatus: "Aguardando atualização do catálogo"

    function finishCatalogRefresh() {
        // Índices são posições: após reconstrução, voltar ao primeiro grupo.
        root.subcategoryPath = [];
        root.selectedCategoryIndex = 0;
        root.catalogReady = true;
    }

    Connections {
        target: appsModel

        function onModelAboutToBeReset() {
            root.catalogReady = false;
            root.subcategoryPath = [];
            root.launchStatus = "Nenhuma execução solicitada";
        }

        function onModelReset() {
            root.catalogResetCount += 1;
            Qt.callLater(root.finishCatalogRefresh);
        }

        function onRefreshed() {
            root.catalogReady = false;
            root.subcategoryPath = [];
            root.catalogRevision += 1;
            root.catalogStatus = "Sinal refreshed recebido; seleção reiniciada";
            root.launchStatus = "Nenhuma execução solicitada";
            Qt.callLater(root.finishCatalogRefresh);
        }
    }

    // Caminho posicional válido somente até a próxima reconstrução.
    property var subcategoryPath: []

    function selectedApplicationModel() {
        if (!root.catalogReady || root.selectedCategoryIndex < 0
            || root.selectedCategoryIndex >= appsModel.count)
            return null;
        let current = appsModel.modelForRow(root.selectedCategoryIndex);
        for (const step of root.subcategoryPath) {
            if (!current || step.row < 0 || step.row >= current.count)
                return null;
            current = current.modelForRow(step.row);
        }
        return current;
    }

    function enterSubcategory(current, row, label) {
        if (!root.catalogReady || !current || row < 0 || row >= current.count)
            return;
        const child = current.modelForRow(row);
        if (!child)
            return;
        root.subcategoryPath = root.subcategoryPath.concat([{row: row, label: label}]);
        root.launchStatus = "Nenhuma execução solicitada";
    }

    function leaveSubcategory() {
        root.subcategoryPath = root.subcategoryPath.slice(0, -1);
        root.launchStatus = "Nenhuma execução solicitada";
    }

    property int selectedCategoryIndex: 0
    property string launchStatus: "Nenhuma execução solicitada"
    readonly property string allowedKateId: "applications:org.kde.kate.desktop"

    function isAllowedKate(entry) {
        return Boolean(entry)
            && !Boolean(entry.isParent)
            && !Boolean(entry.hasChildren)
            && !Boolean(entry.isSeparator)
            && !Boolean(entry.disabled)
            && String(entry.favoriteId ?? "") === root.allowedKateId;
    }

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
                text: "PoC 02G.1 — Identidade do aplicativo"
                font.bold: true
            }

            RowLayout {
                Layout.fillWidth: true

                PlasmaComponents.Button {
                    text: "Atualizar catálogo"
                    enabled: root.catalogReady
                    onClicked: {
                        root.catalogReady = false;
                        root.launchStatus = "Nenhuma execução solicitada";
                        root.catalogStatus = "Atualização manual solicitada";
                        try {
                            appsModel.refresh();
                        } catch (error) {
                            root.catalogStatus = "Falha ao atualizar: " + String(error);
                        }
                        Qt.callLater(root.finishCatalogRefresh);
                    }
                }

                PlasmaComponents.Label {
                    text: "Categorias: " + appsModel.count
                        + " | refreshed: " + root.catalogRevision
                        + " | resets: " + root.catalogResetCount
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                }
            }

            PlasmaComponents.Label {
                text: root.catalogStatus
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
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

                PlasmaComponents.Button {
                    text: "Voltar"
                    enabled: root.catalogReady && root.subcategoryPath.length > 0
                    onClicked: {
                        root.leaveSubcategory();
                    }
                }

                PlasmaComponents.Label {
                    text: root.subcategoryPath.length > 0
                        ? root.subcategoryPath.map(step => step.label).join(" / ")
                        : "Selecione uma categoria; use Entrar para abrir subcategorias"
                    Layout.fillWidth: true
                    elide: Text.ElideRight
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
                    enabled: root.catalogReady
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
                            root.subcategoryPath = [];
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
                    // A revisão também invalida o binding quando a contagem não muda.
                    model: root.catalogRevision >= 0 ? root.selectedApplicationModel() : null
                    // A troca de modelo pode destruir o delegate que iniciou a navegação.
                    // Reposicionar aqui, no objeto que continua vivo, não após o clique.
                    onModelChanged: applicationList.positionViewAtBeginning()
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

                        PlasmaComponents.Label {
                            text: "ID: " + String(applicationDelegate.model.favoriteId ?? "(ausente)")
                            visible: root.isAllowedKate(applicationDelegate.model)
                                || String(applicationDelegate.model.display ?? "") === "Kate"
                            Layout.maximumWidth: 200
                            elide: Text.ElideMiddle
                        }

                        PlasmaComponents.Button {
                            text: "Entrar"
                            visible: Boolean(applicationDelegate.model.hasChildren)
                            enabled: visible && root.catalogReady
                            onClicked: {
                                const currentView = applicationDelegate.ListView.view;
                                root.enterSubcategory(currentView ? currentView.model : null,
                                    applicationDelegate.index,
                                    String(applicationDelegate.model.display ?? ""));
                                // Não acessar IDs/contexto do delegate após trocar o modelo.
                            }
                        }

                        PlasmaComponents.Button {
                            text: "Abrir Kate"
                            visible: root.isAllowedKate(applicationDelegate.model)
                            enabled: visible && root.catalogReady
                            onClicked: {
                                const currentView = applicationDelegate.ListView.view;
                                const currentModel = currentView ? currentView.model : null;
                                // O índice pertence ao submodelo exibido, não ao RootModel.
                                if (!root.catalogReady
                                    || !root.isAllowedKate(applicationDelegate.model)
                                    || !currentModel
                                    || typeof currentModel.trigger !== "function"
                                    || applicationDelegate.index < 0
                                    || applicationDelegate.index >= currentModel.count) {
                                    root.launchStatus = "Abertura bloqueada: identidade ou modelo indisponível";
                                    return;
                                }
                                try {
                                    const result = currentModel.trigger(applicationDelegate.index, "", null);
                                    root.launchStatus = root.allowedKateId
                                        + " | Retorno de Kicker.trigger: " + String(result)
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
