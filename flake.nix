{
  description = "Project development environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
      };
    in
    {
      devShells.${system}.default = pkgs.mkShell {
        packages = with pkgs; [
          opentofu
          awscli2
          tflint
          trivy
          github-cli
          #terratest
        ];

        shellHook = ''
          export TF_VAR_github_token="$(gh auth token)"
        '';
      };
    };
}
