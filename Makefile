push:
	@echo "Updating nvim files in local files"
	rm -rf .config/ | true
	mkdir -p .config/
	cp -r ~/.config/nvim ./.config/
	cp -r ~/.config/redshift ./.config/
	rm -rf ./.config/nvim/.git | true
	rm -rf ./.config/nvim/undodir | true
	rm -rf ./.config/nvim/plugin | true
	rm -rf ./.config/nvim/autoload | true
	rm -rf ./.config/nvim/sessions | true

red:
	redshift -P -O 6000

pull:
	@echo "Updating nvim files from git"
	git pull origin main
	cp .config/nvim/ ${HOME}/.config/ -rv
	cp .config/redshift/ ${HOME}/.config/ -rv
	make link

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


del:
	rm ${HOME}/.tmux.conf | true
	rm ${HOME}/.zshrc | true
	rm ${HOME}/.vimrc | true
	rm ${HOME}/.config/redshift/ -rv | true
	rm ${HOME}/.config/vifm/ -rv | true
