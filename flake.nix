{
  description = "A very basic flake";

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

        modules = [
          inputs.apple-silicon.nixosModules.default
          inputs.aurora.nixosModules.default
          inputs.aurora.nixosModules.installed

          inputs.dedsec-grub-theme.nixosModule
          ./configuration.nix

          {
            nixpkgs.overlays = [
              inputs.apple-silicon.overlays.default
              inputs.aurora.overlays.default
            ]
            ++ overlays;

            nixpkgs.config.allowUnfree = true;

            aurora.desktop = "gnome";
            aurora.update.flake = "/etc/nixos#m1";
            aurora.stage2.requiredBoards = [ "j293" ];

            boot.loader.grub.timeoutStyle = "menu";
            boot.loader.timeout = 10;
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
