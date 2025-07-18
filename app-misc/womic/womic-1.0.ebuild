# Copyright 2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DESCRIPTION="WO Mic Client (AppImage - terminal only)"
HOMEPAGE="https://wolicheng.com/womic/wo_mic_linux.html"
SRC_URI="mirror://local/micclient-x86_64.AppImage"

LICENSE="all-rights-reserved"
SLOT="0"
KEYWORDS="~amd64"
RESTRICT="mirror bindist strip"

RDEPEND=""

DEPEND="${RDEPEND}"
BDEPEND="dev-vcs/git-lfs"

S="${WORKDIR}"

src_unpack() {
  : # Nada a descompactar
}

src_install() {
  # Instalar o AppImage em /opt/womic
  insinto /opt/womic
  doins "${DISTDIR}/micclient-x86_64.AppImage"
  fperms +x /opt/womic/micclient-x86_64.AppImage

  # Criar atalho global em /usr/bin
  dosym /opt/womic/micclient-x86_64.AppImage /usr/bin/womic
}
