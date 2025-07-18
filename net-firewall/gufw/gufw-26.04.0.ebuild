# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PYTHON_COMPAT=( python3_{9..12} )
DISTUTILS_USE_PEP517=setuptools

inherit distutils-r1 desktop xdg

DESCRIPTION="Uncomplicated Firewall GUI"
HOMEPAGE="https://gufw.org/ https://github.com/costales/gufw"
SRC_URI="https://github.com/costales/gufw/archive/refs/tags/${PV%.*}.tar.gz -> ${P}.tar.gz"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="~amd64"

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

S="${WORKDIR}/${PN}-${PV%.*}"

python_prepare_all() {
	# Create custom desktop file that runs with pkexec
	cat > data/gufw.desktop << 'EOF'
[Desktop Entry]
Version=1.0
Type=Application
Name=Firewall Configuration
Name[pt_BR]=Configuração do Firewall
Comment=Configure the built-in firewall
Comment[pt_BR]=Configure o firewall integrado
GenericName=Firewall Configuration
GenericName[pt_BR]=Configuração do Firewall
Icon=gufw
Exec=pkexec env DISPLAY=$DISPLAY XAUTHORITY=$XAUTHORITY XDG_RUNTIME_DIR=$XDG_RUNTIME_DIR python3 /usr/share/gufw/gufw/gufw.py
Terminal=false
StartupNotify=true
Categories=System;Security;
Keywords=firewall;security;ufw;iptables;network;
EOF
	
	# Fix pkexec script - this is critical for the syntax error
	if [[ -f bin/gufw-pkexec ]]; then
		# Create a proper pkexec script
		cat > bin/gufw-pkexec << 'EOF'
#!/bin/bash
pkexec python3 /usr/share/gufw/gufw/gufw.py "$@"
EOF
		chmod +x bin/gufw-pkexec || die
	fi
	
	# Create app_profiles directory if it doesn't exist in the source
	if [[ ! -d data/app_profiles ]]; then
		mkdir -p data/app_profiles || die
		
		# Create some basic app profile files
		cat > data/app_profiles/apache.profile << 'EOF'
[Apache]
ports=80/tcp,443/tcp
title=Apache Web Server
description=Apache HTTP Server - allows HTTP and HTTPS traffic
EOF

		cat > data/app_profiles/ssh.profile << 'EOF'
[SSH]
ports=22/tcp
title=OpenSSH
description=Secure Shell - allows SSH connections
EOF

		cat > data/app_profiles/ftp.profile << 'EOF'
[FTP]
ports=21/tcp
title=FTP Server
description=File Transfer Protocol server
EOF

		cat > data/app_profiles/dns.profile << 'EOF'
[DNS]
ports=53/tcp,53/udp
title=DNS Server
description=Domain Name System server
EOF

		cat > data/app_profiles/mail.profile << 'EOF'
[Mail]
ports=25/tcp,110/tcp,143/tcp,465/tcp,587/tcp,993/tcp,995/tcp
title=Mail Server
description=Email server (SMTP, POP3, IMAP)
EOF

		cat > data/app_profiles/samba.profile << 'EOF'
[Samba]
ports=137/udp,138/udp,139/tcp,445/tcp
title=Samba
description=SMB/CIFS file sharing
EOF

		cat > data/app_profiles/nfs.profile << 'EOF'
[NFS]
ports=111/tcp,111/udp,2049/tcp,2049/udp
title=NFS
description=Network File System
EOF

		cat > data/app_profiles/mysql.profile << 'EOF'
[MySQL]
ports=3306/tcp
title=MySQL Database
description=MySQL database server
EOF

		cat > data/app_profiles/postgresql.profile << 'EOF'
[PostgreSQL]
ports=5432/tcp
title=PostgreSQL Database
description=PostgreSQL database server
EOF

		cat > data/app_profiles/vnc.profile << 'EOF'
[VNC]
ports=5900/tcp
title=VNC Server
description=Virtual Network Computing remote desktop
EOF
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
	
	# Create a proper launcher script that works with pkexec
	cat > "${T}/gufw-launcher" << 'EOF'
#!/usr/bin/env python3
import sys
import os
import subprocess

def main():
    """Main launcher for GUFW with proper privilege handling"""
    
    # Check if we're running as root (via pkexec)
    if os.geteuid() == 0:
        # Running as root, proceed with GUFW
        run_gufw()
    else:
        # Not running as root, try to run with pkexec
        try:
            # Preserve X11 environment variables for GUI applications
            env = os.environ.copy()
            
            # Build pkexec command with environment preservation
            cmd = [
                'pkexec',
                '--disable-internal-agent',
                'env',
                f'DISPLAY={env.get("DISPLAY", ":0")}',
                f'XAUTHORITY={env.get("XAUTHORITY", "")}',
                f'XDG_RUNTIME_DIR={env.get("XDG_RUNTIME_DIR", "")}',
                f'XDG_SESSION_TYPE={env.get("XDG_SESSION_TYPE", "")}',
                f'WAYLAND_DISPLAY={env.get("WAYLAND_DISPLAY", "")}',
                sys.executable,
                __file__
            ] + sys.argv[1:]
            
            # Remove empty environment variables
            cmd = [arg for arg in cmd if not arg.endswith('=')]
            
            subprocess.run(cmd)
            return
        except FileNotFoundError:
            print("Error: pkexec not found. Please install polkit.")
            sys.exit(1)
        except Exception as e:
            print(f"Error running with pkexec: {e}")
            print("Trying to run without elevated privileges...")
            run_gufw()

def run_gufw():
    """Run GUFW using various methods"""
    
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
	
	# Create an alternative wrapper script for pkexec
	cat > "${T}/gufw-pkexec-wrapper" << 'EOF'
#!/bin/bash

# Preserve X11 environment variables for GUI applications
export DISPLAY="${DISPLAY:-:0}"
export XAUTHORITY="${XAUTHORITY}"
export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR}"
export XDG_SESSION_TYPE="${XDG_SESSION_TYPE}"
export WAYLAND_DISPLAY="${WAYLAND_DISPLAY}"

# Run GUFW with preserved environment
exec python3 /usr/share/gufw/gufw/gufw.py "$@"
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
	
	# CRITICAL: Install app_profiles directory to /etc/gufw/
	# This is what was missing and causing the FileNotFoundError
	if [[ -d data/app_profiles ]]; then
		insinto /etc/gufw
		doins -r data/app_profiles
	fi
	
	# Create the main gufw config directory
	keepdir /etc/gufw
	
	# Install desktop file (always use our custom one)
	domenu data/gufw.desktop
	
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
	
	# Install polkit policy file
	cat > "${T}/com.ubuntu.pkexec.gufw.policy" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE policyconfig PUBLIC
 "-//freedesktop//DTD PolicyKit Policy Configuration 1.0//EN"
 "http://www.freedesktop.org/standards/PolicyKit/1/policyconfig.dtd">
<policyconfig>
  <vendor>GUFW</vendor>
  <vendor_url>https://gufw.org/</vendor_url>
  <action id="com.ubuntu.pkexec.gufw">
    <description>Run GUFW Firewall Configuration</description>
    <description xml:lang="pt_BR">Executar Configuração do Firewall GUFW</description>
    <message>Authentication is required to run GUFW</message>
    <message xml:lang="pt_BR">Autenticação é necessária para executar o GUFW</message>
    <icon_name>gufw</icon_name>
    <defaults>
      <allow_any>no</allow_any>
      <allow_inactive>no</allow_inactive>
      <allow_active>auth_admin_keep</allow_active>
    </defaults>
    <annotate key="org.freedesktop.policykit.exec.path">/usr/share/gufw/gufw/gufw.py</annotate>
    <annotate key="org.freedesktop.policykit.exec.allow_gui">true</annotate>
    <annotate key="org.freedesktop.policykit.exec.argv1">--</annotate>
  </action>
</policyconfig>
EOF
	
	insinto /usr/share/polkit-1/actions
	doins "${T}/com.ubuntu.pkexec.gufw.policy"
	
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
	elog "   gufw (will automatically request administrator privileges)"
	elog "   (or search for 'Firewall Configuration' in your application menu)"
	elog ""
	elog "9. DESKTOP INTEGRATION:"
	elog "   The desktop file now automatically runs GUFW with pkexec"
	elog "   You'll see an authentication dialog when clicking the icon"
	elog ""
	elog "═══════════════════════════════════════════════════════════════════"
	elog "                         IMPORTANT NOTES"
	elog "═══════════════════════════════════════════════════════════════════"
	elog ""
	ewarn "• UFW MUST be enabled BEFORE using GUFW, or GUFW will show errors"
	ewarn "• Always allow SSH access before enabling UFW on remote systems"
	ewarn "• Test firewall rules carefully to avoid locking yourself out"
	elog ""
	elog "FIXED IN THIS VERSION:"
	elog "• Added missing /etc/gufw/app_profiles directory"
	elog "• Created basic application profiles for common services"
	elog "• Fixed FileNotFoundError when starting GUFW"
	elog "• Desktop file now automatically runs with administrator privileges"
	elog "• Added proper PolicyKit integration for GUI authentication"
	elog "• Now using official GUFW source repository"
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