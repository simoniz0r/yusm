#!/bin/bash
# yusm - Yad uAppExplorer Snap Manager - Unofficial app for managing snaps based on uappexplorer.com/snaps

REALPATH="$(readlink -f $0)"
RUNNING_DIR="$(dirname "$REALPATH")" # Find directory script is running from

function snapinstall() {
    if [[ ! "$@" =~ snap:// ]]; then
        exit 1
    fi
    SNAP="$(echo "$@" | cut -f3 -d'/')"
    PASSWORD="$(yad --class="yusm" --title="yusm" --window-icon="$RUNNING_DIR/yusm.png" --entry --mouse --on-top --hide-text --text="Enter password for sudo snap install $SNAP\n")"
    case $? in
        0)
            touch /tmp/yusmsnapinstallstatus
            FAKEPERCENT=0
            echo "$PASSWORD" | sudo -S snap install "$SNAP" 2> /tmp/yusmsnapinstallstatus && rm /tmp/yusmsnapinstallstatus &
            while [ -f "/tmp/yusmsnapinstallstatus" ]; do
                case $(cat /tmp/yusmsnapinstallstatus) in
                    *--classic*)
                        rm /tmp/yusmsnapinstallstatus
                        yad --class="yusm" --title="yusm" --window-icon="$RUNNING_DIR/yusm.png" --error --mouse --on-top --text="Error installing $SNAP!\n$SNAP is in classic confinment mode.\nClassic confinement snaps are not currently supported though yusm." --button=gtk-ok
                        ;;
                    *incorrect*)
                        rm /tmp/yusmsnapinstallstatus
                        yad --class="yusm" --title="yusm" --window-icon="$RUNNING_DIR/yusm.png" --error --mouse --on-top --text="Error installing $SNAP!\nIncorrect password for sudo snap install $SNAP!" --button=gtk-ok
                        ;;
                esac
                echo "$FAKEPERCENT"
                sleep 0.5
                FAKEPERCENT=$(($FAKEPERCENT+1))
                if [ $FAKEPERCENT -eq 99 ]; then
                    FAKEPERCENT=$(($FAKEPERCENT-1))
                fi
            done | yad --class="yusm" --title="yusm" --window-icon="$RUNNING_DIR/yusm.png" --progress --percent="$FAKEPERCENT" --text="Installing snap $SNAP\n" --mouse --on-top --no-buttons --auto-close
            rm -f /tmp/yusmsnapinstallstatus
            exit 1
            ;;
        1)
            exit 0
            ;;
    esac
}
export -f snapinstall

function snaprefresh() {
    SNAP="$(echo "$@" | cut -f1 -d' ')"
    case $SNAP in
        *Refresh*)
            SNAP=""
            ;;
        *)
            SNAP="$SNAP"
            ;;
    esac
    PASSWORD="$(yad --class="yusm" --title="yusm" --window-icon="$RUNNING_DIR/yusm.png" --entry --mouse --on-top --hide-text --text="Enter password for sudo snap refresh $SNAP\n")"
    case $? in
        0)
            echo "$PASSWORD" | sudo -S snap refresh "$SNAP" 2>&1 | cut -f2- -d':' | cut -f2- -d'K' | yad --class="yusm" --title="yusm" --window-icon="$RUNNING_DIR/yusm.png" --text-info --mouse --on-top --height 300 --width 800 --tail --no-markup --no-escape --button=gtk-ok
            exit 0
            ;;
        1)
            exit 0
            ;;
    esac
}
export -f snaprefresh

function snapremove() {
    SNAP="$(echo "$@" | cut -f1 -d' ')"
    PASSWORD="$(yad --class="yusm" --title="yusm" --window-icon="$RUNNING_DIR/yusm.png" --entry --mouse --on-top --hide-text --text="Enter password for sudo snap remove $SNAP\n")"
    case $? in
        0)
            touch /tmp/yusmsnapremovestatus
            FAKEPERCENT=0
            echo "$PASSWORD" | sudo -S snap remove "$SNAP" 2> /tmp/yusmsnapremovestatus && rm /tmp/yusmsnapremovestatus &
            while [ -f "/tmp/yusmsnapremovestatus" ]; do
                case $(cat /tmp/yusmsnapremovestatus) in
                    *incorrect*)
                        rm /tmp/yusmsnapremovestatus
                        yad --class="yusm" --title="yusm" --window-icon="$RUNNING_DIR/yusm.png" --error --mouse --on-top --text="Error removing $SNAP!\nIncorrect password for sudo snap install $SNAP!" --button=gtk-ok
                        ;;
                esac
                echo "$FAKEPERCENT"
                sleep 0.5
                FAKEPERCENT=$(($FAKEPERCENT+1))
                if [ $FAKEPERCENT -eq 99 ]; then
                    FAKEPERCENT=$(($FAKEPERCENT-1))
                fi
            done | yad --class="yusm" --title="yusm" --window-icon="$RUNNING_DIR/yusm.png" --progress --percent="$FAKEPERCENT" --text="Removing snap $SNAP\n" --mouse --on-top --no-buttons --auto-close
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
    echo "$(snap list | tail -n +2 | grep -vw 'core' | cut -f1 -d' ')" > /tmp/yusmlist.rest
    echo "Refresh all snaps" > /tmp/yusmlist2.rest
    echo "$(snap list | tail -n +2 | cut -f1 -d' ')" >> /tmp/yusmlist2.rest
    yad --plug="$KEY" --tabnum=1 --html --uri="https://uappexplorer.com/snaps?sort=title" --browser --uri-handler='bash -c "snapinstall %s"' &> /tmp/yusmtab1 &
    yad --plug="$KEY" --tabnum=2 --list --text="Double click a snap to refresh it" --dclick-action='bash -c "snaprefresh %s"' --column="Snap Name" --rest="/tmp/yusmlist2.rest" &> /tmp/yusmtab2 &
    yad --plug="$KEY" --tabnum=3 --list --text="Double click a snap to remove it" --dclick-action='bash -c "snapremove %s"' --column="Snap Name" --rest="/tmp/yusmlist.rest" &> /tmp/yusmtab3 &
    yad --class="yusm" --title="yusm" --window-icon="$RUNNING_DIR/yusm.png" --height 720 --width 1280 --notebook --key="$KEY" --tab="Browse snaps" --tab="Refresh snaps" --tab="Remove snaps" --button="Reload"\!gtk-refresh:0 --button=gtk-close:1
    case $? in
        0)
            rm /tmp/yusmtab1
            rm /tmp/yusmtab2
            rm /tmp/yusmtab3
            rm /tmp/yusmlist.rest
            rm /tmp/yusmlist2.rest
            mainstart
            ;;
        1)
            rm /tmp/yusmtab1
            rm /tmp/yusmtab2
            rm /tmp/yusmtab3
            rm /tmp/yusmlist.rest
            rm /tmp/yusmlist2.rest
            exit 0
            ;;
    esac
}

main
