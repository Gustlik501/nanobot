{ self, lib, pkgs, config, ... }:

let
  cfg = config.services.nanobot;
  dataDir = if cfg.dataDir != null then cfg.dataDir else "${cfg.homeDir}/.nanobot";
  jsonFormat = pkgs.formats.json { };
  configFile =
    if cfg.settingsFile != null
    then cfg.settingsFile
    else jsonFormat.generate "nanobot-config.json" cfg.settings;
  envList = lib.mapAttrsToList (k: v: "${k}=${v}") cfg.environment;
  command = lib.escapeShellArgs cfg.command;
in
{
  options.services.nanobot = with lib; {
    enable = mkEnableOption "nanobot AI assistant";

    package = mkOption {
      type = types.package;
      default = self.packages.${pkgs.system}.nanobot;
      description = "nanobot package to run.";
    };

    user = mkOption {
      type = types.str;
      default = "nanobot";
      description = "User account for the nanobot service.";
    };

    group = mkOption {
      type = types.str;
      default = "nanobot";
      description = "Group for the nanobot service.";
    };

    createUser = mkOption {
      type = types.bool;
      default = true;
      description = "Whether to create the service user/group.";
    };

    homeDir = mkOption {
      type = types.path;
      default = "/var/lib/nanobot";
      description = "Home directory for the service user.";
    };

    dataDir = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = "Nanobot data directory (defaults to homeDir + \"/.nanobot\").";
    };

    settings = mkOption {
      type = types.attrs;
      default = { };
      description = "Config.json settings (use nanobot's camelCase keys).";
    };

    settingsFile = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = "Path to an existing config.json file. If set, settings are ignored.";
    };

    command = mkOption {
      type = types.listOf types.str;
      default = [ "gateway" ];
      description = "nanobot CLI command and args, e.g. [\"gateway\"] or [\"agent\"].";
    };

    environment = mkOption {
      type = types.attrsOf types.str;
      default = { };
      description = "Extra environment variables for the service.";
    };

  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.command != [ ];
        message = "services.nanobot.command must not be empty.";
      }
      {
        assertion = cfg.settingsFile == null || cfg.settings == { };
        message = "Use either services.nanobot.settings or services.nanobot.settingsFile, not both.";
      }
    ];

    users.users = lib.mkIf cfg.createUser {
      ${cfg.user} = {
        isSystemUser = true;
        group = cfg.group;
        home = cfg.homeDir;
        createHome = true;
      };
    };

    users.groups = lib.mkIf cfg.createUser {
      ${cfg.group} = { };
    };

    systemd.tmpfiles.rules = [
      "d ${dataDir} 0750 ${cfg.user} ${cfg.group} -"
      "L+ ${dataDir}/config.json - - - - ${configFile}"
    ];

    systemd.services.nanobot = {
      description = "nanobot AI assistant";
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "simple";
        User = cfg.user;
        Group = cfg.group;
        WorkingDirectory = cfg.homeDir;
        Environment = [ "HOME=${cfg.homeDir}" ] ++ envList;
        ExecStart = "${cfg.package}/bin/nanobot ${command}";
        Restart = "on-failure";
        RestartSec = 2;
      };
    };

  };
}
