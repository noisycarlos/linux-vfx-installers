#!/usr/bin/python3

import gi

gi.require_version("Gtk", "3.0")
from gi.repository import Gtk, GLib
import subprocess
import os
import threading

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))

APPS = [
    {
        "name": "Nuke",
        "script": "nuke.sh",
        "description": "Foundry Nuke - Compositing",
    },
    {
        "name": "Fusion",
        "script": "fusion.sh",
        "description": "Blackmagic Fusion Studio",
    },
    {
        "name": "DaVinci Resolve",
        "script": "resolve.sh",
        "description": "Blackmagic DaVinci Resolve Studio",
    },
]


class InstallerGUI(Gtk.Window):
    def __init__(self):
        super().__init__(title="VFX Installers")
        self.set_default_size(700, 520)
        self.set_icon_name("applications-graphics")
        self._action_buttons = []

        main_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL)
        self.add(main_box)

        header = Gtk.HeaderBar(title="Ubuntu VFX Installers", show_close_button=True)
        self.set_titlebar(header)

        scrolled = Gtk.ScrolledWindow()
        scrolled.set_vexpand(True)
        main_box.pack_start(scrolled, True, True, 0)

        content = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=12)
        content.set_margin_start(18)
        content.set_margin_end(18)
        content.set_margin_top(12)
        content.set_margin_bottom(12)
        scrolled.add(content)


        self.checks = {}
        for app in APPS:
            card = self._build_app_card(app)
            content.pack_start(card, False, False, 0)

        content.pack_start(Gtk.Separator(), False, False, 4)
        download_notice = Gtk.Label(xalign=0)
        download_notice.set_markup("It will search the Downloads directory for the selected installers.")
        content.pack_start(download_notice, False, False, 0)

        btn_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=8)
        content.pack_start(btn_box, False, False, 0)

        btn = Gtk.Button(label="Install Selected")
        btn.get_style_context().add_class("suggested-action")
        btn.connect("clicked", self._on_install_selected)
        btn_box.pack_start(btn, False, False, 0)
        self._action_buttons.append(btn)

        btn = Gtk.Button(label="Install All")
        btn.connect("clicked", self._on_install_all)
        btn_box.pack_start(btn, False, False, 0)
        self._action_buttons.append(btn)

        btn_box.pack_start(
            Gtk.Separator(orientation=Gtk.Orientation.VERTICAL), False, False, 4
        )

        btn = Gtk.Button(label="Associate .nkind")
        btn.connect("clicked", self._on_run_script, "associate-nkind.sh")
        btn_box.pack_start(btn, False, False, 0)
        self._action_buttons.append(btn)

        btn = Gtk.Button(label="Uninstall Nuke")
        btn.get_style_context().add_class("destructive-action")
        btn.connect("clicked", self._on_run_script, "uninstall-nuke.sh")
        btn_box.pack_end(btn, False, False, 0)
        self._action_buttons.append(btn)

        content.pack_start(Gtk.Separator(), False, False, 4)

        log_label = Gtk.Label(xalign=0)
        log_label.set_markup("<b>Output</b>")
        content.pack_start(log_label, False, False, 0)

        self.log_view = Gtk.TextView()
        self.log_view.set_editable(False)
        self.log_view.set_monospace(True)
        self.log_view.set_left_margin(6)
        self.log_view.set_right_margin(6)
        self.log_view.set_top_margin(4)
        self.log_view.set_bottom_margin(4)

        log_scroll = Gtk.ScrolledWindow()
        log_scroll.set_min_content_height(140)
        log_scroll.set_policy(Gtk.PolicyType.AUTOMATIC, Gtk.PolicyType.AUTOMATIC)
        log_scroll.add(self.log_view)
        content.pack_start(log_scroll, True, True, 0)

        self._log_buffer = self.log_view.get_buffer()

    def _build_app_card(self, app):
        frame = Gtk.Frame()
        frame.set_shadow_type(Gtk.ShadowType.ETCHED_IN)

        box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=12)
        box.set_margin_start(10)
        box.set_margin_end(10)
        box.set_margin_top(8)
        box.set_margin_bottom(8)

        check = Gtk.CheckButton()
        check.set_active(True)
        self.checks[app["script"]] = check
        box.pack_start(check, False, False, 0)

        info = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=2)
        name_label = Gtk.Label(xalign=0)
        name_label.set_markup(f"<b>{app['name']}</b>")
        info.pack_start(name_label, False, False, 0)
        desc_label = Gtk.Label(label=app["description"], xalign=0)
        desc_label.get_style_context().add_class("dim-label")
        info.pack_start(desc_label, False, False, 0)
        box.pack_start(info, True, True, 0)

        btn = Gtk.Button(label="Install")
        btn.connect("clicked", self._on_run_script, app["script"])
        box.pack_end(btn, False, False, 0)
        self._action_buttons.append(btn)

        frame.add(box)
        return frame

    def _append_log(self, text):
        def _do():
            end = self._log_buffer.get_end_iter()
            self._log_buffer.insert(end, text)
            self.log_view.scroll_mark_onscreen(self._log_buffer.get_insert())

        GLib.idle_add(_do)

    def _run_script(self, script_name):
        script_path = os.path.join(SCRIPT_DIR, script_name)
        self._append_log(f"\n>>> Running {script_name}...\n")
        try:
            proc = subprocess.Popen(
                ["pkexec", "bash", script_path],
                cwd=SCRIPT_DIR,
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                text=True,
            )
            for line in proc.stdout:
                self._append_log(line)
            proc.wait()
            self._append_log(f"--- {script_name} finished (exit {proc.returncode})\n")
        except Exception as e:
            self._append_log(f"Error: {e}\n")

    def _on_run_script(self, _btn, script_name):
        self._set_buttons_sensitive(False)
        threading.Thread(
            target=self._run_and_reenable, args=(script_name,), daemon=True
        ).start()

    def _run_and_reenable(self, script_name):
        self._run_script(script_name)
        GLib.idle_add(self._set_buttons_sensitive, True)

    def _on_install_selected(self, _btn):
        selected = [s for s, cb in self.checks.items() if cb.get_active()]
        if not selected:
            self._append_log("No apps selected.\n")
            return
        self._set_buttons_sensitive(False)
        threading.Thread(
            target=self._install_batch, args=(selected,), daemon=True
        ).start()

    def _on_install_all(self, _btn):
        self._set_buttons_sensitive(False)
        threading.Thread(
            target=self._install_batch,
            args=([a["script"] for a in APPS],),
            daemon=True,
        ).start()

    def _install_batch(self, scripts):
        for s in scripts:
            self._run_script(s)
        GLib.idle_add(self._set_buttons_sensitive, True)

    def _set_buttons_sensitive(self, sensitive):
        def _do():
            for btn in self._action_buttons:
                btn.set_sensitive(sensitive)

        GLib.idle_add(_do)


def main():
    win = InstallerGUI()
    win.connect("destroy", Gtk.main_quit)
    win.show_all()
    Gtk.main()


if __name__ == "__main__":
    main()
