{
  description = "Aurora NixOS, Home Manager, and nix-darwin for Apple Silicon";

  inputs = {
    aurora.url = "github:aurora-silicon/nixos-aurora/channel-testing";
    apple-silicon.follows = "aurora/apple-silicon";
    nixpkgs.follows = "aurora/nixpkgs";
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
        inherit system;
        specialArgs = { inherit inputs; };

        modules = [
          ./configuration.nix

          {
            nixpkgs.overlays = overlays;
            nixpkgs.config.allowUnfree = true;
          }
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
