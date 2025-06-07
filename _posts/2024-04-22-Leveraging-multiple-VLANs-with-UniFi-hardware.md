---
layout: post
read_time: true
show_date: true
title: "Maximizing Network Security: Leveraging Multiple VLANs with UniFi Hardware"
date: 2024-04-22
img_path: /assets/img/posts/20240422
image: WASD.jpg
tags: [network, security, ubiquiti, unifi, vlan]
category: network
meta_description: "Learn how to maximize network security by leveraging multiple VLANs with UniFi hardware, including setup, best practices, and guest network management."
---

Many household utility devices today rely on internet access to function fully. From washing machines and vacuum robots to air filters, fridges, and air conditioners, these appliances often need a direct link to a server via both the device itself and its associated app.

While this setup provides convenience, it also presents significant concerns. Firstly, there are security implications; dependence on third-party servers may result in excessive data collection, potentially compromising network privacy. Secondly, there's no assurance of server longevity; if the company finds it unprofitable, your device could lose functionality or become unusable. Though crucial, this topic exceeds the scope of this article.

Furthermore, it's increasingly common for guests to request access to your Wi-Fi network for their devices. While security best practices advise against sharing passwords, you likely want to accommodate your guests. Changing the password afterward requires reconfiguring all personal devices.

In both scenarios, the question arises: why grant third-party devices access to your personal network when they only require internet connectivity? One standout feature of UniFi hardware in my network setup is its capability to provide internet access without directly exposing my personal network to third parties.

Although this solution doesn't fully address privacy and security concerns regarding running accompanying apps on personal devices, it mitigates the issue to some extent.

> Disclaimer: I'm not a security expert, so I can't guarantee that this is the optimal solution. Feel free to share in the comments below any important settings or information I might have overlooked.

## Setting Up Multiple Virtual LANs

Virtual LANs (VLANs) allow for the segmentation of traffic within a physical network, offering enhanced organization and security. With the UniFi Controller, creating and managing multiple LANs is straightforward.

Begin by navigating to the `Settings` tab and selecting `Networks`. To add a new VLAN, click on `New Virtual Network` and assign a descriptive name. For instance, I've established two VLANs: `IoT` and `Guests`, each serving its designated purpose. These names are solely for internal reference. The controller automatically assigns distinct VLANs to each new network. You can customize DHCP settings by disabling `Auto-Scale Network` or adjust other parameters like VLAN ID by toggling the `Advanced` switch to `Manual`.

## Configuring Multiple Wi-Fi Networks

In UniFi Controller, assigning a wireless device to a specific VLAN is best achieved by creating a corresponding Wi-Fi network.

Start by navigating to the `Settings` tab and selecting `WiFi`. To add a new Wi-Fi network, click on `Create New` and provide a name. I've added two additional networks, naming them by appending `-iot` and `-guest` to the existing network name. These names will be publicly visible when scanning for Wi-Fi networks.

### Configuring the IoT Wi-Fi Network

For the IoT Wi-Fi network, set a password in the `Password` field. This password will be used for connecting wireless devices to this network. From the dropdown menu labeled `Network`, select the previously created `IoT` network to assign the Wi-Fi network to the corresponding VLAN.

You can leave the default settings unchanged or customize them as needed. Additionally, you can specify which access points will provide this network and access more settings by toggling the `Advanced` switch to `Manual`.

### Configuring the Guest Wi-Fi Network

Configuring the guest Wi-Fi network follows a similar process, but I prefer to set it up as a `Hotspot Portal`. This creates a Wi-Fi network that appears open during scanning. When guests connect, they're presented with a landing page with a welcome message, optional terms of service, and one or more authentication methods.

To set this up, when adding the Wi-Fi network, leave the password field blank and select the `Guest` network from the `Network` dropdown, assigning the respective VLAN to this WiFi network.

To turn on the landing page feature, toggle the `Advanced` switch to `Manual` and check the `Hotspot Portal` option. Click on the `Hotspot Portal` link in the information panel to configure the landing page.

Under the `Authentication` panel, specify the authentication methods to be supported. In my setup, I enabled only the `Password` option, and set a secure yet easily memorable password. This password can be changed at any time.

You can view connection history in the `Hotspot Manager` main panel. You can also access the landing page settings by selecting `Landing Page` from the dropdown menu at the top of the page.

### Setting Up WiFi Speed Limits

You can effectively control the bandwidth usage of each WiFi network by implementing speed limits. This ensures that secondary WiFi networks do not monopolize bandwidth at the expense of your primary network's performance.

To configure WiFi speed limits, begin by navigating to the `Settings` main panel and selecting `Profiles`. From there, navigate to `WiFi Speed Limit` at the top of the page. Click on `Create New`, assign a name to the profile, and specify the desired bandwidth limits. You can create multiple profiles tailored to different requirements.

Next, return to the `Settings` main panel and select `WiFi`. Choose the network you wish to configure, then toggle the `Advanced` switch to `Manual`. Check the box labeled `WiFi Speed Limit`, and from the dropdown menu that appears, select the appropriate profile you previously created. This ensures that the specified speed limits are applied to the selected network.

### Configuring a Scheduler

Automating the pause of a WiFi network at designated times on specific weekdays is also possible.

To set this up, access the settings of the desired WiFi network. Switch the `Advanced` toggle to `Manual`, then activate the `WiFi Scheduler` by toggling it to `On`. Use the weekly calendar to establish the intervals when the network will be paused.

This functionality proves invaluable for implementing scheduled breaks in WiFi access, especially for managing children's usage. For this purpose, simply add an additional WiFi network specifically for your children. Keep it using the `Default` network settings but configure the schedule accordingly. Then click on `Apply Changes`.

## Setting up Wired Devices

When you have IoT devices connected via an Ethernet cable, a different approach is needed to configure the VLAN they use. UniFi switches are managed, allowing you to customize the network provided to connected devices.

To begin, navigate to the `Ports` main tab. Select the desired switch from the top dropdown menu. Ensure the second dropdown menu is set to `Ports`. A visual representation of the switch ports will appear. Choose the specific port you wish to configure, then select the desired network from the `Native LAN/Network` dropdown menu. This assigns all devices connected to the port to the corresponding VLAN.

To verify the network used by each device, go to the `Client Devices` main tab and check the `Network` column for each device.

## Conclusions

In summary, UniFi hardware provides robust network management capabilities, including VLAN segmentation, multiple Wi-Fi network configuration, WiFi speed limits, and automated scheduling. These features empower users to optimize network performance, enhance security, and customize network environments to suit their needs. With UniFi hardware, network administration becomes streamlined and efficient, ensuring a seamless experience for users.
