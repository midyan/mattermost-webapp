.PHONY: build test run clean stop check-style run-unit emojis help

BUILD_WEBAPP_DIR = ../mattermost-webapp
MM_UTILITIES_DIR = ../mattermost-utilities
EMOJI_TOOLS_DIR = ./build/emoji

check-style: node_modules ## Checks JS file for ESLint confirmity
	@echo Checking for style guide compliance

	npm run check

test: node_modules ## Runs tests
	@echo Running jest unit/component testing

	npm run test

i18n-extract: ## Extract strings for translation from the source code
	@[[ -d $(MM_UTILITIES_DIR) ]] || echo "You must clone github.com/mattermost/mattermost-utilities repo in .. to use this command"
	@[[ -d $(MM_UTILITIES_DIR) ]] && cd $(MM_UTILITIES_DIR) && npm install && npm run babel && node mmjstool/build/index.js i18n extract-webapp

node_modules: package.json package-lock.json
	@echo Getting dependencies using npm

	npm install

package: build ## Packages app
	@echo Packaging webapp

	mkdir tmp
	mv dist tmp/client
	tar -C tmp -czf mattermost-webapp.tar.gz client
	mv tmp/client dist
	rmdir tmp

build: node_modules ## Builds the app
	@echo Building mattermost Webapp

	rm -rf dist

	npm run build

run: node_modules ## Runs app
	@echo Running mattermost Webapp for development

	npm run run &

run-fullmap: node_modules ## Legacy alias to run
	@echo Running mattermost Webapp for development

	npm run run &

stop: ## Stops webpack
	@echo Stopping changes watching

ifeq ($(OS),Windows_NT)
	wmic process where "Caption='node.exe' and CommandLine like '%webpack%'" call terminate
else
	@for PROCID in $$(ps -ef | grep "[n]ode.*[w]ebpack" | awk '{ print $$2 }'); do \
		echo stopping webpack watch $$PROCID; \
		kill $$PROCID; \
	done
endif

restart: | stop run ## Restarts the app

clean: ## Clears cached; deletes node_modules and dist directories
	@echo Cleaning Webapp

	rm -rf dist
	rm -rf node_modules

emojis: ## Creates emoji JSX file and extracts emoji images from the system font
	gem install bundler
	bundle install --gemfile=$(EMOJI_TOOLS_DIR)/Gemfile
	BUNDLE_GEMFILE=$(EMOJI_TOOLS_DIR)/Gemfile bundle exec $(EMOJI_TOOLS_DIR)/make-emojis

## Help documentatin à la https://marmelab.com/blog/2016/02/29/auto-documented-makefile.html
help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
