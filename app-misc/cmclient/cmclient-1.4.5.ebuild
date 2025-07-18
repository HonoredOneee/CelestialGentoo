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

	# Create wrapper script in /usr/bin
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

# Base flags for better compatibility
BASE_FLAGS="--no-sandbox --disable-gpu-sandbox --disable-software-rasterizer"

# Detect display server and set appropriate flags
if [ -n "$WAYLAND_DISPLAY" ]; then
    DISPLAY_FLAGS="--enable-features=UseOzonePlatform --ozone-platform=wayland --enable-wayland-ime"
elif [ -n "$DISPLAY" ]; then
    DISPLAY_FLAGS="--enable-features=UseOzonePlatform --ozone-platform=x11"
else
    DISPLAY_FLAGS=""
fi

# Input and keyboard flags for macro support
INPUT_FLAGS="--disable-features=VizDisplayCompositor --enable-features=WebRTCPipeWireCapturer"

exec /opt/CMCLIENT/cmlauncher $BASE_FLAGS $DISPLAY_FLAGS $INPUT_FLAGS "$@"
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

	# Create alternative launcher for troubleshooting
	exeinto /usr/bin
	newexe - cmclient-debug <<'EOF'
#!/bin/sh
echo "CMClient Debug Mode"
echo "Display Server: ${XDG_SESSION_TYPE:-unknown}"
echo "Wayland Display: ${WAYLAND_DISPLAY:-none}"
echo "X11 Display: ${DISPLAY:-none}"
echo ""

exec /opt/CMCLIENT/cmlauncher \
	--no-sandbox \
	--disable-gpu \
	--disable-software-rasterizer \
	--enable-logging \
	--v=1 \
	"$@"
EOF
}

pkg_postinst() {
	xdg_icon_cache_update
	elog "CMClient has been successfully installed!"
	elog ""
	elog "Configuration saved in:"
	elog "  ~/.local/share/.minecraft/cmclient/shared.json"
	elog ""
	elog "Usage:"
	elog "  cmclient           - Normal launcher"
	elog "  cmclient-debug     - Debug mode with verbose logging"
	elog ""
	elog "If macros/shortcuts don't work, try:"
	elog "  - Make sure your desktop environment supports global shortcuts"
	elog "  - Check if the application has focus when using macros"
	elog "  - Use cmclient-debug to see detailed error messages"
	elog ""
	elog "If the icon doesn't appear, try:"
	elog "  gtk-update-icon-cache /usr/share/icons/hicolor"
	elog ""
	elog "For graphics issues, ensure you have proper drivers:"
	elog "  - AMD: emerge -av mesa"
	elog "  - NVIDIA: emerge -av nvidia-drivers"
	elog ""
	elog "Documentation and downloads:"
	elog "  https://cm-pack.pl/download"
}

pkg_postrm() {
	xdg_icon_cache_update
}