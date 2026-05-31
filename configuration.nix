# Save this file to /mnt/etc/nixos/configuration.nix during installation
{ config, pkgs, ... }:

{
  imports = [ 
    # Mandatory local hardware storage and partition configuration
    ./hardware-configuration.nix 
  ];

  # =========================================================================
  # 1. BOOTLOADER 
  # =========================================================================
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  boot.initrd.luks.devices."cryptroot" = {
    # Run `lsblk -f` on your terminal to grab your nvme0n1p2 partition's UUID
    device = "/dev/disk/by-uuid/902819ef-6fbd-44d8-9ce6-1ce774eb57be";
  };

  boot.kernelPackages = pkgs.linuxPackages_latest;

  # =========================================================================
  # 2. NETWORKING & FIRMWARE (Your Intel Setup)
  # =========================================================================
  networking.hostName = "thinkpad-x1";
  networking.networkmanager.enable = true; # Gives you 'nmtui' in TTY

  # Enable WireGuard kernel modules and routing support natively
  networking.wireguard.enable = true;

  time.timeZone = "Europe/Stockholm";
  services.timesyncd.enable = true;

  # =========================================================================
  # 3. SOUND STACK (PipeWire for Sway)
  # =========================================================================
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };
  services.pipewire.wireplumber.extraConfig."10-bluetooth" = {
    "monitor.bluez.properties" = {
      "bluez5.enable-sbc-xq" = true;
      "bluez5.enable-msbc" = true;
      "bluez5.enable-hw-volume" = true;
    };
  };

  # Enable Bluetooth hardware support
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true; # Automatically power up the Bluetooth card on boot
    settings = {
      General = {
        Experimental = true; # Enables battery level tracking for headphones
      };
    };
  };
  
  # Enables battery monitoring daemons so i3status-rs can read your battery life
  services.upower.enable = true;
  services.dbus.enable = true;
  security.polkit.enable = true;
  hardware.graphics.enable = true;
  services.fwupd.enable = true;

  # =========================================================================
  # 4. MINIMAL TTY & SWAY (No Login Manager)
  # =========================================================================
  programs.sway = {
    enable = true;
    wrapperFeatures.gtk = true; 
  };


  programs.neovim = {
    enable = true;
    vimAlias = true;
    viAlias = true;
  };

  # Suppress display managers and boot completely to text console
  services.xserver.enable = false;

  # =========================================================================
  # 5. USER ACCOUNT & SHELL 
  # =========================================================================
  programs.zsh.enable = true;

  users.users.robert = {
    isNormalUser = true;
    extraGroups = [ "wheel" "video" "audio" "networkmanager" ]; 
    shell = pkgs.zsh;

    # Required for podman
    subUidRanges = [{ startUid = 100000; count = 65536; }];
    subGidRanges = [{ startGid = 100000; count = 65536; }];
    
    # OPTIONAL: Paste your MacBook's public key here to bypass SSH passwords
    # openssh.authorizedKeys.keys = [ "ssh-ed25519 AAAAC3... user@macbook" ];
  };

  # =========================================================================
  # 6. REMOTE MANAGEMENT (MacBook SSH)
  # =========================================================================
  services.openssh = {
    enable = true;
    settings.PermitRootLogin = "no";
  };

  security.pki.certificateFiles = [
    ./certs/rootCA.crt
  ];

  # Enable the Flakes toolchain and modern Nix command-line interface
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # =========================================================================
  # 6.5 VIRTUALIZATION & CONTAINERS (Podman Engine)
  # =========================================================================
  virtualisation.podman = {
    enable = true;
    
    # Creates a 'docker' alias wrapper so standard docker CLI triggers function seamlessly
    dockerCompat = true;

    # Activates internal DNS management so container pods can talk to each other safely
    defaultNetwork.settings.dns_enabled = true;
  };

  # =========================================================================
  # 7. CORE PACKAGES & ENVIRONMENT
  # =========================================================================
  environment.systemPackages = with pkgs; [
    foot
    brave
    chromium
    keepassxc
    wireguard-tools
    adwaita-icon-theme
    lm_sensors
    btop
    libnotify
    openssl
    
    git
    silver-searcher
    ripgrep
    curl
    wget
    tree
    bat

    # sway deps
    i3status-rust
    wofi
    
    wl-clipboard   # Core Wayland copy/paste engine
    brightnessctl  # Backlight control
    wlr-randr      # Display resolution engine
    kanshi         # Dynamic monitor profile daemon
    clipman        # Clipboard history manager
    wlsunset       # Night light / color temperature daemon
    mako           # Notificaitons

    gcc
    nodejs_22
    podman-compose
    fastfetch

    nvd

    tree-sitter
    nixd       # The Nix Language Server
    alejandra  # The lightning-fast Nix code formatter
  ];

  # =========================================================================
  # 8. FONTS & COLOR EMOJI CONFIGURATION
  # =========================================================================
  fonts = {
    # 1. Register the core typography assets to your environment
    packages = with pkgs; [
      nerd-fonts.jetbrains-mono  # Your Alacritty / Sway coding font
      noto-fonts-color-emoji     # Google's complete, native color emoji set
      font-awesome               # Font Awesome icons for i3status-rs / Waybar
    ];

    # 2. Tell Fontconfig to use Noto Color Emoji as a system fallback
    # This prevents applications like Brave from rendering blank square boxes []
    fontconfig = {
      enable = true;
      defaultFonts = {
        # Ensures that emojis automatically resolve inline inside your terminal
        monospace = [ "JetBrainsMono Nerd Font" "Noto Color Emoji" ];
        sansSerif = [ "DejaVu Sans" "Noto Color Emoji" ];
        serif     = [ "DejaVu Serif" "Noto Color Emoji" ];
        emoji     = [ "Noto Color Emoji" ];
      };
    };
  };

  system.stateVersion = "25.11"; 
}
