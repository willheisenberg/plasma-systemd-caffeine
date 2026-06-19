import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.kirigami as Kirigami
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasma5support as Plasma5Support

PlasmoidItem {
    id: root

    // Set representation to compact to prevent default popup behavior
    preferredRepresentation: compactRepresentation

    // Custom state variable tracking caffeine status ("active", "paused", "inactive")
    property string caffeineState: "inactive"

    // Timer state variables
    property int timerSecondsRemaining: 0
    property bool isTimerActive: false

    // Track previous state for notifications
    property string previousCaffeineState: "inactive"

    // State change handler: cancel countdown if turned off externally + notifications
    onCaffeineStateChanged: {
        if (caffeineState === "inactive") {
            cancelTimer();
        }

        // Send desktop notification on state transitions
        if (previousCaffeineState !== caffeineState) {
            if (caffeineState === "active" && previousCaffeineState === "inactive") {
                executable.exec("notify-send -i preferences-desktop-screensaver -a Caffeine 'Caffeine' '" + i18n("Sleep inhibit activated") + "'")
            } else if (caffeineState === "inactive" && previousCaffeineState !== "inactive") {
                executable.exec("notify-send -i preferences-desktop-screensaver -a Caffeine 'Caffeine' '" + i18n("Sleep inhibit deactivated") + "'")
            }
            previousCaffeineState = caffeineState;
        }
    }

    // Write the auto-inhibit app list from QML config to the config file
    function syncAppsConfig() {
        var apps = (plasmoid.configuration.autoInhibitApps || "").trim();
        if (apps.length === 0) {
            executable.exec("rm -f $HOME/.config/caffeine-apps.list");
        } else {
            // Write each app on its own line — safe against injection
            var parts = apps.split(/\s+/);
            var escaped = parts.map(function(a) { return a.replace(/[^a-zA-Z0-9._-]/g, ""); }).filter(function(a) { return a.length > 0; });
            if (escaped.length > 0) {
                executable.exec("printf '%s\\n' " + escaped.join(" ") + " > $HOME/.config/caffeine-apps.list");
            }
        }
    }

    // Start a custom duration inhibit
    function startTimer(minutes) {
        timerSecondsRemaining = minutes * 60;
        isTimerActive = true;

        if (root.caffeineState !== "active") {
            executable.exec("$HOME/.local/bin/caffeine-toggle.sh")
            updateTimer.start()
        }

        countdownTimer.start();
    }

    // Cancel the running timer
    function cancelTimer() {
        isTimerActive = false;
        timerSecondsRemaining = 0;
        countdownTimer.stop();
    }

    // Right-Click Context Menu Actions (KDE Plasma standard)
    Plasmoid.contextualActions: [
        PlasmaCore.Action {
            text: i18n("Deactivate")
            icon.name: "dialog-close"
            visible: root.caffeineState !== "inactive"
            onTriggered: {
                root.cancelTimer();
                executable.exec("$HOME/.local/bin/caffeine-toggle.sh")
                updateTimer.start()
            }
        },
        PlasmaCore.Action {
            text: i18n("Activate (Unlimited)")
            icon.name: "media-playback-start"
            visible: root.caffeineState === "inactive"
            onTriggered: {
                root.cancelTimer();
                executable.exec("$HOME/.local/bin/caffeine-toggle.sh")
                updateTimer.start()
            }
        },
        PlasmaCore.Action {
            text: i18n("Activate for 5 min")
            icon.name: "preferences-system-time"
            visible: root.caffeineState === "inactive"
            onTriggered: root.startTimer(5)
        },
        PlasmaCore.Action {
            text: i18n("Activate for 15 min")
            icon.name: "preferences-system-time"
            visible: root.caffeineState === "inactive"
            onTriggered: root.startTimer(15)
        },
        PlasmaCore.Action {
            text: i18n("Activate for 30 min")
            icon.name: "preferences-system-time"
            visible: root.caffeineState === "inactive"
            onTriggered: root.startTimer(30)
        },
        PlasmaCore.Action {
            text: i18n("Activate for 1 hour")
            icon.name: "preferences-system-time"
            visible: root.caffeineState === "inactive"
            onTriggered: root.startTimer(60)
        },
        PlasmaCore.Action {
            text: i18n("Activate for 2 hours")
            icon.name: "preferences-system-time"
            visible: root.caffeineState === "inactive"
            onTriggered: root.startTimer(120)
        }
    ]

    // Configure theme-integrated tooltip
    toolTipMainText: "Caffeine"
    toolTipSubText: {
        if (caffeineState === "active") {
            if (isTimerActive) {
                var mins = Math.floor(timerSecondsRemaining / 60);
                var secs = timerSecondsRemaining % 60;
                var secsStr = secs < 10 ? "0" + secs : secs;
                return i18n("Inhibit active (%1 remaining)", mins + ":" + secsStr)
            }
            return i18n("System sleep inhibited (Caffeine ON)")
        } else if (caffeineState === "paused") {
            return i18n("Caffeine paused (screen locked)")
        } else {
            return i18n("System sleep enabled (Caffeine OFF)")
        }
    }

    // Panel representation
    compactRepresentation: Item {
        id: compactRoot

        implicitWidth: Kirigami.Units.iconSizes.smallMedium
        implicitHeight: Kirigami.Units.iconSizes.smallMedium

        Layout.minimumWidth: implicitWidth
        Layout.preferredWidth: implicitWidth
        Layout.minimumHeight: implicitHeight
        Layout.preferredHeight: implicitHeight
        Layout.fillHeight: true

        Kirigami.Icon {
            id: compactIcon
            anchors.centerIn: parent
            width: plasmoid.configuration.useCustomIcons
                ? Math.round(Kirigami.Units.iconSizes.smallMedium * 0.8)
                : Kirigami.Units.iconSizes.smallMedium
            height: width

            source: {
                var isActive = (root.caffeineState === "active" || root.caffeineState === "paused");
                if (plasmoid.configuration.useCustomIcons) {
                    return isActive ? "bundledcaffeinecupfull" : "bundledcaffeinecupempty";
                } else {
                    return isActive ? "caffeine-cup-full" : "caffeine-cup-empty";
                }
            }

            // Treat SVG as symbolic mask matching panel icon colors
            isMask: true
            color: Kirigami.Theme.textColor

            // Dim slightly when paused (optional visual indicator)
            opacity: root.caffeineState === "paused" ? 0.5 : 1.0
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                if (root.caffeineState !== "inactive") {
                    root.cancelTimer();
                }
                executable.exec("$HOME/.local/bin/caffeine-toggle.sh")
                updateTimer.start()
            }
        }
    }

    fullRepresentation: Item {}

    // Plasma 5 Support Executable data engine to run status and toggle commands
    Plasma5Support.DataSource {
        id: executable
        engine: "executable"
        connectedSources: []

        onNewData: function(sourceName, data) {
            if (sourceName.indexOf("caffeine-status.sh") !== -1) {
                var out = (data["stdout"] || "").trim();
                if (out === "active" || out === "paused" || out === "inactive") {
                    root.caffeineState = out;
                }
            }
            disconnectSource(sourceName);
        }

        function exec(cmd) {
            connectSource(cmd);
        }
    }

    // Countdown Timer tick handler
    Timer {
        id: countdownTimer
        interval: 1000
        repeat: true
        running: false
        onTriggered: {
            if (root.timerSecondsRemaining > 0) {
                root.timerSecondsRemaining -= 1;
            } else {
                root.cancelTimer();
                if (root.caffeineState !== "inactive") {
                    executable.exec("$HOME/.local/bin/caffeine-toggle.sh")
                    updateTimer.start()
                }
            }
        }
    }

    // Timer to periodically poll the state (every 5 seconds)
    Timer {
        id: statusTimer
        interval: 5000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            executable.exec("$HOME/.local/bin/caffeine-status.sh")
        }
    }

    // Short timer to fetch state immediately after clicking the toggle
    Timer {
        id: updateTimer
        interval: 150
        repeat: false
        onTriggered: {
            executable.exec("$HOME/.local/bin/caffeine-status.sh")
        }
    }

    // Listen to configuration changes and sync the app list file
    Connections {
        target: plasmoid.configuration
        function onAutoInhibitAppsChanged() {
            root.syncAppsConfig();
            executable.exec("$HOME/.local/bin/caffeine-status.sh")
        }
    }

    // Sync app config on startup
    Component.onCompleted: {
        syncAppsConfig();
    }
}
