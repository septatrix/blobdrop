{
	description = "Drag and drop your files directly out of the terminal";
	inputs = {
		nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
	};

	outputs = { self, nixpkgs }:
	let outputsFor = system:
		let
			pkgs = nixpkgs.legacyPackages.${system};
			stdenvs = [ { name = "gcc"; pkg = pkgs.gcc14Stdenv; } { name = "clang"; pkg = pkgs.llvmPackages_18.stdenv; } ];
			defaultStdenv = (builtins.head stdenvs).name;
			makeStdenvPkg = env: env.mkDerivation {
				pname = "blobdrop";
				version = builtins.head (builtins.match ".*project\\([[:alnum:]]+ VERSION ([0-9]+\\.[0-9]+).*" (builtins.readFile ./CMakeLists.txt));

				src = ./.;

				nativeBuildInputs = with pkgs; [
					cmake
					extra-cmake-modules
					qt6.wrapQtAppsHook
				];
				buildInputs = with pkgs; [
					qt6.qtbase
					qt6.qtdeclarative
					qt6.qtsvg
					kdePackages.kirigami
					kdePackages.kcoreaddons
					kdePackages.knotifications
					kdePackages.kwindowsystem
					kdePackages.qqc2-desktop-style
				];
			};
		in {
			packages = {
				default = self.outputs.packages.${system}.${defaultStdenv};
			} // builtins.listToAttrs (map (x: { name = x.name; value = makeStdenvPkg x.pkg; }) stdenvs);
			checks = {
				format = pkgs.runCommand "format" { src = ./.; nativeBuildInputs = [ pkgs.clang-tools pkgs.git ]; } "mkdir $out && cd $src && find . -type f -path './*\\.[hc]pp' -exec clang-format -style=file --dry-run --Werror {} \\;";
			} // builtins.listToAttrs (map (x: { name = "tests-" + x.name; value = (makeStdenvPkg x.pkg).overrideAttrs (finalAttrs: previousAttrs: {
					doCheck = true;
					cmakeFlags = (previousAttrs.cmakeFlags or []) ++ ["-DBUILD_TESTING=ON"];
					QT_QPA_PLATFORM = "offscreen";
				}
			); }) stdenvs);
		};
	in {
		packages = nixpkgs.lib.genAttrs nixpkgs.lib.systems.flakeExposed (system: (outputsFor system).packages);
		checks = nixpkgs.lib.genAttrs nixpkgs.lib.systems.flakeExposed (system: (outputsFor system).checks);
	};
}
