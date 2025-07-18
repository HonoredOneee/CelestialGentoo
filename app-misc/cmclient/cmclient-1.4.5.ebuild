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
RESTRICT="mirror bindist"

RDEPEND="
	dev-libs/nss
	dev-libs/atk
	app-accessibility/at-spi2-atk
	x11-libs/gtk+:3
	media-libs/alsa-lib
"

DEPEND="${RDEPEND}"
BDEPEND="dev-vcs/git-lfs"

S="${WORKDIR}"

src_unpack() {
	ar x "${DISTDIR}/CMCLIENT-Linux-${PV}.deb" || die "Falha ao extrair .deb"
	tar -xf data.tar.* || die "Falha ao extrair data.tar.*"
}

src_install() {
	# Instalar os arquivos do aplicativo
	insinto /opt/CMCLIENT
	doins -r opt/CMCLIENT/* || die "Falha ao instalar arquivos em /opt/CMCLIENT"

	# Permissão de execução
	fperms +x /opt/CMCLIENT/cmlauncher

	# Criar wrapper em /usr/bin
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

exec /opt/CMCLIENT/cmlauncher "$@"
EOF

	# Ícones
	local iconpath="${WORKDIR}/usr/share/icons/hicolor"
	for size in 16 22 24 32 48 64 96 128 256; do
		local src_icon="${iconpath}/${size}x${size}/apps/cmlauncher.png"
		if [[ -f "${src_icon}" ]]; then
			insinto /usr/share/icons/hicolor/${size}x${size}/apps
			newins "${src_icon}" cmclient.png
		fi
	done

	# Fallback para pixmaps
	if [[ -f "${iconpath}/256x256/apps/cmlauncher.png" ]]; then
		insinto /usr/share/pixmaps
		newins "${iconpath}/256x256/apps/cmlauncher.png" cmclient.png
	fi

	# Arquivo .desktop
	insinto /usr/share/applications
	cat > "${D}/usr/share/applications/cmclient.desktop" <<EOF
[Desktop Entry]
Name=CMClient
Comment=Minecraft Client Launcher
GenericName=Minecraft Launcher
Exec=cmclient
Icon=cmclient
Terminal=false
Type=Application
Categories=Game;Network;Communication;
StartupNotify=true
StartupWMClass=cmclient
MimeType=application/x-minecraft-launcher;
Keywords=Minecraft;Game;Launcher;
EOF
}

pkg_postinst() {
	xdg_icon_cache_update
	elog "CMClient foi instalado com sucesso!"
	elog ""
	elog "Configurações salvas em:"
	elog "  ~/.local/share/.minecraft/cmclient/shared.json"
	elog ""
	elog "Se o ícone não aparecer, tente:"
	elog "  gtk-update-icon-cache /usr/share/icons/hicolor"
	elog ""
	elog "Documentação e downloads:"
	elog "  https://cm-pack.pl/download"
}

pkg_postrm() {
	xdg_icon_cache_update
}