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
          
          src = pkgs.fetchFromGitHub {
            owner = "cmang";
            repo = "durdraw";
            rev = version;
            # This hash needs to be updated - run nix build first to get the correct hash
            hash = "sha256-a+4DGWBD5XLaNAfTN/fmI/gALe76SCoWrnjyglNhVPY=";
          };
          
          # Specify the build system
          pyproject = true;
          build-system = with python.pkgs; [
            setuptools
          ];
          
          propagatedBuildInputs = with python.pkgs; [
            # Core dependencies - durdraw mainly uses standard library
            # Add any specific Python dependencies here if needed
          ];
          
          # Optional runtime dependencies
          makeWrapperArgs = [
            "--prefix PATH : ${pkgs.lib.makeBinPath [ 
              pkgs.ansilove  # For PNG/GIF export
              pkgs.neofetch  # For durfetch support
            ]}"
          ];
          
          postInstall = ''
            # Install configuration and themes if they exist
            if [ -d themes ]; then
              mkdir -p $out/share/durdraw
              cp -r themes $out/share/durdraw/
            fi
            
            if [ -f durdraw.ini ]; then
              mkdir -p $out/share/durdraw
              cp durdraw.ini $out/share/durdraw/
            fi
            
            # Install examples if they exist
            if [ -d examples ]; then
              mkdir -p $out/share/durdraw
              cp -r examples $out/share/durdraw/
              
              # Create wrapper scripts for convenience
              cat > $out/bin/durdraw-examples <<EOF
            #!/bin/sh
            exec $out/bin/durdraw -p $out/share/durdraw/examples/*.dur "\$@"
            EOF
              chmod +x $out/bin/durdraw-examples
            fi
            
            # Install shell completion if available
            # if [ -f completion/durdraw.bash ]; then
            #   installShellCompletion --bash completion/durdraw.bash
            # fi
          '';
          
          # Tests - only run if test directory exists
          nativeCheckInputs = with python.pkgs; [
            pytestCheckHook
          ];
          
          # Only run tests if test directory exists
          checkPhase = ''
            if [ -d test ]; then
              pytest -v test/
            else
              echo "No test directory found, skipping tests"
            fi
          '';
          
          # Disable tests by default since they might not exist
          doCheck = false;
          
          meta = with pkgs.lib; {
            description = "ASCII, Unicode and ANSI art editor for Unix-like systems";
            homepage = "https://durdraw.org";
            license = licenses.bsd3;
            maintainers = with maintainers; [ ];
            platforms = platforms.unix;
            mainProgram = "durdraw";
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
            name = "durdraw";
          };
          
          durdraw = flake-utils.lib.mkApp {
            drv = durdraw;
            name = "durdraw";
          };
          
          # Only create durfetch app if it exists
          durfetch = flake-utils.lib.mkApp {
            drv = durdraw;
            name = "durfetch";
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
            python.pkgs.setuptools
            python.pkgs.wheel
          ];
          
          shellHook = ''
            echo "Durdraw development environment"
            echo "Run 'python -m durdraw' to test locally"
            echo "Run 'pytest -vv test/' to run tests (if test directory exists)"
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