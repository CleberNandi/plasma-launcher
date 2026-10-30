pragma ComponentBehavior: Bound

import QtQuick
import QtQml
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.plasmoid
import org.kde.plasma.private.kicker as Kicker
import org.kde.kitemmodels as KItemModels

PlasmoidItem {
    id: root

    signal selectionInvalidated()

    function nextGridIndex(row, count, columns, direction) {
        if (count <= 0)
            return -1;
        if (!Number.isInteger(row) || row < 0 || row >= count)
            return 0;
        const stride = Math.max(1, columns);
        if (direction === "left")
            return Math.max(0, row - 1);
        if (direction === "right")
            return Math.min(count - 1, row + 1);
        if (direction === "up")
            return Math.max(0, row - stride);
        if (direction === "down")
            return Math.min(count - 1, row + stride);
        return row;
    }

    property string searchText: ""
    readonly property string searchQuery: root.searchText.trim()
    readonly property bool searching: root.searchQuery.length > 0
    readonly property var allApplicationsModel: root.catalogReady
        && root.catalogRevision >= 0 && appsModel.count > 0
        ? appsModel.modelForRow(0) : null

    onSearchQueryChanged: {
        root.selectionInvalidated();
        if (searchProxy)
            searchProxy.invalidateFilter();
        root.launchStatus = "Nenhuma execução solicitada";
    }

    function matchesSearch(name, description) {
        const terms = root.searchQuery.toLowerCase().split(/\s+/).filter(term => term.length > 0);
        const haystack = (String(name ?? "") + " " + String(description ?? "")).toLowerCase();
        return terms.every(term => haystack.includes(term));
    }

    property bool catalogReady: true
    property int catalogRevision: 0
    property int catalogResetCount: 0
    property string catalogStatus: "Catálogo nativo de aplicativos"

    function finishCatalogRefresh() {
        // Índices são posições: após reconstrução, voltar ao primeiro grupo.
        root.subcategoryPath = [];
        root.selectedCategoryIndex = 0;
        root.selectedCategoryName = appsModel.labelForRow(0) || "Aplicativos";
        root.catalogReady = true;
    }

    Connections {
        target: appsModel

        function onModelAboutToBeReset() {
            root.selectionInvalidated();
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
        root.selectionInvalidated();
        root.subcategoryPath = root.subcategoryPath.concat([{row: row, label: label}]);
        root.launchStatus = "Nenhuma execução solicitada";
    }

    function leaveSubcategory() {
        root.selectionInvalidated();
        root.subcategoryPath = root.subcategoryPath.slice(0, -1);
        root.launchStatus = "Nenhuma execução solicitada";
    }

    property int selectedCategoryIndex: 0
    property string selectedCategoryName: "Aplicativos"
    property string launchStatus: "Nenhuma execução solicitada"
    function isLaunchableEntry(entry) {
        if (!entry || Boolean(entry.isParent) || Boolean(entry.hasChildren)
            || Boolean(entry.isSeparator) || Boolean(entry.disabled))
            return false;
        // Aceitar apenas IDs de aplicações do catálogo, sem ações/fragmentos.
        return /^applications:[^?#]+\.desktop$/.test(String(entry.favoriteId ?? ""));
    }

    function selectCategory(row, label) {
        if (!root.catalogReady || row < 0 || row >= appsModel.count)
            return;
        root.selectionInvalidated();
        root.searchText = "";
        root.subcategoryPath = [];
        root.selectedCategoryIndex = row;
        root.selectedCategoryName = label;
        root.launchStatus = "Nenhuma execução solicitada";
    }


    function activateEntry(view, row, entry) {
        let currentModel = view ? view.model : null;
        if (!root.catalogReady || !currentModel || !entry
            || Boolean(entry.disabled) || Boolean(entry.isSeparator)
            || !Number.isInteger(row) || row < 0 || row >= currentModel.count)
            return;

        if (currentModel === searchProxy) {
            const sourceIndex = searchProxy.mapToSource(searchProxy.index(row, 0));
            currentModel = searchProxy.sourceModel;
            row = sourceIndex.row;
            if (!currentModel || !Number.isInteger(row)
                || row < 0 || row >= currentModel.count)
                return;
        }

        if (Boolean(entry.hasChildren)) {
            root.enterSubcategory(currentModel, row, String(entry.display ?? ""));
            return;
        }

        if (!root.isLaunchableEntry(entry) || typeof currentModel.trigger !== "function")
            return;

        // Capturar apresentação antes da chamada; o delegate pode ser destruído.
        const applicationName = String(entry.display ?? "aplicativo");
        try {
            const result = currentModel.trigger(row, "", null);
            root.launchStatus = result
                ? "Solicitação de abertura de " + applicationName + " enviada ao KDE."
                : "O KDE não aceitou a solicitação de abertura de " + applicationName + ".";
        } catch (error) {
            root.launchStatus = "Falha ao solicitar abertura pelo Kicker: " + String(error);
        }
    }

    Plasmoid.icon: "start-here-kde"
    toolTipMainText: "Plasma Launcher Lab"

    Kicker.RootModel {
        id: appsModel
        autoPopulate: true
        // Preservar categorias principais, reunindo os aplicativos dos subgrupos.
        flat: true
        showAllApps: true
        showAllAppsCategorized: false
        showFavoritesPlaceholder: false
        showRootSeparator: false
        showRecentApps: false
        showRecentDocs: false
        showPowerSession: false
    }


    KItemModels.KSortFilterProxyModel {
        id: searchProxy
        sourceModel: root.allApplicationsModel
        sortRoleName: ""
        // Resolver dinamicamente o ID do role description; o callback substitui
        // o filtro padrão e combina esse role com Qt.DisplayRole.
        filterRoleName: "description"
        filterRowCallback: function(sourceRow, sourceParent) {
            const source = searchProxy.sourceModel;
            if (!source)
                return false;
            const sourceIndex = source.index(sourceRow, 0, sourceParent);
            return root.matchesSearch(source.data(sourceIndex, Qt.DisplayRole),
                source.data(sourceIndex, searchProxy.filterRole));
        }
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

                QQC2.TextField {
                    id: searchField
                    Layout.fillWidth: true
                    Layout.preferredWidth: 280
                    Layout.minimumWidth: 160
                    placeholderText: "Pesquisar aplicativos…"
                    text: root.searchText
                    onTextEdited: root.searchText = text
                    Component.onCompleted: searchField.forceActiveFocus()
                    Keys.onDownPressed: event => {
                        applicationGrid.focusForKeyboard(true);
                        event.accepted = true;
                    }
                    Keys.onReturnPressed: event => {
                        if (!event.isAutoRepeat && applicationGrid.focusForKeyboard(true))
                            applicationGrid.requestActivation();
                        event.accepted = true;
                    }
                    Keys.onEnterPressed: event => {
                        if (!event.isAutoRepeat && applicationGrid.focusForKeyboard(true))
                            applicationGrid.requestActivation();
                        event.accepted = true;
                    }
                    Keys.onEscapePressed: event => {
                        root.searchText = "";
                        event.accepted = true;
                    }
                }

                PlasmaComponents.ToolButton {
                    text: "Limpar"
                    visible: root.searchText.length > 0
                    onClicked: {
                        root.searchText = "";
                        searchField.forceActiveFocus();
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
                    spacing: 2
                    model: appsModel
                    enabled: root.catalogReady
                    boundsBehavior: Flickable.StopAtBounds
                    activeFocusOnTab: true
                    keyNavigationEnabled: false
                    currentIndex: root.selectedCategoryIndex

                    function moveCategory(delta) {
                        if (!root.catalogReady || categoryList.count <= 0)
                            return;
                        const row = Math.max(0, Math.min(categoryList.count - 1,
                            root.selectedCategoryIndex + delta));
                        root.selectCategory(row, appsModel.labelForRow(row));
                        categoryList.positionViewAtIndex(row, ListView.Contain);
                    }

                    Keys.onUpPressed: event => {
                        categoryList.moveCategory(-1);
                        event.accepted = true;
                    }
                    Keys.onDownPressed: event => {
                        categoryList.moveCategory(1);
                        event.accepted = true;
                    }
                    Keys.onRightPressed: event => {
                        applicationGrid.focusForKeyboard(true);
                        event.accepted = true;
                    }
                    Keys.onReturnPressed: event => {
                        applicationGrid.focusForKeyboard(true);
                        event.accepted = true;
                    }
                    Keys.onEnterPressed: event => {
                        applicationGrid.focusForKeyboard(true);
                        event.accepted = true;
                    }
                    Keys.onEscapePressed: event => {
                        root.searchText = "";
                        searchField.forceActiveFocus();
                        event.accepted = true;
                    }

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
                        highlighted: !root.searching && root.selectedCategoryIndex === index
                        focusPolicy: Qt.NoFocus
                        onClicked: {
                            categoryList.forceActiveFocus();
                            root.selectCategory(index, String(model.display ?? ""));
                        }

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
                            visible: !root.searching && root.subcategoryPath.length > 0
                            flat: true
                            enabled: root.catalogReady && root.subcategoryPath.length > 0
                            onClicked: root.leaveSubcategory()
                        }

                        PlasmaComponents.Label {
                            text: root.searching ? "Resultados (" + searchProxy.count + ")"
                                : root.selectedCategoryName
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
                        cellHeight: 104
                        model: root.searching ? searchProxy
                            : root.catalogRevision >= 0 ? root.selectedApplicationModel() : null
                        signal activationRequested(int row)
                        currentIndex: -1
                        activeFocusOnTab: true
                        keyNavigationEnabled: false

                        function clearSelection() {
                            applicationGrid.currentIndex = -1;
                        }

                        function focusForKeyboard(first) {
                            if (!root.catalogReady || applicationGrid.count <= 0)
                                return false;
                            if (first || applicationGrid.currentIndex < 0
                                || applicationGrid.currentIndex >= applicationGrid.count)
                                applicationGrid.currentIndex = 0;
                            applicationGrid.positionViewAtIndex(applicationGrid.currentIndex, GridView.Contain);
                            applicationGrid.forceLayout();
                            applicationGrid.forceActiveFocus();
                            return true;
                        }

                        function moveSelection(direction) {
                            if (!root.catalogReady || applicationGrid.count <= 0)
                                return;
                            applicationGrid.currentIndex = root.nextGridIndex(applicationGrid.currentIndex,
                                applicationGrid.count, applicationGrid.columnCount, direction);
                            applicationGrid.positionViewAtIndex(applicationGrid.currentIndex, GridView.Contain);
                        }

                        function requestActivation() {
                            if (!root.catalogReady || !applicationGrid.activeFocus
                                || applicationGrid.currentIndex < 0
                                || applicationGrid.currentIndex >= applicationGrid.count)
                                return;
                            applicationGrid.forceLayout();
                            applicationGrid.activationRequested(applicationGrid.currentIndex);
                        }

                        // Reposicionamento/seleção pertencem à view que continua viva.
                        onModelChanged: {
                            applicationGrid.clearSelection();
                            applicationGrid.positionViewAtBeginning();
                        }
                        onCountChanged: applicationGrid.clearSelection()

                        Connections {
                            target: root
                            function onSelectionInvalidated() { applicationGrid.clearSelection(); }
                        }

                        Connections {
                            target: applicationGrid.model
                            function onModelAboutToBeReset() { applicationGrid.clearSelection(); }
                            function onModelReset() { applicationGrid.clearSelection(); }
                            function onRowsInserted() { applicationGrid.clearSelection(); }
                            function onRowsRemoved() { applicationGrid.clearSelection(); }
                            function onRowsMoved() { applicationGrid.clearSelection(); }
                            function onLayoutChanged() { applicationGrid.clearSelection(); }
                        }

                        Keys.onLeftPressed: event => {
                            if (applicationGrid.currentIndex >= 0
                                && applicationGrid.currentIndex % applicationGrid.columnCount === 0)
                                categoryList.forceActiveFocus();
                            else
                                applicationGrid.moveSelection("left");
                            event.accepted = true;
                        }
                        Keys.onRightPressed: event => {
                            applicationGrid.moveSelection("right");
                            event.accepted = true;
                        }
                        Keys.onUpPressed: event => {
                            if (applicationGrid.currentIndex >= 0
                                && applicationGrid.currentIndex < applicationGrid.columnCount)
                                searchField.forceActiveFocus();
                            else
                                applicationGrid.moveSelection("up");
                            event.accepted = true;
                        }
                        Keys.onDownPressed: event => {
                            applicationGrid.moveSelection("down");
                            event.accepted = true;
                        }
                        Keys.onReturnPressed: event => {
                            if (!event.isAutoRepeat)
                                applicationGrid.requestActivation();
                            event.accepted = true;
                        }
                        Keys.onEnterPressed: event => {
                            if (!event.isAutoRepeat)
                                applicationGrid.requestActivation();
                            event.accepted = true;
                        }
                        Keys.onEscapePressed: event => {
                            root.searchText = "";
                            searchField.forceActiveFocus();
                            event.accepted = true;
                        }

                        QQC2.ScrollBar.vertical: QQC2.ScrollBar {
                            id: applicationScrollBar
                            policy: QQC2.ScrollBar.AsNeeded
                        }

                        delegate: QQC2.ItemDelegate {
                            id: applicationDelegate
                            required property var model
                            required property int index
                            readonly property bool actionable:
                                Boolean(applicationDelegate.model.hasChildren)
                                    || root.isLaunchableEntry(applicationDelegate.model)
                            width: applicationGrid.cellWidth - 8
                            height: applicationGrid.cellHeight - 8
                            padding: 8
                            text: String(model.display ?? "")
                            hoverEnabled: true
                            enabled: root.catalogReady
                            focusPolicy: Qt.NoFocus
                            highlighted: applicationGrid.activeFocus
                                && applicationGrid.currentIndex === applicationDelegate.index
                            Accessible.name: Boolean(applicationDelegate.model.hasChildren)
                                ? "Abrir grupo " + applicationDelegate.text
                                : root.isLaunchableEntry(applicationDelegate.model)
                                    ? "Abrir " + applicationDelegate.text : applicationDelegate.text
                            onClicked: {
                                const view = applicationDelegate.GridView.view;
                                view.currentIndex = applicationDelegate.index;
                                view.forceActiveFocus();
                                root.activateEntry(view, applicationDelegate.index, applicationDelegate.model);
                            }

                            Connections {
                                target: applicationGrid
                                function onActivationRequested(row) {
                                    if (applicationDelegate.index === row)
                                        root.activateEntry(applicationGrid, row, applicationDelegate.model);
                                }
                            }

                            QQC2.ToolTip.visible: applicationDelegate.hovered
                            QQC2.ToolTip.delay: 600
                            QQC2.ToolTip.text: applicationDelegate.text
                                + (String(applicationDelegate.model.description ?? "").length > 0
                                    ? "\n" + String(applicationDelegate.model.description) : "")

                            contentItem: ColumnLayout {
                                spacing: 4

                                Kirigami.Icon {
                                    source: applicationDelegate.model.decoration
                                    implicitWidth: 32
                                    implicitHeight: 32
                                    Layout.alignment: Qt.AlignHCenter
                                }

                                PlasmaComponents.Label {
                                    text: applicationDelegate.text
                                    color: applicationDelegate.highlighted
                                        ? Kirigami.Theme.highlightedTextColor : Kirigami.Theme.textColor
                                    Layout.fillWidth: true
                                    horizontalAlignment: Text.AlignHCenter
                                    wrapMode: Text.Wrap
                                    maximumLineCount: 2
                                    elide: Text.ElideRight
                                }

                                Item { Layout.fillHeight: true }
                            }
                        }
                    }

                    PlasmaComponents.Label {
                        Layout.fillWidth: true
                        visible: root.catalogReady && applicationGrid.count === 0
                        text: root.searching ? "Nenhum aplicativo encontrado."
                            : "Nenhuma entrada disponível nesta categoria."
                        wrapMode: Text.WordWrap
                    }
                }
            }

            PlasmaComponents.Label {
                Layout.fillWidth: true
                text: root.catalogStatus
                visible: root.catalogStatus.startsWith("Falha")
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
