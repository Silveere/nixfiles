{
  lib,
  newScope,
  python,
}:
# i have no idea what this is but there's some conflict if i don't do this
# based on https://github.com/NixOS/nixpkgs/blob/77f0d2095a8271fdb6e0d08c90a7d93631fd2748/pkgs/applications/audio/mopidy/default.nix
lib.makeScope newScope (self:
    with self; {
      inherit python;
      pythonPackages = python.pkgs;

      mopidy-autoplay = callPackage ./autoplay.nix {};
    })
