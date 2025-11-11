SHELL := /bin/sh

# Allow overriding compose and project name
COMPOSE ?= docker compose
COMPOSE_FILE ?= compose.yaml
COMPOSE_ENV ?= .env
PROJECT_NAME ?= n8n-compose

export COMPOSE_PROJECT_NAME := $(PROJECT_NAME)

.PHONY: up down restart logs ps pull update backup restore shell copy

up:
	$(COMPOSE) -f $(COMPOSE_FILE) --env-file $(COMPOSE_ENV) up -d

down:
	$(COMPOSE) -f $(COMPOSE_FILE) --env-file $(COMPOSE_ENV) down

restart:
	$(COMPOSE) -f $(COMPOSE_FILE) --env-file $(COMPOSE_ENV) restart

logs:
	$(COMPOSE) -f $(COMPOSE_FILE) --env-file $(COMPOSE_ENV) logs -f --tail=200

ps:
	$(COMPOSE) -f $(COMPOSE_FILE) --env-file $(COMPOSE_ENV) ps

pull:
	$(COMPOSE) -f $(COMPOSE_FILE) --env-file $(COMPOSE_ENV) pull

update: pull up

# Backup/restore the named data volume
VOLUME_NAME := $(COMPOSE_PROJECT_NAME)_n8n_data
BACKUP_FILE ?= n8n_data_$(shell date +%Y-%m-%d_%H%M%S).tar.gz

backup:
	docker run --rm \
		-v $(VOLUME_NAME):/data:ro \
		-v $$(pwd):/backup \
		busybox sh -c "cd /data && tar czf /backup/$(BACKUP_FILE) ."
	@echo "Backup written to $(BACKUP_FILE)"

restore:
	@if [ -z "$(FILE)" ]; then echo "Usage: make restore FILE=path/to/backup.tar.gz"; exit 1; fi
	docker run --rm \
		-v $(VOLUME_NAME):/data \
		-v $$(pwd):/backup \
		busybox sh -c "rm -rf /data/* && tar xzf /backup/$(FILE) -C /data"
	@echo "Restore completed from $(FILE)"


# Open an interactive shell inside the n8n container
shell:
	$(COMPOSE) -f $(COMPOSE_FILE) --env-file $(COMPOSE_ENV) exec n8n bash || \
	$(COMPOSE) -f $(COMPOSE_FILE) --env-file $(COMPOSE_ENV) exec n8n sh

# Copy files from host to the running n8n container
# Usage: make copy SRC=./local-files/my.json DEST=/files/
copy:
	@if [ -z "$(SRC)" ] || [ -z "$(DEST)" ]; then \
		echo "Usage: make copy SRC=/path/on/host DEST=/path/in/container"; exit 1; \
	fi
	@CID=$$($(COMPOSE) -f $(COMPOSE_FILE) --env-file $(COMPOSE_ENV) ps -q n8n); \
	if [ -z "$$CID" ]; then \
		echo "n8n container not running. Start it with 'make up' first."; exit 1; \
	fi; \
	docker cp $(SRC) $$CID:$(DEST)


