# AUR packages

# AUR tools used here:
# - namcap (namcap)
# - mksrcinfo (pkgbuild-introspection)

# wildcard: all items with slash
# |> extract directory portion
# |> filter the slash (replace '/' with '')
# |> sort the list
AVAILABLE_PACKAGES=$(sort $(subst /,,$(dir $(wildcard */))))
PKG_SUFFIX=.pkg.tar.xz
MAKEPKG_ARGS=--clean --syncdeps --noarchive
NAMCAP_ARGS=-i
GIT_SSH_CMD=GIT_SSH_COMMAND="ssh -o VisualHostKey=no"

CURRENT_PACKAGE=$(firstword $(MAKECMDGOALS))
PACKAGE_GOALS=$(strip $(filter-out $(CURRENT_PACKAGE), $(MAKECMDGOALS)))
NO_GOALS_ERR=No goals for package "$(CURRENT_PACKAGE)" given

default:
	@echo You need to specify the package you want to check/build.
	@echo
	@echo Available packages:
	@for package in $(AVAILABLE_PACKAGES); do echo "-- $$package"; done
.PHONY: default

list-packages:
	@echo $(AVAILABLE_PACKAGES)
.PHONY: list-packages

$(AVAILABLE_PACKAGES): %:
	@echo [$(CURRENT_PACKAGE)]
ifeq ($(PACKAGE_GOALS),)
	$(error $(NO_GOALS_ERR))
endif
.PHONY: $(AVAILABLE_PACKAGES)

fetch-and-pull:
	@echo [FETCH-AND-PULL] CURRENT_PACKAGE = $(CURRENT_PACKAGE)
	@$(GIT_SSH_CMD) git fetch $(CURRENT_PACKAGE)
	@$(GIT_SSH_CMD) git subtree pull --prefix $(CURRENT_PACKAGE) $(CURRENT_PACKAGE) master --squash
.PHONY: fetch-and-pull

push:
	@echo [PUSH] CURRENT_PACKAGE = $(CURRENT_PACKAGE)
	@$(GIT_SSH_CMD) git subtree push --prefix $(CURRENT_PACKAGE) $(CURRENT_PACKAGE) master --squash

checksum:
	@cd $(CURRENT_PACKAGE) && updpkgsums
.PHONY: checksum

build: makepkg mksrcinfo
.PHONY: build

makepkg:
	@echo [MAKEPKG] CURRENT_PACKAGE = $(CURRENT_PACKAGE)
	@cd $(CURRENT_PACKAGE) && makepkg $(MAKEPKG_ARGS)
.PHONY: makepkg

mksrcinfo:
	@echo [MKSRCINFO] CURRENT_PACKAGE = $(CURRENT_PACKAGE)
	@cd $(CURRENT_PACKAGE) && mksrcinfo
.PHONY: mksrcinfo

check:
	@echo [CHECK] CURRENT_PACKAGE = $(CURRENT_PACKAGE)
	@namcap $(NAMCAP_ARGS) $(CURRENT_PACKAGE)/PKGBUILD
.PHONY: check

clean: clean-archives
.PHONY: clean

clean-archives:
	@rm -rf **/*.tar.{bz2,gz,xz}
.PHONY: clean-archives
