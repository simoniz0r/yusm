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
            PERCENT=0
            echo "$PASSWORD" | sudo -S snap install "$SNAP" > /tmp/yusmsnapinstallstatus 2>&1 && rm /tmp/yusmsnapinstallstatus &
            while [ -f "/tmp/yusmsnapinstallstatus" ]; do
                case $(cat /tmp/yusmsnapinstallstatus) in
                    *--classic*)
                        echo "100"
                        rm /tmp/yusmsnapinstallstatus
                        yad --class="yusm" --title="yusm" --window-icon="$RUNNING_DIR/yusm.png" --error --mouse --on-top --borders=15 --text="Error installing $SNAP!\n\nThis revision of snap $SNAP was published using classic confinement and thus may perform\narbitrary system changes outside of the security sandbox that snaps are usually confined to,\nwhich may put your system at risk.\n\n\nIf you understand and want to proceed, click yes." --button=gtk-no:1 --button=gtk-yes:0
                        case $? in
                            1)
                                exit 0
                                ;;
                            0)
                                snapclassicinstall "$SNAP"
                                exit 0
                                ;;
                        esac
                        ;;
                    *incorrect*)
                        echo "100"
                        rm /tmp/yusmsnapinstallstatus
                        yad --class="yusm" --title="yusm" --window-icon="$RUNNING_DIR/yusm.png" --borders=15 --error --mouse --on-top --text="Error installing $SNAP!\nIncorrect password for sudo snap install $SNAP!" --button=gtk-ok
                        ;;
                esac
                cat /tmp/yusmsnapinstallstatus | tr ' ' '\n' | tac | grep -m1 '%' | cut -f1 -d'.'
                sleep 0.5
            done | yad --class="yusm" --title="yusm" --window-icon="$RUNNING_DIR/yusm.png" --borders=15 --progress --percent="$PERCENT" --text="Installing snap $SNAP\n" --mouse --on-top --no-buttons --auto-close
            rm -f /tmp/yusmsnapinstallstatus
            exit 1
            ;;
        1)
            exit 0
            ;;
    esac
}
export -f snapinstall

function snapclassicinstall() {
    SNAP="$1"
    PASSWORD="$(yad --class="yusm" --title="yusm" --window-icon="$RUNNING_DIR/yusm.png" --entry --mouse --on-top --hide-text --text="Enter password for sudo snap install $SNAP --classic\n")"
    case $? in
        0)
            touch /tmp/yusmsnapclassicstatus
            CLASSIC_PERCENT=0
            echo "$PASSWORD" | sudo -S snap install "$SNAP" --classic > /tmp/yusmsnapclassicstatus 2>&1 && rm /tmp/yusmsnapclassicstatus &
            while [ -f "/tmp/yusmsnapclassicstatus" ]; do
                case $(cat /tmp/yusmsnapclassicstatus) in
                    *incorrect*)
                        echo "100"
                        rm /tmp/yusmsnapclassicstatus
                        yad --class="yusm" --title="yusm" --window-icon="$RUNNING_DIR/yusm.png" --borders=15 --error --mouse --on-top --text="Error installing $SNAP!\nIncorrect password for sudo snap install $SNAP!" --button=gtk-ok
                        ;;
                esac
                cat /tmp/yusmsnapclassicstatus | tr ' ' '\n' | tac | grep -m1 '%' | cut -f1 -d'.'
                sleep 0.5
            done | yad --class="yusm" --title="yusm" --window-icon="$RUNNING_DIR/yusm.png" --borders=15 --progress --percent="$CLASSIC_PERCENT" --text="Installing snap $SNAP\n" --mouse --on-top --no-buttons --auto-close
            rm -f /tmp/yusmsnapclassicstatus
            exit 1
            ;;
        1)
            exit 0
            ;;
    esac
}
export -f snapclassicinstall

function snaprefresh() {
    SNAP="$(( echo "Refresh all snaps" ; snap list | tail -n +2 | cut -f1 -d' ' ) | yad --class="yusm" --title="yusm" --window-icon="$RUNNING_DIR/yusm.png" --list --mouse --width 400 --height 500 --separator="" --text="Refresh installed snaps\n" --column="Snap Name" --button=gtk-cancel:1 --button=gtk-ok:0)"
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
    SNAP="$(snap list | tail -n +2 | cut -f1 -d' ' | grep -vw 'core' | yad --class="yusm" --title="yusm" --window-icon="$RUNNING_DIR/yusm.png" --list --mouse --width 400 --height 500 --separator="" --text="Remove installed snaps\n" --column="Snap Name" --button=gtk-cancel:1 --button=gtk-ok:0)"
    if [ -z "$SNAP" ]; then
        exit 0
    fi
    PASSWORD="$(yad --class="yusm" --title="yusm" --window-icon="$RUNNING_DIR/yusm.png" --entry --mouse --on-top --hide-text --text="Enter password for sudo snap remove $SNAP\n")"
    case $? in
        0)
            touch /tmp/yusmsnapremovestatus
            FAKEPERCENT=0
            echo "$PASSWORD" | sudo -S snap remove "$SNAP" 2> /tmp/yusmsnapremovestatus && rm /tmp/yusmsnapremovestatus &
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

main
