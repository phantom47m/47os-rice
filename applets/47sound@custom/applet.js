const Applet = imports.ui.applet;
const PopupMenu = imports.ui.popupMenu;
const GLib = imports.gi.GLib;
const Util = imports.misc.util;
const St = imports.gi.St;
const Slider = imports.ui.slider;
const Gio = imports.gi.Gio;

const STATE_FILE = GLib.build_filenamev([GLib.get_home_dir(), ".config/47industries/sound-state"]);
const ICON_PATH = GLib.build_filenamev([GLib.get_home_dir(), ".local/share/cinnamon/applets/47sound@custom/47sound-icon.svg"]);

class SoundControlApplet extends Applet.IconApplet {
    constructor(orientation, panelHeight, instanceId) {
        super(orientation, panelHeight, instanceId);

        this.set_applet_icon_path(ICON_PATH);
        this.set_applet_tooltip("47 System Sounds");

        this.menuManager = new PopupMenu.PopupMenuManager(this);
        this.menu = new Applet.AppletPopupMenu(this, orientation);
        this.menuManager.addMenu(this.menu);

        this._muted = false;
        this._volume = 100;
        this._readState();
        this._updateIcon();
    }

    _readState() {
        try {
            let [ok, contents] = GLib.file_get_contents(STATE_FILE);
            let text = contents.toString();
            let mutedMatch = text.match(/muted=(\w+)/);
            let volMatch = text.match(/volume=(\d+)/);
            if (mutedMatch) this._muted = (mutedMatch[1] === "true");
            if (volMatch) this._volume = parseInt(volMatch[1]);
        } catch (e) {
            // State file doesn't exist yet, use defaults
            this._muted = false;
            this._volume = 100;
        }
    }

    _writeState() {
        let dir = GLib.build_filenamev([GLib.get_home_dir(), ".config/47industries"]);
        GLib.mkdir_with_parents(dir, 0o755);
        let content = "muted=" + this._muted + "\nvolume=" + this._volume + "\n";
        GLib.file_set_contents(STATE_FILE, content);
    }

    _updateIcon() {
        if (this._muted || this._volume === 0) {
            this.set_applet_icon_symbolic_name("audio-volume-muted");
            this.actor.style = "color: #666666;";
        } else {
            this.set_applet_icon_path(ICON_PATH);
            this.actor.style = "";
        }

        let tooltip = this._muted
            ? "47 Sounds: MUTED"
            : "47 Sounds: " + this._volume + "%";
        this.set_applet_tooltip(tooltip);
    }

    _buildMenu() {
        this.menu.removeAll();

        // Header
        let header = new PopupMenu.PopupMenuItem("47 System Sounds", { reactive: false });
        header.label.set_style("font-weight: bold; font-size: 1.1em; color: #ffffff;");
        this.menu.addMenuItem(header);

        this.menu.addMenuItem(new PopupMenu.PopupSeparatorMenuItem());

        // Mute toggle
        let muteLabel = this._muted ? "Unmute" : "Mute";
        let muteItem = new PopupMenu.PopupMenuItem(muteLabel);
        muteItem.connect("activate", () => {
            this._muted = !this._muted;
            this._writeState();
            this._updateIcon();
        });
        this.menu.addMenuItem(muteItem);

        this.menu.addMenuItem(new PopupMenu.PopupSeparatorMenuItem());

        // Volume label with current value
        let volLabel = new PopupMenu.PopupMenuItem("Volume: " + this._volume + "%", { reactive: false });
        this.menu.addMenuItem(volLabel);

        // Volume slider
        let sliderItem = new PopupMenu.PopupBaseMenuItem({ activate: false });
        let slider = new Slider.Slider(this._volume / 100);
        slider.connect("value-changed", (s, value) => {
            this._volume = Math.round(value * 100);
            this._writeState();
            this._updateIcon();
            volLabel.label.set_text("Volume: " + this._volume + "%");
            // If adjusting volume, auto-unmute
            if (this._muted && this._volume > 0) {
                this._muted = false;
                this._writeState();
                this._updateIcon();
            }
        });
        sliderItem.addActor(slider.actor, { expand: true });
        this.menu.addMenuItem(sliderItem);

        this.menu.addMenuItem(new PopupMenu.PopupSeparatorMenuItem());

        // Quick presets
        let presetsHeader = new PopupMenu.PopupMenuItem("Presets", { reactive: false });
        presetsHeader.label.set_style("font-weight: bold;");
        this.menu.addMenuItem(presetsHeader);

        let presets = [
            { name: "25%", value: 25 },
            { name: "50%", value: 50 },
            { name: "75%", value: 75 },
            { name: "100%", value: 100 },
        ];

        for (let preset of presets) {
            let item = new PopupMenu.PopupMenuItem("  " + preset.name);
            let val = preset.value;
            item.connect("activate", () => {
                this._volume = val;
                this._muted = false;
                this._writeState();
                this._updateIcon();
            });
            this.menu.addMenuItem(item);
        }
    }

    on_applet_clicked() {
        this._readState();
        this._buildMenu();
        this.menu.toggle();
    }

    on_applet_middle_clicked() {
        // Middle-click to quick toggle mute
        this._readState();
        this._muted = !this._muted;
        this._writeState();
        this._updateIcon();
    }
}

function main(metadata, orientation, panelHeight, instanceId) {
    return new SoundControlApplet(orientation, panelHeight, instanceId);
}
