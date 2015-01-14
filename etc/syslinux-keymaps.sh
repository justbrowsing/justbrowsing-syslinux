#!/bin/bash

# Contributed for archiso by Gerardo Exequiel Pozzi <vmlinuz386@yahoo.com.ar>

SYSLINUX_DIR=${1?ERROR: needs /path/to/install as first argument}
KBD_MAP_DIR=/usr/share/kbd/keymaps/i386
KEYTAB_LILO=/usr/bin/keytab-lilo
KEYTAB_LILO_UNICODE=./keytab-lilo-unicode

if [[ -x ${KEYTAB_LILO_UNICODE} ]]; then
    sed 's@\(loadkeys -m\)@\1 -u@' ${KEYTAB_LILO} > ${KEYTAB_LILO_UNICODE}
    chmod +x ${KEYTAB_LILO_UNICODE}
fi

gen_syslinux_map_cfg() {
    local _layout=$1
    local _map=$2
    local _unicode=$3

    echo "LABEL ${_map}"
    echo "  MENU LABEL ${_map}"
    echo "  COM32 kbdmap.c32"
    echo "  APPEND kbdmap/${_layout}/${_unicode}/${_map}.ktl"
    echo
}

get_syslinux_lay_cfg() {
    local _layout=$1

    echo "MENU BEGIN ${_layout}_n"
    echo "  MENU LABEL ${_layout}"
    echo "  INCLUDE kbdmap/${_layout}_n.cfg"
    echo "MENU END"
    echo
    echo "MENU BEGIN ${_layout}_u"
    echo "  MENU LABEL ${_layout} (Unicode)"
    echo "  INCLUDE kbdmap/${_layout}_u.cfg"
    echo "MENU END"
    echo
}

for _lay in azerty dvorak qwerty qwertz; do
    mkdir -p ${SYSLINUX_DIR}/kbdmap/${_lay}/{n,u}
    get_syslinux_lay_cfg ${_lay} >> ${SYSLINUX_DIR}/kbdmap/kbdmap.cfg

    for _kbd in ${KBD_MAP_DIR}/${_lay}/*.map.gz; do
        _kbd_map=${_kbd##*/}
        _kbd_map=${_kbd_map%.map.gz}

        _kbd_map_ktl=${_kbd_map//-/_}

        ${KEYTAB_LILO}         ${KBD_MAP_DIR}/qwerty/us.map.gz ${_kbd} > \
            ${SYSLINUX_DIR}/kbdmap/${_lay}/n/${_kbd_map_ktl}.ktl 2> /dev/null
        ${KEYTAB_LILO_UNICODE} ${KBD_MAP_DIR}/qwerty/us.map.gz ${_kbd} > \
            ${SYSLINUX_DIR}/kbdmap/${_lay}/u/${_kbd_map_ktl}.ktl 2> /dev/null


        if [[ -s ${SYSLINUX_DIR}/kbdmap/${_lay}/n/${_kbd_map_ktl}.ktl && \
              -s ${SYSLINUX_DIR}/kbdmap/${_lay}/u/${_kbd_map_ktl}.ktl ]]; then
            if [[ $(md5sum ${SYSLINUX_DIR}/kbdmap/${_lay}/n/${_kbd_map_ktl}.ktl) == \
                  $(md5sum ${SYSLINUX_DIR}/kbdmap/${_lay}/u/${_kbd_map_ktl}.ktl) ]]; then
                rm ${SYSLINUX_DIR}/kbdmap/${_lay}/u/${_kbd_map_ktl}.ktl
            else
                gen_syslinux_map_cfg ${_lay} ${_kbd_map_ktl} u >> ${SYSLINUX_DIR}/kbdmap/${_lay}_u.cfg
            fi
            gen_syslinux_map_cfg ${_lay} ${_kbd_map_ktl} n >> ${SYSLINUX_DIR}/kbdmap/${_lay}_n.cfg
        else
            if [[ -s ${SYSLINUX_DIR}/kbdmap/${_lay}/n/${_kbd_map_ktl}.ktl ]]; then
                gen_syslinux_map_cfg ${_lay} ${_kbd_map_ktl} n >> ${SYSLINUX_DIR}/kbdmap/${_lay}_n.cfg
            else
                rm ${SYSLINUX_DIR}/kbdmap/${_lay}/n/${_kbd_map_ktl}.ktl
            fi
            if [[ -s ${SYSLINUX_DIR}/kbdmap/${_lay}/u/${_kbd_map_ktl}.ktl ]]; then
                gen_syslinux_map_cfg ${_lay} ${_kbd_map_ktl} u >> ${SYSLINUX_DIR}/kbdmap/${_lay}_u.cfg
            else
                rm ${SYSLINUX_DIR}/kbdmap/${_lay}/u/${_kbd_map_ktl}.ktl
            fi
        fi
    done
done
