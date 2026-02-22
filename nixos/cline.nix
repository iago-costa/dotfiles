{ pkgs }:

pkgs.buildNpmPackage rec {
  pname = "cline";
  version = "2.4.2";

  src = pkgs.fetchurl {
    url = "https://registry.npmjs.org/cline/-/cline-2.4.2.tgz";
    hash = "sha256-2utOBC0vhoj5fR+cG+Vdo3N6+i/pNW1E4mESF/dZS/c=";
  };

  npmDepsHash = "sha256-lWp3cFY8azcKue2O/l54AhPdGuaLk+eATAMAz1mxgxU=";

  # Copy the generated lock file since the NPM tarball doesn't have one
  # And remove the missing man page entry to avoid install errors
  postPatch = ''
    cp ${./package-lock.json} package-lock.json
    sed -i '/"man":/d' package.json
  '';

  npmFlags = [ "--ignore-scripts" ];

  nativeBuildInputs = [ pkgs.python3 ];

  dontNpmBuild = true; # NPM package is already built

  postInstall = ''
    # The binary is usually at lib/node_modules/cline/dist/cli.mjs
    # Ensure it's executable and symlinked
    chmod +x $out/lib/node_modules/cline/dist/cli.mjs
    mkdir -p $out/bin
    ln -sf $out/lib/node_modules/cline/dist/cli.mjs $out/bin/cline
  '';

  meta = with pkgs.lib; {
    description = "Autonomous coding agent CLI";
    homepage = "https://github.com/cline/cline";
    license = licenses.asl20;
    mainProgram = "cline";
  };
}
