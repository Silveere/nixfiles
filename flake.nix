{
  description = "NixOS Configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.11";
                 # ^^^^^^^^^^^^^ this part is optional
  };

  outputs = { self, nixpkgs }: 
  let
    lib = nixpkgs.lib;
  in {
    nixosConfigurations = {
      slab = lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./hosts/slab/configuration.nix
          ./hosts/slab/nvidia-optimus.nix
          ./roles/base.nix
          ./roles/me.nix
          ./roles/remote.nix
          ./roles/desktop.nix
        ];
      };
    };
  };
}
