nixfiles: final: prev:
let
  pkgs-unstable = import nixfiles.inputs.nixpkgs-unstable { config.allowUnfree = true; inherit (final) system; };
  inherit (final) callPackage lib electron_28;

  backport = pkg: let
    inherit (lib) getAttrFromPath;
    inherit (builtins) getAttr isString;
    getAttr' = name: attrs: if isString pkg then getAttr name attrs else getAttrFromPath name attrs;
    oldPkg = getAttr' pkg prev;
    newPkg = getAttr' pkg pkgs-unstable;
  in if oldPkg.version == newPkg.version
    then oldPkg
    else (callPackage newPkg.override);

in {

  vesktop = backport "vesktop" { };
  obsidian = backport "obsidian" { electron = final.electron_28; };
}
