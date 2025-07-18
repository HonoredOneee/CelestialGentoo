# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PYTHON_COMPAT=( python3_{9..12} )
# Corrigido: removido PYTHON_REQ_USE="xml"

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
	virtual/pkgconfig
	dev-vcs/git-lfs"

S="${WORKDIR}/gufw-${PV}"

src_prepare() {
	default

	# Fix desktop file
	sed -i \
		-e 's/^Categories=.*/Categories=System;Security;/' \
		-e '/^Icon=/s/gufw/gufw/' \
		setup.py || die

	# Remove hardcoded paths
	sed -i \
		-e "s|/usr/share/gufw|${EPREFIX}/usr/share/gufw|g" \
		-e "s|/usr/bin/gufw|${EPREFIX}/usr/bin/gufw|g" \
		bin/gufw-pkexec || die
}

src_compile() {
	# Compile translations
	for po in po/*.po; do
		lang=$(basename "$po" .po)
		mkdir -p "build/mo/$lang/LC_MESSAGES" || die
		msgfmt "$po" -o "build/mo/$lang/LC_MESSAGES/gufw.mo" || die
	done
}

src_install() {
	python_domodule gufw

	python_newscript bin/gufw gufw
	python_newscript bin/gufw-pkexec gufw-pkexec

	# Install desktop file
	domenu data/gufw.desktop

	# Install icons
	local size
	for size in 16 22 24 32 48 64 128 256; do
		newicon -s ${size} data/icons/gufw_${size}.png gufw.png
	done

	# Install scalable icon
	newicon -s scalable data/icons/gufw.svg gufw.svg

	# Install translations
	insinto /usr/share/locale
	doins -r build/mo/*

	# Install polkit policy
	insinto /usr/share/polkit-1/actions
	doins data/gufw.policy

	# Install man page
	doman data/gufw.1

	# Install documentation
	dodoc README.md
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
}

pkg_postrm() {
	xdg_desktop_database_update
	xdg_icon_cache_update
}
