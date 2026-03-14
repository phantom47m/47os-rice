const Applet = imports.ui.applet;
const PopupMenu = imports.ui.popupMenu;
const GLib = imports.gi.GLib;
const Util = imports.misc.util;
const St = imports.gi.St;
const Mainloop = imports.mainloop;

class GhostModeApplet extends Applet.IconApplet {
    constructor(orientation, panelHeight, instanceId) {
        super(orientation, panelHeight, instanceId);

        let iconPath = GLib.build_filenamev([GLib.get_home_dir(), ".local/share/cinnamon/applets/ghost-mode@custom/ghost-icon.png"]);
        this.set_applet_icon_path(iconPath);
        this.set_applet_tooltip("Ghost Mode");

        this.menuManager = new PopupMenu.PopupMenuManager(this);
        this.menu = new Applet.AppletPopupMenu(this, orientation);
        this.menuManager.addMenu(this.menu);

        this._ghostActive = false;
        this._vpnConnected = false;
        this._checkStatus();
        this._timeout = Mainloop.timeout_add_seconds(5, () => {
            this._checkStatus();
            return true;
        });
    }

    _checkStatus() {
        this._ghostActive = GLib.file_test("/tmp/.ghost-mode-active", GLib.FileTest.EXISTS);
        try {
            let [ok, out] = GLib.spawn_command_line_sync("warp-cli --accept-tos status");
            this._vpnConnected = out.toString().indexOf("Connected") >= 0;
        } catch (e) { this._vpnConnected = false; }
    }

    _getInfo() {
        let info = {};
        try {
            let [ok, mac] = GLib.spawn_command_line_sync("bash -c \"ip link show $(ip route | grep default | awk '{print $5}' | head -1) | grep ether | awk '{print $2}'\"");
            info.mac = mac.toString().trim();
        } catch(e) { info.mac = "unknown"; }
        try {
            let [ok, dns] = GLib.spawn_command_line_sync("systemctl is-active stubby");
            info.dnsEncrypted = dns.toString().trim() === "active";
        } catch(e) { info.dnsEncrypted = false; }
        try {
            let [ok, ip] = GLib.spawn_command_line_sync("bash -c \"hostname -I | awk '{print $1}'\"");
            info.ip = ip.toString().trim();
        } catch(e) { info.ip = "unknown"; }
        return info;
    }

    _buildMenu() {
        this.menu.removeAll();

        let info = this._getInfo();

        // --- GHOST MODE ---
        let ghostHeader = new PopupMenu.PopupMenuItem("Ghost Mode", { reactive: false });
        ghostHeader.label.set_style("font-weight: bold; font-size: 1.1em;");
        this.menu.addMenuItem(ghostHeader);

        this.menu.addMenuItem(new PopupMenu.PopupSeparatorMenuItem());

        if (this._ghostActive) {
            let s = new PopupMenu.PopupMenuItem("Status: ACTIVE", { reactive: false });
            s.label.set_style("color: #00ff00;");
            this.menu.addMenuItem(s);
            let off = new PopupMenu.PopupIconMenuItem("Disable Ghost Mode", "process-stop-symbolic", St.IconType.SYMBOLIC);
            off.connect("activate", () => {
                Util.spawnCommandLine("bash /home/deansabr/.local/bin/ghost-mode.sh off");
            });
            this.menu.addMenuItem(off);
        } else {
            let s = new PopupMenu.PopupMenuItem("Status: OFF", { reactive: false });
            s.label.set_style("color: #ff4444;");
            this.menu.addMenuItem(s);
            let on = new PopupMenu.PopupIconMenuItem("Enable Ghost Mode", "security-high-symbolic", St.IconType.SYMBOLIC);
            on.connect("activate", () => {
                Util.spawnCommandLine("bash /home/deansabr/.local/bin/ghost-mode.sh on");
            });
            this.menu.addMenuItem(on);
        }

        this.menu.addMenuItem(new PopupMenu.PopupSeparatorMenuItem());

        // --- VPN ---
        let vpnHeader = new PopupMenu.PopupMenuItem("VPN (Cloudflare WARP)", { reactive: false });
        vpnHeader.label.set_style("font-weight: bold; font-size: 1.1em;");
        this.menu.addMenuItem(vpnHeader);

        let vpnLabel = this._vpnConnected ? "VPN: Connected" : "VPN: Disconnected";
        let vpnStatus = new PopupMenu.PopupMenuItem(vpnLabel, { reactive: false });
        vpnStatus.label.set_style(this._vpnConnected ? "color: #00ff00;" : "color: #ff4444;");
        this.menu.addMenuItem(vpnStatus);

        if (this._vpnConnected) {
            let dc = new PopupMenu.PopupIconMenuItem("Disconnect VPN", "process-stop-symbolic", St.IconType.SYMBOLIC);
            dc.connect("activate", () => {
                Util.spawnCommandLine("warp-cli --accept-tos disconnect");
            });
            this.menu.addMenuItem(dc);
        } else {
            let co = new PopupMenu.PopupIconMenuItem("Connect VPN", "network-vpn-symbolic", St.IconType.SYMBOLIC);
            co.connect("activate", () => {
                Util.spawnCommandLine("warp-cli --accept-tos connect");
            });
            this.menu.addMenuItem(co);
        }

        this.menu.addMenuItem(new PopupMenu.PopupSeparatorMenuItem());

        // --- PRIVACY TOOLS ---
        let privHeader = new PopupMenu.PopupMenuItem("Privacy Tools", { reactive: false });
        privHeader.label.set_style("font-weight: bold; font-size: 1.1em;");
        this.menu.addMenuItem(privHeader);

        let macItem = new PopupMenu.PopupMenuItem("Device Address: " + info.mac, { reactive: false });
        this.menu.addMenuItem(macItem);

        let macRand = new PopupMenu.PopupMenuItem("Randomize Device Address");
        macRand.connect("activate", () => {
            Util.spawnCommandLine("bash -c \"IFACE=$(ip route | grep default | awk '{print $5}' | head -1) && sudo ip link set $IFACE down && sudo macchanger -r $IFACE && sudo ip link set $IFACE up && notify-send 'Device Address' 'Randomized successfully'\"");
        });
        this.menu.addMenuItem(macRand);

        let dnsLabel = "Encrypted DNS: " + (info.dnsEncrypted ? "ON" : "OFF");
        let dnsStatus = new PopupMenu.PopupMenuItem(dnsLabel, { reactive: false });
        dnsStatus.label.set_style(info.dnsEncrypted ? "color: #00ff00;" : "color: #ff4444;");
        this.menu.addMenuItem(dnsStatus);

        let dnsToggle = new PopupMenu.PopupMenuItem(info.dnsEncrypted ? "Disable Encrypted DNS" : "Enable Encrypted DNS");
        dnsToggle.connect("activate", () => {
            if (info.dnsEncrypted) {
                Util.spawnCommandLine("bash -c 'sudo systemctl stop stubby && notify-send DNS Disabled'");
            } else {
                Util.spawnCommandLine("bash -c 'sudo systemctl start stubby && notify-send DNS Enabled'");
            }
        });
        this.menu.addMenuItem(dnsToggle);

        this.menu.addMenuItem(new PopupMenu.PopupSeparatorMenuItem());

        let ipItem = new PopupMenu.PopupMenuItem("IP: " + info.ip, { reactive: false });
        this.menu.addMenuItem(ipItem);
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
    return new GhostModeApplet(orientation, panelHeight, instanceId);
}
