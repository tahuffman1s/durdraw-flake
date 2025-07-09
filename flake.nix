{
  description = "Durdraw - ASCII, Unicode and ANSI art editor for Unix-like systems";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        
        python = pkgs.python311;
        
        durdraw = python.pkgs.buildPythonApplication rec {
          pname = "durdraw";
          version = "0.29.0";
          
          # Add these required attributes
          pyproject = true;
          build-system = with python.pkgs; [
            setuptools
          ];
          
          src = pkgs.fetchFromGitHub {
            owner = "cmang";
            repo = "durdraw";
            rev = version;
            # You'll need to update this hash after first attempt
            hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
          };
          
          propagatedBuildInputs = with python.pkgs; [
            # Core dependencies (ncurses is included with Python)
          ];
          
          # Optional runtime dependencies
          makeWrapperArgs = [
            "--prefix PATH : ${pkgs.lib.makeBinPath [ 
              pkgs.ansilove  # For PNG/GIF export
              pkgs.neofetch  # For durfetch support
            ]}"
          ];
          
          postInstall = ''
            # Install configuration and themes
            mkdir -p $out/share/durdraw
            cp -r themes $out/share/durdraw/
            cp durdraw.ini $out/share/durdraw/
            
            # Install examples
            cp -r examples $out/share/durdraw/
            
            # Create wrapper scripts for convenience
            cat > $out/bin/durdraw-examples <<EOF
            #!/bin/sh
            exec $out/bin/durdraw -p $out/share/durdraw/examples/*.dur "\$@"
            EOF
            chmod +x $out/bin/durdraw-examples
            
            # Install shell completion if available
            if [ -f completion/durdraw.bash ]; then
              installShellCompletion --bash completion/durdraw.bash
            fi
          '';
          
          # Tests
          checkInputs = with python.pkgs; [
            pytestCheckHook
          ];
          
          # Run tests if they exist
          pytestFlagsArray = [
            "test/"
          ];
          
          meta = with pkgs.lib; {
            description = "ASCII, Unicode and ANSI art editor for Unix-like systems";
            homepage = "https://durdraw.org";
            license = licenses.bsd3;
            maintainers = with maintainers; [ ];
            platforms = platforms.unix;
          };
        };
        
      in {
        packages = {
          default = durdraw;
          durdraw = durdraw;
        };
        
        apps = {
          default = flake-utils.lib.mkApp {
            drv = durdraw;
          };
          
          durdraw = flake-utils.lib.mkApp {
            drv = durdraw;
          };
          
          durfetch = flake-utils.lib.mkApp {
            drv = durdraw;
            exePath = "/bin/durfetch";
          };
        };
        
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            python
            python.pkgs.pip
            python.pkgs.pytest
            ansilove
            neofetch
            # Development tools
            python.pkgs.black
            python.pkgs.flake8
          ];
          
          shellHook = ''
            echo "Durdraw development environment"
            echo "Run 'python -m durdraw' to test locally"
            echo "Run 'pytest -vv test/' to run tests"
          '';
        };
        
        # Optional: Home Manager module
        homeManagerModules.default = { config, lib, pkgs, ... }:
          with lib;
          let
            cfg = config.programs.durdraw;
          in {
            options.programs.durdraw = {
              enable = mkEnableOption "durdraw ASCII art editor";
              
              package = mkOption {
                type = types.package;
                default = self.packages.${pkgs.system}.durdraw;
                description = "The durdraw package to use";
              };
              
              settings = mkOption {
                type = types.attrs;
                default = {};
                example = literalExpression ''
                  {
                    Main = {
                      color-mode = 256;
                      cursor-mode = "underscore";
                      scroll-colors = true;
                    };
                    Theme = {
                      theme-16 = "~/.durdraw/themes/mutedchill-16.dtheme.ini";
                      theme-256 = "~/.durdraw/themes/mutedform-256.dtheme.ini";
                    };
                  }
                '';
                description = "Configuration for durdraw";
              };
              
              installThemes = mkOption {
                type = types.bool;
                default = true;
                description = "Whether to install default themes";
              };
            };
            
            config = mkIf cfg.enable {
              home.packages = [ cfg.package ];
              
              xdg.configFile = mkIf (cfg.settings != {}) {
                "durdraw/durdraw.ini".text = lib.generators.toINI {} cfg.settings;
              };
              
              home.file = mkIf cfg.installThemes {
                ".durdraw/themes" = {
                  source = "${cfg.package}/share/durdraw/themes";
                  recursive = true;
                };
              };
            };
          };
      });
}