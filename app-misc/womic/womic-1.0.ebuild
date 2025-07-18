# Copyright 2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DESCRIPTION="WO Mic Client (AppImage - terminal only)"
HOMEPAGE="https://wolicheng.com/womic/wo_mic_linux.html"
SRC_URI="https://github.com/HonoredOneee/CelestialGentoo/releases/download/v${PV}/micclient-x86_64.AppImage"

LICENSE="all-rights-reserved"
SLOT="0"
KEYWORDS="~amd64"
RESTRICT="mirror bindist strip"

RDEPEND="
	sys-fs/fuse:0
	media-libs/alsa-lib
"

DEPEND="${RDEPEND}"
BDEPEND=""

S="${WORKDIR}"

src_unpack() {
	: # Nada a descompactar - AppImage é usado diretamente
}

src_install() {
	# Instala o AppImage em /opt/womic
	insinto /opt/womic
	doins "${DISTDIR}/micclient-x86_64.AppImage"
	fperms +x /opt/womic/micclient-x86_64.AppImage

	# Cria atalho global em /usr/bin
	dosym /opt/womic/micclient-x86_64.AppImage /usr/bin/womic
}

pkg_postinst() {
	elog "WO Mic foi instalado com sucesso!"
	elog ""
	elog "Para usar o WO Mic:"
	elog "  1. Execute 'womic' no terminal"
	elog "  2. Instale o app WO Mic no seu telefone"
	elog "  3. Configure a conexão (WiFi, USB ou Bluetooth)"
	elog ""
	elog "Documentação: https://wolicheng.com/womic/wo_mic_linux.html"
}
