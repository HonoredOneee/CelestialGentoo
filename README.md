# CelestialGentoo

**CelestialGentoo** is a community-driven Gentoo overlay focused on providing cutting-edge packages and optimizations for enthusiasts and power users.

## About

This repository contains ebuilds for software that's only available in other package formats, bringing them to Gentoo users:

**Featured Packages:**
- **cmclient** - Connection Manager client (originally DEB-only)
- **womic** - Wireless microphone application (originally AppImage-only)

**Categories:**
- Network management tools and utilities
- Audio/multimedia applications and drivers
- System administration tools
- Development utilities and frameworks
- Gaming-related packages and optimizations
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
# Connection Manager client
sudo emerge cmclient

# Wireless microphone application
sudo emerge womic
```

## Contributing

Contributions are welcome! Please:
- Follow Gentoo packaging standards
- Test ebuilds thoroughly before submitting
- Include proper metadata and documentation
- Submit pull requests with clear descriptions

## Maintainer

- **HonoredOneee** - Primary maintainer and developer

## License

This repository is licensed under the GPL-2, following Gentoo's licensing standards.

---

*CelestialGentoo - Elevating your Gentoo experience to new heights*
