
#!/bin/sh
sudo softwareupdate --install-rosetta --agree-to-license
brew bundle --global 

flutter doctor --android-licenses 
