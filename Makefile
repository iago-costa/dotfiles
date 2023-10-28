update:
	@echo "Updating nvim files"
	rm -rf nvim
	cp -r ~/.config/nvim .
	rm -rf nvim/.git

links:
	ln ${HOME}/.tmux.conf .tmux.conf | true
	ln ${HOME}/.zshrc .zshrc | true
