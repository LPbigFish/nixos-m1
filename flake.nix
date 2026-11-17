{
  description = "A very basic flake";

  inputs = {
    apple-silicon.url = "github:nix-community/nixos-apple-silicon";
    nixpkgs.follows = "apple-silicon/nixpkgs";
    home-nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "home-nixpkgs";
    };
    nix-darwin = {
      url = "github:nix-darwin/nix-darwin";
      inputs.nixpkgs.follows = "home-nixpkgs";
    };
    dedsec-grub-theme = {
      url = "github:LPbigFish/dedsec-grub2-theme";
    };
    vim-conf = {
      url = "./modules/nvim";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { nixpkgs, home-nixpkgs, ... }@inputs:
    let
      system = "aarch64-linux";
      overlays = [
        (import ./overlays/generic-overlay.nix)
        inputs.vim-conf.overlays.default
      ];
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
        inherit overlays;
      };
      homePkgs = import home-nixpkgs {
        inherit system overlays;
        config.allowUnfree = true;
      };
    in
    {
      darwinConfigurations.macbook = inputs.nix-darwin.lib.darwinSystem {
        specialArgs = { inherit inputs; };
        modules = [
          ./darwin.nix
          inputs.home-manager.darwinModules.home-manager
        ];
      };

      nixosConfigurations.m1 = nixpkgs.lib.nixosSystem {

        inherit system pkgs;

        modules = [
          inputs.apple-silicon.nixosModules.default
          inputs.dedsec-grub-theme.nixosModule
          ./configuration.nix
        ];
      };

      homeConfigurations.lpbigfish = inputs.home-manager.lib.homeManagerConfiguration {
        pkgs = homePkgs;
        extraSpecialArgs = {
          inherit inputs;
          gnomeExtensions = import ./modules/gnome-extensions.nix { pkgs = homePkgs; };
        };
        modules = [ ./home/home.nix ];
      };
    };
}
