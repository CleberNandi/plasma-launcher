pragma ComponentBehavior: Bound

import QtQuick
import QtQml
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasmoid
import org.kde.plasma.private.kicker as Kicker
import org.kde.kitemmodels as KItemModels

PlasmoidItem {
    id: root

    // O Plasma hospeda o popup; fora do painel, manter a representação completa.
    readonly property bool inPanel: Plasmoid.formFactor === PlasmaCore.Types.Horizontal
        || Plasmoid.formFactor === PlasmaCore.Types.Vertical
    preferredRepresentation: root.inPanel ? root.compactRepresentation : root.fullRepresentation
    activationTogglesExpanded: true
    hideOnWindowDeactivate: true

    function closePanelPopup() {
        if (root.inPanel)
            root.expanded = false;
    }

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


    property bool showingFavorites: false
    readonly property var favoriteIds:
        root.normalizeFavoriteIds(Plasmoid.configuration.favoriteApplicationIds)

    function normalizeFavoriteIds(values) {
        const result = [];
        if (!values || typeof values === "string")
            return result;
        for (let i = 0; i < values.length; ++i) {
            const id = String(values[i] ?? "");
            if (/^applications:[^?#]+\.desktop$/.test(id) && !result.includes(id))
                result.push(id);
        }
        return result;
    }

    function isFavorite(id) {
        return root.favoriteIds.includes(String(id));
    }

    function toggleFavorite(id) {
        id = String(id);
        if (!root.catalogReady || !/^applications:[^?#]+\.desktop$/.test(id))
            return;
        const ids = root.favoriteIds.slice();
        const index = ids.indexOf(id);
        if (index >= 0)
            ids.splice(index, 1);
        else
            ids.push(id);
        root.selectionInvalidated();
        // Uma nova lista mantém a notificação do KConfig e o binding nativo.
        Plasmoid.configuration.favoriteApplicationIds = ids;
    }

    function selectFavorites() {
        if (!root.catalogReady)
            return;
        root.selectionInvalidated();
        root.searchText = "";
        root.subcategoryPath = [];
        root.showingFavorites = true;
        root.launchStatus = "Nenhuma execução solicitada";
    }

    property string searchText: ""
    readonly property string searchQuery: root.searchText.trim()
    readonly property bool searching: root.searchQuery.length > 0
    readonly property var allApplicationsModel: root.catalogReady
        && root.catalogRevision >= 0 && appsModel.count > 0
        ? appsModel.modelForRow(0) : null

    property bool searchResultsReady: false

    // Desvincular a view antes de filtrar: nesta sessão nativa, alterações
    // incrementais deixavam roles de outro aplicativo no card sobrevivente.
    function scheduleSearchRefresh() {
        root.searchResultsReady = false;
        root.selectionInvalidated();
        if (searchProxy)
            Qt.callLater(root.finishSearchRefresh);
    }

    function finishSearchRefresh() {
        if (!root.catalogReady || !root.allApplicationsModel)
            return;
        searchProxy.invalidateFilter();
        root.searchResultsReady = true;
    }

    onSearchQueryChanged: {
        root.scheduleSearchRefresh();
        root.launchStatus = "Nenhuma execução solicitada";
    }

    onAllApplicationsModelChanged: root.scheduleSearchRefresh()

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
        if (root.catalogReady && root.showingFavorites)
            return localFavorites;
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
        root.showingFavorites = false;
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
            if (!root.searchResultsReady || !root.searching)
                return;
            const sourceIndex = searchProxy.mapToSource(searchProxy.index(row, 0));
            // Usar a referência dinâmica ao Kicker: sourceModel é tipado
            // como QAbstractItemModel e não declara a propriedade count.
            currentModel = root.allApplicationsModel;
            // QModelIndex.row integra a API QML documentada pelo Qt, mas
            // seus metadados não são reconhecidos por este qmllint.
            // qmllint disable missing-property
            row = sourceIndex.row;
            // qmllint enable missing-property
            if (!currentModel || !Number.isInteger(row)
                || row < 0 || row >= currentModel.count)
                return;
            // Não abrir silenciosamente um item diferente do nome apresentado.
            if (String(entry.display ?? "") !== currentModel.labelForRow(row)) {
                root.launchStatus = "Resultado desatualizado; refaça a pesquisa.";
                return;
            }
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
            if (result)
                root.closePanelPopup();
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

        // O pai RootModel fornece o contexto de apresentação ao AppEntry.
        // Armazenamento próprio em KConfig; sem contexto KAStats do Kickoff.
        property var launcherFavorites: Kicker.SimpleFavoritesModel {
            id: localFavorites
            favorites: root.catalogReady && root.catalogRevision >= 0 ? root.favoriteIds : []
        }
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

    compactRepresentation: PlasmaComponents.ToolButton {
        id: panelButton
        property bool expandedOnPress: false
        Layout.minimumWidth: Kirigami.Units.iconSizes.smallMedium
        Layout.minimumHeight: Kirigami.Units.iconSizes.smallMedium
        Layout.preferredWidth: Plasmoid.formFactor === PlasmaCore.Types.Horizontal
            ? panelButton.height : Kirigami.Units.iconSizes.medium
        Layout.preferredHeight: Plasmoid.formFactor === PlasmaCore.Types.Vertical
            ? panelButton.width : Kirigami.Units.iconSizes.medium
        icon.name: "start-here-kde"
        text: "Plasma Launcher"
        display: QQC2.AbstractButton.IconOnly
        Accessible.name: "Abrir Plasma Launcher"
        down: panelButton.pressed || root.expanded
        onPressed: panelButton.expandedOnPress = root.expanded
        onClicked: root.expanded = !panelButton.expandedOnPress
    }

    fullRepresentation: Item {
        id: launcherContent
        Keys.onEscapePressed: event => launcherContent.handleEscape(event)

        function prepareOpening() {
            if (!launcherContent.visible || (root.inPanel && !root.expanded))
                return;
            root.searchText = "";
            root.selectionInvalidated();
            root.launchStatus = "Nenhuma execução solicitada";
            searchField.forceActiveFocus();
        }

        function handleEscape(event) {
            event.accepted = true;
            if (event.isAutoRepeat)
                return;
            if (root.searchText.length > 0) {
                root.searchText = "";
                root.selectionInvalidated();
                searchField.forceActiveFocus();
            } else {
                root.closePanelPopup();
                if (!root.inPanel)
                    searchField.forceActiveFocus();
            }
        }

        Component.onCompleted: Qt.callLater(launcherContent.prepareOpening)
        onVisibleChanged: {
            if (visible)
                Qt.callLater(launcherContent.prepareOpening);
        }

        Connections {
            target: root
            function onExpandedChanged() {
                if (root.expanded)
                    Qt.callLater(launcherContent.prepareOpening);
                else {
                    favoriteMenu.close();
                    root.selectionInvalidated();
                }
            }
        }

        QQC2.Menu {
            id: favoriteMenu
            property string applicationId: ""
            property string applicationName: ""
            title: favoriteMenu.applicationName

            QQC2.MenuItem {
                text: root.isFavorite(favoriteMenu.applicationId)
                    ? "Remover dos favoritos" : "Adicionar aos favoritos"
                icon.name: root.isFavorite(favoriteMenu.applicationId)
                    ? "bookmark-remove" : "bookmark-new"
                enabled: root.catalogReady
                    && /^applications:[^?#]+\.desktop$/.test(favoriteMenu.applicationId)
                onTriggered: root.toggleFavorite(favoriteMenu.applicationId)
            }
        }

        Layout.minimumWidth: 660
        Layout.preferredWidth: 760
        Layout.minimumHeight: 460
        Layout.preferredHeight: 520

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 0
            spacing: 0

            RowLayout {
                Layout.fillWidth: true
                Layout.margins: 12
                spacing: 8

                QQC2.TextField {
                    id: searchField
                    Layout.fillWidth: true
                    Layout.preferredWidth: 280
                    Layout.minimumWidth: 160
                    placeholderText: "Pesquisar aplicativos…"
                    leftPadding: 34
                    Accessible.name: "Pesquisar aplicativos"
                    Kirigami.Icon {
                        anchors.left: parent.left
                        anchors.leftMargin: 10
                        anchors.verticalCenter: parent.verticalCenter
                        width: 16
                        height: 16
                        source: "edit-find"
                    }
                    text: root.searchText
                    onTextEdited: root.searchText = text
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
                    Keys.onEscapePressed: event => launcherContent.handleEscape(event)
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

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                color: Kirigami.Theme.textColor
                opacity: 0.12
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 0

                Item {
                    Layout.minimumWidth: 208
                    Layout.preferredWidth: 208
                    Layout.maximumWidth: 208
                    Layout.fillHeight: true

                    Rectangle {
                        anchors.fill: parent
                        color: Kirigami.Theme.textColor
                        opacity: 0.035
                    }

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 8
                        spacing: 4

                        QQC2.ItemDelegate {
                            id: favoritesButton
                            Layout.fillWidth: true
                            implicitHeight: 32
                            text: "Favoritos"
                            icon.name: "bookmarks"
                            highlighted: root.showingFavorites && !root.searching
                            enabled: root.catalogReady
                            onClicked: {
                                favoritesButton.forceActiveFocus();
                                root.selectFavorites();
                            }
                            Keys.onDownPressed: event => {
                                root.selectCategory(0, appsModel.labelForRow(0));
                                categoryList.forceActiveFocus();
                                event.accepted = true;
                            }
                            Keys.onRightPressed: event => {
                                applicationGrid.focusForKeyboard(true);
                                event.accepted = true;
                            }
                            Keys.onEscapePressed: event => launcherContent.handleEscape(event)
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 1
                            color: Kirigami.Theme.textColor
                            opacity: 0.12
                        }

                        ListView {
                            id: categoryList
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            clip: true
                            header: PlasmaComponents.Label {
                                width: categoryList.width
                                height: 24
                                leftPadding: 8
                                text: "Aplicativos"
                                opacity: 0.65
                                verticalAlignment: Text.AlignVCenter
                            }
                            spacing: 0
                            model: appsModel
                            enabled: root.catalogReady
                            boundsBehavior: Flickable.StopAtBounds
                            activeFocusOnTab: true
                            keyNavigationEnabled: false
                            currentIndex: root.selectedCategoryIndex

                            function moveCategory(delta) {
                                if (!root.catalogReady || categoryList.count <= 0)
                                    return;
                                if (delta < 0 && root.selectedCategoryIndex === 0) {
                                    root.selectFavorites();
                                    favoritesButton.forceActiveFocus();
                                    return;
                                }
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
                            Keys.onEscapePressed: event => launcherContent.handleEscape(event)

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
                                highlighted: !root.searching && !root.showingFavorites
                                    && root.selectedCategoryIndex === index
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

                    }
                }

                Rectangle {
                    Layout.preferredWidth: 1
                    Layout.fillHeight: true
                    color: Kirigami.Theme.textColor
                    opacity: 0.12
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.minimumWidth: 0
                    Layout.margins: 16
                    spacing: 10

                    RowLayout {
                        Layout.fillWidth: true

                        PlasmaComponents.Button {
                            text: "Voltar"
                            visible: !root.searching && !root.showingFavorites
                                && root.subcategoryPath.length > 0
                            flat: true
                            enabled: root.catalogReady && root.subcategoryPath.length > 0
                            onClicked: root.leaveSubcategory()
                        }

                        PlasmaComponents.Label {
                            text: root.searching ? (root.searchResultsReady
                                ? "Resultados (" + searchProxy.count + ")" : "Pesquisando…")
                                : root.showingFavorites ? "Favoritos" : root.selectedCategoryName
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
                            Math.floor((width - applicationScrollBar.width - 8) / 104))
                        cellWidth: Math.max(1, (width - applicationScrollBar.width - 8) / columnCount)
                        cellHeight: 92
                        model: root.searching ? (root.searchResultsReady ? searchProxy : null)
                            : root.catalogRevision >= 0 ? root.selectedApplicationModel() : null
                        signal activationRequested(int row)
                        signal favoriteMenuRequested(int row)
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


                        function requestFavoriteMenu() {
                            if (!root.catalogReady || !applicationGrid.activeFocus
                                || applicationGrid.currentIndex < 0
                                || applicationGrid.currentIndex >= applicationGrid.count)
                                return;
                            applicationGrid.forceLayout();
                            applicationGrid.favoriteMenuRequested(applicationGrid.currentIndex);
                        }

                        Shortcut {
                            sequence: "Shift+F10"
                            enabled: applicationGrid.activeFocus
                            onActivated: applicationGrid.requestFavoriteMenu()
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
                                (root.showingFavorites ? favoritesButton : categoryList).forceActiveFocus();
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
                        Keys.onEscapePressed: event => launcherContent.handleEscape(event)

                        QQC2.ScrollBar.vertical: QQC2.ScrollBar {
                            id: applicationScrollBar
                            policy: QQC2.ScrollBar.AsNeeded
                        }

                        delegate: Item {
                            id: applicationDelegate
                            required property int index
                            // Roles explícitos: nome, ícone e ativação observam
                            // os mesmos dados quando o proxy altera suas linhas.
                            required property var display
                            required property var decoration
                            required property var description
                            required property var favoriteId
                            required property var isParent
                            required property var hasChildren
                            required property var isSeparator
                            required property var disabled
                            readonly property var entryData: ({
                                display: applicationDelegate.display,
                                favoriteId: applicationDelegate.favoriteId,
                                isParent: applicationDelegate.isParent,
                                hasChildren: applicationDelegate.hasChildren,
                                isSeparator: applicationDelegate.isSeparator,
                                disabled: applicationDelegate.disabled
                            })

                            function openFavoriteMenu() {
                                if (!root.catalogReady || !root.isLaunchableEntry(applicationDelegate.entryData))
                                    return;
                                favoriteMenu.applicationId = String(applicationDelegate.favoriteId);
                                favoriteMenu.applicationName = String(applicationDelegate.display);
                                const position = applicationDelegate.mapToItem(applicationGrid, 16, 16);
                                // Ancorar à view estável; o delegate pode ser removido.
                                favoriteMenu.popup(applicationGrid, position.x, position.y);
                            }

                            TapHandler {
                                acceptedButtons: Qt.RightButton
                                onTapped: {
                                    applicationGrid.currentIndex = applicationDelegate.index;
                                    applicationGrid.forceActiveFocus();
                                    applicationDelegate.openFavoriteMenu();
                                }
                            }

                            width: applicationGrid.cellWidth - 8
                            height: applicationGrid.cellHeight - 8
                            QQC2.ItemDelegate {
                                id: applicationButton
                                anchors.fill: parent
                                padding: 6
                                text: String(applicationDelegate.display ?? "")
                                hoverEnabled: true
                                enabled: root.catalogReady
                                focusPolicy: Qt.NoFocus
                                highlighted: applicationGrid.activeFocus
                                    && applicationGrid.currentIndex === applicationDelegate.index
                                Accessible.name: Boolean(applicationDelegate.hasChildren)
                                    ? "Abrir grupo " + applicationButton.text
                                    : root.isLaunchableEntry(applicationDelegate.entryData)
                                        ? "Abrir " + applicationButton.text : applicationButton.text
                                onClicked: {
                                    const view = applicationDelegate.GridView.view;
                                    view.currentIndex = applicationDelegate.index;
                                    view.forceActiveFocus();
                                    root.activateEntry(view, applicationDelegate.index, applicationDelegate.entryData);
                                }

                                Connections {
                                    target: applicationGrid
                                    function onFavoriteMenuRequested(row) {
                                        if (applicationDelegate.index === row)
                                            applicationDelegate.openFavoriteMenu();
                                    }
                                    function onActivationRequested(row) {
                                        if (applicationDelegate.index === row)
                                            root.activateEntry(applicationGrid, row, applicationDelegate.entryData);
                                    }
                                }

                                QQC2.ToolTip.visible: applicationButton.hovered
                                QQC2.ToolTip.delay: 600
                                QQC2.ToolTip.text: applicationButton.text
                                    + (String(applicationDelegate.description ?? "").length > 0
                                        ? "\n" + String(applicationDelegate.description) : "")

                                contentItem: ColumnLayout {
                                    spacing: 4

                                    Kirigami.Icon {
                                        source: applicationDelegate.decoration
                                        implicitWidth: 32
                                        implicitHeight: 32
                                        Layout.alignment: Qt.AlignHCenter
                                    }

                                    PlasmaComponents.Label {
                                        text: applicationButton.text
                                        color: applicationButton.highlighted
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
                    }

                    PlasmaComponents.Label {
                        Layout.fillWidth: true
                        visible: root.catalogReady && (!root.searching || root.searchResultsReady)
                            && applicationGrid.count === 0
                        text: root.searching ? "Nenhum aplicativo encontrado."
                            : root.showingFavorites
                                ? "Nenhum favorito. Clique com o botão direito em um aplicativo para adicionar."
                                : "Nenhuma entrada disponível nesta categoria."
                        wrapMode: Text.WordWrap
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                color: Kirigami.Theme.textColor
                opacity: 0.12
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 12
                Layout.rightMargin: 12
                Layout.topMargin: 8
                Layout.bottomMargin: 8
                spacing: 8

                Kirigami.Icon {
                    source: "start-here-kde"
                    implicitWidth: 20
                    implicitHeight: 20
                }

                PlasmaComponents.Label {
                    text: "Plasma Launcher"
                    opacity: 0.7
                }

                PlasmaComponents.Label {
                    Layout.fillWidth: true
                    text: root.catalogStatus.startsWith("Falha")
                        ? root.catalogStatus
                        : root.launchStatus !== "Nenhuma execução solicitada"
                            ? root.launchStatus : ""
                    elide: Text.ElideRight
                    horizontalAlignment: Text.AlignRight
                    opacity: 0.7
                }
            }
        }
    }
}
