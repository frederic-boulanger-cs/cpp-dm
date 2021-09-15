DOCKUSR = fred0cs
REPO    = $(DOCKUSR)/
NAME    = cpp-dm
ARCH    = `uname -m`
TAG     = 2021
ARCH   := $$(arch=$$(uname -m); if [ "$$arch" = "x86_64" ]; then echo "amd64"; elif [ "$$arch" = "aarch64" ]; then echo "arm64"; else echo $$arch; fi)
ARCHS   = amd64 arm64
IMAGES := $(ARCHS:%=$(REPO)$(NAME):$(TAG)-%)
PLATFORMS := $$(first="True"; for a in $(ARCHS); do if [[ $$first == "True" ]]; then printf "linux/%s" $$a; first="False"; else printf ",linux/%s" $$a; fi; done)

# Build image
build:
	docker build --build-arg arch=$(ARCH) --tag $(REPO)$(NAME):$(TAG) .
#	docker build --build-arg arch=$(ARCH) --tag $(REPO)$(NAME):$(TAG)-$(ARCH) .
	@danglingimages=$$(docker images --filter "dangling=true" -q); \
	if [[ $$danglingimages != "" ]]; then \
	  docker rmi $$(docker images --filter "dangling=true" -q); \
	fi

# Safe way to build multiarchitecture images:
# - build each image on the matching hardware, with the -$(ARCH) tag
# - push the architecture specific images to Dockerhub
# - build a manifest list referencing those images
# - push the manifest list so that the multiarchitecture image exist
manifest:
	docker manifest create $(REPO)$(NAME):$(TAG) $(IMAGES)
	@for arch in $(ARCHS); \
	 do \
	   echo docker manifest annotate --os linux --arch $$arch $(REPO)$(NAME):$(TAG) $(REPO)$(NAME):$(TAG)-$$arch; \
	   docker manifest annotate --os linux --arch $$arch $(REPO)$(NAME):$(TAG) $(REPO)$(NAME):$(TAG)-$$arch; \
	 done
	docker manifest push $(REPO)$(NAME):$(TAG)

login:
	docker login --username $(DOCKUSR)

logout:
	docker logout

rmmanifest:
	docker manifest rm $(REPO)$(NAME):$(TAG)

push:
	docker push $(REPO)$(NAME):$(TAG)
#	docker push $(REPO)$(NAME):$(TAG)-$(ARCH)

save:
	docker save $(REPO)$(NAME):$(TAG) | gzip > $(NAME)-$(TAG).tar.gz
#	docker save $(REPO)$(NAME):$(TAG)-$(ARCH) | gzip > $(NAME)-$(TAG)-$(ARCH).tar.gz

# Clear caches
clean:
	docker builder prune

clobber:
	docker rmi $(REPO)$(NAME):$(TAG) $(REPO)$(NAME):$(TAG)-$(ARCH)
	docker builder prune --all

run:
	docker run --rm --detach \
    --env USERNAME=`id -n -u` --env USERID=`id -u` \
		--volume "${PWD}":/config/workspace:rw \
		--publish 8443:8443 \
		--name $(NAME) \
		$(REPO)$(NAME):$(TAG)
#		$(REPO)$(NAME):$(TAG)-$(ARCH)
	sleep 5
	open http://localhost:8443 || xdg-open http://localhost:8443 || echo "http://localhost:8443"

debug:
	docker run --rm --interactive --tty \
    --env USERNAME=`id -n -u` --env USERID=`id -u` \
		--volume "${PWD}":/config/workspace:rw \
		--publish 8443:8443 \
		--name $(NAME) \
		--entrypoint "/bin/bash" \
		$(REPO)$(NAME):$(TAG)
#		$(REPO)$(NAME):$(TAG)-$(ARCH)
