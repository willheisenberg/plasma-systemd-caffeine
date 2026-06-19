import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Kirigami.FormLayout {
    id: page

    property alias cfg_autoInhibitApps: autoInhibitAppsField.text
    property alias cfg_useCustomIcons: useCustomIconsField.checked

    TextField {
        id: autoInhibitAppsField
        Kirigami.FormData.label: i18n("Auto-inhibit apps:")
        placeholderText: i18n("e.g. vlc mpv steam")
        Layout.fillWidth: true
    }

    Label {
        text: i18n("Enter process names separated by spaces.\nCaffeine will activate automatically when any of these programs is running.")
        font.italic: true
        font.pointSize: 9
        color: Kirigami.Theme.disabledTextColor
        Layout.fillWidth: true
    }

    CheckBox {
        id: useCustomIconsField
        Kirigami.FormData.label: i18n("Icon preference:")
        text: i18n("Use bundled Caffeine icons instead of system theme icons")
    }
}
