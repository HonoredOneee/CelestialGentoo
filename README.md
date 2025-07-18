# CelestialGentoo
**CelestialGentoo** is a community-driven Gentoo overlay focused on providing cutting-edge packages and optimizations for enthusiasts and power users.

## About
This repository contains ebuilds for software that's only available in other package formats, bringing them to Gentoo users with proper integration and optimization.

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

**Browse available packages:**
```bash
# List all packages in the overlay
eix --in-overlay celestialgentoo

# Search for specific packages
emerge --search %@celestialgentoo
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
