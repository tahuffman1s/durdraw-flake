{
  description = "Durdraw - ASCII, ANSI and Unicode art editor for UNIX terminals";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs, flake-utils }:
    let
      pkgs = nixpkgs.${system};
    in
    {
      packages = {
        default = self.packages.${system}.durdraw;
        
        durdraw = pkgs.python3Packages.buildPythonApplication rec {
          pname = "durdraw";
          version = "0.29.0";

          src = pkgs.fetchFromGitHub {
            owner = "cmang";
            repo = "durdraw";
            rev = version;
            sha256 = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
          };

          propagatedBuildInputs = [ ];

          nativeBuildInputs = with pkgs.python3Packages; [
            setuptools
            wheel
          ];

          passthru.optional-dependencies = {
            export = [ pkgs.ansilove ];
            fetch = [ pkgs.neofetch ];
          };

          buildInputs = [ pkgs.ncurses ];

          checkInputs = with pkgs.python3Packages; [ pytest ];

          checkPhase = ''
            runHook preCheck
            pytest -vv test/
            runHook postCheck
          '';

          meta = with pkgs.lib; {
            description = "ASCII, ANSI and Unicode art editor for UNIX terminals";
            homepage = "https://github.com/cmang/durdraw";
            license = licenses.bsd3;
            maintainers = with maintainers; [ Travis Huffman ];
            platforms = platforms.unix;
            mainProgram = "durdraw";
          };
        };
      };

      apps.default = flake-utils.lib.mkApp {
        drv = self.packages.${system}.durdraw;
      };

      devShells.default = pkgs.mkShell {
        inputsFrom = [ self.packages.${system}.durdraw ];
        
        packages = with pkgs; [
          python3
          python3Packages.pytest
          # Optional tools for full functionality
          ansilove
          neofetch
        ];

        shellHook = ''
          echo "Durdraw development environment"
          echo "Run 'durdraw' to start the application"
          echo "Optional: ansilove (PNG export), neofetch (system info)"
        '';
      };
    };
}