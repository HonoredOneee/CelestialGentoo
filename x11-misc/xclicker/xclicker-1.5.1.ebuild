# Copyright 2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DESCRIPTION="A fast GUI autoclicker for Linux (X11)"
HOMEPAGE="https://github.com/robiot/xclicker"
SRC_URI="https://github.com/robiot/xclicker/archive/refs/tags/v${PV}.tar.gz -> ${P}.tar.gz"
LICENSE="GPL-3+"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE=""

DEPEND="
  dev-libs/glib:2
  x11-libs/gtk+:3
  x11-libs/libX11
  x11-libs/libXi
  x11-libs/libXtst
"
RDEPEND="${DEPEND}"
BDEPEND="
  virtual/pkgconfig
  dev-build/meson
  dev-build/ninja
"

S="${WORKDIR}/${P}"

src_configure() {
  meson setup --prefix=/usr "${S}/build" "${S}"
}

src_compile() {
  meson compile -C "${S}/build"
}

src_install() {
  # Instalar o binário compilado
  dobin "${S}/build/src/xclicker"

  # Criar um arquivo .desktop temporário
  local desktop_file="${T}/xclicker.desktop"
  cat > "${desktop_file}" << EOF
[Desktop Entry]
Name=XClicker
Comment=A fast GUI autoclicker for Linux (X11)
Exec=xclicker
Icon=xclicker
Terminal=false
Type=Application
Categories=Utility;
EOF

  # Instalar o .desktop
  insinto /usr/share/applications
  doins "${desktop_file}"

  # Instalar o ícone, se existir
  if [[ -f "${S}/icon.png" ]]; then
    insinto /usr/share/pixmaps
    newins "${S}/icon.png" xclicker.png
  fi

  # Instalar README
  dodoc "${S}/README.md"
}


pkg_postinst() {
  elog "xclicker instalado com sucesso!"
  elog ""
  elog "Execute com: xclicker"
  elog "Projeto: ${HOMEPAGE}"
}
