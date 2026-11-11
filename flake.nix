{
  description = "mac-setup: the package layer of ./setup.sh --nix (nix-darwin), for the personal and work profiles";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:nix-darwin/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    { nixpkgs, nix-darwin, ... }:
    let
      system = "aarch64-darwin";

      # Machine-specific values come from setup.conf through steps/packages.sh (--impure),
      # so nothing personal is committed. The defaults keep `nix flake check` working.
      env =
        name: default:
        let
          value = builtins.getEnv name;
        in
        if value == "" then default else value;

      mkProfile =
        profile:
        nix-darwin.lib.darwinSystem {
          specialArgs = {
            inherit profile system;
            user = env "MAC_SETUP_USER" "user";
            brewCleanup = env "MAC_SETUP_BREW_CLEANUP" "none";
          };
          modules = [ ./nix/darwin.nix ];
        };
    in
    {
      darwinConfigurations = nixpkgs.lib.genAttrs [ "personal" "work" ] mkProfile;

      # First run, before darwin-rebuild is on the PATH: nix run .#darwin-rebuild -- switch ...
      packages.${system}.darwin-rebuild = nix-darwin.packages.${system}.darwin-rebuild;
    };
}
