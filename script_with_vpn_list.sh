#!/bin/bash

notify-send "Wifi" "Getting list of Wifi networks..."
wifi_inuse=$(nmcli -t -f security,bars,in-use,ssid,bssid device wifi list | grep \* | sed 's/^.*\*:/ /g' | sed 's/.\{23\}$//')
wifi_list=$(nmcli -t -f security,bars,in-use,ssid,bssid device wifi list | sed '/:.*::/d' | sed '/\*/d' | sed 's/^:▂▄▆█: :/󰤨 /g' | sed 's/^:▂▄▆_: :/󰤥 /g' |sed 's/^:▂▄__: :/󰤟 /g' | sed 's/^:▂___: :/󰤯 /g'| sed 's/.*:▂▄▆█: :/󰤪 /g' | sed 's/.*:▂▄▆_: :/󰤧 /g' |  sed 's/.*:▂▄__: :/󰤡 /g' | sed 's/.*:▂___: :/󰤬 /g' | sed 's/.\{23\}$//')

connected=$(nmcli radio wifi)
if [[ "$connected" =~ "enabled" ]]; then
  wifi_status="󰤭 Disable Wifi"
elif [[ "$connected" =~ "disabled" ]]; then
  wifi_status="󰤨 Enable Wifi"
fi 
if [[ -n $wifi_inuse ]]; then
  choosen_wifi=$(echo -e "$wifi_status\n󰖂 VPN List\n$wifi_inuse\n$wifi_list" | uniq -s 4 | rofi -dmenu -i -p "Select a network")
else
  choosen_wifi=$(echo -e "$wifi_status\n$wifi_list" | uniq -s 4 | rofi -dmenu -i -p "Select a network")
fi

if [[ $choosen_wifi =~ "󰤭 Disable Wifi" ]]; then
  nmcli radio wifi off
elif [[ $choosen_wifi =~ "󰤨 Enable Wifi" ]]; then
  nmcli radio wifi on
elif [[ "$choosen_wifi" =~ "󰖂 VPN List" ]]; then
  choosen_vpn=$(nmcli -t -f state,name,type  connection show | grep "wireguard" | sed 's/^://g' | sed 's/^activated:/  /g' | sed 's/:.*//g' | rofi -dmenu -i -p "Select a VPN")
  if [[ $(echo $choosen_vpn | grep ) ]]; then 
    nmcli connection down "${choosen_vpn:3}"
  else
    nmcli connection up "${choosen_vpn}"
  fi
elif [[ -n $choosen_wifi ]]; then
  if [[ $(echo $choosen_wifi | grep ) ]]; then
    if [[ $(nmcli -f name,autoconnect c s | grep -m 1 "${choosen_wifi:2}") =~ yes ]]; then
      choosen_option=$(echo -e "Disconnect\nForget\nDisable autoconnect" | rofi -dmenu -i -p "${choosen_wifi:2}")
    else
      choosen_option=$(echo -e "Disconnect\nForget\nEnable autoconnect" | rofi -dmenu -i -p "${choosen_wifi:2}")
    fi

    if [[ "$choosen_option" =~ Disconnect ]]; then
      nmcli connection down "${choosen_wifi:2}" 
      notify-send "Wifi" "Disconnected from ${choosen_wifi:2}"
    elif [[ "$choosen_option" =~ "Forget" ]]; then
      nmcli connection delete "${choosen_wifi:2}"  
      notify-send "Wifi" "${choosen_wifi:2} has been removed"
    elif [[ "$choosen_option" =~ "Enable autoconnect" ]]; then
      nmcli connection modify "${choosen_wifi:2}" connection.autoconnect yes  
      notify-send "Wifi" "Autoconnect enabled"
    elif [[ "$choosen_option" =~ "Disable autoconnect" ]]; then
      nmcli connection modify "${choosen_wifi:2}" connection.autoconnect no
      notify-send "Wifi" "Autoconnect disabled"
    else
      notify-send "Wifi" "No option selected"
    fi
  else
    if [[ $(echo "$choosen_wifi" | grep -e "󰤪"  -e "󰤧"  -e "󰤡" -e "󰤬" ) ]]; then
      if [[ $(nmcli device wifi connect "${choosen_wifi:2}" | grep successfully) ]]; then
        notify-send "Wifi" "Successfully connected to ${choosen_wifi:2}"
      else
        password=$(rofi -dmenu -p "Password:" -password -i)
        notify-send "Wifi" "Connecting to ${choosen_wifi:2}"
        if [[ $(nmcli device wifi connect "${choosen_wifi:2}" password "$password" | grep successfully) ]]; then
          notify-send "Wifi" "Successfully connected to ${choosen_wifi:2}"
        else
          notify-send "Wifi" "There was an error connecting to ${choosen_wifi:2}"
        fi
      fi
    else
      notify-send "Wifi" "Connecting to ${choosen_wifi:2}"
      if [[ $(nmcli device wifi connect "${choosen_wifi:2}" | grep successfully) ]]; then
        notify-send "Wifi" "Successfully connected to ${choosen_wifi:2}"
      else
        notify-send "Wifi" "There was an error connecting to ${choosen_wifi:2}"
      fi
    fi
  fi
else
  notify-send "Wifi" "No option selected"
fi
