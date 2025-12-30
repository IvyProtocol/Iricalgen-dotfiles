#!/usr/bin/env bash

set -eo pipefail

scrDir="$(dirname "$(realpath "$0")")"
if [[ ! "${scrDir}/globalfunction.sh" ]]; then
  echo " :: Something went wrong to '${scrDir}/globalfunction.sh'"
else
  echo " :: Sourcing Global Variable"
fi
[[ -e ${scrDir}/globalfunction.sh ]] && source "${scrDir}/globalfunction.sh"

if [[ $EUID -eq 0 ]]; then
  echo "${IndentError} This script should ${indentWarning} NOT ${indentReset} be executed as root!!"
  printf "\n%.0s" {1..2}
  exit 1
fi

if grep -iqE '(ID|ID_LIKE)=.*(arch)' /etc/os-release >/dev/null 2>&1; then
  echo " :: ${indentOk} Arch Linux Detected"
  while true; do
    read -p "$(echo -n " :: ${indentAction} Do you want to install anyway? (y/n): ")" check
    case ${check} in
      y|yes)
        echo " :: ${indentNotice} Proceeding on Arch Linux by user confirmation."
        break
        ;;
      n|no|"")
        echo " :: ${indentError} Aborting installation due to user choice. No changes were made."
        exit 0
        ;;
      *)
        echo " :: ${indentError} Please answer 'y' or 'n'."
        ;;
    esac
  done
fi

if [[ -d "${cloneDir}/${aurRp}" ]]; then
  echo -n "${indentAction} AUR exists '${cloneDir}/${aurRp}'...."
  while true; do
    prompt_timer 120 "${indentAction} Do you want to remove the directory? "
    case $PROMPT_INPUT in
      Y|y)
        if [[ $(stat -c '%U' ${cloneDir}/${aurRp}) = $USER ]] && [[ $(stat -c '%U' ${cloneDir}/${aurRp}/PKGBUILD) = $USER ]]; then
          echo -n " :: ${indentAction} Removing..."
          rm -rf "${cloneDir}"
          break
        elif [[ $(stat -c '%u' ${cloneDir}/${aurRp}) -eq 0 ]] && [[ $(stat -c '%u' ${cloneDir}/${aurRp}/PKGBUILD) -eq 0 ]]; then
          echo " :: ${indentWarning} The file has ${indentWarning}root${indentWarning} ownership!!! Manual intervention required - ${indentError} Code: 1"
        fi
        ;;
      N|n)
        prompt_timer 120 "${indentAction} !!!? Would you like to use that folder instead?"
        case $PROMPT_INPUT in
          Y|y)
            if [[ -e "${cloneDir}/${aurRp}/PKGBUILD" ]]; then
              (cd "${cloneDir}/${aurRp}/" && makepkg -si)
              break
            else
              echo "${indentWarning} !!! Something went ${indentWarning}wrong${indentWarning} in our side..."
              if [[ $(stat -c '%U' ${cloneDir}/${aurRp}) = $USER ]] && [[ $(stat -c '%U' ${cloneDir}/${aurRp}/PKGBUILD) = $USER ]]; then
                echo " :: ${indentAction} Retrying the script"
              elif [[ $(stat -c '%u' ${confDir}/${aurRp}) -eq 0 ]] && [[ $(stat -c '%u' ${confDir}/${aurRp}/PKGBUILD) -eq 0 ]]; then
                echo " :: ${indentInfo} The folder has ${indentWarning}root${indentWarning} ownership. Manual intervention required - ${indentError} Code: 1"
                exit 1
              fi
            fi
            ;;
          N|n)
            if [[ $(stat -c '%U' ${cloneDir}/${aurRp}) = $USER ]] && [[ $(stat -c '%U' ${cloneDir}/${aurRp}/PKGBUILD) = $USER ]]; then
              echo " :: ${indentAction} Removing..."
              rm -rf "${cloneDir}"
              break
            elif [[ $(stat -c '%u' ${cloneDir}/${aurRp}) -eq 0 ]] && [[ $(stat -c '%U' ${cloneDir}/${aurRp}/PKGBUILD) -eq 0 ]]; then
              echo " :: ${indentError} The file has ${indentWarning}root${indentWarning} ownership!!! ${indentError} Code: 1"
            fi
            ;;
          *)
            echo " :: ${indentError} Please answer 'y' or 'n'."
            ;;
        esac
        ;;
      *)
        echo " :: ${IndentError} Please answer 'y' or 'n'."
        ;;
    esac
  done
else
  mkdir -p ${cloneDir}
fi

if [[ "${check}" = "Y" ]] || [[ ${check} = "y" ]]; then
  while true; do
    if [[ -d "${cloneDir}/cachyos-repo" ]] || [[ -d "${cloneDir}/${cachyRp}" ]]; then
      prompt_timer 120 "${indentAction} Would you like to delete the repository?"
      case "$PROMPT_INPUT" in
        Y|y)
          if [[ $(stat -c '%U' ${cloneDir}/${cachyRp}) = $USER ]] || [[ $(stat -c '%U' ${cloneDir}/cachyos-repo) = $USER ]]; then
            echo " :: ${indentNotice} Deleting ${indentGreen}the Repository"
            rm -rf ${cloneDir}/${cachyRp}
            rm -rf ${cloneDir}/cachyos-repo
            break
          elif [[ $(stat -c '%u' ${cloneDir}/${cachyRp}) -eq 0 ]] || [[ $(stat -c '%u' ${cloneDir}/cachyos-repo) -eq 0 ]]; then
            echo " :: ${indentError} The file has ${indentWarning}root${indentWarning} ownership!! Manual intervention required - ${indentError} Code: 1"
            exit 1
          fi
          ;;
        N|n|*)
          prompt_timer 120 " :: ${indentNotice} Would you like to rather use the repository?"
          case $PROMPT_INPUT in
            y|Y)
              if [[ -e "${cloneDir}/cachyos-repo/cachyos-repo.sh" ]]; then
                sudo bash "${cloneDir}/cachyos-repo/cachyos-repo.sh"
                break
              else
                echo "${indentError} !!! Something went ${indentWarning}wrong${indentWarning} in our side..."
                if [[ $(stat -c '%U' ${cloneDir}/${cachyRp}) = $USER ]] || [[ $(stat -c '%U' ${cloneDir}/cachyos-repo) = $USER ]]; then
                  echo " :: ${indentAction} Retrying the script!"
                elif [[ $(stat -c '%u' ${cloneDir}/${cachyRp}) -eq 0 ]] || [[ $(stat -c '%u' ${cloneDir}/cachyos-repo) -eq 0 ]]; then
                  echo " :: ${indentError} The folder has ${indentWarning}root${indentWarning} ownership. Manual intervention required - ${indentError} Code: 1"
                  exit 1
                fi
              fi
              ;;
            n|N|""|*)
              if [[ $(stat -c '%U' ${cloneDir}/${cachyRp}) = $USER ]] || [[ $(stat -c '%U' ${cloneDir}/cachyos-repo) = $USER ]]; then
                echo " :: ${indentNotice} Deleting ${indentGreen}the repository."
                rm -rf ${cloneDir}/${cachyRp}
                rm -rf ${cloneDir}/cachyos-repo
                break
              elif [[ $(stat -c '%u' ${cloneDir}/${cachyRp}) -eq 0 ]] || [[ $(stat -c '%u' ${cloneDir}/cachyos-repo) -eq 0 ]]; then
                echo " :: ${indentError} The file has ${indentWarning}root${indentWarning} ownership!!! ${indentError} Code: 1"
                exit 1
              fi
              ;;
          esac
          ;;
      esac
    else
      prompt_timer 120 "${indentNotice} Would you like to get cachyos-repository? "
      case "$PROMPT_INPUT" in
        y|Y)
          curl "https://mirror.cachyos.org/${cachyRp}" -o "${cloneDir}/${cachyRp}"
          tar xvf "${cloneDir}/${cachyRp}" -C "${cloneDir}"
          sudo bash "${cloneDir}/cachyos-repo/cachyos-repo.sh"
          echo " :: ${indentOk} Repository has been ${indentGreen}installed${indentGreen} successfully."
          break
          ;;
        n|N|""|*)
          echo " :: ${indentReset} Aborting installation due to user preference."
          break
          ;;
      esac 
    fi
  done
fi

if [[ $check = "Y" ]] || [[ $check = "y" ]]; then
  prompt_timer 120 "${indentAction} Would you like to install yay?"

  case "$PROMPT_INPUT" in
    [Yy]*)
      git clone "https://aur.archlinux.org/${aurRp}.git" "${cloneDir}/${aurRp}"
      var=$(stat -c '%U' "${cloneDir}/${aurRp}")
      var1=$(stat -c '%U' "${cloneDir}/${aurRp}/PKGBUILD")

      if [[ $var = "$USER" ]] && [[ $var1 = "$USER" ]]; then
        (cd "${cloneDir}/${aurRp}/" && makepkg -si)
      fi
      ;;
    [Nn]*|""|*)
      echo " :: ${indentReset} Aborting Installation due to user preference. ${aurRp} wasn't ${indentOrange}installed${indentOrange}."
      ;;
  esac
fi

if [[ $check = "Y" ]] || [[ $check = "y" ]]; then
  while true; do
    if [[ -e "${pkgsRp}" ]]; then
      if [[ $(stat -c '%U' ${pkgsRp}) = $USER ]]; then
        ${pkgsRp} --hyprland
        echo -e " :: ${indentOk} All hyprland packages were ${indentGreen}installed${indentGreen}."
      elif [[ $(stat -c '%u' ${pkgsRp}) -eq 0 ]]; then
        echo " :: ${indentError} The shell script has ${indentWarning}root ownership!!! ${indentWarning}Exiting${indentWarning}"
       exit 1
      fi
      prompt_timer 120 "${indentNotice} Would you like to get additional packages?"
      case "$PROMPT_INPUT" in
        [Yy]*)
          echo -e " :: ${indentAction} Proeeding installation due to User's request."
          ${pkgsRp} --extra
          echo -e " :: ${indentOk} All extra packages were ${indentGreen}installed${indentGreen}"
          break
          ;;
        [Nn]|*)
          echo -e " :: ${indentAction} Avorting installation due to User Preferences."
          break
          ;;
      esac
      prompt_timer 120 "${indentNotice} Would you also like to get driver packages? [Intel Only]"
      case "$PROMPT_INPUT" in
        [Yy]*)
          echo -e " :: ${indentAction} Proceeding installation due to User's request."
          ${pkgsRp} --driver
          echo -e " :: ${indentAction} All driver packages were ${indentGreen}installed${indentGreen}"
          break
          ;;
        [Nn]|*)
          echo -e " :: ${indentReset} Avorting installation due to User Preferences."
          break
          ;;
      esac
    else
      echo " :: ${indentError} The Package DOES NOT EXIST!! ${indentWarning}"
      exit 0
    fi
  done
fi

if [[ -d $configDir ]]; then
  if [[ $(stat -c '%U' ${configDir}) = $USER ]]; then
    echo -e "${indentOk} Populating ${confDir}"
    ${scrDir}/dircaller.sh --all ${homDir}/ 
  elif [[ $(stat -c '%u' ${configDir}) -eq 0 ]]; then
    echo -e "${indentError} The directory is owned by ${indentWarning}root! ${indentWarning}Exiting${indentWarning}!"
    exit 1
  fi
  tar -xvf "${sourceDir}/Sweet-cursors.tar.xz" -C "${homDir}/.icons"
  if [[ ! -e "${confDir}/gtk-4.0/assets" ]] || [[ ! -e "${confDir}/gtk-4.0/gtk-dark.css" ]] || [[ -L "${confDir}/gtk-4.0/assets" ]] || [[ -L "${confDir}/gtk-4.0/gtk-dark.css" ]]; then
    ln -sf /usr/share/themes/adw-gtk3/assets "${confDir}/gtk-4.0/assets" 2>&1
    ln -sf /usr/share/themes/adw-gtk3/gtk-4.0/gtk-dark.css "${confDir}/gtk-4.0/gtk-dark.css" 2>&1
    echo -e "${indentOk} Symlink initialized."
  fi
  
  prompt_timer 120 "${indentAction} Would you like to switch to fish?"
  case $PROMPT_INPUT in
    Y|y)
      var=$(echo "$SHELL")
      echo -e "${indentNotice} Switching the shell to fish"
      chsh -s /usr/bin/fish
      var1=$(echo "$SHELL")
      echo -e " :: ${indentOk} Changed from $var to ${indentGreen}$var1${indentOrange} is completed!"
      ;;
    N|n|*|"")
      echo -e " :: ${indentReset} Aborting due to user preference. Keeping $(echo "$SHELL") intact."
      ;;
  esac
  prompt_timer 120 "${indentYellow} Would you like to get wallpapers?"
  case "$PROMPT_INPUT" in
    Y|y)
      echo -e " :: ${indentAction} Proceeding pulling repository due to User's repository."
      mkdir -p "${walDir}"
      if git clone --depth 1 "https://${repRp}" "${walDir}"; then
        echo -e " :: ${indentOk} ${indentMagenta}wallpapers${indentReset} cloned successfully!"
      else
        echo -e " :: ${indentError} Failed to clone ${indentYellow}wallpapers${indentReset}"
      fi
      ${localDir}/color-cache.sh
      echo -e " :: ${indentOk} ${indentOrange}wallpapers${indentGreen} has been cached by ${localDir}/color-cache.sh"
      ;;
    N|n)
      prompt_timer 120 "${indentAction} Would you like to pull from another repository? [Drop the full clone link or say --skip to avoid"
      case $prompt_input in
        "")
          echo -e " :: ${indentError} No Link was given. ${indentReset}"
          ;;
        *)
          if git clone --depth 1 "$PROMPT_INPUT" "${walDir}"; then
            echo -e " :: ${indentOk} ${indentMagenta}wallpapers${indentReset} cloned successfully"
          else
            echo -e " :: ${indentError} Failed to clone ${indentYellow}wallpapers${indentReset}"
          fi
          ${localDir}/color-cache.sh
          echo -e " :: ${indentOk} ${indentOrange}wallpapers${indentGreen} has been cached by ${localDir}/color-cache.sh"
          ;;
        --skip)
          echo -e " :: ${indentOk} Pulling wallpapers from source."
          if cp -r ${sourceDir}/assets/*.png "${walDir}" 2>/dev/null || cp -r ${sourceDir}/assets/*.jpg "${walDir}" 2>/dev/null; then
            echo -e " :: ${indentOk} Some ${indentMagenta}wallpapers${indentReset} copied successfully!"
          else
            echo -e " :: ${indentError} Failed to copy some ${indentYellow}wallpapers${indentReset}"
            ${localDir}/color-cache.sh 
            echo -e " :: ${indentOk} ${indentOrange}wallpapers${indentGreen} has been cached by ${localDir}/color-cache.sh"
          fi
          ;;
      esac
      ;;
  esac
fi

reboot

