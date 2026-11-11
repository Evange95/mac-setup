# The package layer of the Nix path. Everything else (dotfile links, mise, git identity,
# macOS and security settings) is still done by the steps of ./setup.sh, so the two
# paths share one implementation instead of two that drift.
{
  pkgs,
  lib,
  profile,
  system,
  user,
  brewCleanup,
  ...
}:
let
  brewfile = import ./brewfile.nix { inherit lib; } [
    ../Brewfile
    (../. + "/Brewfile.${profile}")
  ];
  formulae = import ./formulae.nix pkgs;

  unmapped = builtins.filter (name: !(formulae ? ${name})) brewfile.brews;
  fromNix = builtins.filter (name: (formulae.${name} or null) != null) brewfile.brews;
  fromBrew = builtins.filter (name: (formulae.${name} or null) == null) brewfile.brews;
in
{
  assertions = [
    {
      assertion = unmapped == [ ];
      message = "Brewfile formulae without an entry in nix/formulae.nix: ${toString unmapped}";
    }
  ];

  environment.systemPackages = map (name: formulae.${name}) fromNix;
  # docker finds compose/buildx here (registered by steps/docker.sh)
  environment.pathsToLink = [ "/libexec/docker/cli-plugins" ];

  homebrew = {
    enable = true;
    taps = brewfile.taps;
    brews = fromBrew;
    casks = brewfile.casks;
    masApps = brewfile.masApps;
    onActivation = {
      # Like `brew bundle --no-upgrade` in the Homebrew path: upgrades are a separate, explicit action
      autoUpdate = false;
      upgrade = false;
      # none: leave undeclared packages alone (steps/packages.sh reports them);
      # uninstall: remove them. Set with BREW_CLEANUP in setup.conf.
      cleanup = brewCleanup;
    };
  };

  nix = {
    settings.experimental-features = [
      "nix-command"
      "flakes"
    ];
    # The store only grows otherwise
    gc = {
      automatic = true;
      options = "--delete-older-than 14d";
    };
    optimise.automatic = true;
  };

  # Lets nix-darwin own /etc/zshenv and /etc/zshrc, but without its global compinit and
  # prompt: the managed ~/.zshrc does both, and doing them twice costs startup time.
  programs.zsh = {
    enable = true;
    enableCompletion = false;
    enableBashCompletion = false;
    enableGlobalCompInit = false;
    promptInit = "";
  };

  # /nix is millions of small immutable files that can always be rebuilt:
  # indexing them or backing them up only burns CPU and disk.
  system.activationScripts.postActivation.text = ''
    /usr/bin/mdutil -i off /nix > /dev/null 2>&1 || true
    /usr/bin/tmutil addexclusion -p /nix > /dev/null 2>&1 || true
  '';

  system.primaryUser = user;
  users.users.${user}.home = "/Users/${user}";

  nixpkgs.hostPlatform = system;
  system.stateVersion = 6;
}
