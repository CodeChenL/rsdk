{ pkgs, lib, config, ... }:

{
  # https://devenv.sh/packages/
  packages = with pkgs; [
    aptly
    bash-completion
    cargo
    commitizen
    curl
    dosfstools
    file
    git
    gh
    gptfdisk
    guestfs-tools
    jq
    libguestfs-with-appliance
    mdbook
    mdbook-cmdrun
    mdbook-admonish
    mdbook-cmdrun
    mdbook-i18n-helpers
    mdbook-linkcheck
    mdbook-toc
    multipath-tools
    newt
    parted
    util-linux
    wget
    xz
    yq
    zx
  ];

  enterShell = ''
    export PATH=$PWD/src/bin:$PWD/node_modules/.bin:$HOME/.cargo/bin:$PATH

    if [[ -n "$DEVENV_NIX" ]]
    then
      # Does not work from direnv
      # https://github.com/direnv/direnv/issues/773#issuecomment-792688396
      source $PWD/src/share/bash-completion/completions/rsdk
      rsdk welcome
    else
      rsdk welcome 'Please run `rsdk shell` to enter the full development shell.
'
    fi
  '';

  languages.javascript = {
    enable = true;
    npm.enable = true;
  };
  languages.jsonnet.enable = true;

  pre-commit = {
    hooks = {
      commitizen.enable = true;
      shellcheck = {
        enable = true;
        entry = lib.mkForce "${pkgs.shellcheck}/bin/shellcheck -x";
      };
      shfmt.enable = true;
      statix.enable = true;
      typos = {
        enable = true;
        excludes = [
          "theme/highlight.js"
        ];
      };
    };
  };

  starship.enable = true;
}
