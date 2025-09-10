{
inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
};
outputs = {self, nixpkgs, ...}:
  let
      systems = [ "x86_64-linux" "aarch64-linux" "aarch64-darwin" "x86_64-darwin" ];
      forEachSystem = f: builtins.listToAttrs (map (system: {
        name = system;
        value = f system;
      }) systems);
  in {
  packages = forEachSystem (system: {
      consensusj =
        let
          pkgs = import nixpkgs {
            inherit system;
          };
          mainProgram = "jrpc";
          graalvm = pkgs.graalvmPackages.graalvm-ce;
          gradle = pkgs.gradle_8.override {
            java = graalvm;  # Run Gradle with this JDK
          };
          self = pkgs.stdenv.mkDerivation (_finalAttrs: {
            pname = "consensusj";
            version = "0.7.0-SNAPSHOT";
            meta = {
              inherit mainProgram;
            };

            src = pkgs.fetchFromGitHub {
              owner = "ConsensusJ";
              repo = "consensusj";
              rev = "ba5a4dfc3c61b149136cca50bacdfd6595231291"; # master 25-09-09 - jrpc
              sha256 = "sha256-mgguyBXMm6XNjHwNPKUQalgg9QxTkeJG9i1g4BzKWRg=";
            };


            nativeBuildInputs = [gradle pkgs.makeWrapper graalvm];

            mitmCache = gradle.fetchDeps {
              pkg = self;
              # update or regenerate this by running:
              #  $(nix build .#consensusj.mitmCache.updateScript --print-out-paths)
              data = ./deps.json;
            };

            gradleBuildTask = "consensusj-jsonrpc-cli:nativeCompile";

            gradleFlags = [ "--info --stacktrace" ];

            # will run the gradleCheckTask (defaults to "test")
            doCheck = false;

            installPhase = ''
              mkdir -p $out/bin
              cp consensusj-jsonrpc-cli/build/${mainProgram} $out/bin/${mainProgram}
              wrapProgram $out/bin/${mainProgram}
            '';
          });
        in
          self;
    });
  };
}
