sync-from-user-hard-to-root:
	@echo "Sync from user and delete all and sync in root"
	make sync-from-user
	make hard-pull-root
	
sync-from-user:
	@echo "Updating redshift and nvim files from user to root"
	cp -r ${HOME}/.config/redshift ./.config/
	
	rm -rf ./.config/nvim | true
	mkdir -p ./.config/nvim/lua | true
	mkdir -p ./.config/nvim/ftplugin | true
	cp -r ${HOME}/.config/nvim/lua ./.config/nvim/ | true
	cp -r ${HOME}/.config/nvim/init.lua ./.config/nvim/	| true
	cp -r ${HOME}/.config/nvim/ftplugin ./.config/nvim/ | true

nixos-link:
	@echo "Linking nixos configuration"
	sudo ln /etc/nixos/configuration.nix ./nixos/configuration.nix | true
	sudo ln /etc/nixos/hardware-configuration.nix ./nixos/hardware-configuration.nix | true
	sudo ln /etc/nixos/suspend-and-hibernate.nix ./nixos/suspend-and-hibernate.nix | true

nixos-del:
	@echo "Removing nixos configuration"
	sudo rm ./nixos/configuration.nix | true
	sudo rm ./nixos/hardware-configuration.nix | true
	sudo rm ./nixos/suspend-and-hibernate.nix | true

nixos-hard:
	@echo "Updating nixos configuration"
	make nixos-del
	make nixos-link

red:
	redshift -P -O 6000

hard-pull-base:
	@echo "Delete all and sync/link from git for base"
	git pull origin main
	make del-base
	make sync-to-base
	make link-base

hard-pull-user:
	@echo "Delete all and sync/link from git for user"
	git pull origin main
	make del-user
	make sync-to-user
	make link-user

hard-pull-root:
	@echo "Delete all and sync/link from git for root"
	git pull origin main
	make del-root
	make sync-to-root
	make link-root

sync-to-base:
	@echo "Updating nvim files to base files"
	rm -rf ${HOME}/.config/nvim | true
	mkdir -p ${HOME}/.config/nvim/lua | true
	mkdir -p ${HOME}/.config/nvim/ftplugin | true
	cp -r ./.config/nvim/lua/ ${HOME}/.config/nvim/ | true
	cp -r ./.config/nvim/init.lua ${HOME}/.config/nvim/	| true
	cp -r ./.config/nvim/ftplugin ${HOME}/.config/nvim/ | true

sync-to-root:
	@echo "Updating redshift and nvim files to root files"
	sudo rm -rf /root/.config/redshift | true
	sudo cp -r ./.config/redshift /root/.config/ | true

	sudo rm -rf /root/.config/nvim | true
	sudo mkdir -p /root/.config/nvim/lua | true
	sudo mkdir -p /root/.config/nvim/ftplugin | true
	sudo cp -r ./.config/nvim/lua/ /root/.config/nvim/ | true
	sudo cp -r ./.config/nvim/init.lua /root/.config/nvim/ | true
	sudo cp -r ./.config/nvim/ftplugin /root/.config/nvim/ | true

sync-to-user:
	@echo "Updating redshift and nvim files to user files"
	rm -rf ${HOME}/.config/redshift | true	
	cp -r ./.config/redshift ${HOME}/.config/ | true

	rm -rf ${HOME}/.config/nvim | true
	mkdir -p ${HOME}/.config/nvim/lua | true
	mkdir -p ${HOME}/.config/nvim/ftplugin | true
	cp -r ./.config/nvim/lua/ ${HOME}/.config/nvim/ | true
	cp -r ./.config/nvim/init.lua ${HOME}/.config/nvim/	| true
	cp -r ./.config/nvim/ftplugin ${HOME}/.config/nvim/ | true

link-base:
	@echo "Set zsh, vim, zellij, nvim to base"
	ln .zshrc ${HOME}/.zshrc | true
	
	ln .vimrc ${HOME}/.vimrc | true
	
	mkdir -p ${HOME}/.config/zellij/ | true
	ln ./zellij/config.kdl ${HOME}/.config/zellij/config.kdl | true
	
	mkdir -p ${HOME}/.config/nvim/lua | true
	mkdir -p ${HOME}/.config/nvim/ftplugin | true

link-user:
	@echo "Set tmux, zsh, vim, zellij, vifm, alacritty, xmobar, xmonad to user"
	ln .tmux.conf ${HOME}/.tmux.conf | true
	
	ln .zshrc ${HOME}/.zshrc | true
	
	ln .vimrc ${HOME}/.vimrc | true
	
	mkdir -p ${HOME}/.config/zellij/ | true
	ln ./zellij/config.kdl ${HOME}/.config/zellij/config.kdl | true
	
	mkdir -p ${HOME}/.config/vifm/ | true
	ln vifmrc ${HOME}/.config/vifm/vifmrc | true
	
	mkdir -p ${HOME}/.config/alacritty/ | true
	ln alacritty.toml ${HOME}/.config/alacritty/alacritty.toml | true
	
	ln .xmobarrc ${HOME}/.xmobarrc | true
	
	mkdir -p ${HOME}/.xmonad/ | true
	ln xmonad.hs ${HOME}/.xmonad/xmonad.hs | true

link-root:
	@echo "Set tmux, zsh, vim, zellij, vifm, alacritty, xmobar, xmonad to root"
	sudo ln .tmux.conf /root/.tmux.conf | true

	sudo ln .zshrc /root/.zshrc | true
	
	sudo ln .vimrc /root/.vimrc | true
	
	sudo mkdir -p /root/.config/zellij/ | true
	sudo ln ./zellij/config.kdl /root/.config/zellij/config.kdl | true
	
	sudo mkdir -p /root/.config/vifm/ | true
	sudo ln vifmrc /root/.config/vifm/vifmrc | true
	
	sudo mkdir -p /root/.config/alacritty/ | true
	sudo ln alacritty.toml /root/.config/alacritty/alacritty.toml | true
	
	sudo ln .xmobarrc /root/.xmobarrc | true
	
	sudo mkdir -p /root/.xmonad/ | true
	sudo ln xmonad.hs /root/.xmonad/xmonad.hs | true

del-base:
	@echo "Removing zsh, vim, zellij, nvim from base"
	rm ${HOME}/.zshrc | true
	
	rm ${HOME}/.vimrc | true
	
	rm -rf ${HOME}/.config/zellij/ | true
	
	rm -rf ${HOME}/.config/nvim/ | true

del-user:
	@echo "Removing tmux, zsh, vim, zellij, redshift, vifm, alacritty, xmobar, xmonad from user"
	cp ${HOME}/.tmux.conf ${HOME}/.tmux.conf.bak | true
	rm ${HOME}/.tmux.conf | true
	
	cp ${HOME}/.zshrc ${HOME}/.zshrc.bak | true
	rm ${HOME}/.zshrc | true

	cp ${HOME}/.vimrc ${HOME}/.vimrc.bak | true
	rm ${HOME}/.vimrc | true

	cp ${HOME}/.config/zellij/ ${HOME}/.config/zellij.bak -r | true
	rm ${HOME}/.config/zellij/ -rv | true

	cp ${HOME}/.config/redshift/ ${HOME}/.config/redshift.bak -r | true
	rm ${HOME}/.config/redshift/ -rv | true

	cp ${HOME}/.config/vifm/ ${HOME}/.config/vifm.bak -r | true
	rm ${HOME}/.config/vifm/ -rv | true

	cp ${HOME}/.config/alacritty/ ${HOME}/.config/alacritty.bak -r | true
	rm ${HOME}/.config/alacritty/ -rv | true

	cp ${HOME}/.xmobarrc ${HOME}/.xmobarrc.bak | true
	rm ${HOME}/.xmobarrc | true

	cp ${HOME}/.xmonad/xmonad.hs ${HOME}/.xmonad/xmonad.hs.bak | true
	rm ${HOME}/.xmonad/xmonad.hs | true

del-root:
	@echo "Removing tmux, zsh, vim, zellij, redshift, vifm, alacritty, xmobar, xmonad from root"
	sudo cp /root/.tmux.conf /root/.tmux.conf.bak | true
	sudo rm /root/.tmux.conf | true
	
	sudo cp /root/.zshrc /root/.zshrc.bak | true
	sudo rm /root/.zshrc | true

	sudo cp /root/.vimrc /root/.vimrc.bak | true
	sudo rm /root/.vimrc | true

	sudo cp /root/.config/zellij/ /root/.config/zellij.bak -r | true
	sudo rm /root/.config/zellij/ -rv | true
	
	sudo cp /root/.config/redshift/ /root/.config/redshift.bak -r | true
	sudo rm /root/.config/redshift/ -rv | true

	sudo cp /root/.config/vifm/ /root/.config/vifm.bak -r | true
	sudo rm /root/.config/vifm/ -rv | true

	sudo cp /root/.config/alacritty/ /root/.config/alacritty.bak -r | true
	sudo rm /root/.config/alacritty/ -rv | true

	sudo cp /root/.xmobarrc /root/.xmobarrc.bak | true
	sudo rm /root/.xmobarrc | true

	sudo cp /root/.xmonad/xmonad.hs /root/.xmonad/xmonad.hs.bak | true
	sudo rm /root/.xmonad/xmonad.hs | true

