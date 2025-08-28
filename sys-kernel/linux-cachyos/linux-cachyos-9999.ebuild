# Copyright 2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit toolchain-funcs

DESCRIPTION="CachyOS Kernel with performance patches"
HOMEPAGE="https://github.com/CachyOS/linux-cachyos"
SRC_URI="https://github.com/CachyOS/linux-cachyos/archive/refs/tags/${PV}.tar.gz -> ${P}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64"
IUSE="+initramfs"

DEPEND="
	sys-apps/kmod
	sys-apps/util-linux
	dev-util/pahole
	sys-kernel/linux-firmware
	net-misc/curl
"
RDEPEND="${DEPEND}
	sys-boot/grub
	sys-kernel/dracut
"

# Nome do kernel (será atualizado em pkg_setup)
CACHYOS_VERSION=""

pkg_setup() {
	# Obter versão mais recente automaticamente
	einfo "Buscando versão mais recente do kernel CachyOS..."
	CACHYOS_VERSION=$(curl -s https://api.github.com/repos/CachyOS/linux-cachyos/releases/latest | grep -oP '"tag_name": "\K([^"]+)' | head -1)

	# Verificar se conseguiu obter a versão
	if [[ -z "${CACHYOS_VERSION}" ]]; then
		ewarn "Falha ao obter a versão mais recente do GitHub. Usando versão do ebuild: ${PV}"
		CACHYOS_VERSION="${PV}"
	else
		einfo "Versão mais recente encontrada: ${CACHYOS_VERSION}"
	fi
}

src_unpack() {
	# Se a versão foi obtida com sucesso, baixar o tarball correto
	if [[ "${CACHYOS_VERSION}" != "${PV}" ]]; then
		einfo "Baixando versão ${CACHYOS_VERSION}..."
		curl -L "https://github.com/CachyOS/linux-cachyos/archive/refs/tags/${CACHYOS_VERSION}.tar.gz" -o "${P}.tar.gz" || die
	fi

	default
}

src_prepare() {
	default

	# Usa a config atual se existir
	if [[ -f /usr/src/linux/.config ]] ; then
		cp /usr/src/linux/.config .config || die
		emake olddefconfig
	else
		emake defconfig
	fi
}

src_compile() {
	tc-export CC
	emake -j"$(makeopts_jobs)"
}

src_install() {
	# Instala módulos
	emake INSTALL_MOD_PATH="${D}" modules_install

	# Nome amigável no /boot
	local KNAME="linux-cachyos-${CACHYOS_VERSION}"
	insinto /boot
	newins arch/x86/boot/bzImage vmlinuz-${KNAME}
	newins .config config-${KNAME}
	newins System.map System.map-${KNAME}

	# Headers (para compilação de módulos externos)
	emake INSTALL_HDR_PATH="${D}/usr" headers_install
}

pkg_postinst() {
	elog "Kernel CachyOS ${CACHYOS_VERSION} instalado com sucesso!"
	elog ""

	if use initramfs; then
		elog "Gerando initramfs com dracut..."
		local KNAME="linux-cachyos-${CACHYOS_VERSION}"

		if command -v dracut &>/dev/null; then
			dracut --kver "${CACHYOS_VERSION}" --force "/boot/initramfs-${KNAME}.img" || ewarn "Falha ao gerar initramfs"
		else
			ewarn "Dracut não encontrado! Initramfs não foi gerado."
		fi
	fi

	elog ""
	elog "Arquivos instalados:"
	elog "  /boot/vmlinuz-${KNAME}"
	elog "  /boot/config-${KNAME}"
	elog "  /boot/System.map-${KNAME}"

	if use initramfs; then
		elog "  /boot/initramfs-${KNAME}.img"
	fi

	elog ""
	elog "Atualize seu bootloader:"
	elog "  grub-mkconfig -o /boot/grub/grub.cfg"
}
