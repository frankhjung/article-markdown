---
title: "From QuickShell to Waybar: Simplifying My Sway Desktop"
author: "[Frank Jung](https://www.linkedin.com/in/frankjung/)"
date: 12 November 2026
tags: [sway, waybar, wayland, ansible, linux, desktop]
---

![A minimalist banner showing the move to Waybar](images/banner.jpg)

Not long after publishing my [previous article][xfce-to-sway] on migrating from
Xfce4 to Sway and QuickShell, I noticed a creeping problem. While QuickShell
gave me total freedom to build a custom top panel, I was spending far too much
time maintaining bespoke QML widgets and background polling scripts just to keep
basic desktop status indicators running. I had traded Xfce's brittle XML files
for my own mini widget framework—so I began looking for a simpler way.

That search led me straight to [Waybar][waybar]. Because Sway and Wayland were
already doing the heavy lifting for window management, replacing QuickShell with
Waybar allowed me to retire nearly all of my custom panel code in favour of a
native, configuration-driven status bar. Here is a quick look at what was
required for the conversion and how the desktop feels on the other side.

## Why Move On from QuickShell?

QuickShell is a clever toolkit, and it handled rich popups and custom hover
cards beautifully. However, building every panel widget from scratch meant
owning the full lifecycle of each indicator. Every time I wanted to tweak
battery metrics, CPU temperature readouts, or clipboard previews, I had to loop
through QML layout code and helper scripts.

Using my AI tools to compare alternatives, I mapped out what an equivalent
Waybar setup would look like against my existing panel. The comparison was eye-
opening: almost everything I had hand-crafted in QuickShell was already built
into Waybar right out of the box.

## What the Conversion Required

Because the underlying desktop was already managed declaratively through
Ansible, swapping the panel layer turned out to be surprisingly straightforward.
The conversion boiled down to four practical adjustments:

- **Replacing QML Widgets with Waybar Modules:** My 32-pixel top panel layout—
  with the application menu, workspace pager, window tasklist, clock, audio,
  battery, system tray, and CPU/temperature telemetry—mapped directly onto
  standard Waybar JSON configuration and a clean CSS stylesheet.
- **Handling Popups with Fuzzel:** Waybar is strictly a status bar rather than a
  popup engine. To replace QuickShell's modal overlays without losing
  functionality, I leaned on [Fuzzel][fuzzel] running in `dmenu` mode. Clicking
  the top-left Debian icon or top-right power button now triggers lightweight
  Fuzzel menus anchored neatly beneath the bar, while my searchable keyboard
  shortcut cheatsheets open as centred overlays.
- **Routing Alerts Through Mako:** Instead of rendering custom QML on-screen
  displays for volume and brightness keys, a tiny helper script now sends
  progress hints straight to the [Mako][mako] notification daemon, which styles
  them into crisp, temporary progress bars.
- **Keeping a Single Theme and Shortcut Source:** My existing Ansible variables
  for the Debian steel-cerulean colour palette and action-based keyboard
  shortcuts didn't need to change. I simply pointed the Ansible templates at
  Waybar, Fuzzel, and Mako instead of QuickShell, and purged the old packages.

## First Impressions

Living with the new setup day to day, the biggest win is what is no longer
there. Stripping out custom QML components and background telemetry scripts
dramatically simplified my Ansible playbooks, making the configuration much
easier to read, maintain, and replicate across my workstations and laptops.

Performance and polish haven't skipped a beat:

- **Native Speed and Lower Overhead:** Waybar is written in C++ and reads kernel
  telemetry directly rather than spawning shell scripts every few seconds.
- **Rich Tooltips Without Custom UI Code:** Hovering over the clock still shows
  a full 12-month calendar, and hovering over the clipboard icon still previews
  recent copied text—all driven by standard Waybar tooltips.
- **Zero Workflow Disruption:** From across the room, the desktop still looks
  and behaves just like the classic Xfce4 layout I have used for over a decade.

Sometimes the best improvement you can make to a personal setup is deleting code
you don't actually need to maintain. Moving from QuickShell to Waybar kept
everything I enjoyed about my modern Wayland workflow while returning my desktop
configuration to what it should be: lightweight, boringly reliable, and easy to
look after.

[xfce-to-sway]: https://frankhjung.blogspot.com/2026/10/rebuilding-desktop-from-xfce4-to-sway.html
[waybar]: https://github.com/Alexays/Waybar
[fuzzel]: https://codeberg.org/dnkl/fuzzel
[mako]: https://wayland.emersion.fr/mako/
