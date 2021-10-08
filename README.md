# Traefik VM
Traefik VM targets to be drop-in replacement for Citrix ADC [Content Switching](https://docs.citrix.com/en-us/citrix-adc/current-release/content-switching.html) in legacy/non-containerized environments.

It is designed to be paired with Firewall which provides virtual IP for multiple Traefik VMs with automatic failover.


Features:
* Minimal footprint (image size only 309 MB)
* Traefik running on chroot
* [Read-only rootfs with tmpfs overlay](https://wiki.alpinelinux.org/wiki/Raspberry_Pi#Loopback_image_with_overlayfs) (all modifications will be discarded at shutdown)

TODO:
* Run Traefik as non-root (needs chroot binary replacement as busybox version does not support run as)
* Centralized log server, etc

**NOTE!!!** This project is currently on early draft phase.

# Idea
## Pictures

Illustration of Traefik VMs running on DMZ:

![alt text](https://github.com/olljanat/traefik-vm/raw/main/pics/traefik-vm.png "Traefik VM network")


Traefik VM get IP from DHCP and start Traefik instead of normal Linux console.

![alt text](https://github.com/olljanat/traefik-vm/raw/main/pics/boot.png "Traefik VM booted")


