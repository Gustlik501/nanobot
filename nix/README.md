# NixOS Module: nanobot

This folder ships a NixOS module that runs nanobot as a systemd service and
generates `config.json` from declarative Nix settings.

## Import

```nix
{
  imports = [ inputs.nanobot.nixosModules.nanobot ];
}
```

## Options

`services.nanobot.enable`
- Type: bool
- Default: `false`
- Enable the nanobot systemd service.

`services.nanobot.package`
- Type: package
- Default: `self.packages.${pkgs.system}.nanobot`
- Package to run.

`services.nanobot.user`
- Type: string
- Default: `"nanobot"`
- User account for the service.

`services.nanobot.group`
- Type: string
- Default: `"nanobot"`
- Group for the service.

`services.nanobot.createUser`
- Type: bool
- Default: `true`
- Create the user/group automatically.

`services.nanobot.homeDir`
- Type: path
- Default: `"/var/lib/nanobot"`
- Home directory for the service user.

`services.nanobot.dataDir`
- Type: null or path
- Default: `null`
- Nanobot data directory. If `null`, defaults to `${homeDir}/.nanobot`.

`services.nanobot.settings`
- Type: attrs
- Default: `{}`
- Declarative `config.json` content (use nanobot's camelCase keys).

`services.nanobot.settingsFile`
- Type: null or path
- Default: `null`
- Path to an existing `config.json`. If set, `settings` is ignored.

`services.nanobot.command`
- Type: list of strings
- Default: `[ "gateway" ]`
- CLI subcommand and args. Examples: `[ "gateway" ]`, `[ "agent" ]`.

`services.nanobot.environment`
- Type: attrs of strings
- Default: `{}`
- Extra environment variables for the service.

## Behavior Notes

- The module symlinks `${dataDir}/config.json` to a generated Nix store file when
  using `settings`.
- If you need a writable config or secret management, use `settingsFile` instead
  (for example from sops-nix or agenix).
- The service sets `HOME=${homeDir}` to keep nanobot state in the service user
  home directory.

## Example

```nix
{
  services.nanobot = {
    enable = true;

    settings = {
      providers.openrouter.apiKey = "sk-or-...";
      agents.defaults.model = "anthropic/claude-opus-4-5";
      channels.telegram.enabled = true;
      channels.telegram.token = "YOUR_BOT_TOKEN";
      channels.telegram.allowFrom = [ "123456789" ];
    };

    command = [ "gateway" ];
  };
}
```
