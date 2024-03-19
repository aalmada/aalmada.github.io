---
layout: post
read_time: true
show_date: true
title: "Deploying UniFi Controller on Raspberry Pi with Portainer"
date: 2024-03-19
img_path: /assets/img/posts/20240319
image: Pears.jpg
tags: [network, ubiquiti, unifi, docker, portainer, raspberry pi]
category: network
---

For years, my home network has relied on Ubiquiti UniFi, delivering seamless connectivity across every corner of the house. Its robust suite of features provides exceptional network management tools, ensuring a secure environment with regular software updates. A standout capability is its ability to segregate IoT and guest devices into isolated SSIDs and networks, bolstering overall network security and organization.

Initially, I managed the network using a UniFi Cloud Key—a compact pen-computer with built-in network connectivity. Its seamless integration into the UniFi ecosystem and automatic update feature were advantageous. However, due to its inability to support the latest software versions, I transitioned to hosting the controller software on a Raspberry Pi, avoiding costly upgrades. I began with a Raspberry Pi 3, then progressed to a 4, and now utilize a 5 for enhanced performance and compatibility.

Presently, I employ a Raspberry Pi 5 with 4 GB of RAM, housed in a fanless aluminum case. It operates efficiently, utilizing less than 2% of CPU, around 30% of memory, and consistently maintaining a temperature below 50ºC.

I've also transitioned from directly installing the software on the system to utilizing containers. This method significantly simplifies installation and upgrades, while also enabling the harnessing of processing power by allowing the installation of multiple applications without conflicts.

In this post, I'll walk you through the installation and configuration of all the necessary components.

## Installing the Raspberry Pi OS

To begin, we'll need to install the operating system on the SD card intended for the Raspberry Pi.

For this process, I recommend having the following applications installed on your computer:

- [SD Card Formatter](https://www.sdcard.org/downloads/formatter/)
- [Raspberry Pi Imager](https://www.raspberrypi.com/software/)

Now, insert the SD card into the card slot of your computer or into a card reader connected to your computer. Utilize the SD Card Formatter application to format the card, then launch the Raspberry Pi Imager application.

Select the **Raspberry Pi Device** type, specifying the model accordingly (e.g., **Raspberry Pi 5**). For the **Operating System**, choose **Raspberry Pi OS (other)**, and then opt for **Raspberry Pi OS Lite (64 bit)**. Since we won't require a user interface, the lite version suffices. Next, select your SD card for storage.

Click **Next**, and in the **Use OS customizations?** prompt, click **EDIT SETTINGS**. Enable the checkboxes for **Set hostname** and **Set username and password**, and input the desired credentials.

If you intend to connect the Raspberry Pi to your Wi-Fi network, tick the box for **Configure wireless LAN**, and provide the necessary information.

Enable the checkbox for **Set locale settings**, and select your timezone. As we won't be attaching a keyboard directly to the Raspberry Pi, choose the desired **Keyboard layout**.

After configuring the settings, click **Save**, and then confirm the settings usage by clicking **Yes**.

Proceed by clicking **Yes** to confirm the installation of the operating system on the SD card. This process may take several minutes for installation and validation.

Once completed, eject the SD card from the reader and insert it into the Raspberry Pi. Connect the network and power cables, and switch on the unit (Raspberry Pi 5 features a power switch).

## Installing Docker and Portainer

For streamlined container installation and management, I recommend using Portainer, which requires Docker to be installed. To proceed, follow the instructions outlined in this separate [tutorial for Docker installation](https://pimylifeup.com/raspberry-pi-docker/), followed by this additional [tutorial for Portainer installation](https://pimylifeup.com/raspberry-pi-portainer/).

Once both Docker and Portainer are installed, you can access the Portainer web interface from your computer by navigating to `http://<IPADDRESS>:9000`, where `<IPADDRESS>` should be replaced with the IP address of your Raspberry Pi. If unsure of the IP address, you can use [Angry IP Scanner](https://angryip.org/download/) to find it.

Upon accessing the web interface, you should see a **local** environment listed, featuring the Docker logo. Click on the **Live connect** button to manage this environment.

## Installing UniFi Controller

To install UniFi Controller via Portainer, we'll set up and deploy a container. We'll leverage the convenience of Portainer's stack feature for better container management. For this demonstration, I'll be utilizing a pre-configured setup available at [jacobalberty/unifi-docker](https://github.com/jacobalberty/unifi-docker).

Begin by navigating to the **Stacks** option within the **local** environment in Portainer. Click on **Add stack** to initiate the process. Provide a name for the stack, such as `unifi-controller`, and keep the **Build method** set as **Web editor**. Then, paste the following configuration into the **Web editor** field:

```yaml
version: "3.8"

services:
  unifi:
    user: unifi
    image: ghcr.io/jacobalberty/unifi-docker
    container_name: unifi-controller
    restart: unless-stopped
    ports:
      - "8080:8080"
      - "8443:8443"
      - "8880:8880"
      - "3478:3478/udp"
      - "10001:10001/udp"
    environment:
      TZ: ${TZ}
    volumes:
      - ./data:/unifi
```

Click on the **Add environment variable** button. Set the **name** to `TZ` and input your local time-zone identifier as the **value**. You can find the appropriate values in the **TZ identifier** column of the Wikipedia page titled [List of tz database time zones](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones).

Once the configuration is set, click **Deploy the stack**. The deployment process may take a few minutes to complete.

Once completed, the controller web interface will be available at `https://<IPADDRESS>:8443`, where `<IPADDRESS>` should be replaced with the IP address of your Raspberry Pi. There you can reconfigure the controller using a backup of an preexisting controller. Otherwise; login or create and account and configure the controller from scratch.

Once you configure the controller, don't forget to assign a static address to the Raspberry Pi to avoid it changing address under the new configuration. To do this, go to the **Client Devices**, press on the line containing the Raspberry Pi info, press the cog wheel **Settings** button and check the **Fix IP Address** option. 

## Installing Glances

Monitoring the system's health is crucial, and installing a monitoring application facilitates easy access to vital metrics such as CPU and memory usage, as well as hardware temperature. For this purpose, I recommend using [Glances](https://nicolargo.github.io/glances/).

Once again, Portainer simplifies the installation process. We'll utilize a pre-configured setup available at [nicolargo/glances](https://github.com/nicolargo/glances).

Navigate back to the **Stacks** option within the **local** environment in Portainer. Click on **Add stack** to begin. Provide a name for the stack, such as `glances`, and keep the **Build method** set as **Web editor**. Then, paste the following configuration into the **Web editor** field:

```yaml
version: "3"

services:
  glances:
    container_name: glances

    image: nicolargo/glances:latest

    ports:
      - 7300:61208

    environment:
      - TZ=${TZ} 
      - GLANCES_OPT=-w # run as a web server

    pid: host

    restart: unless-stopped

    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro 
```

Click on the **Add environment variable** button. Set the **name** to `TZ` and input your local time-zone identifier as the **value**. You can find the appropriate values in the **TZ identifier** column of the Wikipedia page titled [List of tz database time zones](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones).

Once the configuration is set, click **Deploy the stack**. The deployment process may take a few minutes to complete.

Upon completion, the Glances web interface will be accessible at `http://<IPADDRESS>:7300`, where `<IPADDRESS>` should be replaced with the IP address of your Raspberry Pi.

## Conclusion

I trust you'll find this tutorial valuable. It provides a practical method for setting up your UniFi controller, practicing container deployment, and utilizing your Raspberry Pi as a server.
