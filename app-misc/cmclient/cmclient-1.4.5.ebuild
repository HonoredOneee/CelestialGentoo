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

	# Set executable permission
	fperms +x /opt/CMCLIENT/cmlauncher

	# Create main wrapper script with GPU stall fixes
	exeinto /usr/bin
	newexe - cmclient <<'EOF'
#!/bin/sh
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

# Advanced compatibility flags for AMD Cedar and old GPUs
# These flags specifically address GPU stall issues with ReadPixels
COMPATIBILITY_FLAGS="--no-sandbox --disable-gpu --disable-gpu-sandbox --disable-software-rasterizer --disable-dev-shm-usage"
WEBGL_FIXES="--disable-webgl --disable-webgl2 --disable-accelerated-2d-canvas --disable-accelerated-video-decode --disable-accelerated-video-encode --disable-accelerated-mjpeg-decode"
GPU_STALL_FIXES="--disable-gpu-rasterization --disable-partial-raster --disable-gl-drawing-for-tests"
PERFORMANCE_FLAGS="--disable-background-timer-throttling --disable-backgrounding-occluded-windows --disable-renderer-backgrounding --disable-features=VizDisplayCompositor --max-old-space-size=2048"

# Display server detection
if [ -n "$WAYLAND_DISPLAY" ]; then
    DISPLAY_FLAGS="--enable-features=UseOzonePlatform --ozone-platform=wayland --enable-wayland-ime"
elif [ -n "$DISPLAY" ]; then
    DISPLAY_FLAGS="--enable-features=UseOzonePlatform --ozone-platform=x11"
else
    DISPLAY_FLAGS=""
fi

exec /opt/CMCLIENT/cmlauncher $COMPATIBILITY_FLAGS $WEBGL_FIXES $GPU_STALL_FIXES $PERFORMANCE_FLAGS $DISPLAY_FLAGS "$@"
EOF

	# Enhanced debug launcher with verbose logging
	exeinto /usr/bin
	newexe - cmclient-debug <<'EOF'
#!/bin/sh
echo "=== CMClient Debug Mode ==="
echo "System Information:"
echo "  OS: $(uname -sr)"
echo "  Desktop: ${XDG_SESSION_TYPE:-unknown}"
echo "  Wayland: ${WAYLAND_DISPLAY:-none}"
echo "  X11: ${DISPLAY:-none}"

if command -v glxinfo >/dev/null 2>&1; then
    echo "  GPU: $(glxinfo 2>/dev/null | grep 'OpenGL renderer' | cut -d':' -f2 | sed 's/^[[:space:]]*//' || echo 'Unknown')"
fi

echo ""
echo "Java versions available:"
for java_cmd in java /usr/lib/jvm/*/bin/java; do
    if [ -x "$java_cmd" ]; then
        echo "  $($java_cmd -version 2>&1 | head -n1)"
    fi
done
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

echo "Launching with debug flags..."
exec /opt/CMCLIENT/cmlauncher \
	--no-sandbox \
	--disable-gpu \
	--disable-webgl \
	--disable-webgl2 \
	--disable-accelerated-2d-canvas \
	--disable-dev-shm-usage \
	--enable-logging \
	--log-level=0 \
	--v=2 \
	"$@"
EOF

	# Ultra-minimal launcher for severe compatibility issues
	exeinto /usr/bin
	newexe - cmclient-minimal <<'EOF'
#!/bin/sh
echo "CMClient Minimal Mode - Maximum compatibility for problematic systems"

mkdir -p "${HOME}/.local/share/.minecraft/cmclient"
mkdir -p "${HOME}/.config/cmclient"

CONFIG_DIR="${HOME}/.local/share/.minecraft/cmclient"
SHARED_JSON="${CONFIG_DIR}/shared.json"

if [ ! -f "${SHARED_JSON}" ]; then
    echo '{}' > "${SHARED_JSON}"
    chmod 600 "${SHARED_JSON}"
fi

pkill -f "cmclient|cmlauncher" 2>/dev/null || true
sleep 2

echo "Using absolute minimal flags..."
exec /opt/CMCLIENT/cmlauncher \
	--no-sandbox \
	--disable-gpu \
	--disable-dev-shm-usage \
	--disable-extensions \
	--disable-plugins \
	--disable-web-security \
	--single-process \
	"$@"
EOF

	# GPU acceleration test launcher
	exeinto /usr/bin
	newexe - cmclient-gpu-test <<'EOF'
#!/bin/sh
echo "CMClient GPU Test Mode - Attempting hardware acceleration"
echo "WARNING: This may cause GPU stalls on older hardware"

mkdir -p "${HOME}/.local/share/.minecraft/cmclient"
mkdir -p "${HOME}/.config/cmclient"

CONFIG_DIR="${HOME}/.local/share/.minecraft/cmclient"
SHARED_JSON="${CONFIG_DIR}/shared.json"

if [ ! -f "${SHARED_JSON}" ]; then
    echo '{}' > "${SHARED_JSON}"
    chmod 600 "${SHARED_JSON}"
fi

pkill -f "cmclient|cmlauncher" 2>/dev/null || true

if [ -n "$WAYLAND_DISPLAY" ]; then
    DISPLAY_FLAGS="--enable-features=UseOzonePlatform --ozone-platform=wayland"
elif [ -n "$DISPLAY" ]; then
    DISPLAY_FLAGS="--enable-features=UseOzonePlatform --ozone-platform=x11"
else
    DISPLAY_FLAGS=""
fi

echo "Testing with GPU acceleration enabled..."
exec /opt/CMCLIENT/cmlauncher \
	--no-sandbox \
	--ignore-gpu-blacklist \
	--enable-gpu-rasterization \
	--enable-accelerated-2d-canvas \
	--disable-dev-shm-usage \
	$DISPLAY_FLAGS \
	"$@"
EOF

	# Configuration reset utility
	exeinto /usr/bin
	newexe - cmclient-reset <<'EOF'
#!/bin/sh
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

	# Install icons
	local iconpath="${WORKDIR}/usr/share/icons/hicolor"
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

	# Create desktop entry
	make_desktop_entry \
		"cmclient" \
		"CMClient" \
		"cmclient" \
		"Game;Network;Communication;" \
		"Comment=Minecraft Client Launcher\nGenericName=Minecraft Launcher\nStartupNotify=true\nStartupWMClass=cmclient\nMimeType=application/x-minecraft-launcher;\nKeywords=Minecraft;Game;Launcher;"

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
	elog "CMClient has been successfully installed with GPU compatibility fixes!"
	elog ""
	elog "Available launchers:"
	elog "  cmclient              - Main launcher (GPU stall fixes applied)"
	elog "  cmclient-debug        - Debug mode with verbose logging"
	elog "  cmclient-minimal      - Ultra-minimal for severe compatibility issues"
	elog "  cmclient-gpu-test     - Test hardware acceleration (may cause issues)"
	elog "  cmclient-reset        - Reset all configuration and cached data"
	elog ""
	elog "Configuration files:"
	elog "  ~/.local/share/.minecraft/cmclient/shared.json"
	elog "  ~/.config/cmclient/"
	elog ""
	elog "Troubleshooting guide:"
	elog "1. If CMClient loads indefinitely or shows GPU stalls:"
	elog "   → The main launcher now includes fixes for this issue"
	elog "   → If problems persist, try: cmclient-minimal"
	elog ""
	elog "2. If you need detailed error information:"
	elog "   → Use: cmclient-debug"
	elog ""
	elog "3. If settings become corrupted:"
	elog "   → Use: cmclient-reset"
	elog ""
	elog "4. If you have a newer GPU and want to test acceleration:"
	elog "   → Use: cmclient-gpu-test (not recommended for AMD Cedar series)"
	elog ""
	elog "5. Check Java installation:"
	elog "   → Ensure Java 8, 11, 17, or 21 is installed"
	elog "   → Test with: java -version"
	elog ""
	elog "Hardware compatibility:"
	elog "  ✓ Optimized for AMD Cedar series (Radeon HD 5000/6000/7000/8000)"
	elog "  ✓ Works with software rendering"
	elog "  ✓ Wayland and X11 support"
	elog ""
	elog "For more information visit: https://cm-pack.pl/download"
}

pkg_postrm() {
	xdg_icon_cache_update
}