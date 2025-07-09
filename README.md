# durdraw-flake

A Nix flake for [durdraw](https://durdraw.org) - an ASCII, Unicode and ANSI art editor for Unix-like systems.

## What is durdraw?

Durdraw is a versatile text-based art editor that allows you to create ASCII, Unicode, and ANSI art directly in your terminal. It supports multiple color modes, various drawing tools, and can export to different formats.

## Installation

### Using the flake in your NixOS configuration

Add this flake as an input to your `flake.nix`:

```nix
{
  inputs = {
    # ... your other inputs
    durdraw = {
      url = "github:tahuffman1s/durdraw-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, durdraw, ... }@inputs: {
    # ... your configuration
  };
}
```

Then add it to your packages:

```nix
# In your configuration.nix or home.nix
environment.systemPackages = with pkgs; [
  # ... your other packages
  inputs.durdraw.packages.${pkgs.system}.default
];

# Or in Home Manager
home.packages = with pkgs; [
  # ... your other packages
  inputs.durdraw.packages.${pkgs.system}.default
];
```

### Direct installation

You can also install durdraw directly without adding it to your configuration:

```bash
# Install temporarily
nix shell github:tahuffman1s/durdraw-flake

# Install to your profile
nix profile install github:tahuffman1s/durdraw-flake
```

### Try it out

Test durdraw without installing:

```bash
nix run github:tahuffman1s/durdraw-flake
```

## Available Packages

This flake provides the following packages:

- `default` - The main durdraw package
- `durdraw` - Alias for the main package

## Available Apps

- `default` - Runs durdraw
- `durdraw` - Runs durdraw 
- `durfetch` - Runs durfetch (system info display tool)

You can run these apps directly:

```bash
# Run durdraw
nix run github:tahuffman1s/durdraw-flake

# Run durfetch
nix run github:tahuffman1s/durdraw-flake#durfetch
```

## Home Manager Module

This flake includes a Home Manager module for easy configuration. To use it:

```nix
{
  inputs = {
    durdraw = {
      url = "github:tahuffman1s/durdraw-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, durdraw, ... }@inputs: {
    homeConfigurations.yourusername = home-manager.lib.homeManagerConfiguration {
      # ... your configuration
      modules = [
        durdraw.homeManagerModules.default
        {
          programs.durdraw = {
            enable = true;
            # Optional configuration
            settings = {
              Main = {
                color-mode = 256;
                cursor-mode = "underscore";
                scroll-colors = true;
              };
              Theme = {
                theme-16 = "~/.durdraw/themes/mutedchill-16.dtheme.ini";
                theme-256 = "~/.durdraw/themes/mutedform-256.dtheme.ini";
              };
            };
            installThemes = true;
          };
        }
      ];
    };
  };
}
```

### Home Manager Module Options

- `programs.durdraw.enable` - Enable durdraw (default: `false`)
- `programs.durdraw.package` - The durdraw package to use (default: this flake's package)
- `programs.durdraw.settings` - Configuration settings for durdraw (default: `{}`)
- `programs.durdraw.installThemes` - Whether to install default themes (default: `true`)

### Configuration Examples

```nix
programs.durdraw = {
  enable = true;
  settings = {
    Main = {
      color-mode = 256;           # Color mode (16, 256, or truecolor)
      cursor-mode = "underscore"; # Cursor style
      scroll-colors = true;       # Enable color scrolling
      auto-save = true;           # Auto-save files
    };
    Theme = {
      theme-16 = "~/.durdraw/themes/custom-16.dtheme.ini";
      theme-256 = "~/.durdraw/themes/custom-256.dtheme.ini";
    };
    Keys = {
      # Custom key bindings
      quit = "q";
      save = "s";
    };
  };
};
```

## Development

### Development Shell

This flake provides a development shell with all necessary tools:

```bash
# Enter development shell
nix develop github:tahuffman1s/durdraw-flake

# Or clone and develop locally
git clone https://github.com/tahuffman1s/durdraw-flake.git
cd durdraw-flake
nix develop
```

The development shell includes:
- Python 3.11 with pip and pytest
- ansilove (for PNG/GIF export)
- neofetch (for durfetch support)
- Development tools (black, flake8)

### Building from Source

```bash
# Build the package
nix build github:tahuffman1s/durdraw-flake

# Build and run
nix run github:tahuffman1s/durdraw-flake
```

## Optional Dependencies

This flake includes optional runtime dependencies that enhance durdraw's functionality:

- **ansilove** - Enables PNG and GIF export functionality
- **neofetch** - Required for durfetch system info display

These are automatically included when you install the package.

## Features

- **Multiple color modes**: 16-color, 256-color, and truecolor support
- **Export formats**: Save as .dur files, export to various formats with ansilove
- **Themes**: Includes default themes, supports custom themes
- **Examples**: Comes with example art files
- **Shell completion**: Bash completion support (if available)
- **Convenience scripts**: Includes `durdraw-examples` wrapper script

## Usage

After installation, you can:

```bash
# Start durdraw
durdraw

# Load example files
durdraw-examples

# Run durfetch for system info
durfetch

# Get help
durdraw --help
```

## File Locations

When installed via the Home Manager module:
- Configuration: `~/.config/durdraw/durdraw.ini`
- Themes: `~/.durdraw/themes/`
- Examples: Available via the installed package

## Contributing

This flake packages the upstream durdraw project. For issues with durdraw itself, please report them to the [upstream repository](https://github.com/cmang/durdraw).

For packaging-related issues, please open an issue in this repository.

## License

This flake is provided under the same license as durdraw (BSD-3-Clause). See the upstream project for details.
