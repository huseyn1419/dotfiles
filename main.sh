#!/bin/sh

# description: auto setup script to setup required programs after doing fresh install
# tested against debian

# set -x # for debugging

# check if root
if [ $(id -u) -ne 0 ] ; then echo "PLEASE RUN AS ROOT" ; exit 1 ; fi


main() {
  while [ 1 ] ; do
    echo "----------------------------------------"
    echo " 1 CONFIGURE APT"
    echo " 2 CONFIGURE KEYBOARD"
    echo " 3 CONFIGURE GRUB"
    echo " 4 EXPAND BRIGHTNESS SETTINGS"
    echo " 5 IMWHEEL"
    echo "99 CONFIGURE VIM"
    echo " Q QUIT"
    echo "----------------------------------------"
    echo -n "SELECT OPTION:"
    read option

    case ${option} in
      q)
      exit
      ;;

      1)
      configure_apt
      echo "+ APT CONFIGURATION OK"
      ;;

      2)
      configure_keyboard f
      echo "+ KEYBOARD CONFIGURATION OK"
      ;;

      3)
      configure_grub 2 en
      echo "+ GRUB CONFIGURATION OK"
      ;;

      4)
      expand_brightness_settings
      echo "+ BRIGHTNESS EXPAND OK"
      ;;
      
      5)
      imwheel
      echo "+ IMWHEEL OK"
      ;;

      99)
      configure_vim
      echo "+ VIM CONFIGURATION OK"
      ;;

    esac
done

}




# FUNCTIONS




configure_apt() {

  cat <<'eof' > /etc/apt/preferences.d/99-pin
package: *
pin: release a=unstable
pin-priority: 502

package: *
pin: release a=testing
pin-priority: 503

package: *
pin: release a=stable
pin-priority: 501

package: *
pin: release a=oldstable
pin-priority: 500
eof

  cat <<'eof' > /etc/apt/sources.list
# unstable (sid)
deb      http://ftp.debian.org/debian/ unstable main contrib non-free
#deb-src http://ftp.debian.org/debian/ unstable main contrib non-free

# testing (bullseye)
deb      http://ftp.debian.org/debian/ testing main contrib non-free
#deb-src http://ftp.debian.org/debian/ testing main contrib non-free

deb      http://ftp.debian.org/debian/ testing-updates main contrib non-free
#deb-src http://ftp.debian.org/debian/ testing-updates main contrib non-free

deb      http://security.debian.org/ testing-security main contrib non-free
#deb-src http://security.debian.org/ testing-security main contrib non-free

# stable (buster)
deb      http://ftp.debian.org/debian/ stable main contrib non-free
#deb-src http://ftp.debian.org/debian/ stable main contrib non-free

deb      http://ftp.debian.org/debian stable-updates main contrib non-free
#deb-src http://ftp.debian.org/debian stable-updates main contrib non-free

deb      http://security.debian.org/debian-security stable/updates main contrib non-free
#deb-src http://security.debian.org/debian-security stable/updates main contrib non-free

deb      http://ftp.debian.org/debian buster-backports main contrib non-free
#deb-src http://ftp.debian.org/debian buster-backports main contrib non-free

# oldstable (stretch)
deb      http://ftp.debian.org/debian/ oldstable main contrib non-free
#deb-src http://ftp.debian.org/debian/ oldstable main contrib non-free

deb      http://ftp.debian.org/debian/ oldstable-updates main contrib non-free
#deb-src http://ftp.debian.org/debian/ oldstable-updates main contrib non-free

deb      http://security.debian.org/debian-security oldstable/updates main contrib non-free
#deb-src http://security.debian.org/debian-security oldstable/updates main contrib non-free

deb      http://ftp.debian.org/debian stretch-backports main contrib non-free
#deb-src http://ftp.debian.org/debian stretch-backports main contrib non-free
eof

}



configure_keyboard() {
  # FIRST TURKISH F, THEN TURKISH Q LAYOUT
  sed -i 's/.*XKBLAYOUT.*/XKBLAYOUT="tr,tr"/' /etc/default/keyboard

  if [ $1 = "q" ]; then
    sed -i 's/.*XKBVARIANT.*/XKBVARIANT=",f"/' /etc/default/keyboard
  else
    sed -i 's/.*XKBVARIANT.*/XKBVARIANT="f,"/' /etc/default/keyboard
  fi

  sed -i 's/.*XKBOPTIONS.*/XKBOPTIONS="grp:alt_shift_toggle,terminate:ctrl_alt_bksp"/' /etc/default/keyboard

}



configure_vim() {

  cat <<'eof' > ~/.vimrc
"" open line numbers
set number
"" colorizing on
syntax on

"" show existing tab with 4 spaces width
set tabstop=2
"" when indenting with '>', use 4 spaces width
set shiftwidth=2
"" On pressing tab, insert 4 spaces
set expandtab

colorscheme murphy
eof

}







configure_grub() {
  # usage:
  # configure_grub timeoutsüresi language
  # configure_grub 0 tr
  # configure_grub 2 en
  mv /etc/grub.d/05_debian_theme /root/

  sed -i 's/.*GRUB_CMDLINE_LINUX_DEFAULT.*/GRUB_CMDLINE_LINUX_DEFAULT="quiet splash"/' /etc/default/grub


  if [ $1 = "0" ]; then
    sed -i 's/.*GRUB_TIMEOUT.*/GRUB_TIMEOUT=0/' /etc/default/grub
  else
    sed -i 's/.*GRUB_TIMEOUT.*/GRUB_TIMEOUT=2/' /etc/default/grub
  fi


    cat <<'eof' > /boot/grub/custom.cfg
menuentry "REBOOT" {
  reboot
}

menuentry "SHUTDOWN" {
  halt
}
eof



}


expand_brightness_settings() {

mkdir -p /opt/expand-brightness

cat <<'eof' > /opt/expand-brightness/expand-brightness.sh
#!/bin/sh

selected_display="HDMI-1"

zenity --scale --min-value=0 --max-value=100 --step=5 --title "SET BRIGHTNESS OF $selected_display" --value=50 --print-partial |
while read brightness
do
  xrandr --output "$selected_display" --brightness 0.$brightness
done
eof

chmod +x /opt/expand-brightness/expand-brightness.sh
chmod 644 /opt/expand-brightness/*
chmod 755 /opt/expand-brightness/expand-brightness.sh
ln -s /opt/expand-brightness/expand-brightness.sh /usr/bin/expand-brightness

cat <<'eof' > /usr/share/applications/expand-brightness.desktop
[Desktop Entry]
Type=Application
Name=expand-brightness
Path=/opt/expand-brightness
Exec=expand-brightness
Icon=application-octet-stream
Terminal=false
Categories=Utility;System
eof


}

imwheel() {

mkdir -p /opt/imwheel

cat <<'eof' > /opt/imwheel/imwheel.sh
#!/bin/sh
imwheel --kill --buttons "4 5"
eof

chmod +x /opt/imwheel/imwheel.sh
chmod 644 /opt/imwheel/*
chmod 755 /opt/imwheel/imwheel.sh
ln -s /opt/imwheel/imwheel.sh /usr/bin/imwheel-startup

cat <<'eof' > /usr/share/applications/imwheel-startup.desktop
[Desktop Entry]
Type=Application
Name=imwheel-startup
Path=/opt/imwheel
Exec=imwheel-startup
Icon=application-octet-stream
Terminal=false
Categories=Utility;System
eof

}


main
