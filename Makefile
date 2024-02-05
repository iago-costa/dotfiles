push:
	@echo "Updating nvim files from local files"
	rm -rf .config/ | true
	mkdir -p .config/
	cp -r ${HOME}/.config/nvim ./.config/
	cp -r ${HOME}/.config/redshift ./.config/
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

red:
	redshift -P -O 6000

pull:
	@echo "Updating nvim files from git"
	git pull origin main
	cp .config/nvim/ ${HOME}/.config/ -rv
	cp .config/redshift/ ${HOME}/.config/ -rv
	make link

pull-root:
	@echo "Updating nvim files from git"
	git pull origin main
	cp .config/nvim/ /root/.config/ -rv
	cp .config/redshift/ /root/.config/ -rv
	make link-root

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

del:
	rm ${HOME}/.tmux.conf | true
	rm ${HOME}/.zshrc | true
	rm ${HOME}/.vimrc | true
	rm ${HOME}/.config/redshift/ -rv | true
	rm ${HOME}/.config/vifm/ -rv | true

del-root:
	rm /root/.tmux.conf | true
	rm /root/.zshrc | true
	rm /root/.vimrc | true
	rm /root/.config/redshift/ -rv | true
	rm /root/.config/vifm/ -rv | true


