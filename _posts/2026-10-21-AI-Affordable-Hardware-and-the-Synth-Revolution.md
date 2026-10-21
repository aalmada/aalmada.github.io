---
layout: post
read_time: true
show_date: true
title: "AI, Affordable Hardware, and the Synth Revolution"
date: 2026-10-21
img_path: /assets/img/posts/20261021
media_subpath: /assets/img/posts/20261021
image:
  path: fm1-browser-emulator.webp
  alt: "The FM-1 browser emulator running community synthesizer firmware"
tags: [ai, open-source, synthesizers, firmware]
category: ai
meta_description: "How a $60 M-VAVE FM-1 synthesizer led me into a community using open-source firmware and AI coding tools to rethink what affordable music hardware can become."
---

I bought a small synthesizer for about $60. Within days, I was watching people turn the same hardware into very different instruments by replacing its firmware. Better interfaces, new synthesis engines, multiple tracks, browser installers, even Doom.

I've written quite a bit about [AI and software development]({% post_url 2026-06-29-From-Hero-Prompts-to-Shared-AI-Infrastructure %}). But this little synth made one part of that change feel much more personal: **more people can now build the software they want, for the hardware they own.**

Not because a manufacturer decided there was a market for it. Because someone wanted it to exist.

## The synth I always wanted to play

I've always loved the sound of synthesizers. I grew up listening to Jean-Michel Jarre, Vangelis, Depeche Mode, The Human League, and so many others. Those sounds have stayed with me.

I had piano lessons, but what I really wanted was to play synths. I wanted to explore the sounds, turn the knobs, and understand how those textures were made.

The price was always a barrier. A synthesizer felt like a considerable investment just to find out whether I had any talent for it, or whether I would enjoy making those sounds as much as listening to them. Software synths have long offered a cheaper way in, but I wanted an instrument I could put my hands on.

Recently, while watching synthesizer reviews on YouTube, I kept seeing the same little device appear on different channels: the **M-VAVE FM-1**.

A small digital synth from China, available through marketplaces such as AliExpress and Temu, for around $60, depending on the seller and the usual taxes and shipping. Rechargeable battery, Bluetooth MIDI, a surprisingly decent color display, a built-in speaker, and a sound engine compatible with Yamaha DX7 voices from the 1980s.

The [manufacturer's specifications](https://www.cuvave.com/product.html?id=fm-1) describe six-operator FM synthesis with 32 algorithms. In less technical terms: a very inexpensive way to start exploring that classic world of FM sounds. It is not a complete replacement for an original DX7, but that was never what I needed.

Finally, a chance to play with a hardware synth without making a large financial commitment!

## Then the firmware started arriving

A few days after I got mine, I discovered custom firmware with a much better-looking interface, FM synthesis, and **virtual analog synthesis**. That last term means digitally recreating aspects of an analog synth's sound generation and filtering. The hardware had not changed, but the range of sounds and the experience of using it had.

[Baud Girl's FM-1+VA](https://baudgirl.com/work/FM-1+VA) is one example of that approach. It adds virtual analog capabilities and reworks the interface and sequencing. It is free to install, although it is not open source.

What also caught my attention was the installation. Open a compatible browser, connect the synth by USB, give the page MIDI access, and install. No need to compile firmware or buy a hardware programmer. The community installers commonly use Chrome or Edge and a USB data cable.

A couple of days later, I was looking at firmware offering four tracks and many more synthesis engines. Projects such as [Felucca](https://github.com/hugelton/Felucca), by Leo Kuroshita of Hügelton Instruments, and [SLOOP](https://github.com/isod89/sloop-fm1), by isod89, turn the FM-1 into a multi-engine instrument or a live groovebox: a device that combines sounds, drums, and sequencing to build up music.

These projects are open source. Other people can inspect them, change them, and publish their own versions. And they did.

Some forks focus on particular sounds. Others change the performance workflow. [X0X](https://github.com/charlesvestal/fm1-x0x), by Charles Vestal, takes it toward classic drum machines and acid basslines. [FoMni](https://github.com/charlesvestal/fm1-fomni) turns the same keys into a chord harp inspired by the Omnichord.

And, of course, someone [ported Doom](https://github.com/zvenson/fm1doom). Apparently, a screen and a processor are an invitation.

This was no longer just a cheap synth with a few extra presets. People were making different instruments out of the same little box.

## An ecosystem around a $60 instrument

It quickly became difficult to keep track of all the options. That created another problem for someone to solve.

[The FM-1 Firmware Hub](https://thefirmwarehub.com/), by Sven Trogus, brings community firmware together, with project links and browser installation for the packages it hosts. Instead of following every repository separately, you can browse the alternatives in one place.

Then came ways to try the instruments without installing anything on the device. The hub links to browser previews, and projects such as [Joakim Eriksson's FM-1 emulator](https://joakimeriksson.github.io/fm1-emu/) emulate the hardware and run firmware packages in the browser.

![The FM-1 emulator showing the instrument's screen, knobs, buttons, and small keyboard](fm1-browser-emulator.webp)
_Browser screenshot of [fm1-emu](https://github.com/joakimeriksson/fm1-emu), by Joakim Eriksson, running community firmware. This is an emulated panel, not a photograph of my device._

You can explore an interface and hear what it does before deciding whether to put it on your synth. It lowers the cost of trying something again: first the hardware became affordable, then experimenting with its software became easier too.

I even started seeing people buying multiple FM-1s so they could keep different firmware running on separate devices and play them together. The attraction was no longer only the original product. It was what the community was making it become.

## Where AI actually fits

Hardware hacking, reverse engineering, and open-source synthesizers existed long before today's coding agents. It would be wrong to give AI all the credit for this community's work.

But the AI connection here is not just an assumption based on how quickly new firmware appeared. **Felucca's own README explicitly states that AI coding agents assist with code, tests, documentation, translation, and maintenance.** It also makes an important distinction: the design, features, sound design, and direction come from the maintainer and community. That is AI helping people build an instrument, not AI deciding what music they should make.

That distinction is what interests me.

A musician may know exactly what is awkward about an interface, what should happen when a button is held, or how a sequencer should respond during a performance. Turning that knowledge into reliable embedded software is a different skill, and a substantial barrier.

AI tools can help bridge parts of that gap: explain unfamiliar code, work through an existing implementation, adapt controls, write tests, and iterate on a change. They do not remove the need to learn, listen, debug, or test on the real device. They can make attempting the project practical for more people.

Open source is essential to that process. A coding agent with a working codebase, documented hardware behavior, and tests has a much better starting point than one asked to invent a firmware from a vague description. Each useful contribution gives the next person something concrete to build on.

## Beyond the tiny rubber keyboard

The FM-1 has an obvious limitation: its keyboard. The rubbery keys are very small, and there are only so many physical controls available. New firmware can change what those controls do, but it cannot make the keys bigger.

M-VAVE also sells the **SMK-37**, a 37-key keyboard with considerably more controls, including pads, encoders, faders, and pitch and modulation wheels. Community hardware research identifies the same JieLi AC791N chip family inside both devices.

That does not make their firmware interchangeable. The screens, controls, wiring, and storage layout still need to be handled correctly. But it creates an opportunity to carry the software over to a more playable instrument.

The community is already doing it. The [FM-1 to SMK-37 porting kit](https://github.com/genkigenki/fm1-to-smk37), by genkigenki, documents the hardware differences and provides a workflow for using a coding agent to port existing firmware.

Its process starts with questions about what the extra controls should do. The agent then works through the port, builds, and tests. A person backs up the device, installs the result, plays it, and reports what actually works.

For example, a requirement for such a port might look like this:

```text
Keep the existing FM-1 behavior unchanged.
Use the four faders for the four track levels.
Use the pads for drum performance.
Preserve the device's factory calibration data.
Build and test before proposing an installation.
Ask for approval before flashing hardware.
```

That is an illustrative specification, not a complete porting procedure. The project's hardware and recovery instructions still matter. What stands out to me is that the user gets to make those decisions, instead of accepting only the mapping a manufacturer chose.

## Software for a particular person

The same change reaches far beyond synthesizers.

Think of an application that solves one person's particular problem, with their own workflow and specifications. A small tool does not need a subscription business behind it, a large addressable market, or a product team willing to prioritize its features. It needs to be useful to the person who wants it.

Or consider an older piece of hardware whose manufacturer has stopped providing drivers. The physical device may still work perfectly. The missing part is software that lets it work with a current computer. AI-assisted development can help an owner investigate an existing open-source driver, understand a documented protocol, or attempt a compatibility fix. Success still depends on access to information, the operating system's requirements, and testing; a prompt cannot unlock every abandoned device.

The FM-1 is not abandoned hardware. It is an example of users extending a current product. But both cases challenge the same assumption: that the manufacturer's software roadmap must define what an owner can do with their device.

For me, that is a meaningful form of democratization. More people can participate in making the tools they use, even when their needs are too specific to become a commercial product.

## Easier to build is not the same as safe to install

There are real trade-offs. A polished browser installer does not prove that the firmware behind it is reliable. Neither does an emulator, a successful build, or an AI-generated test suite.

Firmware can lose saved work, break a feature that the stock software supported, or leave a device needing recovery. Some alternatives do not support the FM-1's Bluetooth functionality. On the SMK-37, the porting guide specifically warns about factory calibration data that must not be overwritten.

Before experimenting, read the exact project's compatibility notes, back up what it supports backing up, and understand the recovery path for your model. A firmware package for one device is not automatically suitable for another just because they share a processor.

There is also the human cost of maintaining all this software. More forks mean more choices, but also fragmented bug reports, duplicated fixes, and uncertain support. Felucca's maintainer has already announced a step back from active development. Source availability lets others continue the work; it does not guarantee that someone will.

Democratizing development should also mean sharing responsibility: crediting the original authors, respecting licenses, reporting useful bugs, contributing fixes, and supporting maintainers where we can.

## What this could change

Much of the traditional synth market has been shaped by a relatively small group of established brands and products whose firmware users could not meaningfully change. There have always been exceptions, including DIY instruments, open-source projects, and platforms designed for third-party extensions. This did not start with the FM-1.

What feels different is the combination of price, access, and the speed at which people can now try an idea.

Affordable hardware gets an instrument into more hands. Open-source firmware gives people a place to start. AI-assisted coding can help more of them make changes. Browser installers and emulators let a much wider audience try the results.

Even M-VAVE now publishes an [official open firmware project and development toolkit](https://github.com/m-vave/fm1_open), alongside a browser workbench. It is not an entirely open stack: the project still includes vendor binary components. But it shows that the manufacturer can participate in this kind of ecosystem too.

I believe this combination could seriously disrupt parts of the synth industry. Not by making every expensive instrument obsolete. Good keyboards, physical controls, sound, build quality, and dependable live performance still matter enormously.

The change is in who gets to decide what an instrument can become. A manufacturer can sell a useful piece of hardware, and its users can take it in directions that were never on the original feature list.

I bought the FM-1 because I wanted an inexpensive way to finally play with a synth. I did not expect it to become such a concrete example of why AI-assisted software development matters.

The affordable hardware let me try the instrument. The community keeps giving me new reasons to pick it up.
