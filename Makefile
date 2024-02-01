
.PHONY: help env up stop rm rmv rmi logs sh init_linters lint test dropmain updmain rsmain gha_ci_build_test_image _rm_test_container gha_ci_check_linting gha_ci_test

# --- Application settings
default_env_file_name := .env
env_clone_dir := env_gist_temp

# --- Application virtual environment settings (can be changed)
env_file_name := .env
env_snippet_repo := $(GIST_REPO)

# --- Docker
compose_cmd := docker compose -f
compose_local := $(compose_cmd) docker-compose-local.yml
main_app_service_name := api

# --- Docker test
test_api_container_name := sh_runner_daemon_test_api
test_api_image_name := sh_runner_daemon_test_api_image


help: ## Commands
	@echo "Please use 'make <target>' where <target> is one of:"
	@awk -F ':|##' '/^[a-zA-Z\-_0-9]+:/ && !/^[ \t]*all:/ { printf "\t\033[36m%-30s\033[0m %s\n", $$1, $$3 }' $(MAKEFILE_LIST)

env: ## Fetch '.env' file from GitHub GIST
	@if [ ! -f $(default_env_file_name) ]; then \
  		git clone  $(env_snippet_repo) $(env_clone_dir) && \
  		mv $(env_clone_dir)/$(env_file_name) ./$(default_env_file_name) && \
  		rm -rf $(env_clone_dir) && \
  		echo "tg__token=$(TG_TOKEN)" >> $(default_env_file_name) && \
  		echo "NGROK_AUTHTOKEN=$(NGROK_AUTHTOKEN)" >> $(default_env_file_name); \
  	fi
  	env_arg := --env-file $(default_env_file_name)

init_linters: ## Install pre-commit hooks
	@pre-commit install

up: env ## Run docker containers
	@$(compose_local) $(env_arg) up -d

stop: env ## Stop docker containers
	@$(compose_local) $(env_arg) stop

rm: env ## Stop and remove docker containers
	@$(compose_local) $(env_arg) down

rmv: env ## Stop and remove docker containers with their volumes
	@$(compose_local) $(env_arg) down -v

rmi: env ## Stop and remove docker containers with their images and volumes
	@$(compose_local) $(env_arg) down --rmi all -v

logs: up ## Stdout logs from docker containers
	@$(compose_local) logs -f

sh: up ## Run the command line in the selected SERVICE docker container
	@docker exec -it $(firstword $(filter-out $@,$(MAKEOVERRIDES) $(MAKECMDGOALS))) sh

lint: init_linters ## Run linting
	@pre-commit run -a

_rm_test_container: ## !Do not run manually!
	@docker rm $(test_api_container_name) -f

test: env ## Run tests for the API service
	@docker build -t $(test_api_image_name) .
	@docker run $(env_arg) --name $(test_api_container_name) $(test_api_image_name) pytest || true
	$(MAKE) _rm_test_container
	@docker rmi $(test_api_image_name)


gha_ci_build_test_image: ## Build test image into GitHub actions
	@if [ -z $$(docker images -q $(test_api_image_name)) ]; then \
        docker build -t $(test_api_image_name) . ; \
    fi

gha_ci_check_linting: gha_ci_build_test_image ## Check linting for CI into GitHub actions
	@docker run $(env_arg) --name $(test_api_container_name) $(test_api_image_name) sh -c "autoflake . --check && black . --check && isort . --check && flake8"
	$(MAKE) _rm_test_container

gha_ci_test: gha_ci_build_test_image ## Run tests for CI into GitHub actions
	@docker run $(env_arg) --name $(test_api_container_name) $(test_api_image_name) pytest
	$(MAKE) _rm_test_container

dropmain: env ## Stop and remove main app docker container with image and volume
	@$(compose_local) $(env_arg) down --rmi all -v $(main_app_service_name)

updmain: env ## Stop and remove old main app container with image and volume, rebuild and run new one
	@$(compose_local) $(env_arg) up -d --build $(main_app_service_name)

rsmain: env ## Restart main app container
	@$(compose_local) $(env_arg) restart $(main_app_service_name)
	$(MAKE) logs