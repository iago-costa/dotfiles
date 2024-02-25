### add new channel
```bash
nix-channel --add https://nixos.org/channels/nixos-24.04 nixos-24.04
nix-channel --update
```

### delete channel
```bash
nix-channel --remove nixos-24.04
nix-channel --update
```

### list channels
```bash
nix-channel --list
```

### update system
```bash
nixos-rebuild switch --upgrade
```

### test configuration
```bash
nixos-rebuild test
```
