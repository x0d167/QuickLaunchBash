#!/bin/sh -e

RC='\033[0m'
RED='\033[31m'
YELLOW='\033[33m'
GREEN='\033[32m'

# Check if the home directory and linuxtoolbox folder exist, create them if they don't
LINUXTOOLBOXDIR="$HOME/linuxtoolbox"

if [ ! -d "$LINUXTOOLBOXDIR" ]; then
  echo "${YELLOW}Creating linuxtoolbox directory: $LINUXTOOLBOXDIR${RC}"
  mkdir -p "$LINUXTOOLBOXDIR"
  echo "${GREEN}linuxtoolbox directory created: $LINUXTOOLBOXDIR${RC}"
fi

if [ -d "$LINUXTOOLBOXDIR/QuickLaunchBash" ]; then rm -rf "$LINUXTOOLBOXDIR/QuickLaunchBash"; fi

echo "${YELLOW}Cloning QuickLaunchBash repository into: $LINUXTOOLBOXDIR/QuickLaunchBash${RC}"
git clone https://github.com/x0d167/QuickLaunchBash "$LINUXTOOLBOXDIR/QuickLaunchBash"
if [ $? -eq 0 ]; then
  echo "${GREEN}Successfully cloned QuickLaunchBash repository${RC}"
else
  echo "${RED}Failed to clone QuickLaunchBash repository${RC}"
  exit 1
fi

# add variables to top level so can easily be accessed by all functions
PACKAGER=""
SUDO_CMD=""
SUGROUP=""
GITPATH=""

cd "$LINUXTOOLBOXDIR/QuickLaunchBash" || exit

command_exists() {
  command -v "$1" >/dev/null 2>&1
}

checkEnv() {
  ## Check for requirements.
  REQUIREMENTS='curl groups sudo'
  for req in $REQUIREMENTS; do
    if ! command_exists "$req"; then
      echo "${RED}To run me, you need: $REQUIREMENTS${RC}"
      exit 1
    fi
  done

  ## Check Package Handler
  PACKAGEMANAGER='nala apt dnf yum pacman zypper emerge xbps-install nix-env'
  for pgm in $PACKAGEMANAGER; do
    if command_exists "$pgm"; then
      PACKAGER="$pgm"
      echo "Using $pgm"
      break
    fi
  done

  if [ -z "$PACKAGER" ]; then
    echo "${RED}Can't find a supported package manager${RC}"
    exit 1
  fi

  if command_exists sudo; then
    SUDO_CMD="sudo"
  elif command_exists doas && [ -f "/etc/doas.conf" ]; then
    SUDO_CMD="doas"
  else
    SUDO_CMD="su -c"
  fi

  echo "Using $SUDO_CMD as privilege escalation software"

  ## Check if the current directory is writable.
  GITPATH=$(dirname "$(realpath "$0")")
  if [ ! -w "$GITPATH" ]; then
    echo "${RED}Can't write to $GITPATH${RC}"
    exit 1
  fi

  ## Check SuperUser Group

  SUPERUSERGROUP='wheel sudo root'
  for sug in $SUPERUSERGROUP; do
    if groups | grep -q "$sug"; then
      SUGROUP="$sug"
      echo "Super user group $SUGROUP"
      break
    fi
  done

  ## Check if member of the sudo group.
  if ! groups | grep -q "$SUGROUP"; then
    echo "${RED}You need to be a member of the sudo group to run me!${RC}"
    exit 1
  fi
}

installDepend() {
  ## Check for dependencies.
  DEPENDENCIES='bash bash-completion tar batcat tree multitail fastfetch wget unzip fontconfig stow'

  echo "${YELLOW}Installing dependencies...${RC}"
  if [ "$PACKAGER" = "pacman" ]; then
    if ! command_exists yay && ! command_exists paru; then
      echo "Installing yay as AUR helper..."
      ${SUDO_CMD} ${PACKAGER} --noconfirm -S base-devel
      cd /opt && ${SUDO_CMD} git clone https://aur.archlinux.org/yay-git.git && ${SUDO_CMD} chown -R "${USER}:${USER}" ./yay-git
      cd yay-git && makepkg --noconfirm -si
    else
      echo "AUR helper already installed"
    fi
    if command_exists yay; then
      AUR_HELPER="yay"
    elif command_exists paru; then
      AUR_HELPER="paru"
    else
      echo "No AUR helper found. Please install yay or paru."
      exit 1
    fi
    ${AUR_HELPER} --noconfirm -S ${DEPENDENCIES}
  elif [ "$PACKAGER" = "nala" ]; then
    ${SUDO_CMD} ${PACKAGER} install -y ${DEPENDENCIES}
  elif [ "$PACKAGER" = "emerge" ]; then
    ${SUDO_CMD} ${PACKAGER} -v app-shells/bash app-shells/bash-completion app-arch/tar app-editors/neovim sys-apps/bat app-text/tree app-text/multitail app-misc/fastfetch
  elif [ "$PACKAGER" = "xbps-install" ]; then
    ${SUDO_CMD} ${PACKAGER} -v ${DEPENDENCIES}
  elif [ "$PACKAGER" = "nix-env" ]; then
    ${SUDO_CMD} ${PACKAGER} -iA nixos.bash nixos.bash-completion nixos.gnutar nixos.neovim nixos.bat nixos.tree nixos.multitail nixos.fastfetch nixos.pkgs.starship
  elif [ "$PACKAGER" = "dnf" ]; then
    ${SUDO_CMD} ${PACKAGER} install -y ${DEPENDENCIES}
  else
    ${SUDO_CMD} ${PACKAGER} install -yq ${DEPENDENCIES}
  fi

  # Check to see if the MesloLGS Nerd Font is installed (Change this to whatever font you would like)
  FONT_NAME="MesloLGS Nerd Font Mono"
  if fc-list :family | grep -iq "$FONT_NAME"; then
    echo "Font '$FONT_NAME' is installed."
  else
    echo "Installing font '$FONT_NAME'"
    # Change this URL to correspond with the correct font
    FONT_URL="https://github.com/ryanoasis/nerd-fonts/releases/latest/download/Meslo.zip"
    FONT_DIR="$HOME/.local/share/fonts"
    # check if the file is accessible
    if wget -q --spider "$FONT_URL"; then
      TEMP_DIR=$(mktemp -d)
      wget -q --show-progress $FONT_URL -O "$TEMP_DIR"/"${FONT_NAME}".zip
      unzip "$TEMP_DIR"/"${FONT_NAME}".zip -d "$TEMP_DIR"
      mkdir -p "$FONT_DIR"/"$FONT_NAME"
      mv "${TEMP_DIR}"/*.ttf "$FONT_DIR"/"$FONT_NAME"
      # Update the font cache
      fc-cache -fv
      # delete the files created from this
      rm -rf "${TEMP_DIR}"
      echo "'$FONT_NAME' installed successfully."
    else
      echo "Font '$FONT_NAME' not installed. Font URL is not accessible."
    fi
  fi
}

installStarshipAndFzf() {
  if command_exists starship; then
    echo "Starship already installed"
    return
  fi

  if ! curl -sS https://starship.rs/install.sh | sh; then
    echo "${RED}Something went wrong during starship install!${RC}"
    exit 1
  fi
  if command_exists fzf; then
    echo "Fzf already installed"
  else
    git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
    ~/.fzf/install
  fi
}

installZoxide() {
  if command_exists zoxide; then
    echo "Zoxide already installed"
    return
  fi

  if ! curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh; then
    echo "${RED}Something went wrong during zoxide install!${RC}"
    exit 1
  fi
}

installRust() {
  if command_exists rustc; then
    echo "Rust already installed"
    return
  fi

  if ! curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh; then
    echo "${RED}Something went wrong during Rust install!${RC}"
    exit 1
  fi
}

install_additional_dependencies() {
  # Only install Neovim if it's not already installed
  if ! command_exists nvim; then
    echo "${YELLOW}Installing Neovim...${RC}"

    case "$PACKAGER" in
    *apt | *nala)
      # For apt/nala-based systems, install the latest AppImage version
      echo "${YELLOW}Installing latest Neovim AppImage...${RC}"
      # Download the latest Neovim AppImage
      curl -L -o nvim.appimage https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.appimage

      # Make it executable
      chmod u+x nvim.appimage

      # Move it to /usr/local/bin/nvim
      ${SUDO_CMD} mv nvim.appimage /usr/local/bin/nvim

      echo "${GREEN}Neovim AppImage installed to /usr/local/bin/nvim${RC}"
      ;;
    *zypper)
      ${SUDO_CMD} zypper refresh
      ${SUDO_CMD} zypper -n install neovim
      ;;
    *dnf)
      ${SUDO_CMD} dnf check-update
      ${SUDO_CMD} dnf install -y neovim
      ;;
    *pacman)
      ${SUDO_CMD} pacman -Syu
      ${SUDO_CMD} pacman -S --noconfirm neovim
      ;;
    *)
      echo "${YELLOW}No specific Neovim installation method for $PACKAGER.${RC}"
      echo "${YELLOW}Attempting to install using package manager...${RC}"
      ${SUDO_CMD} ${PACKAGER} install -y neovim

      if ! command_exists nvim; then
        echo "${YELLOW}Package manager installation failed. Installing AppImage version...${RC}"
        # Download the latest Neovim AppImage
        curl -L -o nvim.appimage https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.appimage

        # Make it executable
        chmod u+x nvim.appimage

        # Move it to /usr/local/bin/nvim
        ${SUDO_CMD} mv nvim.appimage /usr/local/bin/nvim

        echo "${GREEN}Neovim AppImage installed to /usr/local/bin/nvim${RC}"
      fi
      ;;
    esac
  else
    echo "${GREEN}Neovim already installed, skipping...${RC}"
  fi
}

setup_dotfiles() {
  DOTFILES_REPO="https://github.com/x0d167/.dotfiles.git"
  DOTFILES_DIR="$HOME/.dotfiles"

  print_colored "$YELLOW" "Setting up dotfiles..."

  # Check if dotfiles directory already exists
  if [ -d "$DOTFILES_DIR" ]; then
    print_colored "$YELLOW" "Dotfiles directory already exists at $DOTFILES_DIR"
    print_colored "$YELLOW" "Backing up existing dotfiles directory to $DOTFILES_DIR.bak"
    if ! mv "$DOTFILES_DIR" "$DOTFILES_DIR.bak"; then
      print_colored "$RED" "Failed to backup existing dotfiles directory"
      exit 1
    fi
  fi

  # Clone the dotfiles repository
  print_colored "$YELLOW" "Cloning dotfiles repository from $DOTFILES_REPO"
  if git clone "$DOTFILES_REPO" "$DOTFILES_DIR"; then
    print_colored "$GREEN" "Successfully cloned dotfiles repository"
  else
    print_colored "$RED" "Failed to clone dotfiles repository"
    exit 1
  fi

  # Run stow
  print_colored "$YELLOW" "Creating symlinks with stow..."
  cd "$DOTFILES_DIR" || exit
  if stow .; then
    print_colored "$GREEN" "Symbolic links created successfully"
  else
    print_colored "$RED" "Failed to create symbolic links with stow"
    exit 1
  fi
}

setup_wallpaper() {
  print_colored "$YELLOW" "Setting up wallpaper..."

  # Path to your wallpaper
  WALLPAPER_SOURCE="$LINUXTOOLBOXDIR/QuickLaunchBash/wallpaper.jpg" # Adjust path as needed
  WALLPAPER_DEST="$HOME/Pictures/wallpaper.jpg"

  # Create Pictures directory if it doesn't exist
  mkdir -p "$(dirname "$WALLPAPER_DEST")"

  # Copy wallpaper to Pictures directory
  if [ -f "$WALLPAPER_SOURCE" ]; then
    cp "$WALLPAPER_SOURCE" "$WALLPAPER_DEST"
    print_colored "$GREEN" "Wallpaper copied to $WALLPAPER_DEST"
  else
    print_colored "$RED" "Wallpaper not found at $WALLPAPER_SOURCE"
    return 1
  fi

  # Detect desktop environment
  if [ "$XDG_CURRENT_DESKTOP" = "GNOME" ] || [ "$XDG_CURRENT_DESKTOP" = "ubuntu:GNOME" ]; then
    print_colored "$YELLOW" "GNOME desktop environment detected"

    # Set wallpaper for GNOME
    gsettings set org.gnome.desktop.background picture-uri "file://$WALLPAPER_DEST"
    gsettings set org.gnome.desktop.background picture-uri-dark "file://$WALLPAPER_DEST"

    # Check if using Wayland
    if [ "$XDG_SESSION_TYPE" = "wayland" ]; then
      print_colored "$YELLOW" "Wayland display server detected"
      gsettings set org.gnome.desktop.background picture-uri-dark "file://$WALLPAPER_DEST"
    fi

    print_colored "$GREEN" "Wallpaper set successfully for GNOME"

  elif [ "$XDG_CURRENT_DESKTOP" = "KDE" ]; then
    print_colored "$YELLOW" "KDE desktop environment detected"

    # Set wallpaper for KDE Plasma
    if command_exists plasma-apply-wallpaperimage; then
      plasma-apply-wallpaperimage "$WALLPAPER_DEST"
      print_colored "$GREEN" "Wallpaper set successfully for KDE"
    else
      print_colored "$RED" "plasma-apply-wallpaperimage not found. Unable to set KDE wallpaper automatically"
    fi

  elif [ "$XDG_CURRENT_DESKTOP" = "XFCE" ]; then
    print_colored "$YELLOW" "XFCE desktop environment detected"

    # Set wallpaper for XFCE
    if command_exists xfconf-query; then
      for i in $(xfconf-query -c xfce4-desktop -p /backdrop -l | grep -E "screen.*/monitor.*image-path$"); do
        xfconf-query -c xfce4-desktop -p "$i" -s "$WALLPAPER_DEST"
      done
      print_colored "$GREEN" "Wallpaper set successfully for XFCE"
    else
      print_colored "$RED" "xfconf-query not found. Unable to set XFCE wallpaper automatically"
    fi

  elif [ "$XDG_CURRENT_DESKTOP" = "i3" ] || [ "$XDG_CURRENT_DESKTOP" = "sway" ]; then
    print_colored "$YELLOW" "i3/sway window manager detected"

    # Set wallpaper for i3/sway
    if command_exists feh; then
      feh --bg-fill "$WALLPAPER_DEST"

      # Add to i3 config for persistence
      if [ -f "$HOME/.config/i3/config" ]; then
        if ! grep -q "feh --bg-fill" "$HOME/.config/i3/config"; then
          echo "exec --no-startup-id feh --bg-fill $WALLPAPER_DEST" >>"$HOME/.config/i3/config"
        fi
      fi

      print_colored "$GREEN" "Wallpaper set successfully for i3 using feh"
    elif command_exists swaybg; then
      # For Sway (Wayland)
      if [ -f "$HOME/.config/sway/config" ]; then
        if ! grep -q "output \* bg" "$HOME/.config/sway/config"; then
          echo "output * bg $WALLPAPER_DEST fill" >>"$HOME/.config/sway/config"
        fi
      fi
      print_colored "$GREEN" "Wallpaper configuration added for Sway"
    else
      print_colored "$RED" "feh or swaybg not found. Unable to set wallpaper for i3/sway"
    fi
  else
    print_colored "$YELLOW" "Desktop environment not detected or not supported"
    print_colored "$YELLOW" "Wallpaper saved to $WALLPAPER_DEST, please set it manually"
  fi
}

setup_gnome_config() {
  print_colored "$YELLOW" "Checking for GNOME desktop environment..."

  # Check if running in GNOME
  if [ "$XDG_CURRENT_DESKTOP" = "GNOME" ] || [ "$XDG_CURRENT_DESKTOP" = "ubuntu:GNOME" ]; then
    print_colored "$YELLOW" "GNOME desktop environment detected"

    # Path to your GNOME config file
    GNOME_CONFIG_FILE="$LINUXTOOLBOXDIR/QuickLaunchBash/gnome-shell-config.txt"

    # Check if the config file exists
    if [ -f "$GNOME_CONFIG_FILE" ]; then
      print_colored "$YELLOW" "Loading GNOME shell extensions and configurations..."

      # Load GNOME configurations using dconf
      if dconf load /org/gnome/shell/extensions/ <"$GNOME_CONFIG_FILE"; then
        print_colored "$GREEN" "GNOME configurations loaded successfully"
      else
        print_colored "$RED" "Failed to load GNOME configurations"
      fi
    else
      print_colored "$YELLOW" "GNOME configuration file not found at: $GNOME_CONFIG_FILE"
    fi
  else
    print_colored "$YELLOW" "Not running GNOME. Skipping GNOME configuration setup."
  fi
}

checkEnv
installDepend
installStarshipAndFzf
installZoxide
install_additional_dependencies
create_fastfetch_config
setup_gnome_config # Add this line to call the new function

if setup_dotfiles; then
  echo "${GREEN}Done!\nrestart your shell to see the changes.${RC}"
else
  echo "${RED}Something went wrong!${RC}"
fi
