{ config, pkgs, ... }: let
  hibernateEnvironment = {
    HIBERNATE_SECONDS = "3600";
    HIBERNATE_LOCK = "/var/run/autohibernate.lock";
  };
in {
  systemd.services."awake-after-hybrid-sleep-for-a-time" = {
    description = "Sets up the hybrid-sleep so that it'll awake for hibernation";
    wantedBy = [ "hybrid-sleep.target" ];
    before = [ "systemd-hybrid-sleep.service" ];
    environment = hibernateEnvironment;
    script = ''
      curtime=$(date +%s)
      echo "$curtime $1" >> /tmp/autohibernate.log
      echo "$curtime" > $HIBERNATE_LOCK
      ${pkgs.utillinux}/bin/rtcwake -m no -s $HIBERNATE_SECONDS
    '';
    serviceConfig.Type = "simple";
  };
  systemd.services."hibernate-after-recovery-hybrid-sleep" = {
    description = "Hibernates after a hybrid-sleep recovery due to timeout";
    wantedBy = [ "hybrid-sleep.target" ];
    after = [ "systemd-hybrid-sleep.service" ];
    environment = hibernateEnvironment;
    script = ''
      curtime=$(date +%s)
      sustime=$(cat $HIBERNATE_LOCK)
      rm $HIBERNATE_LOCK
      if [ $(($curtime - $sustime)) -ge $HIBERNATE_SECONDS ] ; then
        systemctl hibernate
      else
        ${pkgs.utillinux}/bin/rtcwake -m no -s 1
      fi
    '';
    serviceConfig.Type = "simple";
  };
}
