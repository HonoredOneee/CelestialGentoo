# CelestialGentoo

**CelestialGentoo** is a community-driven Gentoo overlay focused on providing cutting-edge packages and optimizations for enthusiasts and power users.

## About

This repository contains ebuilds for software that's only available in other package formats, bringing them to Gentoo users:

**Featured Packages:**
- **cmclient** - Minecraft launcher (originally DEB-only)
- **womic** - Wireless microphone application (originally AppImage-only)
- **odin4** - OdinV4 Samsung flash tool (terminal only, binary app)
- **gufw** - GUI for Uncomplicated Firewall (AppImage-based, Python)

**Categories:**
- Gaming applications and launchers  
- Audio/multimedia applications and drivers  
- System administration tools  
- Development utilities and frameworks  
- Software converted from DEB, RPM, and AppImage formats  
- Latest upstream versions not yet in the official Gentoo tree  

## Installation

Add the repository using eselect:

```bash
sudo eselect repository add celestialgentoo git https://github.com/HonoredOneee/CelestialGentoo.git
sudo emerge --sync celestialgentoo
```

**Install featured packages:**
```bash
# Minecraft launcher
sudo emerge cmclient

# Wireless microphone application
sudo emerge womic

# OdinV4 Samsung flash tool (terminal)
sudo emerge odin4

# GUI for UFW firewall
sudo emerge gufw

# A fast GUI autoclicker for Linux (X11)
sudo emerge xclicker
```

## Contributing

Contributions are welcome! Please:

- Follow Gentoo packaging standards  
- Test ebuilds thoroughly before submitting  
- Include proper metadata and documentation  
- Submit pull requests with clear descriptions  

## Maintainers

- **HonoredOneee** - Primary maintainer and developer  
- **Davideveloper89** - Contributor and collaborator  

## License

This repository is licensed under the GPL-2, following Gentoo's licensing standards.

---

*CelestialGentoo - Elevating your Gentoo experience to new heights*
