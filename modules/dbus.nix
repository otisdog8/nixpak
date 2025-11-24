{ config, lib, pkgs, sloth, ... }:
with lib;
let
  inherit (types) attrsOf listOf enum str bool;
in {
  options.dbus = {
    enable = mkEnableOption "D-Bus access" // { default = true; };
    policies = mkOption {
      default = {};
      type = attrsOf (enum [ "see" "talk" "own" ]);
      description = "Policies to apply to the given bus object name.";
    };
    rules.call = mkOption {
      default = {};
      type = attrsOf (listOf str);
      description = "Rules for calls on the given bus object name.";
    };
    rules.broadcast = mkOption {
      default = {};
      type = attrsOf (listOf str);
      description = "Rules for broadcasts on the given bus object name.";
    };
    args = mkOption {
      default = [];
      type = listOf str;
      description = "Arguments (proxy options) to xdg-dbus-proxy.";
    };
    mountDocumentPortal = mkOption {
      default = false;
      type = bool;
      description = "Mount the document portal directory for this app.";
    };
  };

  config = {
    dbus.args =
      (mapAttrsToList (n: v: "--${v}=${n}") config.dbus.policies) ++

      (flatten (mapAttrsToList
        (n: v: map (x: "--call=${n}=${x}") v)
          config.dbus.rules.call)
      ) ++

      (flatten (mapAttrsToList
        (n: v: map (x: "--broadcast=${n}=${x}") v)
          config.dbus.rules.broadcast)
      );

    bubblewrap.bind.rw = mkIf (config.dbus.enable && config.dbus.mountDocumentPortal) (let
      docPortalHost = sloth.concat [
        "/run/user/"
        sloth.uid
        "/doc/by-app/"
        config.flatpak.appId
      ];
      docPortalSandbox = sloth.concat [
        (sloth.env "XDG_RUNTIME_DIR")
        "/doc"
      ];
    in [
      [ docPortalHost docPortalSandbox ]
    ]);
  };
}