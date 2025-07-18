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

	# Fix desktop file if it exists
	if [[ -f setup.py ]]; then
		sed -i \
			-e 's/^Categories=.*/Categories=System;Security;/' \
			-e '/^Icon=/s/gufw/gufw/' \
			setup.py 2>/dev/null || true
	fi

	# Fix pkexec script paths if it exists
	if [[ -f bin/gufw-pkexec ]]; then
		sed -i \
			-e "s|/usr/share/gufw|${EPREFIX}/usr/share/gufw|g" \
			-e "s|/usr/bin/gufw|${EPREFIX}/usr/bin/gufw|g" \
			bin/gufw-pkexec || die
	fi
}

src_compile() {
	# Compile translations if po directory exists
	if [[ -d po ]]; then
		for po in po/*.po; do
			if [[ -f "$po" ]]; then
				lang=$(basename "$po" .po)
				mkdir -p "build/mo/$lang/LC_MESSAGES" || die
				msgfmt "$po" -o "build/mo/$lang/LC_MESSAGES/gufw.mo" || die
			fi
		done
	else
		einfo "No po directory found, skipping translation compilation"
	fi
}

src_install() {
	# Install Python module
	if [[ -d gufw ]]; then
		python_domodule gufw
	fi

	# Create a proper Python launcher script
	cat > "${T}/gufw-launcher" << EOF
#!/usr/bin/env python3
import sys
import os

# Try to import and run gufw
try:
    from gufw.gufw import main
    if __name__ == '__main__':
        main()
except ImportError as e:
    print(f"Error importing gufw: {e}")
    print("Trying alternative import methods...")
    
    # Try different import paths
    try:
        import gufw
        if hasattr(gufw, 'main'):
            gufw.main()
        else:
            print("gufw module found but no main function")
            sys.exit(1)
    except ImportError:
        try:
            # Try to run as module
            import subprocess
            result = subprocess.run([sys.executable, '-m', 'gufw'], 
                                  capture_output=True, text=True)
            if result.returncode != 0:
                print(f"Error running gufw module: {result.stderr}")
                sys.exit(1)
        except Exception as e:
            print(f"Failed to run gufw: {e}")
            sys.exit(1)
EOF

	# Install the launcher script
	python_newscript "${T}/gufw-launcher" gufw

	# Install pkexec script if it exists
	if [[ -f bin/gufw-pkexec ]]; then
		dobin bin/gufw-pkexec
	fi

	# Install desktop file if it exists
	if [[ -f data/gufw.desktop ]]; then
		domenu data/gufw.desktop
	elif [[ -f gufw.desktop ]]; then
		domenu gufw.desktop
	fi

	# Install icons if they exist
	if [[ -d data/icons ]]; then
		local size
		for size in 16 22 24 32 48 64 128 256; do
			if [[ -f "data/icons/gufw_${size}.png" ]]; then
				newicon -s ${size} "data/icons/gufw_${size}.png" gufw.png
			fi
		done
		
		# Install scalable icon
		if [[ -f data/icons/gufw.svg ]]; then
			newicon -s scalable data/icons/gufw.svg gufw.svg
		fi
	fi

	# Install translations if built
	if [[ -d build/mo ]]; then
		insinto /usr/share/locale
		doins -r build/mo/*
	fi

	# Install polkit policy if it exists
	if [[ -f data/gufw.policy ]]; then
		insinto /usr/share/polkit-1/actions
		doins data/gufw.policy
	fi

	# Install man page if it exists
	if [[ -f data/gufw.1 ]]; then
		doman data/gufw.1
	elif [[ -f gufw.1 ]]; then
		doman gufw.1
	fi

	# Install documentation
	if [[ -f README.md ]]; then
		dodoc README.md
	elif [[ -f README ]]; then
		dodoc README
	fi
}

pkg_postinst() {
	xdg_desktop_database_update
	xdg_icon_cache_update

	ewarn "IMPORTANT: GUFW is a GUI frontend for UFW (Uncomplicated Firewall)."
	ewarn "UFW must be properly configured before using GUFW."
	ewarn ""
	elog "═══════════════════════════════════════════════════════════════════"
	elog "                    GUFW POST-INSTALLATION SETUP"
	elog "═══════════════════════════════════════════════════════════════════"
	elog ""
	elog "1. INSTALL UFW (if not already installed):"
	elog "   emerge net-firewall/ufw"
	elog ""
	elog "2. ENABLE UFW SERVICE:"
	elog "   sudo systemctl enable ufw"
	elog "   sudo systemctl start ufw"
	elog ""
	elog "3. ENABLE UFW FIREWALL:"
	elog "   sudo ufw enable"
	elog ""
	elog "4. CHECK UFW STATUS:"
	elog "   sudo ufw status verbose"
	elog ""
	elog "5. ADD USER TO WHEEL GROUP (for polkit authentication):"
	elog "   sudo usermod -a -G wheel \$USER"
	elog "   (then logout and login again)"
	elog ""
	elog "6. VERIFY POLKIT IS RUNNING:"
	elog "   sudo systemctl status polkit"
	elog "   (if not running: sudo systemctl enable polkit && sudo systemctl start polkit)"
	elog ""
	elog "7. LAUNCH GUFW:"
	elog "   gufw"
	elog "   (or search for 'Firewall Configuration' in your application menu)"
	elog ""
	elog "═══════════════════════════════════════════════════════════════════"
	elog "                         IMPORTANT NOTES"
	elog "═══════════════════════════════════════════════════════════════════"
	ewarn ""
	ewarn "• UFW must be enabled BEFORE using GUFW, or GUFW will show errors"
	ewarn "• If GUFW shows 'Firewall disabled', run: sudo ufw enable"
	ewarn "• For SSH access, allow SSH before enabling UFW: sudo ufw allow ssh"
	ewarn "• Test firewall rules carefully to avoid locking yourself out"
	elog ""
	elog "TROUBLESHOOTING:"
	elog "• If authentication fails: check if user is in 'wheel' group"
	elog "• If UFW commands fail: verify UFW is installed and service is running"
	elog "• For remote servers: ALWAYS allow SSH before enabling UFW!"
	elog ""
	elog "DOCUMENTATION:"
	elog "• GUFW: https://gufw.org/"
	elog "• UFW Guide: https://help.ubuntu.com/community/UFW"
	elog "• Gentoo UFW Wiki: https://wiki.gentoo.org/wiki/Ufw"
	elog "═══════════════════════════════════════════════════════════════════"
	elog ""
	elog "You can now run GUFW by typing: gufw"
	elog ""
}

pkg_postrm() {
	xdg_desktop_database_update
	xdg_icon_cache_update
}