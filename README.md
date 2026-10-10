# libfprint-10a5-9800

Updated flake and patch (compatible with `libfprint v1.94.100+`) to enable support for fingerprint reader `10a5:9800` on NixOS. Based on [andrevmatos' flake and patch](https://github.com/NixOS/nixpkgs/issues/324624#issuecomment-2692141032).

## Usage

**1. Add the flake to your inputs and modules**

Edit your system's `flake.nix` to include this repository and import the provided NixOS module:

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    
    libfprint-10a5-9800 = {
      url = "github:furcom/libfprint-10a5-9800";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, libfprint-10a5-9800, ... }: {
    nixosConfigurations."your-hostname" = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ./configuration.nix
        
        # Import the module
        libfprint-10a5-9800.nixosModules.default
      ];
    };
  };
}
```

**2. Enable the service**

Add the following option to your `configuration.nix` (or any other hardware module file) to activate the patched driver and `fprintd`:

```nix
services.libfprint-10a5-9800.enable = true;
```
