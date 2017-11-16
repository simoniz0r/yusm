#!/bin/bash
# yusm - Yad uAppExplorer Snap Manager - Unofficial app for managing snaps based on uappexplorer.com/snaps

REALPATH="$(readlink -f $0)"
RUNNING_DIR="$(dirname "$REALPATH")" # Find directory script is running from

function snapinstall() {
    if [[ ! "$@" =~ snap:// ]]; then
        exit 1
    fi
    SNAP="$(echo "$@" | cut -f3 -d'/')"
    touch /tmp/yusmsnapinstallstatus
    INSTALL_SIZE=$(snap info $SNAP | grep -m1 'stable:' | tr -d '[:blank:][:alpha:]' | cut -f2 -d')' | cut -f1 -d'-' | cut -f1 -d'.')
    PERCENT=0
    sudo -A snap install "$SNAP" > /tmp/yusmsnapinstallstatus 2>&1 &
    while [ -f "/tmp/yusmsnapinstallstatus" ]; do
        PARTIAL_SIZE=$(du -h -a --max-depth=1 "/var/lib/snapd/snaps/" | grep -wm1 '.*.partial' | tr -d '[:blank:][:alpha:]' | cut -f1 -d'/' | cut -f1 -d'.')
        PERCENT=$((${PARTIAL_SIZE}00/$INSTALL_SIZE))
        if grep -qw 'installed' /tmp/yusmsnapinstallstatus; then
            echo 100
            cat /tmp/yusmsnapinstallstatus
            rm /tmp/yusmsnapinstallstatus
        elif grep -qw '\--classic' /tmp/yusmsnapinstallstatus; then
            echo 0
            echo "Error installing $SNAP!  This revision of snap $SNAP was published using classic confinement and thus may perform arbitrary system changes outside of the security sandbox that snaps are usually confined to, which may put your system at risk.  If you understand and want to proceed, click 'Classic install'."
            rm /tmp/yusmsnapinstallstatus
        else
            if [ $PERCENT -lt 10 ]; then
                echo 1
            elif [ $PERCENT -gt 90 ]; then
                echo 90
            else
                echo "$PERCENT"
            fi
            echo "Installing $SNAP..."
            sleep 0.5
        fi
    done | yad --class="yusm" --title="yusm" --window-icon="$RUNNING_DIR/yusm.png" --list --limit=1 --mouse --on-top --text="Installing $SNAP..." --height 300 --width 800 --tail --no-markup --no-escape --button="Classic install!gtk-home":1 --button=gtk-close:0 --wrap-width=400 --wrap-cols=2 --no-selection --no-click --column="Progress":BAR --column="Status":TEXT
    case $? in
        1)
            snapclassicinstall "$SNAP"
            exit 0
            ;;
        0)
            exit 1
            ;;
    esac
}
export -f snapinstall

function snapclassicinstall() {
    SNAP="$1"
    INSTALL_SIZE=$(snap info $SNAP | grep -m1 'stable:' | tr -d '[:blank:][:alpha:]' | cut -f2 -d')' | cut -f1 -d'-' | cut -f1 -d'.')
    PERCENT=0
    touch /tmp/yusmsnapinstallstatus
    sudo -A snap install "$SNAP" --classic > /tmp/yusmsnapinstallstatus 2>&1 &
    while [ -f "/tmp/yusmsnapinstallstatus" ]; do
        PARTIAL_SIZE=$(du -h -a --max-depth=1 "/var/lib/snapd/snaps/" | grep -wm1 '.*.partial' | tr -d '[:blank:][:alpha:]' | cut -f1 -d'/' | cut -f1 -d'.')
        PERCENT=$((${PARTIAL_SIZE}00/$INSTALL_SIZE))
        if grep -qw 'installed' /tmp/yusmsnapinstallstatus; then
            echo 100
            cat /tmp/yusmsnapinstallstatus
            rm /tmp/yusmsnapinstallstatus
        else
            if [ $PERCENT -lt 10 ]; then
                echo 1
            elif [ $PERCENT -gt 90 ]; then
                echo 90
            else
                echo "$PERCENT"
            fi
            echo "Installing $SNAP..."
            sleep 0.5
        fi
    done | yad --class="yusm" --title="yusm" --window-icon="$RUNNING_DIR/yusm.png" --list --limit=1 --mouse --on-top --text="Installing $SNAP..." --height 300 --width 800 --tail --no-markup --no-escape --button=gtk-close --wrap-width=400 --wrap-cols=2 --no-selection --no-click --column="Progress":BAR --column="Status":TEXT
    exit 1
}
export -f snapclassicinstall

function snaprefresh() {
    echo "Refresh all snaps" > /tmp/yusmrefreshlist
    snap list | tail -n +2 | cut -f1 -d' ' >> /tmp/yusmrefreshlist
    SNAP="$(yad --class="yusm" --title="yusm" --window-icon="$RUNNING_DIR/yusm.png" --list --rest="/tmp/yusmrefreshlist" --mouse --width 400 --height 500 --separator="" --text="Refresh installed snaps\n" --column="Snap Name" --button=gtk-cancel:1 --button=gtk-ok:0)"
    rm /tmp/yusmrefreshlist
    if [ -z "$SNAP" ]; then
        exit 0
    fi
    case $SNAP in
        *Refresh*)
            SNAP=""
            ;;
        *)
            SNAP="$SNAP"
            ;;
    esac
    sudo -A snap refresh "$SNAP" 2>&1 | cut -f2- -d':' | cut -f2- -d'K' | yad --class="yusm" --title="yusm" --window-icon="$RUNNING_DIR/yusm.png" --text-info --mouse --on-top --height 300 --width 800 --tail --no-markup --no-escape --button=gtk-ok
}
export -f snaprefresh

function snapremove() {
    SNAP="$(snap list | tail -n +2 | cut -f1 -d' ' | grep -vw 'core' | yad --class="yusm" --title="yusm" --window-icon="$RUNNING_DIR/yusm.png" --list --mouse --width 400 --height 500 --separator="" --text="Remove installed snaps\n" --column="Snap Name" --button=gtk-cancel:1 --button=gtk-ok:0)"
    if [ -z "$SNAP" ]; then
        exit 0
    fi
    FAKEPERCENT=0
    touch /tmp/yusmsnapremovestatus
    sudo -A snap remove "$SNAP" > /tmp/yusmsnapremovestatus 2>&1 &
    while [ -f "/tmp/yusmsnapremovestatus" ]; do
        if grep -qw 'removed' /tmp/yusmsnapremovestatus; then
            echo 100
            cat /tmp/yusmsnapremovestatus
            rm /tmp/yusmsnapremovestatus
        else
            echo "$FAKEPERCENT"
            echo "Removing $SNAP..."
            sleep 1
            FAKEPERCENT=$(($FAKEPERCENT+1))
        fi
    done | yad --class="yusm" --title="yusm" --window-icon="$RUNNING_DIR/yusm.png" --list --limit=1 --mouse --on-top --text="Removing $SNAP..." --height 300 --width 500 --tail --no-markup --no-escape --button=gtk-close --wrap-width=400 --wrap-cols=2 --no-selection --no-click --column="Progress":BAR --column="Status":TEXT
    exit 0
}
export -f snapremove

function mainstart() {
    main
}

function main() {
    KEY="$RANDOM"
    yad --plug="$KEY" --tabnum=1 --html --uri="https://uappexplorer.com/snaps?sort=title" --browser --uri-handler='bash -c "snapinstall %s"' &> /tmp/yusmtab1 &
    yad --plug="$KEY" --tabnum=2 --form --text="Manage installed snaps\n" --text-align="center" --field="Refresh snaps!gtk-refresh":BTN 'bash -c "snaprefresh"' --field="Remove snaps!gtk-delete":BTN 'bash -c "snapremove"'  &> /tmp/yusmtab2 &
    yad --class="yusm" --title="yusm" --window-icon="$RUNNING_DIR/yusm.png" --height 720 --width 1280 --notebook --key="$KEY" --tab="Browse snaps" --tab="Manage snaps" --button="Reload"\!gtk-refresh:0 --button=gtk-close:1
    case $? in
        0)
            rm /tmp/yusmtab1
            rm /tmp/yusmtab2
            mainstart
            ;;
        1)
            rm /tmp/yusmtab1
            rm /tmp/yusmtab2
            exit 0
            ;;
    esac
}

SUDO_ASKPASS="$(which ssh-askpass)"
case $SUDO_ASKPASS in
    *not*)
        SUDO_ASKPASS="$(which gksu)"
        case $SUDO_ASKPASS in
            *not*)
                yad --error --text="Missing required ssh-askpass or gksu"
                exit 1
                ;;
            *)
                export SUDO_ASKPASS
                ;;
        esac
        ;;
    *)
        export SUDO_ASKPASS
        ;;
esac

main
