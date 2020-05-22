#!/usr/bin/env bash

function cosmonautic_error_exit() {
  echo -e "error: $1"
  exit 1
}

function cosmonautic_os_detect {
  cosmonautic_os_type=""    # macos/linux
  cosmonautic_os_version="" # version
  cosmonautic_os_variant="" # release codename (macos), distribution (linux)

  # detect target operating system
  case $(uname | tr '[:upper:]' '[:lower:]') in
    linux*)
      cosmonautic_os_type="linux"
      cosmonautic_os_version=$(cat /etc/*release \
      | grep ^VERSION_ID \
      | tr -d 'VERSION_ID="' \
      | tr '[:upper:]' '[:lower:]')
      cosmonautic_os_variant=$(cat /etc/*release \
      | grep ^NAME \
      | tr -d 'NAME="' \
      | tr '[:upper:]' '[:lower:]')
      ;;
    darwin*)
      cosmonautic_os_type="macos"
      cosmonautic_os_version=$(sw_vers -productVersion | awk -F '.' '{print $1 "." $2}')

      if [[ $cosmonautic_os_version == "10.14" ]]; then
        cosmonautic_os_variant="mojave"
      elif [[ $cosmonautic_os_version == "10.15" ]]; then
        cosmonautic_os_variant="catalina"
      else
        cosmonautic_error_exit "unsupported version of $os_type ($os_version)"
      fi
      ;;
  esac
}

function cosmonautic_macos_ensure_brew {
  cosmonautic_os_detect

  if [[ $os_type == "macos" ]]; then
    if [[ $(command -v brew) == "" ]]; then
      xcode_clt_installed=$(xcode-select -p 1>/dev/null; echo $?)

      if [[ $xcode_clt_installed != 0 ]]; then
        echo -e "installing xcode command line tools"
        touch /tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress; \
        PROD=$(softwareupdate -l \
        | grep "\*.*Command Line" \
        | head -n 1 \
        | awk -F"*" '{print $2}' \
        | sed -e 's/^ *//' \
        | tr -d '\n') \
        && softwareupdate -i "$PROD" --verbose \
        && rm /tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress \
        && echo -e "xcode command line tools are installed" \
        || cosmonautic_error_exit "unable to install xcode command line tools" 
      fi

      echo -e "installing brew"
      CI=1 yes '' \
      | /usr/bin/ruby -e "$(curl -fsSL $macos_brew_url)" \
      && brew analytics off \
      && echo -e "brew is installed" \
      || cosmonautic_error_exit "unable to install brew" 
    else
      echo -e "updating brew"
      brew update \
      && echo -e "brew is updated" \
      || cosmonautic_error_exit "unable to update brew" 
    fi
  else
    cosmonautic_error_exit "operating system is not macos"
  fi
}

function cosmonautic_macos_ensure_brew_formula {
  cosmonautic_os_detect

  if [[ $os_type == "macos" ]]; then
    if [[ $(command -v brew) == "" ]]; then
      cosmonautic_error_exit "brew is not installed" 
    else
      echo -e "updating brew"
      brew update \
      && echo -e "brew is updated" \
      || cosmonautic_error_exit "unable to update brew"

      echo -e "installing $1"
      brew install docker \
      && echo -e "$1 is installed" \
      || cosmonautic_error_exit "unable to install $1"
    fi
  else
    cosmonautic_error_exit "operating system is not macos"
  fi
}

function cosmonautic_macos_ensure_brew_cask {
  cosmonautic_os_detect

  if [[ $os_type == "macos" ]]; then
    if [[ $(command -v brew) == "" ]]; then
      cosmonautic_error_exit "brew is not installed" 
    else
      echo -e "updating brew"
      brew update \
      && echo -e "brew is updated" \
      || cosmonautic_error_exit "unable to update brew"

      echo -e "installing $1"
      brew cask install docker \
      && echo -e "$1 is installed" \
      || cosmonautic_error_exit "unable to install $1"
    fi
  else
    cosmonautic_error_exit "operating system is not macos"
  fi
}
