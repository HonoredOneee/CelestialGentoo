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

	# Ensure UI directory exists
	mkdir -p "${S}/ui" || die
}

src_install() {
	python_domodule gufw

	# Install UI files - CORREÇÃO CRÍTICA
	if [[ -d "${S}/gufw/view/ui" ]]; then
		insinto /usr/share/gufw/ui
		doins "${S}"/gufw/view/ui/*.ui
	elif [[ -d "${S}/ui" ]]; then
		insinto /usr/share/gufw/ui
		doins "${S}"/ui/*.ui
	else
		ewarn "UI directory not found! Falling back to manual file copy"
		insinto /usr/share/gufw/ui
		newins "${S}"/gufw/view/gufw.ui gufw.ui
	fi

	# Create launcher script
	cat > "${T}/gufw-launcher" <<-EOF || die
	#!/usr/bin/env python3
	import sys
	import os
	import subprocess

	def main():
	    print("GUFW Launcher - Starting...")
	    try:
	        # Try direct import first
	        from gufw.gufw import main as gufw_main
	        print("Found main module, starting GUFW")
	        gufw_main()
	    except ImportError as e:
	        print(f"Import error: {e}")
	        print("Attempting alternative startup method...")
	        # Fallback to module execution
	        try:
	            subprocess.run([sys.executable, "-m", "gufw"], check=True)
	        except subprocess.CalledProcessError as e:
	            print(f"Failed to start GUFW: {e}")
	            sys.exit(1)

	if __name__ == '__main__':
	    main()
	EOF

	python_newscript "${T}/gufw-launcher" gufw

	# Install supporting files
	dobin bin/gufw-pkexec
	
	# Install desktop file - verifica múltiplas localizações
	if [[ -f data/gufw.desktop ]]; then
		domenu data/gufw.desktop
	elif [[ -f gufw.desktop ]]; then
		domenu gufw.desktop
	elif [[ -f setup.py ]]; then
		# Extrai do setup.py se necessário
		sed -n '/Desktop Entry/,/^$/p' setup.py > "${T}/gufw.desktop"
		domenu "${T}/gufw.desktop"
	fi

	# Install icons - com verificações
	if [[ -d data/icons ]]; then
		for size in 16 22 24 32 48 64 128 256; do
			if [[ -f "data/icons/gufw_${size}.png" ]]; then
				newicon -s ${size} "data/icons/gufw_${size}.png" gufw.png
			fi
		done
		if [[ -f data/icons/gufw.svg ]]; then
			newicon -s scalable data/icons/gufw.svg gufw.svg
		fi
	fi

	# Install translations se existirem
	if [[ -d build/mo ]]; then
		insinto /usr/share/locale
		doins -r build/mo/*
	else
		ewarn "Translation files not found, skipping"
	fi

	# Install policy file
	if [[ -f data/gufw.policy ]]; then
		insinto /usr/share/polkit-1/actions
		doins data/gufw.policy
	fi

	# Install documentation
	if [[ -f data/gufw.1 ]]; then
		doman data/gufw.1
	fi
	dodoc README* CONTRIBUTING* CHANGELOG*
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
	elog ""
	elog "If you encounter issues:"
	elog "1. Verify UI files are installed:"
	elog "   ls /usr/share/gufw/ui/"
	elog "2. Check launcher script:"
	elog "   cat /usr/bin/gufw"
	elog "3. Test direct launch:"
	elog "   python -m gufw"
}

pkg_postrm() {
	xdg_desktop_database_update
	xdg_icon_cache_update
}