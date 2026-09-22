---
title: "First Look at Omarchy Linux"
author: "[Frank Jung](https://www.linkedin.com/in/frankjung/)"
date: 22 September 2026
tags: [linux, ai, omarchy, desktop, productivity]
---

![Omarchy Linux desktop with a modern, keyboard-first workspace](images/banner.jpg)

## AI-First Operating System

I've spent the past month exploring [Omarchy][omarchy]. The short version: it is
a fresh and minimal Linux desktop specifically for a world where AI tools are
becoming part of the daily workflow. Created by
[David Heinemeier Hansson (DHH)][dhh], Omarchy is unapologetically opinionated.
Instead of a blank canvas, it offers a curated "omakase" (chef's choice)
experience designed for the age of AI. The premise is simple: if you can use AI
to generate an app quickly, then you should be able to shape your entire
operating system around the same workflow.

I recently revived a 12-year-old ThinkPad X1 Carbon with Omarchy, and the
difference was palpable. The machine felt notably snappier, more coherent, and
more useful. All the hardware was fully recognised, including the fingerprint
scanner. That is not a scientific benchmark, but it is exactly the sort of
result that matters to a real user.

## Installation as a Speed Run

One of the most striking things about Omarchy is how fast it gets you from
power-on to a usable desktop. The installer asks exactly five questions before
handing you a finished, themed desktop. On modern machines, the process can take
as little as 35 seconds. On older hardware, it remains remarkably quick: on my
12-year-old ThinkPad X1 Carbon, it took under five minutes.

Most users will be up and running in less than two minutes. Even on the 2011
ThinkPad X220 with 2GB of RAM that DHH uses to showcase Omarchy on ancient
hardware, the installation completes with plenty of headroom. Indeed, I
successfully installed Omarchy on a 2010 MacBook Air with only 2GB of RAM. For
someone who views [Arch][arch]-based systems as a challenge, that is a
meaningful selling point. Omarchy turns a process that used to feel like a
weekend project into something you can finish while your coffee is still warm.

## A Curated Computing Experience

Most Linux distributions present users with a large menu of software and
configurations. Omarchy makes a different bet: the "chef" chooses the tools for
you. These apps include essential tools for development, productivity, and
system management. Omarchy ships with a pre-tuned stack featuring
[Wayland][wayland], the [Hyprland][hyprland] compositor, the [Foot][foot]
terminal, and [Quickshell][quickshell]. It feels cohesive: aesthetics and
productivity are not treated as separate concerns.

> "When you can vibe code whatever app comes to your mind, you should be able to
> vibe code your operating system." — David Heinemeier Hansson (Lex Fridman
> Podcast \#501, August 2026)

While I replaced many of the chef's default apps with my own favourites,
adapting the system proved straightforward. I remapped keyboard shortcuts, added
a dark/light theme toggle to the top bar, and tailored the optional menu-driven
developer tools to my environment while pruning the rest.

The system starts out as DHH's curated vision, but it quickly adapts to your
personal tools and workflow.

## Keyboard-First Ergonomics: Hyprland and Quickshell

If you are coming from macOS or Windows, the biggest adjustment is Hyprland, a
dynamic tiling Wayland compositor. Omarchy is built around a keyboard-first
workflow where windows tile automatically, reducing the clutter of overlapping
panes and floating windows.

Keyboard-driven window navigation forms the bedrock of the Omarchy experience,
complemented by Quickshell. In Omarchy 4.0, the desktop shell was rewritten with
this toolkit, consolidating the top bar, application launcher, and notifications
into a unified, scriptable shell environment. That creates a workflow that
becomes almost second nature over time, especially on a couch-bound laptop where
a mouse is more of a hindrance than a help.

## The Rise of the Agentic OS

Omarchy treats AI agents—like Claude, GitHub Copilot, and Google Gemini—as
first-class citizens. The system uses "lazy-loaded launchers" via `mise` stubs
located in `~/.local/bin/`. In practical terms, the binaries are not installed
until you call them the first time.

```bash
omarchy default agent gemini
```

Running the command above triggers the automatic download and installation of
the agent. I later installed GitHub Copilot and Google Antigravity tools as
well.

This "agentic layer" goes beyond a simple chat window. The agents are embedded
in the system's workflow. If a process crashes via `systemd-coredump`, the
notification system lets you hand the crash log directly to an agent to diagnose
it using the built-in `diagnose-crash` skill.

That makes the operating system feel less like a fixed set of tools and more
like an environment that can assist with active troubleshooting and system
administration. It is a compelling direction, especially for developers who
already live in the terminal.

> "The future of AI computing might end up looking a lot like the old way of
> using computers: files, terminals, scripts, text and a machine you can
> actually understand." — Lars Jansen (@oldstackjournal, Omarchy, August 2026)

## Dotfiles, Portability, and AI-Friendly Systems

Omarchy is a highly malleable Linux distro. Most of the things that make the
system feel like yours live in plain text configuration files inside
`~/.config/`. Because these are simple text files, many users manage them with
tools like GNU Stow to symlink their personal dotfiles into a central Git
repository — a popular community convention rather than something Omarchy
imposes itself.

This plain-text approach makes your entire OS setup portable. More importantly,
it makes the system AI-friendly. An agent can read your config files, understand
your setup, and suggest improvements or fixes. Because the agent can "see" the
dotfiles, the terminal becomes the most natural place for AI to help manage the
environment.

That is one of the most compelling ideas in Omarchy: it turns the system into a
readable, explainable machine rather than a black box.

## The Safety Net of the Update Wrapper

Under the hood, Omarchy is still Arch Linux, but it addresses the standard fear
of a rolling-release system: breaking the system while updating it. While Arch
purists might reach for `pacman`, Omarchy expects users to run its
`omarchy update` wrapper as a safety net, avoiding manual `pacman -Syu` commands
that bypass snapshot hooks and system migrations.

This wrapper creates a [Btrfs][btrfs] snapshot before installing updates. The
stable channel tracks roughly a month behind upstream Arch to reduce breakage
and catch regressions sooner. The system draws on three package sources: the
Omarchy Arch Mirror (the stable, month-behind snapshot of the official Arch
repositories), the Omarchy Package Repository (which includes the custom
`linux-omarchy` kernel and dedicated shell integrations), and the [AUR][aur].

This is where Omarchy feels particularly thoughtful. It does not pretend that
rolling release is risk-free. Instead, it gives users a safer default path.

## Conclusion

Omarchy is a promising entry in the world of agentic Linux. Its simple
installation, config-driven design, and hardware-aware approach make it a strong
choice for anyone willing to embrace its philosophy. The AI agent can read your
configuration, help diagnose crashes, and support your customisations without
pulling you out of the terminal.

Linux has always been about choice, and Omarchy shows that choice does not have
to mean endless setup friction. I am happy to use Omarchy as my distro on the
road, while my desktop remains on Debian. Even so, some of the ideas I have
encountered in Omarchy are worth borrowing back into my Debian setup.

For a first look, I am impressed. It feels like the kind of system that could
become genuinely useful to people who want a more thoughtful, AI-assisted
desktop without giving up control.

[arch]: https://archlinux.org/
[aur]: https://aur.archlinux.org/
[btrfs]: https://btrfs.readthedocs.io/
[dhh]: https://dhh.dk/
[foot]: https://codeberg.org/dnkl/foot
[hyprland]: https://hyprland.org/
[omarchy]: https://omarchy.org/
[quickshell]: https://quickshell.org/
[wayland]: https://wayland.freedesktop.org/
