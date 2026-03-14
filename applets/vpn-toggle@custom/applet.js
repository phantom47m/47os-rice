const Applet = imports.ui.applet;
const PopupMenu = imports.ui.popupMenu;
const GLib = imports.gi.GLib;
const Util = imports.misc.util;
const St = imports.gi.St;
const Mainloop = imports.mainloop;

const COUNTRIES = [
    { name: "Fastest Server", code: "-f" },
    { name: "United States", code: "--cc US" },
    { name: "Netherlands", code: "--cc NL" },
    { name: "Japan", code: "--cc JP" },
];

class VPNToggleApplet extends Applet.IconApplet {
    constructor(orientation, panelHeight, instanceId) {
        super(orientation, panelHeight, instanceId);
        this.set_applet_icon_symbolic_name("network-vpn-symbolic");
        this.set_applet_tooltip("VPN: Disconnected");

        this.menuManager = new PopupMenu.PopupMenuManager(this);
        this.menu = new Applet.AppletPopupMenu(this, orientation);
        this.menuManager.addMenu(this.menu);

        this._connected = false;
        this._checkStatus();
        this._timeout = Mainloop.timeout_add_seconds(5, () => {
            this._checkStatus();
            return true;
        });
    }

    _checkStatus() {
        try {
            let [ok, out] = GLib.spawn_command_line_sync("protonvpn status");
            let output = out.toString();
            if (output.indexOf("Connected") >= 0 || output.indexOf("Server:") >= 0) {
                this._connected = true;
                this.set_applet_icon_symbolic_name("network-vpn-acquiring-symbolic");
                this.set_applet_tooltip("VPN: Connected");
            } else {
                this._connected = false;
                this.set_applet_icon_symbolic_name("network-vpn-symbolic");
                this.set_applet_tooltip("VPN: Disconnected");
            }
        } catch (e) {
            this._connected = false;
        }
    }

    _buildMenu() {
        this.menu.removeAll();

        let header = new PopupMenu.PopupMenuItem("ProtonVPN", { reactive: false });
        header.label.set_style("font-weight: bold; font-size: 1.1em;");
        this.menu.addMenuItem(header);

        this.menu.addMenuItem(new PopupMenu.PopupSeparatorMenuItem());

        if (this._connected) {
            let statusItem = new PopupMenu.PopupIconMenuItem("Connected", "emblem-ok-symbolic", St.IconType.SYMBOLIC, { reactive: false });
            this.menu.addMenuItem(statusItem);

            this.menu.addMenuItem(new PopupMenu.PopupSeparatorMenuItem());

            let disconnectItem = new PopupMenu.PopupIconMenuItem("Disconnect", "process-stop-symbolic", St.IconType.SYMBOLIC);
            disconnectItem.connect("activate", () => {
                Util.spawnCommandLine("bash -c 'protonvpn disconnect 2>/dev/null || protonvpn d'");
                this._connected = false;
                this.set_applet_icon_symbolic_name("network-vpn-symbolic");
            });
            this.menu.addMenuItem(disconnectItem);
        } else {
            let statusItem = new PopupMenu.PopupIconMenuItem("Disconnected", "dialog-warning-symbolic", St.IconType.SYMBOLIC, { reactive: false });
            this.menu.addMenuItem(statusItem);

            this.menu.addMenuItem(new PopupMenu.PopupSeparatorMenuItem());

            let connectHeader = new PopupMenu.PopupMenuItem("Connect to:", { reactive: false });
            connectHeader.label.set_style("font-weight: bold;");
            this.menu.addMenuItem(connectHeader);

            for (let country of COUNTRIES) {
                let item = new PopupMenu.PopupIconMenuItem(country.name, "network-vpn-acquiring-symbolic", St.IconType.SYMBOLIC);
                let code = country.code;
                item.connect("activate", () => {
                    Util.spawnCommandLine("bash -c 'protonvpn connect " + code + " 2>/dev/null || protonvpn c " + code + "'");
                    this._connected = true;
                    this.set_applet_icon_symbolic_name("network-vpn-acquiring-symbolic");
                });
                this.menu.addMenuItem(item);
            }
        }

        this.menu.addMenuItem(new PopupMenu.PopupSeparatorMenuItem());

        let loginItem = new PopupMenu.PopupMenuItem("ProtonVPN Login...");
        loginItem.connect("activate", () => {
            Util.spawnCommandLine("bash -c 'gnome-terminal -- protonvpn init'");
        });
        this.menu.addMenuItem(loginItem);
    }

    on_applet_clicked() {
        this._checkStatus();
        this._buildMenu();
        this.menu.toggle();
    }

    on_applet_removed_from_panel() {
        if (this._timeout) Mainloop.source_remove(this._timeout);
    }
}

function main(metadata, orientation, panelHeight, instanceId) {
    return new VPNToggleApplet(orientation, panelHeight, instanceId);
}
