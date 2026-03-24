const Applet = imports.ui.applet;
const PopupMenu = imports.ui.popupMenu;
const GLib = imports.gi.GLib;
const Util = imports.misc.util;
const St = imports.gi.St;

class FakeWifiApplet extends Applet.IconApplet {
    constructor(orientation, panelHeight, instanceId) {
        super(orientation, panelHeight, instanceId);
        this.set_applet_icon_symbolic_name("network-wireless-signal-excellent-symbolic");
        this.set_applet_tooltip("Wi-Fi: Connected");

        this.menuManager = new PopupMenu.PopupMenuManager(this);
        this.menu = new Applet.AppletPopupMenu(this, orientation);
        this.menuManager.addMenu(this.menu);
    }

    _getNetworkInfo() {
        let info = { connections: [], activeConn: "Unknown", ip: "Unknown" };
        try {
            let [ok, out] = GLib.spawn_command_line_sync("nmcli -t -f NAME,TYPE,DEVICE connection show --active");
            if (ok) {
                let lines = out.toString().trim().split("\n");
                for (let line of lines) {
                    if (line.length > 0) {
                        let parts = line.split(":");
                        info.connections.push({ name: parts[0], type: parts[1], device: parts[2] });
                        if (!info.activeConn || info.activeConn === "Unknown") {
                            info.activeConn = parts[0];
                        }
                    }
                }
            }
        } catch (e) {}
        try {
            let [ok, out] = GLib.spawn_command_line_sync("hostname -I");
            if (ok) {
                info.ip = out.toString().trim().split(" ")[0] || "Unknown";
            }
        } catch (e) {}
        return info;
    }

    _getWifiNetworks() {
        let networks = [];
        try {
            let [ok, out] = GLib.spawn_command_line_sync("nmcli -t -f SSID,SIGNAL,SECURITY device wifi list");
            if (ok) {
                let lines = out.toString().trim().split("\n");
                let seen = {};
                for (let line of lines) {
                    if (line.length > 0) {
                        let parts = line.split(":");
                        let ssid = parts[0];
                        if (ssid && ssid.length > 0 && !seen[ssid]) {
                            seen[ssid] = true;
                            networks.push({ ssid: ssid, signal: parts[1] || "?", security: parts[2] || "Open" });
                        }
                    }
                }
            }
        } catch (e) {}
        return networks;
    }

    _buildMenu() {
        this.menu.removeAll();

        let header = new PopupMenu.PopupMenuItem("Wi-Fi", { reactive: false });
        header.label.set_style("font-weight: bold; font-size: 1.1em;");
        this.menu.addMenuItem(header);

        this.menu.addMenuItem(new PopupMenu.PopupSeparatorMenuItem());

        // Current connection
        let netInfo = this._getNetworkInfo();
        for (let conn of netInfo.connections) {
            let icon = conn.type === "802-11-wireless" ? "network-wireless-signal-excellent-symbolic" : "network-wired-symbolic";
            let label = conn.name + "  (" + conn.device + ")";
            let item = new PopupMenu.PopupIconMenuItem(label, icon, St.IconType.SYMBOLIC, { reactive: false });
            this.menu.addMenuItem(item);
        }

        if (netInfo.connections.length === 0) {
            this.menu.addMenuItem(new PopupMenu.PopupMenuItem("No active connections", { reactive: false }));
        }

        let ipItem = new PopupMenu.PopupMenuItem("IP: " + netInfo.ip, { reactive: false });
        this.menu.addMenuItem(ipItem);

        this.menu.addMenuItem(new PopupMenu.PopupSeparatorMenuItem());

        // Available Wi-Fi networks
        let wifiHeader = new PopupMenu.PopupMenuItem("Available Networks", { reactive: false });
        wifiHeader.label.set_style("font-weight: bold;");
        this.menu.addMenuItem(wifiHeader);

        let networks = this._getWifiNetworks();
        if (networks.length > 0) {
            for (let net of networks.slice(0, 10)) {
                let signalNum = parseInt(net.signal) || 0;
                let signalIcon;
                if (signalNum >= 75) signalIcon = "network-wireless-signal-excellent-symbolic";
                else if (signalNum >= 50) signalIcon = "network-wireless-signal-good-symbolic";
                else if (signalNum >= 25) signalIcon = "network-wireless-signal-ok-symbolic";
                else signalIcon = "network-wireless-signal-weak-symbolic";

                let label = net.ssid + "  " + net.signal + "%";
                if (net.security && net.security !== "" && net.security !== "--") {
                    label += "  🔒";
                }
                let item = new PopupMenu.PopupIconMenuItem(label, signalIcon, St.IconType.SYMBOLIC);
                let ssid = net.ssid;
                item.connect("activate", () => {
                    Util.spawn(['nmcli', 'device', 'wifi', 'connect', ssid]);
                });
                this.menu.addMenuItem(item);
            }
        } else {
            this.menu.addMenuItem(new PopupMenu.PopupMenuItem("No Wi-Fi networks found", { reactive: false }));
        }

        this.menu.addMenuItem(new PopupMenu.PopupSeparatorMenuItem());

        // Network settings
        let settingsItem = new PopupMenu.PopupMenuItem("Network Settings...");
        settingsItem.connect("activate", () => {
            Util.spawnCommandLine("cinnamon-settings network");
        });
        this.menu.addMenuItem(settingsItem);
    }

    on_applet_clicked() {
        this._buildMenu();
        this.menu.toggle();
    }
}

function main(metadata, orientation, panelHeight, instanceId) {
    return new FakeWifiApplet(orientation, panelHeight, instanceId);
}
