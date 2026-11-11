# Which nixpkgs package replaces each `brew` line of the Brewfiles in the Nix path.
# null = keep installing it with Homebrew. Every formula must be listed: the build
# fails with the missing names otherwise, so the two paths cannot drift apart.
pkgs: {
  git = pkgs.git;
  curl = pkgs.curl;
  wget = pkgs.wget;
  coreutils = pkgs.coreutils;
  jq = pkgs.jq;
  yq = pkgs.yq-go;

  bat = pkgs.bat;
  eza = pkgs.eza;
  ripgrep = pkgs.ripgrep;
  fd = pkgs.fd;
  fzf = pkgs.fzf;
  zoxide = pkgs.zoxide;
  btop = pkgs.btop;
  xh = pkgs.xh;
  tlrc = pkgs.tlrc;
  tree = pkgs.tree;
  watch = pkgs.watch;

  mise = pkgs.mise;
  gh = pkgs.gh;
  lazygit = pkgs.lazygit;
  git-delta = pkgs.delta;
  direnv = pkgs.direnv;
  just = pkgs.just;
  watchexec = pkgs.watchexec;
  hyperfine = pkgs.hyperfine;
  shellcheck = pkgs.shellcheck;
  git-filter-repo = pkgs.git-filter-repo;
  bats-core = pkgs.bats;
  starship = pkgs.starship;

  ffmpeg = pkgs.ffmpeg;
  webp = pkgs.libwebp;
  p7zip = pkgs.p7zip;
  unzip = pkgs.unzip;

  colima = pkgs.colima;
  docker = pkgs.docker-client;
  docker-compose = pkgs.docker-compose;
  docker-buildx = pkgs.docker-buildx;
  docker-credential-helper = pkgs.docker-credential-helpers;

  # Stay in Homebrew
  mas = null; # brew bundle needs it for the `mas` entries
  rtk = null; # not checked against the nixpkgs package of the same name
  mole = null; # same
  # zshrc sources the plugins from the Homebrew prefix (and you-should-use is Linux-only in nixpkgs)
  zsh-autosuggestions = null;
  zsh-fast-syntax-highlighting = null;
  zsh-completions = null;
  zsh-you-should-use = null;
}
