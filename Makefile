# Default shell
SHELL := bash

# https://stackoverflow.com/a/26339924/
# How do you get the list of targets in a makefile?
list:
	@$(MAKE) -pRrq -f $(lastword $(MAKEFILE_LIST)) : 2>/dev/null | awk -v RS= -F: '/^# File/,/^# Finished Make data base/ {if ($$1 !~ "^[#.]") {print $$1}}' | sort | egrep -v -e '^[^[:alnum:]]' -e '^$@$$'

default: all

# Help message
help:
	@echo "NixOS Project Template"
	@echo
	@echo "Target rules:"
	@echo "    all      - Compiles and generates the iso"
	@echo "    start    - Boots the iso into a virtual machine"
	@echo "    clean    - Clean the project by removing the iso"
	@echo "    help     - Prints a help message with target rules"

# Default rule
all:
	nix-shell --command 'nixos-generate -c ./configuration.nix -f vm-nogui -o ./dist'

# see https://github.com/nix-community/nixos-generators#supported-formats
google-image:
	nix-shell --command 'nixos-generate -c ./configuration.nix -f gce'

amazon-image:
	nix-shell --command 'nixos-generate -c ./configuration.nix -f amazon'

# see https://github.com/NixOS/nix/issues/2964#issuecomment-504097120
#     https://gist.github.com/573/312cbe9e22d7e71dcf87c7c816a775a5
#     echo "system-features = kvm" >> ~/.config/nix/nix.conf
patch-nixconf-kvm:
	file="$$HOME/.config/nix/nix.conf" ;\
	s="system-features = kvm" ;\
	grep -Fxqe "$$s" < "$$file" || printf "%s\n" "$$s" >> "$$file"

patch-nixconf-flakes:
	file="$$HOME/.config/nix/nix.conf" ;\
	s="experimental-features = nix-command flakes" ;\
	grep -Fxqe "$$s" < "$$file" || printf "%s\n" "$$s" >> "$$file"

# Boots the qcow2 image into a kvm virtual machine
start: all
	sudo ./dist/bin/run-nixos-vm \
		-m 4096M \
		-smp 8 \
		-nic user,hostfwd=tcp::2222-:22 \

ssh:
	while ! nc -z 127.0.0.1 2222; do sleep 0.1; done
	sshpass  -p 'password' ssh -o StrictHostKeychecking=no -p 2222 nixos@127.0.0.1				

# Clean the project by removing the iso
clean:
	rm -rf *.iso
