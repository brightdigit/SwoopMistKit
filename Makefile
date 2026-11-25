.PHONY: help build test lint format headers docs docs-preview clean install docker-build docker-test docker-run xcode

.DEFAULT_GOAL := help

EXECUTABLE_NAME = swoopmist
INSTALL_PATH = /usr/local/bin
BUILD_PATH = .build/release/$(EXECUTABLE_NAME)
DOCKER_IMAGE = swift:6.4-noble

## build: Build the package in release mode
build:
	swift build -c release

## test: Run the test suite
test:
	swift test

## lint: Format, then run swift-format, SwiftLint, the build and periphery (Scripts/lint.sh)
lint:
	@./Scripts/lint.sh

## format: Format sources in place without linting
format:
	@FORMAT_ONLY=1 ./Scripts/lint.sh

## headers: Add or refresh the license header in Sources and Tests
headers:
	@./Scripts/header.sh -d Sources -c "Leo Dion" -o "BrightDigit" -p "SwoopMistKit"
	@./Scripts/header.sh -d Tests -c "Leo Dion" -o "BrightDigit" -p "SwoopMistKit"

## docs: Build the DocC archive (.build/docs); fails on unresolved symbol links
docs:
	@./Scripts/docc.sh

## docs-preview: Serve a live DocC preview
docs-preview:
	@DOCC_PREVIEW=1 ./Scripts/docc.sh

## clean: Remove build products
clean:
	swift package clean
	rm -rf .build DerivedData

## install: Install swoopmist to /usr/local/bin
install: build
	@install -m 755 $(BUILD_PATH) $(INSTALL_PATH)/$(EXECUTABLE_NAME)
	@echo "Installed $(EXECUTABLE_NAME) to $(INSTALL_PATH)"

## docker-build: Build in a Linux container ($(DOCKER_IMAGE))
docker-build:
	docker run --rm -v $(PWD):/workspace -w /workspace $(DOCKER_IMAGE) swift build

## docker-test: Run the tests in a Linux container
docker-test:
	docker run --rm -v $(PWD):/workspace -w /workspace $(DOCKER_IMAGE) swift test

## docker-run: Open a shell in a Linux container
docker-run:
	docker run -it --rm -v $(PWD):/workspace -w /workspace $(DOCKER_IMAGE) bash

## xcode: Generate SwoopMistKit.xcodeproj with XcodeGen (project.yml)
xcode:
	xcodegen generate

## help: Show this help
help:
	@echo "SwoopMistKit targets:"
	@sed -n 's/^##//p' $(MAKEFILE_LIST) | column -t -s ':' | sed -e 's/^/ /'
	@echo ""
	@echo "Lint tools are pinned in mise.toml; run 'mise install' once."
