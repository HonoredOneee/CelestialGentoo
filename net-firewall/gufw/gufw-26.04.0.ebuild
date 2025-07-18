# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PYTHON_COMPAT=( python3_{9..12} )

inherit python-single-r1 desktop xdg-utils

DESCRIPTION="Uncomplicated Firewall GUI"
HOMEPAGE="https://gufw.org/ https://github.com/costales/gufw"
SRC_URI="https://github.com/HonoredOneee/CelestialGentoo/releases/download/v1.4.5/gui-ufw-${PV}.tar.gz"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="~amd64"
RESTRICT="mirror"

REQUIRED_USE="${PYTHON_REQUIRED_USE}"

RDEPEND="${PYTHON_DEPS}
	$(python_gen_cond_dep '
		dev-python/pygobject:3[${PYTHON_USEDEP}]
		dev-python/python-distutils-extra[${PYTHON_USEDEP}]
	')
	net-firewall/ufw
	x11-libs/gtk+:3[introspection]
	gnome-base/librsvg:2[introspection]
	x11-libs/gdk-pixbuf:2[introspection]
	dev-libs/glib:2[introspection]
	sys-auth/polkit"

DEPEND="${RDEPEND}"

BDEPEND="
	sys-devel/gettext
	virtual/pkgconfig"

S="${WORKDIR}/gui-ufw-${PV}"

src_prepare() {
	default

	# Fix desktop file
	sed -i \
		-e 's/^Categories=.*/Categories=System;Security;/' \
		-e '/^Icon=/s/gufw/gufw/' \
		setup.py || die "sed failed for setup.py"

	# Fix pkexec script paths
	sed -i \
		-e "s|/usr/share/gufw|${EPREFIX}/usr/share/gufw|g" \
		-e "s|/usr/bin/gufw|${EPREFIX}/usr/bin/gufw|g" \
		bin/gufw-pkexec || die "sed failed for gufw-pkexec"
}

src_compile() {
	# Compile translations
	for po in po/*.po; do
		lang=$(basename "${po}" .po)
		mkdir -p "build/mo/${lang}/LC_MESSAGES" || die
		msgfmt "${po}" -o "build/mo/${lang}/LC_MESSAGES/gufw.mo" || die
	done
}

src_install() {
	python_domodule gufw

	# Install UI files
	insinto /usr/share/gufw/ui
	doins ui/*.ui

	# Create launcher script
	cat > "${T}/gufw-launcher" <<-EOF || die
	#!/usr/bin/env python3
	import sys
	import os
	import subprocess
	import importlib.util

	def main():
	    print("GUFW Launcher - Starting...")
	    try:
	        from gufw.gufw import main as gufw_main
	        print("Found main module, starting GUFW")
	        gufw_main()
	    except ImportError as e:
	        print(f"Import error: {e}")
	        print("Attempting alternative startup method...")
	        os.execlp("python3", "python3", "-m", "gufw")

	if __name__ == '__main__':
	    main()
	EOF

	python_newscript "${T}/gufw-launcher" gufw

	# Install supporting files
	dobin bin/gufw-pkexec
	domenu data/gufw.desktop

	# Install icons
	for size in 16 22 24 32 48 64 128 256; do
		newicon -s ${size} "data/icons/gufw_${size}.png" gufw.png
	done
	newicon -s scalable data/icons/gufw.svg gufw.svg

	# Install translations
	insinto /usr/share/locale
	doins -r build/mo/*

	# Install policy file
	insinto /usr/share/polkit-1/actions
	doins data/gufw.policy

	# Install documentation
	doman data/gufw.1
	dodoc README*
}

pkg_postinst() {
	xdg_desktop_database_update
	xdg_icon_cache_update

	elog "GUFW requires UFW to be enabled and running:"
	elog "1. Enable UFW service:"
	elog "   # systemctl enable ufw"
	elog "2. Start UFW:"
	elog "   # systemctl start ufw"
	elog "3. Enable firewall:"
	elog "   # ufw enable"
	elog "4. Check status:"
	elog "   # ufw status verbose"
	elog ""
	elog "Note: Ensure your user is in the 'wheel' group for authentication."
}

pkg_postrm() {
	xdg_desktop_database_update
	xdg_icon_cache_update
}