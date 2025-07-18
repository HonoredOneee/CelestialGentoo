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

S="${WORKDIR}"

src_unpack() {
	mkdir -p "${S}" || die
	cp "${DISTDIR}/odin4" "${S}/odin4" || die "Falha ao copiar o binário"
}

src_install() {
	dobin "${S}/odin4"
	fperms +x "${ED}/usr/bin/odin4"
	dosym /usr/bin/odin4 /usr/bin/odin

	insinto /usr/share/applications
	cat > "${D}/usr/share/applications/odin.desktop" <<EOF
[Desktop Entry]
Name=OdinV4
Comment=Samsung flash tool via terminal
Exec=odin
Icon=utilities-terminal
Terminal=true
Type=Application
Categories=System;Utility;Development;
EOF
}

pkg_postinst() {
	elog "OdinV4 foi instalado com sucesso!"
	elog "Execute com o comando: odin"
}
