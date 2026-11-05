pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents
import org.kde.coreaddons as KCoreAddons

RowLayout {
    id: profile
    spacing: 8

    function userDisplayName(fullName, loginName) {
        return String(fullName ?? "").trim()
            || String(loginName ?? "").trim()
            || "Usuário";
    }

    readonly property string displayName:
        profile.userDisplayName(sessionUser.fullName, sessionUser.loginName)

    Accessible.role: Accessible.StaticText
    Accessible.name: "Usuário da sessão: " + profile.displayName

    KCoreAddons.KUser {
        id: sessionUser
    }

    Item {
        implicitWidth: 24
        implicitHeight: 24
        Accessible.ignored: true

        Kirigami.Icon {
            anchors.fill: parent
            source: "user-identity"
            visible: faceImage.status !== Image.Ready
            Accessible.ignored: true
        }

        Image {
            id: faceImage
            anchors.fill: parent
            source: sessionUser.faceIconUrl
            sourceSize.width: 24
            sourceSize.height: 24
            fillMode: Image.PreserveAspectFit
            asynchronous: true
            visible: faceImage.status === Image.Ready
            Accessible.ignored: true
        }
    }

    PlasmaComponents.Label {
        Layout.fillWidth: true
        Layout.minimumWidth: 0
        text: profile.displayName
        textFormat: Text.PlainText
        elide: Text.ElideRight
        Accessible.ignored: true
    }

    HoverHandler {
        id: profileHover
    }

    QQC2.ToolTip.visible: profileHover.hovered
    QQC2.ToolTip.delay: 600
    QQC2.ToolTip.text: profile.displayName
}
