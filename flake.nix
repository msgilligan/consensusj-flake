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
          mainProgram = "jsonrpc";
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
              rev = "0b6e70e4575e948c641d756f8484613bc8c89acd"; # master 25-09-08
              sha256 = "sha256-+mmLJHZIK/FBOnOScKVTfL0QXCmRf18MIn6VraFxV2w=";
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
