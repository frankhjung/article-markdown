---
title: "First look at Omarchy Linux"
author: "[Frank Jung](https://www.linkedin.com/in/frankjung/)"
date: 21 September 2026
tags: [linux, ai, omarchy, desktop, productivity]
---

![Omarchy Linux desktop with a modern, keyboard-first workspace](images/banner.jpg)

## AI First Operating System

I've spent the past month exploring Omarchy. This is my personal opinion and
represents my initial experience with the distribution, which has been overall a
positive one. Created by David Heinemeier Hansson (DHH), Omarchy is
unapologetically opinionated. Instead of a blank canvas, it offers a curated
"omakase" (chef's choice) experience designed for the age of AI. The premise is
simple: if you can use AI to generate an app quickly, then you should be able to
use AI to shape your entire operating system.

I recently revived a 12-year-old Carbon X1 with Omarchy, and the difference was
immediate. The machine felt more responsive, more coherent, and more useful than
it had in years. That is not a scientific benchmark, but it is the kind of
result that matters to a real user.

## A Curated Computing Experience

Most Linux distributions present users with a large menu of software and
configurations. Omarchy makes a different bet: the "chef" chooses the tools for
you. You do not have to spend time choosing a terminal, text editor, or window
manager; Omarchy ships with a pre-tuned stack featuring Neovim, the Hyprland
compositor, the Foot terminal, and Quickshell.

This approach removes the "paradox of choice" that slows new users down. By
providing polished defaults that look good out of the box, Omarchy lets you skip
straight to building and shipping work. It feels cohesive: aesthetics and
productivity are not treated as separate concerns.

"When you can vibe code whatever app comes to your mind, you should be able to
vibe code your operating system." — David Heinemeier Hansson

## Installation as a Speed Run

From Boot to Desktop in Five Questions

One of the most striking things about Omarchy is how fast it gets you from
power-on to a usable desktop. The installer asks exactly five questions before
handing you a finished, themed desktop. On modern machines, the process can take
as little as 35 seconds. On older hardware, it is still remarkably fast.

Most users will be up and running in less than two minutes. Even on the 2011
ThinkPad X220 with 2GB of RAM that DHH uses to showcase Omarchy on ancient
hardware, the installation completes with plenty of headroom. For someone who
views Arch-based systems as a time sink, that is a meaningful selling point.
Omarchy turns a process that used to feel like a weekend project into something
you can finish while your coffee is still warm.

## The Rise of the Agentic OS

Omarchy treats AI agents—like Claude, GitHub Copilot, and Google Antigravity—as
first-class citizens. The system uses "lazy-loaded launchers" via `mise` stubs
located in `~/.local/bin/`. In practical terms, the binaries are not installed
until you call them the first time.

```bash
omarchy default agent antigravity
```

Running the command above triggers the automatic download and installation of
the Antigravity CLI.

This "agentic layer" goes beyond a simple chat window. The agents are embedded
in the system's workflow. If a process crashes via `systemd-coredump`, the
notification system lets you hand the crash log directly to an agent to diagnose
it using the built-in `diagnose-crash` skill.

That makes the operating system feel less like a fixed set of tools and more
like an environment that can assist with active troubleshooting and environment
management. It is a compelling direction, especially for developers who already
live in the terminal.

"The future of AI computing might end up looking a lot like the old way of using
computers: files, terminals, scripts, text and a machine you can actually
understand." — Lars Jansen

## Keyboard-First Efficiency with Quickshell

If you are coming from macOS or Windows, the biggest adjustment is Hyprland, a
dynamic tiling Wayland compositor. Omarchy is built around a keyboard-first
workflow where windows tile automatically, reducing the clutter of overlapping
panes and floating windows.

Pressing Super + J flips the split orientation between horizontal and vertical.
The bigger revelation, though, is Quickshell. Omarchy 4.0 rewrote its desktop
shell using this toolkit, moving the top bar, application launcher, and
notifications into a unified, scriptable shell environment. That creates a
workflow that becomes almost second nature over time, especially on a
couch-bound laptop where a mouse is more of a hindrance than a help.

## The Safety Net of the Update Wrapper

Under the hood, Omarchy is still Arch Linux, but it addresses the standard fear
of a rolling-release system: breaking the system while updating it. While you
can use raw `pacman`, the system uses the `omarchy update` wrapper as a safety
net.

```bash
omarchy update
```

This wrapper creates a Btrfs snapshot before installing updates. The stable
channel tracks roughly a month behind upstream Arch to reduce breakage and catch
regressions sooner. The system draws on three package sources: the Omarchy Arch
Mirror (the stable, month-behind snapshot of the official Arch repositories),
the Omarchy Package Repository (which includes the custom `linux-omarchy` kernel
and dedicated shell integrations), and the AUR.

This is where Omarchy feels particularly thoughtful. It does not pretend that
rolling release is risk-free. Instead, it gives users a safer default path.

## "Malleability" via Dotfiles

Plain Text Management and Portability

Omarchy is a highly malleable computer. Most of the things that make the system
feel like yours live in plain text configuration files inside `~/.config/`.
Because these are simple text files, many users manage them with tools like GNU
Stow to symlink their personal dotfiles into a central Git repository — a
popular community convention rather than something Omarchy imposes itself.

This makes your entire OS setup portable. More importantly, it makes the system
AI-friendly. An agent can read your config files, understand your setup, and
suggest improvements or fixes. Because the agent can "see" the dotfiles, the
terminal becomes the most natural place for AI to help manage the environment.

That is one of the most compelling ideas in Omarchy: it turns the system into a
readable, explainable machine rather than a black box.

## Conclusion

I think Omarchy is a promising entry in the world of agentic Linux. Its simple
installation, config-driven design, and hardware-aware approach make it a strong
choice for anyone willing to embrace its philosophy. The AI agent can read your
configuration, help diagnose crashes, and support your customisations without
pulling you out of the terminal.

Linux has always been about choice, and Omarchy shows that choice does not have
to mean endless setup friction. I am happy to use Omarchy as my distro on the
road, while my desktop remains on Debian. Even so, some of the ideas I have
encountered in Omarchy are already worth borrowing back into my Debian setup.

For a first look, I am impressed. It feels like the kind of system that could
become genuinely useful to people who want a more thoughtful, AI-assisted
desktop without giving up control.