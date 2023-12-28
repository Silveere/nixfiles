{
  description = "NixOS Configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.11";
                 # ^^^^^^^^^^^^^ this part is optional
    nixpkgs-unstable.url = "github:Nixos/nixpkgs/nixpkgs-unstable";
  };

  outputs = { self, nixpkgs }: 
  let
    # i don't define system here because each system should be defined in here
    lib = nixpkgs.lib;
  in {
    nixosConfigurations = {
      slab = lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./hosts/slab/configuration.nix
          ./hosts/slab/nvidia-optimus.nix
          ./roles/remote.nix
          ./roles/desktop.nix
        ];
      };
      nullbox = lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./hosts/nullbox/configuration.nix
          ./roles/remote.nix
          ./roles/desktop.nix
        ];
      };
    };
  };
}
