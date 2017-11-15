#!/bin/bash
# yusm - Yad uAppExplorer Snap Manager - Unofficial app for managing snaps based on uappexplorer.com/snaps

REALPATH="$(readlink -f $0)"
RUNNING_DIR="$(dirname "$REALPATH")" # Find directory script is running from

function snapinstall() {
    if [[ ! "$@" =~ snap:// ]]; then
        exit 1
    fi
    SNAP="$(echo "$@" | cut -f3 -d'/')"
    sudo -A snap install "$SNAP" 2>&1 | yad --class="yusm" --title="yusm" --window-icon="$RUNNING_DIR/yusm.png" --text-info --mouse --on-top --text="Installing $SNAP..." --height 300 --width 800 --tail --no-markup --no-escape --button="Classic install!gtk-home":1 --button=gtk-close:0
    case $? in
        1)
            snapclassicinstall "$SNAP"
            exit 0
            ;;
        0)
            exit 1
            ;;
    esac
    exit 1
}
export -f snapinstall

function snapclassicinstall() {
    SNAP="$1"
    sudo -A snap install "$SNAP" --classic 2>&1 | yad --class="yusm" --title="yusm" --window-icon="$RUNNING_DIR/yusm.png" --text-info --mouse --on-top --text="Installing $SNAP..." --height 300 --width 800 --tail --no-markup --no-escape --button=gtk-close
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
    sudo -A snap remove "$SNAP" 2> /tmp/yusmsnapremovestatus && rm /tmp/yusmsnapremovestatus &
    # PASSWORD="$(yad --class="yusm" --title="yusm" --window-icon="$RUNNING_DIR/yusm.png" --entry --mouse --on-top --hide-text --text="Enter password for sudo snap remove $SNAP\n")"
    case $? in
        0)
            touch /tmp/yusmsnapremovestatus
            FAKEPERCENT=0
            # echo "$PASSWORD" | sudo -S snap remove "$SNAP" 2> /tmp/yusmsnapremovestatus && rm /tmp/yusmsnapremovestatus &
            while [ -f "/tmp/yusmsnapremovestatus" ]; do
                case $(cat /tmp/yusmsnapremovestatus) in
                    *incorrect*)
                        echo "100"
                        rm /tmp/yusmsnapremovestatus
                        yad --class="yusm" --title="yusm" --window-icon="$RUNNING_DIR/yusm.png" --borders=15 --error --mouse --on-top --text="Error removing $SNAP!\nIncorrect password for sudo snap install $SNAP!" --button=gtk-ok
                        ;;
                esac
                echo "$FAKEPERCENT"
                sleep 0.5
                FAKEPERCENT=$(($FAKEPERCENT+1))
                if [ $FAKEPERCENT -eq 99 ]; then
                    FAKEPERCENT=$(($FAKEPERCENT-10))
                fi
            done | yad --class="yusm" --title="yusm" --window-icon="$RUNNING_DIR/yusm.png" --borders=15 --progress --percent="$FAKEPERCENT" --text="Removing snap $SNAP\n" --mouse --on-top --no-buttons --auto-close
            rm -f /tmp/yusmsnapremovestatus
            exit 0
            ;;
        1)
            exit 0
            ;;
    esac
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
