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
    property string catalogStatus: "Catálogo nativo de aplicativos"

    function finishCatalogRefresh() {
        // Índices são posições: após reconstrução, voltar ao primeiro grupo.
        root.subcategoryPath = [];
        root.selectedCategoryIndex = 0;
        root.selectedCategoryName = "Aplicativos";
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
            root.catalogStatus = "Catálogo atualizado; selecione uma categoria";
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
    property string selectedCategoryName: "Aplicativos"
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


    function selectCategory(row, label) {
        if (!root.catalogReady || row < 0 || row >= appsModel.count)
            return;
        root.subcategoryPath = [];
        root.selectedCategoryIndex = row;
        root.selectedCategoryName = label;
        root.launchStatus = "Nenhuma execução solicitada";
    }

    Plasmoid.icon: "start-here-kde"
    toolTipMainText: "Plasma Launcher Lab"

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
        Layout.minimumWidth: 700
        Layout.preferredWidth: 760
        Layout.minimumHeight: 460
        Layout.preferredHeight: 560

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 8

            RowLayout {
                Layout.fillWidth: true

                Kirigami.Icon {
                    source: "user-identity"
                    implicitWidth: 28
                    implicitHeight: 28
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    PlasmaComponents.Label {
                        text: "Plasma Launcher Lab"
                        font.bold: true
                    }

                    PlasmaComponents.Label {
                        text: "Aplicativos"
                        opacity: 0.7
                    }
                }

                PlasmaComponents.Button {
                    text: "Atualizar"
                    flat: true
                    icon.name: "view-refresh"
                    enabled: root.catalogReady
                    onClicked: {
                        root.catalogReady = false;
                        root.subcategoryPath = [];
                        root.launchStatus = "Nenhuma execução solicitada";
                        root.catalogStatus = "Atualização solicitada";
                        try {
                            appsModel.refresh();
                        } catch (error) {
                            root.catalogStatus = "Falha ao atualizar: " + String(error);
                        }
                        Qt.callLater(root.finishCatalogRefresh);
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 12

                ListView {
                    id: categoryList
                    Layout.minimumWidth: 164
                    Layout.preferredWidth: 164
                    Layout.maximumWidth: 164
                    Layout.fillHeight: true
                    clip: true
                    spacing: 2
                    model: appsModel
                    enabled: root.catalogReady
                    boundsBehavior: Flickable.StopAtBounds

                    QQC2.ScrollBar.vertical: QQC2.ScrollBar {
                        id: categoryScrollBar
                        policy: QQC2.ScrollBar.AsNeeded
                    }

                    delegate: QQC2.ItemDelegate {
                        id: categoryDelegate
                        required property int index
                        required property var model
                        width: categoryList.width - categoryScrollBar.width - 4
                        height: 32
                        text: String(model.display ?? "")
                        highlighted: root.selectedCategoryIndex === index
                        onClicked: root.selectCategory(index, String(model.display ?? ""))

                        contentItem: RowLayout {
                            spacing: 8

                            Kirigami.Icon {
                                source: categoryDelegate.model.decoration
                                implicitWidth: 16
                                implicitHeight: 16
                            }

                            PlasmaComponents.Label {
                                text: categoryDelegate.text
                                color: categoryDelegate.highlighted
                                    ? Kirigami.Theme.highlightedTextColor : Kirigami.Theme.textColor
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                            }
                        }
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.minimumWidth: 0
                    spacing: 8

                    RowLayout {
                        Layout.fillWidth: true

                        PlasmaComponents.Button {
                            text: "Voltar"
                            flat: true
                            enabled: root.catalogReady && root.subcategoryPath.length > 0
                            onClicked: root.leaveSubcategory()
                        }

                        PlasmaComponents.Label {
                            text: root.selectedCategoryName
                                + (root.subcategoryPath.length > 0
                                    ? " / " + root.subcategoryPath.map(step => step.label).join(" / ")
                                    : "")
                            Layout.fillWidth: true
                            elide: Text.ElideMiddle
                            font.bold: true
                        }
                    }

                    GridView {
                        id: applicationGrid
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.minimumWidth: 0
                        clip: true
                        boundsBehavior: Flickable.StopAtBounds
                        readonly property int columnCount: Math.max(1,
                            Math.floor((width - applicationScrollBar.width - 8) / 112))
                        cellWidth: Math.max(1, (width - applicationScrollBar.width - 8) / columnCount)
                        cellHeight: 124
                        model: root.catalogRevision >= 0 ? root.selectedApplicationModel() : null
                        // Reposicionamento pertence à view, não ao delegate destruído.
                        onModelChanged: applicationGrid.positionViewAtBeginning()

                        QQC2.ScrollBar.vertical: QQC2.ScrollBar {
                            id: applicationScrollBar
                            policy: QQC2.ScrollBar.AsNeeded
                        }

                        delegate: Item {
                            id: applicationDelegate
                            required property var model
                            required property int index
                            width: applicationGrid.cellWidth
                            height: applicationGrid.cellHeight

                            HoverHandler { id: applicationHover }
                            QQC2.ToolTip.visible: applicationHover.hovered
                            QQC2.ToolTip.delay: 600
                            QQC2.ToolTip.text: String(applicationDelegate.model.display ?? "")
                                + (String(applicationDelegate.model.description ?? "").length > 0
                                    ? "\n" + String(applicationDelegate.model.description) : "")

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 6
                                spacing: 2

                                Kirigami.Icon {
                                    source: applicationDelegate.model.decoration
                                    implicitWidth: 32
                                    implicitHeight: 32
                                    Layout.alignment: Qt.AlignHCenter
                                }

                                PlasmaComponents.Label {
                                    text: String(applicationDelegate.model.display ?? "")
                                    Layout.fillWidth: true
                                    horizontalAlignment: Text.AlignHCenter
                                    wrapMode: Text.Wrap
                                    maximumLineCount: 2
                                    elide: Text.ElideRight
                                }

                                Item { Layout.fillHeight: true }

                                PlasmaComponents.Button {
                                    text: "Entrar"
                                    flat: true
                                    Layout.alignment: Qt.AlignHCenter
                                    visible: Boolean(applicationDelegate.model.hasChildren)
                                    enabled: visible && root.catalogReady
                                    onClicked: {
                                        const currentView = applicationDelegate.GridView.view;
                                        root.enterSubcategory(currentView ? currentView.model : null,
                                            applicationDelegate.index,
                                            String(applicationDelegate.model.display ?? ""));
                                    }
                                }

                                PlasmaComponents.Button {
                                    text: "Abrir Kate"
                                    flat: true
                                    Layout.alignment: Qt.AlignHCenter
                                    visible: root.isAllowedKate(applicationDelegate.model)
                                    enabled: visible && root.catalogReady
                                    onClicked: {
                                        const currentView = applicationDelegate.GridView.view;
                                        const currentModel = currentView ? currentView.model : null;
                                        const row = applicationDelegate.index;
                                        if (!root.catalogReady
                                            || !root.isAllowedKate(applicationDelegate.model)
                                            || !currentModel
                                            || typeof currentModel.trigger !== "function"
                                            || row < 0 || row >= currentModel.count) {
                                            root.launchStatus = "Abertura bloqueada: identidade ou modelo indisponível";
                                            return;
                                        }
                                        try {
                                            const result = currentModel.trigger(row, "", null);
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

                    PlasmaComponents.Label {
                        Layout.fillWidth: true
                        visible: root.catalogReady && applicationGrid.count === 0
                        text: "Nenhuma entrada disponível nesta categoria."
                        wrapMode: Text.WordWrap
                    }
                }
            }

            PlasmaComponents.Label {
                Layout.fillWidth: true
                text: root.catalogStatus.startsWith("Falha")
                    ? root.catalogStatus : "Prévia: abertura disponível apenas para Kate."
                wrapMode: Text.WordWrap
                opacity: 0.7
            }

            PlasmaComponents.Label {
                Layout.fillWidth: true
                text: root.launchStatus
                visible: root.launchStatus !== "Nenhuma execução solicitada"
                wrapMode: Text.WordWrap
            }
        }
    }
}
