{
  description = "Durdraw - Versatile ASCII and ANSI Art text editor";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        pythonPackages = pkgs.python311Packages;
      in
      {
        packages = {
          default = self.packages.${system}.durdraw;
          
          durdraw = pythonPackages.buildPythonApplication rec {
            pname = "durdraw";
            version = "0.29.0";
            
            src = ./.;
            
            pyproject = true;
            
            build-system = with pythonPackages; [
              setuptools
              wheel
            ];
            
            nativeBuildInputs = with pkgs; [
              makeWrapper
            ];
            
            postInstall = ''
              # Install themes and examples
              mkdir -p $out/share/durdraw
              cp -r themes $out/share/durdraw/
              cp -r examples $out/share/durdraw/
              cp durdraw.ini $out/share/durdraw/
              
              # Wrap with optional dependencies
              wrapProgram $out/bin/durdraw \
                --prefix PATH : ${pkgs.lib.makeBinPath [
                  pkgs.ansilove
                  pkgs.neofetch
                ]}
              
              # Create convenience script for examples
              cat > $out/bin/durdraw-examples <<'EOF'
              #!/usr/bin/env bash
              exec durdraw -p $out/share/durdraw/examples/*.dur "$@"
              EOF
              chmod +x $out/bin/durdraw-examples
              
              # If durfetch exists as separate script, install it
              if [ -f durfetch ]; then
                install -Dm755 durfetch $out/bin/durfetch
                wrapProgram $out/bin/durfetch \
                  --prefix PATH : ${pkgs.lib.makeBinPath [ pkgs.neofetch ]}
              fi
            '';
            
            meta = with pkgs.lib; {
              description = "Versatile ASCII and ANSI Art text editor for drawing in the terminal";
              homepage = "https://durdraw.org";
              license = licenses.bsd3;
              maintainers = [ ];
              platforms = platforms.unix;
              mainProgram = "durdraw";
            };
          };
        };
        
        apps = {
          default = self.apps.${system}.durdraw;
          
          durdraw = flake-utils.lib.mkApp {
            drv = self.packages.${system}.durdraw;
          };
          
          durfetch = flake-utils.lib.mkApp {
            drv = self.packages.${system}.durdraw;
            exePath = "/bin/durfetch";
          };
          
          examples = flake-utils.lib.mkApp {
            drv = self.packages.${system}.durdraw;
            exePath = "/bin/durdraw-examples";
          };
        };
        
        devShells.default = pkgs.mkShell {
          inputsFrom = [ self.packages.${system}.durdraw ];
          
          buildInputs = with pkgs; [
            pythonPackages.python
            pythonPackages.pip
            pythonPackages.pytest
            pythonPackages.black
            pythonPackages.flake8
            ansilove
            neofetch
          ];
          
          shellHook = ''
            echo "Durdraw development environment"
            echo ""
            echo "Commands:"
            echo "  ./start-durdraw    - Run durdraw from source"
            echo "  nix build          - Build the package"
            echo "  nix run            - Run the built package"
            echo "  nix run .#durfetch - Run durfetch"
            echo "  nix run .#examples - Run example animations"
            echo ""
          '';
        };
      });
}