# Copyright 1999-2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit desktop xdg-utils

DESCRIPTION="CMClient - Minecraft Client Launcher"
HOMEPAGE="https://cm-pack.pl"
SRC_URI="https://cdn.cmclient.pl/launcher/linux/CMCLIENT-Linux-${PV}.deb"

LICENSE="all-rights-reserved"
SLOT="0"
KEYWORDS="~amd64"
IUSE=""
RESTRICT="mirror bindist"

RDEPEND="
	dev-libs/nss
	dev-libs/atk
	app-accessibility/at-spi2-atk
	x11-libs/gtk+:3
	media-libs/alsa-lib
	media-libs/mesa
	x11-libs/libdrm
	x11-libs/libxkbcommon
"

DEPEND="${RDEPEND}"
BDEPEND="dev-vcs/git-lfs"

S="${WORKDIR}"

src_unpack() {
	ar x "${DISTDIR}/CMCLIENT-Linux-${PV}.deb" || die "Failed to extract .deb"
	tar -xf data.tar.* || die "Failed to extract data.tar.*"
}

src_install() {
	# Install application files
	insinto /opt/CMCLIENT
	doins -r opt/CMCLIENT/* || die "Failed to install files to /opt/CMCLIENT"

	# Set executable permission for all binaries in the directory
	find "${D}/opt/CMCLIENT" -type f -executable -exec chmod +x {} \; 2>/dev/null || true
	fperms +x /opt/CMCLIENT/cmlauncher

	# Create main wrapper script (WITHOUT compatibility flags)
	exeinto /usr/bin
	newexe - cmclient <<'EOF'
#!/bin/bash
set -e

# Create required directories
mkdir -p "${HOME}/.local/share/.minecraft/cmclient"
mkdir -p "${HOME}/.config/cmclient"

CONFIG_DIR="${HOME}/.local/share/.minecraft/cmclient"
SHARED_JSON="${CONFIG_DIR}/shared.json"

if [ ! -f "${SHARED_JSON}" ]; then
    echo '{}' > "${SHARED_JSON}"
    chmod 600 "${SHARED_JSON}"
fi

# Kill any hung processes first
pkill -f "cmclient|cmlauncher" 2>/dev/null || true
sleep 1

# Check if binary exists and is executable
if [ ! -x "/opt/CMCLIENT/cmlauncher" ]; then
    echo "ERROR: /opt/CMCLIENT/cmlauncher not found or not executable" >&2
    exit 1
fi

# Display server detection (only display flags, no compatibility flags)
if [ -n "$WAYLAND_DISPLAY" ]; then
    DISPLAY_FLAGS="--enable-features=UseOzonePlatform --ozone-platform=wayland"
elif [ -n "$DISPLAY" ]; then
    DISPLAY_FLAGS="--enable-features=UseOzonePlatform --ozone-platform=x11"
else
    DISPLAY_FLAGS=""
fi

# Set library path to ensure all dependencies are found
export LD_LIBRARY_PATH="/opt/CMCLIENT:${LD_LIBRARY_PATH}"

# Execute with error handling (NO COMPATIBILITY FLAGS)
exec /opt/CMCLIENT/cmlauncher $DISPLAY_FLAGS "$@" 2>&1 || {
    echo "ERROR: CMClient launcher failed to start" >&2
    echo "Try running 'cmclient-debug' for more information" >&2
    exit 1
}
EOF

	# Create Shw wrapper script (with --disable-gpu for Wayland)
	exeinto /usr/bin
	newexe - cmclient-Shw <<'EOF'
#!/bin/bash
set -e

# Create required directories
mkdir -p "${HOME}/.local/share/.minecraft/cmclient"
mkdir -p "${HOME}/.config/cmclient"

CONFIG_DIR="${HOME}/.local/share/.minecraft/cmclient"
SHARED_JSON="${CONFIG_DIR}/shared.json"

if [ ! -f "${SHARED_JSON}" ]; then
    echo '{}' > "${SHARED_JSON}"
    chmod 600 "${SHARED_JSON}"
fi

# Kill any hung processes first
pkill -f "cmclient|cmlauncher" 2>/dev/null || true
sleep 1

# Check if binary exists and is executable
if [ ! -x "/opt/CMCLIENT/cmlauncher" ]; then
    echo "ERROR: /opt/CMCLIENT/cmlauncher not found or not executable" >&2
    exit 1
fi

# Display server detection (with --disable-gpu for Wayland)
if [ -n "$WAYLAND_DISPLAY" ]; then
    DISPLAY_FLAGS="--enable-features=UseOzonePlatform --ozone-platform=wayland --disable-gpu"
elif [ -n "$DISPLAY" ]; then
    DISPLAY_FLAGS="--enable-features=UseOzonePlatform --ozone-platform=x11"
else
    DISPLAY_FLAGS="--disable-gpu"
fi

# Set library path to ensure all dependencies are found
export LD_LIBRARY_PATH="/opt/CMCLIENT:${LD_LIBRARY_PATH}"

# Execute with error handling
exec /opt/CMCLIENT/cmlauncher $DISPLAY_FLAGS "$@" 2>&1 || {
    echo "ERROR: CMClient launcher failed to start" >&2
    echo "Try running 'cmclient-debug' for more information" >&2
    exit 1
}
EOF

	# Enhanced debug launcher (unchanged)
	exeinto /usr/bin
	newexe - cmclient-debug <<'EOF'
#!/bin/bash
set -e

echo "=== CMClient Debug Mode ==="
echo "System Information:"
echo "  OS: $(uname -sr)"
echo "  Desktop: ${XDG_SESSION_TYPE:-unknown}"
echo "  Wayland: ${WAYLAND_DISPLAY:-none}"
echo "  X11: ${DISPLAY:-none}"

# Check CMClient binary
echo ""
echo "CMClient Binary Information:"
if [ -f "/opt/CMCLIENT/cmlauncher" ]; then
    echo "  Binary exists: YES"
    if [ -x "/opt/CMCLIENT/cmlauncher" ]; then
        echo "  Executable: YES"
    else
        echo "  Executable: NO - This is the problem!"
        echo "  Run: sudo chmod +x /opt/CMCLIENT/cmlauncher"
        exit 1
    fi
    echo "  File info: $(ls -la /opt/CMCLIENT/cmlauncher)"
else
    echo "  Binary exists: NO - CMClient not properly installed!"
    exit 1
fi

echo ""
echo "Dependency Check:"
if ldd /opt/CMCLIENT/cmlauncher 2>/dev/null | grep "not found"; then
    echo "  Status: MISSING DEPENDENCIES - Install missing libraries above"
    exit 1
else
    echo "  Status: All dependencies found"
fi

echo ""
mkdir -p "${HOME}/.local/share/.minecraft/cmclient"
mkdir -p "${HOME}/.config/cmclient"

CONFIG_DIR="${HOME}/.local/share/.minecraft/cmclient"
SHARED_JSON="${CONFIG_DIR}/shared.json"

if [ ! -f "${SHARED_JSON}" ]; then
    echo '{}' > "${SHARED_JSON}"
    chmod 600 "${SHARED_JSON}"
fi

pkill -f "cmclient|cmlauncher" 2>/dev/null || true
sleep 1

echo "Launching without compatibility flags (basic mode)..."
export LD_LIBRARY_PATH="/opt/CMCLIENT:${LD_LIBRARY_PATH}"

# Launch with minimal flags - no --no-sandbox, --disable-gpu, --disable-dev-shm-usage
/opt/CMCLIENT/cmlauncher \
	--enable-logging \
	--log-level=0 \
	--v=2 \
	"$@" || {
	echo ""
	echo "ERROR: CMClient failed to start!"
	echo "Exit code: $?"
	exit 1
}
EOF

	# Configuration reset utility (unchanged)
	exeinto /usr/bin
	newexe - cmclient-reset <<'EOF'
#!/bin/bash
echo "CMClient Configuration Reset Utility"
echo "This will delete all CMClient settings and cached data."
echo ""
read -p "Continue? [y/N]: " confirm

case $confirm in
    [yY]|[yY][eE][sS])
        echo "Stopping CMClient processes..."
        pkill -f "cmclient|cmlauncher" 2>/dev/null || true
        sleep 2
        
        echo "Removing configuration directories..."
        rm -rf "${HOME}/.local/share/.minecraft/cmclient"
        rm -rf "${HOME}/.config/cmclient"
        
        echo "Recreating clean configuration..."
        mkdir -p "${HOME}/.local/share/.minecraft/cmclient"
        mkdir -p "${HOME}/.config/cmclient"
        echo '{}' > "${HOME}/.local/share/.minecraft/cmclient/shared.json"
        chmod 600 "${HOME}/.local/share/.minecraft/cmclient/shared.json"
        
        echo "Configuration reset complete!"
        echo "You can now launch CMClient normally."
        ;;
    *)
        echo "Reset cancelled."
        ;;
esac
EOF

	# Install icons with proper error handling
	local iconpath="${WORKDIR}/usr/share/icons/hicolor"
	if [[ -d "${iconpath}" ]]; then
		for size in 16 22 24 32 48 64 96 128 256; do
			local src_icon="${iconpath}/${size}x${size}/apps/cmlauncher.png"
			if [[ -f "${src_icon}" ]]; then
				insinto /usr/share/icons/hicolor/${size}x${size}/apps
				newins "${src_icon}" cmclient.png
			fi
		done

		# Fallback icon for pixmaps
		if [[ -f "${iconpath}/256x256/apps/cmlauncher.png" ]]; then
			insinto /usr/share/pixmaps
			newins "${iconpath}/256x256/apps/cmlauncher.png" cmclient.png
		fi
	else
		ewarn "Icon directory not found in package"
	fi

	# Create desktop entry for main launcher
	make_desktop_entry \
		"cmclient" \
		"CMClient" \
		"cmclient" \
		"Game;Network;Communication;" \
		"Comment=Minecraft Client Launcher\nGenericName=Minecraft Launcher\nStartupNotify=true\nStartupWMClass=cmclient\nMimeType=application/x-minecraft-launcher;\nKeywords=Minecraft;Game;Launcher;"

	# Create desktop entry for Shw launcher
	make_desktop_entry \
		"cmclient-Shw" \
		"CMClient (Software Rendering)" \
		"cmclient" \
		"Game;Network;Communication;" \
		"Comment=Minecraft Client Launcher - Software Rendering Mode\nGenericName=Minecraft Launcher Software\nStartupNotify=true\nNoDisplay=false;"

	# Create desktop entry for debug mode
	make_desktop_entry \
		"cmclient-debug" \
		"CMClient (Debug)" \
		"cmclient" \
		"Game;Network;Communication;" \
		"Comment=Minecraft Client Launcher - Debug Mode\nGenericName=Minecraft Launcher Debug\nStartupNotify=true\nNoDisplay=false;"
}

pkg_postinst() {
	xdg_icon_cache_update
	
	# Check if installation was successful
	if [[ ! -f "${EROOT}/opt/CMCLIENT/cmlauncher" ]]; then
		eerror "CMClient binary not found after installation!"
		eerror "This indicates a problem with the package extraction."
		return 1
	fi
	
	if [[ ! -x "${EROOT}/opt/CMCLIENT/cmlauncher" ]]; then
		ewarn "Setting executable permissions on CMClient binary..."
		chmod +x "${EROOT}/opt/CMCLIENT/cmlauncher"
	fi
	
	elog "CMClient has been successfully installed!"
	elog ""
	elog "Available launchers:"
	elog "  cmclient              - Main launcher (no compatibility flags)"
	elog "  cmclient-Shw          - Software rendering mode (Wayland with --disable-gpu)"
	elog "  cmclient-debug        - Debug mode with diagnostics"
	elog "  cmclient-reset        - Reset configuration"
	elog ""
	elog "First run recommendation:"
	elog "  Run 'cmclient-debug' first to verify installation"
	elog ""
	elog "Configuration files:"
	elog "  ~/.local/share/.minecraft/cmclient/shared.json"
	elog "  ~/.config/cmclient/"
	elog ""
	elog "NOTE: Use 'cmclient-Shw' for systems where Wayland GPU acceleration is problematic."
	elog "For more information visit: https://cm-pack.pl/download"
}

pkg_postrm() {
	xdg_icon_cache_update
}