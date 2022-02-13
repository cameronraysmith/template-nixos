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

GCP_REGION = us-east1
GCP_ZONE = $(GCP_REGION)-c
GCP_PROJECT = core-246800
STORAGE_BUCKET_IMAGES = $(GCP_PROJECT)-nixos-images
IMAGE_NAME = nixos-image-2205pre351617942b0817e89-x8664-linux
IMAGE_FILENAME = nixos-image-22.05pre351617.942b0817e89-x86_64-linux.raw.tar.gz
IMAGE_INSTANCE_NAME = nixos-instance-01

create_image:
	gcloud compute images create $(IMAGE_NAME) \
  --project=$(GCP_PROJECT) \
  --source-uri=https://storage.googleapis.com/$(STORAGE_BUCKET_IMAGES)/$(IMAGE_FILENAME) \
  --storage-location=$(GCP_REGION)

create_image_instance:
	gcloud compute instances create $(IMAGE_INSTANCE_NAME) \
  --project=$(GCP_PROJECT) \
  --zone=$(GCP_ZONE) \
  --machine-type=$(GCP_MACHINE_TYPE) \
  --metadata=enable-oslogin=TRUE \
  --no-address \
  --create-disk=auto-delete=yes,boot=yes,device-name=nixos-instance-01,image=projects/$(GCP_PROJECT)/global/images/$(IMAGE_NAME),mode=rw,size=200,type=projects/$(GCP_PROJECT)/zones/$(GCP_ZONE)/diskTypes/pd-balanced \
  --reservation-affinity=any \
  --preemptible
  # --network-interface=network-tier=PREMIUM,subnet=default \ #
  # --scopes=https://www.googleapis.com/auth/devstorage.read_only,https://www.googleapis.com/auth/logging.write,https://www.googleapis.com/auth/monitoring.write,https://www.googleapis.com/auth/servicecontrol,https://www.googleapis.com/auth/service.management.readonly,https://www.googleapis.com/auth/trace.append \ #
  # --maintenance-policy=MIGRATE \ #
  # --service-account=613975745987-compute@developer.gserviceaccount.com \ #


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
