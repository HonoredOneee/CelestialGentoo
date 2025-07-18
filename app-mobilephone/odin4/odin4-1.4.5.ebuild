# Copyright 2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DESCRIPTION="OdinV4 - ferramenta de flash Samsung via terminal"
HOMEPAGE="https://github.com/Adrilaw/OdinV4"
SRC_URI="https://github.com/HonoredOneee/CelestialGentoo/releases/download/v${PV}/odin4"

LICENSE="all-rights-reserved"
SLOT="0"
KEYWORDS="~amd64"
RESTRICT="mirror bindist strip"

RDEPEND="
	dev-libs/libusb
	dev-util/android-tools
	app-arch/unzip
"
DEPEND="${RDEPEND}"
BDEPEND=""

S="${WORKDIR}"

src_unpack() {
	: # Nada a descompactar - binário é usado diretamente
}

src_install() {
	# Instalar o binário em /opt/odin4
	insinto /opt/odin4
	doins "${DISTDIR}/odin4"

	# Corrigir permissões - usar caminho relativo sem ${D}
	fperms +x /opt/odin4/odin4

	# Criar atalhos globais em /usr/bin
	dosym /opt/odin4/odin4 /usr/bin/odin4
	dosym /opt/odin4/odin4 /usr/bin/odin
}

pkg_postinst() {
	elog "OdinV4 foi instalado com sucesso!"
	elog ""
	elog "Para usar o OdinV4:"
	elog "  Execute com o comando: odin4 ou odin"
	elog ""
	elog "Documentação: https://github.com/Adrilaw/OdinV4"
}
