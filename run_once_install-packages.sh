
#!/bin/sh
sudo softwareupdate --install-rosetta --agree-to-license

brew bundle --global 

flutter doctor --android-licenses 
asdf plugin add ruby 
asdf install ruby latest
asdf plugin add nodejs
asdf install nodejs lts
asdf plugin add python
sudo spctl --master-disable
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
sudo xcodebuild -license