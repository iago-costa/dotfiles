sync-from-user:
	@echo "Updating nvim files from user files"
	rm -rf .config/ | true
	mkdir -p .config/ | true
	cp -r ${HOME}/.config/nvim ./.config/
	cp -r ${HOME}/.config/redshift ./.config/
	rm -rf ./.config/nvim/.git | true
	rm -rf ./.config/nvim/undodir | true
	rm -rf ./.config/nvim/plugin | true
	rm -rf ./.config/nvim/autoload | true
	rm -rf ./.config/nvim/sessions | true

sync-from-root:
	@echo "Updating nvim files from root files"
	rm -rf .config/ | true
	mkdir -p .config/ | true
	cp -r /root/.config/nvim ./.config/
	cp -r /root/.config/redshift ./.config/
	rm -rf ./.config/nvim/.git | true
	rm -rf ./.config/nvim/undodir | true
	rm -rf ./.config/nvim/plugin | true
	rm -rf ./.config/nvim/autoload | true
	rm -rf ./.config/nvim/sessions | true

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

hard-pull:
	@echo "Updating nvim files from git"
	git pull origin main
	make sync-to-user
	make del
	make link

hard-pull-root:
	@echo "Updating nvim files from git"
	git pull origin main
	make sync-to-root
	make del-root
	make link-root

sync-to-root:
	@echo "Updating nvim files to root files"
	sudo rm -rf /root/.config/nvim | true
	sudo rm -rf /root/.config/redshift | true
	sudo mkdir -p /root/.config/ | true
	sudo mkdir -p /root/.config/nvim | true
	sudo mkdir -p /root/.config/nvim/lua | true
	sudo mkdir -p /root/.config/nvim/ftplugin | true
	sudo cp -r ./.config/nvim/lua/ /root/.config/nvim/lua/
	sudo cp -r ./.config/nvim/init.vim /root/.config/nvim/
	sudo cp -r ./.config/nvim/ftplugin /root/.config/nvim/
	sudo cp -r ./.config/redshift /root/.config/

sync-to-user:
	@echo "Updating nvim files to user files"
	rm -rf ${HOME}/.config/nvim | true
	rm -rf ${HOME}/.config/redshift | true
	mkdir -p ${HOME}/.config/ | true
	mkdir -p ${HOME}/.config/nvim | true
	mkdir -p ${HOME}/.config/nvim/lua | true
	mkdir -p ${HOME}/.config/nvim/ftplugin | true
	cp -r ./.config/nvim/lua/ ${HOME}/.config/nvim/lua/
	cp -r ./.config/nvim/init.vim ${HOME}/.config/nvim/
	cp -r ./.config/nvim/ftplugin ${HOME}/.config/nvim/
	cp -r ./.config/redshift ${HOME}/.config/

link:
	git pull origin main
	ln .tmux.conf ${HOME}/.tmux.conf | true
	ln .zshrc ${HOME}/.zshrc | true
	ln .vimrc ${HOME}/.vimrc | true
	mkdir -p ${HOME}/.config/vifm/ | true
	ln vifmrc ${HOME}/.config/vifm/vifmrc | true
	mkdir -p ${HOME}/.config/alacritty/ | true
	ln alacritty.toml ${HOME}/.config/alacritty/alacritty.toml | true
	mkdir -p ${HOME}/.config/zellij/ | true
	ln ./zellij/config.kdl ${HOME}/.config/zellij/config.kdl | true
	ln .xmobarrc ${HOME}/.xmobarrc | true
	mkdir -p ${HOME}/.xmonad/ | true
	ln xmonad.hs ${HOME}/.xmonad/xmonad.hs | true

link-root:
	git pull origin main
	ln .tmux.conf /root/.tmux.conf | true
	ln .zshrc /root/.zshrc | true
	ln .vimrc /root/.vimrc | true
	mkdir -p /root/.config/vifm/ | true
	ln vifmrc /root/.config/vifm/vifmrc | true
	mkdir -p /root/.config/alacritty/ | true
	ln alacritty.toml /root/.config/alacritty/alacritty.toml | true
	mkdir -p /root/.config/zellij/ | true
	ln ./zellij/config.kdl /root/.config/zellij/config.kdl | true
	ln .xmobarrc ${HOME}/.xmobarrc | true
	mkdir -p ${HOME}/.xmonad/ | true
	ln xmonad.hs ${HOME}/.xmonad/xmonad.hs | true

del:
	cp ${HOME}/.tmux.conf ${HOME}/.tmux.conf.bak | true
	rm ${HOME}/.tmux.conf | true
	
	cp ${HOME}/.zshrc ${HOME}/.zshrc.bak | true
	rm ${HOME}/.zshrc | true

	cp ${HOME}/.vimrc ${HOME}/.vimrc.bak | true
	rm ${HOME}/.vimrc | true

	cp ${HOME}/.config/redshift/ ${HOME}/.config/redshift.bak | true
	rm ${HOME}/.config/redshift/ -rv | true

	cp ${HOME}/.config/vifm/ ${HOME}/.config/vifm.bak | true
	rm ${HOME}/.config/vifm/ -rv | true

	cp ${HOME}/.xmobarrc ${HOME}/.xmobarrc.bak | true
	rm ${HOME}/.xmobarrc | true

	cp ${HOME}/.xmonad/xmonad.hs ${HOME}/.xmonad/xmonad.hs.bak | true
	rm ${HOME}/.xmonad/xmonad.hs | true

del-root:
	cp /root/.tmux.conf /root/.tmux.conf.bak | true
	sudo rm /root/.tmux.conf | true
	
	cp /root/.zshrc /root/.zshrc.bak | true
	sudo rm /root/.zshrc | true

	cp /root/.vimrc /root/.vimrc.bak | true
	sudo rm /root/.vimrc | true
	
	cp /root/.config/redshift/ /root/.config/redshift.bak | true
	sudo rm /root/.config/redshift/ -rv | true

	cp /root/.config/vifm/ /root/.config/vifm.bak | true
	sudo rm /root/.config/vifm/ -rv | true

	cp /root/.xmobarrc /root/.xmobarrc.bak | true
	sudo rm /root/.xmobarrc | true

	cp /root/.xmonad/xmonad.hs /root/.xmonad/xmonad.hs.bak | true
	sudo rm /root/.xmonad/xmonad.hs | true

