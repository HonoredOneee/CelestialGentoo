# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PYTHON_COMPAT=( python3_{9..12} )
DISTUTILS_USE_PEP517=setuptools

inherit distutils-r1 desktop xdg

DESCRIPTION="Uncomplicated Firewall GUI"
HOMEPAGE="https://gufw.org/ https://github.com/costales/gufw"
SRC_URI="https://github.com/HonoredOneee/CelestialGentoo/releases/download/v1.4.5/gui-ufw-${PV}.tar.gz"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="~amd64"
RESTRICT="mirror"

RDEPEND="
	${PYTHON_DEPS}
	dev-python/pygobject:3[${PYTHON_USEDEP}]
	net-firewall/ufw
	x11-libs/gtk+:3[introspection]
	gnome-base/librsvg:2[introspection]
	x11-libs/gdk-pixbuf:2[introspection]
	dev-libs/glib:2[introspection]
	sys-auth/polkit
"

DEPEND="${RDEPEND}"
BDEPEND="
	sys-devel/gettext
	virtual/pkgconfig
"

S="${WORKDIR}/gui-ufw-${PV}"

python_prepare_all() {
	# Fix desktop file categories
	if [[ -f data/gufw.desktop.in ]]; then
		sed -i 's/Categories=.*/Categories=System;Security;/' data/gufw.desktop.in || die
	fi
	
	# Fix pkexec script - this is critical for the syntax error
	if [[ -f bin/gufw-pkexec ]]; then
		# Create a proper pkexec script
		cat > bin/gufw-pkexec << 'EOF'
#!/bin/bash
pkexec python3 /usr/share/gufw/gufw/gufw.py "$@"
EOF
		chmod +x bin/gufw-pkexec || die
	fi
	
	distutils-r1_python_prepare_all
}

python_compile_all() {
	# Compile translations
	if [[ -d po ]]; then
		for po in po/*.po; do
			if [[ -f "$po" ]]; then
				local lang=$(basename "$po" .po)
				mkdir -p "build/mo/$lang/LC_MESSAGES" || die
				msgfmt "$po" -o "build/mo/$lang/LC_MESSAGES/gufw.mo" || die
			fi
		done
	fi
	
	# Process desktop file
	if [[ -f data/gufw.desktop.in ]]; then
		mkdir -p build/share/applications || die
		msgfmt --desktop --template=data/gufw.desktop.in \
			-d po -o build/share/applications/gufw.desktop || die
	fi
}

python_install_all() {
	distutils-r1_python_install_all
	
	# Create a proper launcher script
	cat > "${T}/gufw-launcher" << 'EOF'
#!/usr/bin/env python3
import sys
import os
import subprocess

def main():
    """Main launcher for GUFW"""
    
    # Method 1: Try to import and run gufw.gufw directly
    try:
        from gufw.gufw import main as gufw_main
        gufw_main()
        return
    except ImportError:
        pass
    except Exception as e:
        print(f"Error running gufw.gufw.main(): {e}")
    
    # Method 2: Try to run the main script directly
    script_paths = [
        '/usr/share/gufw/gufw/gufw.py',
        '/usr/share/gufw/gufw.py',
        '/usr/lib/python*/site-packages/gufw/gufw.py'
    ]
    
    for script_path in script_paths:
        if os.path.exists(script_path):
            try:
                subprocess.run([sys.executable, script_path] + sys.argv[1:])
                return
            except Exception as e:
                print(f"Error running {script_path}: {e}")
                continue
    
    # Method 3: Try to find gufw.py in the installed package
    try:
        import gufw
        gufw_dir = os.path.dirname(gufw.__file__)
        gufw_script = os.path.join(gufw_dir, 'gufw.py')
        if os.path.exists(gufw_script):
            subprocess.run([sys.executable, gufw_script] + sys.argv[1:])
            return
    except ImportError:
        pass
    except Exception as e:
        print(f"Error finding gufw package: {e}")
    
    # Method 4: Try to run any main function in the gufw module
    try:
        import gufw
        # Look for main functions
        for attr in ['main', 'run', 'start', 'app_main']:
            if hasattr(gufw, attr):
                getattr(gufw, attr)()
                return
    except ImportError:
        pass
    except Exception as e:
        print(f"Error running gufw module function: {e}")
    
    print("Error: Could not find or run GUFW. Please check installation.")
    print("Available methods:")
    print("1. Direct script execution")
    print("2. Module import")
    print("3. Package execution")
    
    # Debug information
    try:
        import gufw
        print(f"GUFW module found at: {gufw.__file__}")
        print(f"GUFW module contents: {dir(gufw)}")
        gufw_dir = os.path.dirname(gufw.__file__)
        print(f"Files in gufw directory: {os.listdir(gufw_dir)}")
    except ImportError:
        print("GUFW module not found in Python path")
    
    sys.exit(1)

if __name__ == '__main__':
    main()
EOF
	
	# Install the launcher script
	python_newscript "${T}/gufw-launcher" gufw
	
	# Install UI files - this is the critical part that was missing
	if [[ -d data/ui ]]; then
		insinto /usr/share/gufw/ui
		doins data/ui/*
	fi
	
	# Install other data files
	if [[ -d data ]]; then
		insinto /usr/share/gufw
		doins -r data/*
	fi
	
	# Install the actual gufw module files to /usr/share/gufw/ as well
	if [[ -d gufw ]]; then
		insinto /usr/share/gufw
		doins -r gufw
	fi
	
	# Install desktop file
	if [[ -f build/share/applications/gufw.desktop ]]; then
		domenu build/share/applications/gufw.desktop
	elif [[ -f data/gufw.desktop ]]; then
		domenu data/gufw.desktop
	fi
	
	# Install icons
	local size
	for size in 16 22 24 32 48 64 128 256; do
		if [[ -f "data/icons/gufw-${size}.png" ]]; then
			newicon -s ${size} "data/icons/gufw-${size}.png" gufw.png
		elif [[ -f "data/icons/gufw_${size}.png" ]]; then
			newicon -s ${size} "data/icons/gufw_${size}.png" gufw.png
		fi
	done
	
	# Install scalable icon
	if [[ -f data/icons/gufw.svg ]]; then
		newicon -s scalable data/icons/gufw.svg gufw.svg
	fi
	
	# Install polkit policy
	if [[ -f data/gufw.policy ]]; then
		insinto /usr/share/polkit-1/actions
		newins data/gufw.policy com.ubuntu.pkexec.gufw.policy
	elif [[ -f build/share/polkit-1/actions/com.ubuntu.pkexec.gufw.policy ]]; then
		insinto /usr/share/polkit-1/actions
		doins build/share/polkit-1/actions/com.ubuntu.pkexec.gufw.policy
	fi
	
	# Install corrected pkexec script
	if [[ -f bin/gufw-pkexec ]]; then
		dobin bin/gufw-pkexec
	fi
	
	# Install man page
	if [[ -f data/gufw.8 ]]; then
		doman data/gufw.8
	elif [[ -f build/share/man/man8/gufw.8 ]]; then
		doman build/share/man/man8/gufw.8
	fi
	
	# Install translations
	if [[ -d build/mo ]]; then
		insinto /usr/share/locale
		doins -r build/mo/*
	fi
	
	# Install documentation
	if [[ -f README.md ]]; then
		dodoc README.md
	elif [[ -f README ]]; then
		dodoc README
	fi
	
	if [[ -f CHANGELOG ]]; then
		dodoc CHANGELOG
	fi
}

pkg_postinst() {
	xdg_pkg_postinst
	
	elog "═══════════════════════════════════════════════════════════════════"
	elog "                    GUFW POST-INSTALLATION SETUP"
	elog "═══════════════════════════════════════════════════════════════════"
	elog ""
	elog "GUFW has been successfully installed!"
	elog ""
	elog "REQUIRED SETUP STEPS:"
	elog ""
	elog "1. INSTALL UFW (if not already installed):"
	elog "   emerge net-firewall/ufw"
	elog ""
	elog "2. ENABLE UFW SERVICE:"
	elog "   sudo systemctl enable ufw"
	elog "   sudo systemctl start ufw"
	elog ""
	elog "3. IMPORTANT - ALLOW SSH BEFORE ENABLING UFW:"
	elog "   sudo ufw allow ssh"
	elog "   (This prevents being locked out of remote systems)"
	elog ""
	elog "4. ENABLE UFW FIREWALL:"
	elog "   sudo ufw enable"
	elog ""
	elog "5. VERIFY UFW STATUS:"
	elog "   sudo ufw status verbose"
	elog ""
	elog "6. ADD USER TO WHEEL GROUP (for polkit authentication):"
	elog "   sudo usermod -a -G wheel \$USER"
	elog "   (logout and login again after this)"
	elog ""
	elog "7. VERIFY POLKIT SERVICE:"
	elog "   sudo systemctl status polkit"
	elog "   (if not running: sudo systemctl enable polkit && sudo systemctl start polkit)"
	elog ""
	elog "8. LAUNCH GUFW:"
	elog "   gufw"
	elog "   (or search for 'Firewall Configuration' in your application menu)"
	elog ""
	elog "═══════════════════════════════════════════════════════════════════"
	elog "                         IMPORTANT NOTES"
	elog "═══════════════════════════════════════════════════════════════════"
	elog ""
	ewarn "• UFW MUST be enabled BEFORE using GUFW, or GUFW will show errors"
	ewarn "• Always allow SSH access before enabling UFW on remote systems"
	ewarn "• Test firewall rules carefully to avoid locking yourself out"
	elog ""
	elog "TROUBLESHOOTING:"
	elog "• If authentication fails: check if user is in 'wheel' group"
	elog "• If UFW commands fail: verify UFW service is running"
	elog "• If UI doesn't load: check /usr/share/gufw/ui/ directory exists"
	elog "• For debugging: run 'gufw' in terminal to see error messages"
	elog ""
	elog "USEFUL UFW COMMANDS:"
	elog "• sudo ufw status verbose    - Show current firewall status"
	elog "• sudo ufw allow 22/tcp      - Allow SSH"
	elog "• sudo ufw allow 80/tcp      - Allow HTTP"
	elog "• sudo ufw allow 443/tcp     - Allow HTTPS"
	elog "• sudo ufw reload            - Reload firewall rules"
	elog "• sudo ufw reset             - Reset all rules (use with caution)"
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
	xdg_pkg_postrm
}