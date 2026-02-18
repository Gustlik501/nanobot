{
  description = "nanobot - ultra-lightweight personal AI assistant";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    let
      inherit (flake-utils.lib) eachDefaultSystem mkApp;
    in
    eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
        lib = pkgs.lib;
        py = pkgs.python311Packages;

        has = name: builtins.hasAttr name py;
        get = name: builtins.getAttr name py;
        opt = name: lib.optionals (has name) [ (get name) ];

        nanobot = py.buildPythonPackage {
          pname = "nanobot-ai";
          version = "0.1.4";
          pyproject = true;
          src = self;

          build-system = [ py.hatchling ];

          dependencies =
            [
              py.typer
              py.litellm
              py.pydantic
              (get "pydantic-settings")
              py.websockets
              (get "websocket-client")
              py.httpx
              py.loguru
              (get "readability-lxml")
              py.rich
              py.croniter
              py.socksio
              (get "python-socketio")
              py.msgpack
              (get "slack-sdk")
              py.prompt-toolkit
              (get "python-socks")
            ]
            ++ opt "oauth-cli-kit"
            ++ opt "dingtalk-stream"
            ++ opt "python-telegram-bot"
            ++ opt "lark-oapi"
            ++ opt "slackify-markdown"
            ++ opt "qq-botpy"
            ++ opt "mcp"
            ++ opt "json-repair";

          doCheck = false;
        };
      in
      {
        packages = {
          nanobot = nanobot;
          default = pkgs.python311.withPackages (_: [ nanobot ]);
        };

        apps.default = mkApp {
          drv = self.packages.${system}.default;
          exePath = "/bin/nanobot";
        };

        devShells.default = pkgs.mkShell {
          packages = [ pkgs.python311 ];
        };
      }
    ) // {
      overlays.default = final: _prev: {
        nanobot = self.packages.${final.stdenv.hostPlatform.system}.nanobot;
      };

      nixosModules.nanobot = import ./nix/nanobot-module.nix { inherit self; };
    };
}
