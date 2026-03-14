const Applet = imports.ui.applet;
const PopupMenu = imports.ui.popupMenu;
const St = imports.gi.St;
const GLib = imports.gi.GLib;
const Util = imports.misc.util;

class FakeBatteryApplet extends Applet.IconApplet {
    constructor(orientation, panelHeight, instanceId) {
        super(orientation, panelHeight, instanceId);
        this.set_applet_icon_symbolic_name("battery-full-charged-symbolic");
        this.set_applet_tooltip("Power: Plugged In");

        this.menuManager = new PopupMenu.PopupMenuManager(this);
        this.menu = new Applet.AppletPopupMenu(this, orientation);
        this.menuManager.addMenu(this.menu);
    }

    _buildMenu() {
        this.menu.removeAll();

        // Header
        let header = new PopupMenu.PopupMenuItem("Power Status", { reactive: false });
        header.label.set_style("font-weight: bold; font-size: 1.1em;");
        this.menu.addMenuItem(header);

        this.menu.addMenuItem(new PopupMenu.PopupSeparatorMenuItem());

        // Battery info
        let items = [
            ["Battery:", "100%"],
            ["Status:", "Plugged In"],
            ["Health:", "Good"],
            ["Time Remaining:", "∞"],
            ["Power Source:", "AC Power"]
        ];

        for (let [label, value] of items) {
            let item = new PopupMenu.PopupMenuItem(label + "  " + value, { reactive: false });
            this.menu.addMenuItem(item);
        }

        this.menu.addMenuItem(new PopupMenu.PopupSeparatorMenuItem());

        // Power settings button
        let settingsItem = new PopupMenu.PopupMenuItem("Power Settings...");
        settingsItem.connect("activate", () => {
            Util.spawnCommandLine("cinnamon-settings power");
        });
        this.menu.addMenuItem(settingsItem);
    }

    on_applet_clicked() {
        this._buildMenu();
        this.menu.toggle();
    }
}

function main(metadata, orientation, panelHeight, instanceId) {
    return new FakeBatteryApplet(orientation, panelHeight, instanceId);
}
