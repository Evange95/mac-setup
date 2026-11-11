# Reads Brewfiles so they stay the single package list for both ./setup.sh and Nix.
# Understands one entry per line: brew "x" / cask "x" / tap "x" / mas "Name", id: 123
{ lib }:
files:
let
  lines = lib.concatMap (file: lib.splitString "\n" (builtins.readFile file)) files;

  named =
    kind:
    lib.concatMap (
      line:
      let
        found = builtins.match "${kind} \"([^\"]+)\".*" line;
      in
      if found == null then [ ] else found
    ) lines;

  masApps = lib.concatMap (
    line:
    let
      found = builtins.match "mas \"([^\"]+)\", id: ([0-9]+).*" line;
    in
    if found == null then
      [ ]
    else
      [
        {
          name = builtins.elemAt found 0;
          value = lib.toInt (builtins.elemAt found 1);
        }
      ]
  ) lines;
in
{
  brews = named "brew";
  casks = named "cask";
  taps = named "tap";
  masApps = builtins.listToAttrs masApps;
}
