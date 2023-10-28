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


links:
	ln ${HOME}/.tmux.conf .tmux.conf | true
	ln ${HOME}/.zshrc .zshrc | true

red:
	redshift -P -O 6000
