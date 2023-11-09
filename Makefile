up:
	@echo "Updating nvim files"
	rm -rf .config/ | true
	mkdir -p .config/
	cp -r ~/.config/nvim ./.config/
	cp -r ~/.config/redshift ./.config/
	rm -rf ./.config/nvim/.git | true
	rm -rf ./.config/nvim/undodir | true
	rm -rf ./.config/nvim/plugin | true
	rm -rf ./.config/nvim/autoload | true
	rm -rf ./.config/nvim/sessions | true

links:
	ln ${HOME}/.tmux.conf .tmux.conf | true
	ln ${HOME}/.zshrc .zshrc | true

red:
	redshift -P -O 6000

pull:
	git pull origin main
	cp .tmux.conf ${HOME}/.tmux.conf
	cp .zshrc ${HOME}/.zshrc
	cp .vimrc ${HOME}/.vimrc
	cp .config/nvim/ ${HOME}/.config/nvim/ -r
	cp .config/redshift/ ${HOME}/.config/redshift/ -r
	cp vifmrc ${HOME}/.config/vifm/vifmrc
