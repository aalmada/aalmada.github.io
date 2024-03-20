---
layout: post
read_time: true
show_date: true
title: "Deploying a recursive DNS server on Raspberry Pi with Portainer"
date: 2024-03-20
img_path: /assets/img/posts/20240320
image: CaisDoSodre.jpg
tags: [network, dns, docker, portainer, raspberry pi, pi-hole, unbound]
category: network
---

[Pi-hole](https://pi-hole.net/) is well known for its ad-blocking capabilities but it actually provides an additional layer of control over DNS requests within your home network. It can be installed on a device within your home network and function as a DNS server.

Pi-hole offers the option to configure it as a [recursive DNS server](https://docs.pi-hole.net/guides/dns/unbound/), which enhances the security and privacy of your internet browsing history. This functionality requires the utilization of [Unbound](https://nlnetlabs.nl/projects/unbound/about/), which supports [DNS-over-TLS](https://tools.ietf.org/html/rfc7858) and [DNS-over-HTTPS](https://tools.ietf.org/html/rfc8484), enabling clients to encrypt their communications. Furthermore, Unbound supports various modern standards, such as [Query Name Minimization](https://tools.ietf.org/html/rfc9156), [Aggressive Use of DNSSEC-Validated Cache](https://tools.ietf.org/html/rfc8198), and authority zones, which optimize privacy and bolster DNS robustness.

I've configured Pi-hole and Unbound on a [Raspberry Pi 5](https://www.raspberrypi.com/products/) running [Portainer](https://www.portainer.io/), facilitating multiple servers to coexist on the same device without software conflicts. For detailed instructions on setting up these components, please refer to my [previous article](https://aalmada.github.io/posts/Unifi-controller-on-raspberry-pi/).

## Setting Up Pi-hole and Unbound

To install Pi-hole and Unbound using Portainer, we'll deploy a container and utilize Portainer's stack feature for efficient container management. For this guide, I'll be using a pre-configured setup from [chriscrowe/docker-pihole-unbound](https://github.com/chriscrowe/docker-pihole-unbound/tree/main/one-container), which combines Pi-hole and Unbound as documented in the [official Pi-hole documentation](https://docs.pi-hole.net/guides/dns/unbound/).

Open the Portainer web interface on your web browser by navigating to `http://<IPADDRESS>:9000`, replacing `<IPADDRESS>` with the Raspberry Pi's IP address. If you're unsure of the IP address, you can use [Angry IP Scanner](https://angryip.org/download/) to find it.

To begin, open the Portainer web interface and go to **Stacks** within the **local** environment. Click **Add stack** to start the setup. Name the stack (e.g., `pihole-unbound`) and keep the **Build method** as **Web editor**. Then, paste the provided configuration into the **Web editor** field:

```yaml
version: '3.0'

volumes:
  etc_pihole-unbound:
  etc_pihole_dnsmasq-unbound:

services:
  pihole:
    container_name: pihole
    image: cbcrowe/pihole-unbound:latest
    hostname: ${HOSTNAME}
    domainname: ${DOMAIN_NAME}
    ports:
      - 443:443/tcp
      - 53:53/tcp
      - 53:53/udp
      - ${PIHOLE_WEBPORT:-80}:80/tcp
    environment:
      - FTLCONF_LOCAL_IPV4=${FTLCONF_LOCAL_IPV4}
      - TZ=${TZ:-UTC}
      - WEBPASSWORD=${WEBPASSWORD}
      - WEBTHEME=${WEBTHEME:-default-light}
      - REV_SERVER=${REV_SERVER:-false}
      - REV_SERVER_TARGET=${REV_SERVER_TARGET}
      - REV_SERVER_DOMAIN=${REV_SERVER_DOMAIN}
      - REV_SERVER_CIDR=${REV_SERVER_CIDR}
      - PIHOLE_DNS_=127.0.0.1#5335
      - DNSSEC="true"
      - DNSMASQ_LISTENING=single
    volumes:
      - etc_pihole-unbound:/etc/pihole:rw
      - etc_pihole_dnsmasq-unbound:/etc/dnsmasq.d:rw
    restart: unless-stopped
```

This configuration utilizes environment variables. Click **Add environment variable** to create the following variables:

- `TZ` - Set your local time-zone identifier.
- `FTLCONF_LOCAL_IPV4` - Set to the IP address of the Raspberry Pi.
- `PIHOLE_WEBPORT` - Choose a port number for the Pi-hole web interface.
- `WEBPASSWORD` - Set the password for the web interface. If not set, a random password will be generated which will be found in the Portainer logs.

Once configured, click **Deploy the stack**. The deployment may take a few minutes.

After deployment, access the web interface at `http://<IPADDRESS>:<PORT>`, replacing `<IPADDRESS>` with the Raspberry Pi's IP address and `<PORT>` with the chosen port number.

In the Pi-hole web interface, navigate to the **Settings** option in the left menu and then proceed to the **DNS** tab. Here, you'll find Pi-hole utilizing the custom upstream DNS server 127.0.0.1#5335, where Unbound is hosted. Additionally, notice that the **Use DNSSEC** checkbox is selected.

The **Conditional forwarding** settings can be configured on the same webpage or as Portainer environment variables. Refer to the list of supported variables and values [here](https://github.com/chriscrowe/docker-pihole-unbound/tree/main/one-container#pi-hole-environment-variables).

To utilize Pi-hole solely as a recursive DNS server, access the **Adlist** section from the left menu and deactivate the default adlist. Conversely, if you intend to utilize it as an ad-blocker, keep the default adlist enabled. You also have the option to include additional lists as desired.

## Configuring Pi-hole as a DNS Server

To utilize Pi-hole as the DNS server for your devices, you'll need to adjust their network settings accordingly. The simplest method is to configure the network gateway, ensuring that all devices on the network automatically use Pi-hole.

In my setup, I employ a UniFi gateway. I log in to the UniFi Controller, navigate to **Settings**, and then select **Internet**. Under the list of available internet connections, I choose **Primary (WAN1)**. Within the internet connection settings, I toggle the **Advanced** option to **Manual**. In the **IPv4 Configuration**, I deselect the **Auto** box for **DNS Server**. For the **Primary Server**, I input the IP address of the device hosting Pi-hole.

If you wish to extend this setup to devices outside your network, you can always establish a VPN connection to access it.

## Conclusion

Pi-hole extends beyond its traditional ad-blocking functionality, providing substantial improvements to the security and privacy of your home network. Portainer simplifies the process of installing multiple servers on a single device, eliminating concerns about software conflicts.

I hope you've found this tutorial useful.


