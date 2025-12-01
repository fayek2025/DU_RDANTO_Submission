# Docker Services:
#   up - Start services (use: make up [service...] or make up MODE=prod, ARGS="--build" for options)
#   down - Stop services (use: make down [service...] or make down MODE=prod, ARGS="--volumes" for options)
#   build - Build containers (use: make build [service...] or make build MODE=prod)
#   logs - View logs (use: make logs [service] or make logs SERVICE=backend, MODE=prod for production)
#   restart - Restart services (use: make restart [service...] or make restart MODE=prod)
#   shell - Open shell in container (use: make shell [service] or make shell SERVICE=gateway, MODE=prod, default: backend)
#   ps - Show running containers (use MODE=prod for production)
#
# Convenience Aliases (Development):
#   dev-up - Alias: Start development environment
#   dev-down - Alias: Stop development environment
#   dev-build - Alias: Build development containers
#   dev-logs - Alias: View development logs
#   dev-restart - Alias: Restart development services
#   dev-shell - Alias: Open shell in backend container
#   dev-ps - Alias: Show running development containers
#   backend-shell - Alias: Open shell in backend container
#   gateway-shell - Alias: Open shell in gateway container
#   mongo-shell - Open MongoDB shell
#
# Convenience Aliases (Production):
#   prod-up - Alias: Start production environment
#   prod-down - Alias: Stop production environment
#   prod-build - Alias: Build production containers
#   prod-logs - Alias: View production logs
#   prod-restart - Alias: Restart production services
#
# Backend:
#   backend-build - Build backend TypeScript
#   backend-install - Install backend dependencies
#   backend-type-check - Type check backend code
#   backend-dev - Run backend in development mode (local, not Docker)
#
# Database:
#   db-reset - Reset MongoDB database (WARNING: deletes all data)
#   db-backup - Backup MongoDB database
#
# Cleanup:
#   clean - Remove containers and networks (both dev and prod)
#   clean-all - Remove containers, networks, volumes, and images
#   clean-volumes - Remove all volumes
#
# Utilities:
#   status - Alias for ps
#   health - Check service health
#
# Testing:
#   test - Run all test suites
#   test-integration - Run integration tests (requires services running)
#   test-api - Run API tests (requires services running)
#   test-docker - Run Docker configuration tests
#   test-makefile - Run Makefile command tests
#
# Help:
#   help - Display this help message

.PHONY: help up down build logs restart shell ps \
	dev-up dev-down dev-build dev-logs dev-restart dev-shell dev-ps \
	prod-up prod-down prod-build prod-logs prod-restart \
	backend-shell gateway-shell mongo-shell \
	backend-build backend-install backend-type-check backend-dev \
	db-reset db-backup \
	clean clean-all clean-volumes \
	status health \
	test test-integration test-api test-docker test-makefile

# Default mode
MODE ?= dev
SERVICE ?= backend
ARGS ?=

# Compose file selection
COMPOSE_FILE_DEV = docker/compose.development.yaml
COMPOSE_FILE_PROD = docker/compose.production.yaml

ifeq ($(MODE),prod)
	COMPOSE_FILE = $(COMPOSE_FILE_PROD)
	COMPOSE_CMD = docker compose --env-file .env -f $(COMPOSE_FILE)
else
	COMPOSE_FILE = $(COMPOSE_FILE_DEV)
	COMPOSE_CMD = docker compose --env-file .env -f $(COMPOSE_FILE)
endif

# Docker Services
up:
	$(COMPOSE_CMD) up -d $(ARGS) $(filter-out $@,$(MAKECMDGOALS))

down:
	$(COMPOSE_CMD) down $(ARGS) $(filter-out $@,$(MAKECMDGOALS))

build:
	$(COMPOSE_CMD) build $(ARGS) $(filter-out $@,$(MAKECMDGOALS))

logs:
	@if [ -n "$(filter-out $@,$(MAKECMDGOALS))" ]; then \
		$(COMPOSE_CMD) logs -f $(filter-out $@,$(MAKECMDGOALS)); \
	else \
		$(COMPOSE_CMD) logs -f; \
	fi

restart:
	$(COMPOSE_CMD) restart $(filter-out $@,$(MAKECMDGOALS))

shell:
	@SERVICE=$(SERVICE); \
	if [ -n "$(filter-out $@,$(MAKECMDGOALS))" ]; then \
		SERVICE=$(filter-out $@,$(MAKECMDGOALS)); \
	fi; \
	$(COMPOSE_CMD) exec $$SERVICE sh

ps:
	$(COMPOSE_CMD) ps

# Convenience Aliases (Development)
dev-up:
	$(MAKE) up MODE=dev

dev-down:
	$(MAKE) down MODE=dev

dev-build:
	$(MAKE) build MODE=dev

dev-logs:
	$(MAKE) logs MODE=dev

dev-restart:
	$(MAKE) restart MODE=dev

dev-shell:
	$(MAKE) shell MODE=dev SERVICE=backend

dev-ps:
	$(MAKE) ps MODE=dev

backend-shell:
	$(MAKE) shell MODE=$(MODE) SERVICE=backend

gateway-shell:
	$(MAKE) shell MODE=$(MODE) SERVICE=gateway

mongo-shell:
	@$(COMPOSE_CMD) exec mongo mongosh -u $(shell grep MONGO_INITDB_ROOT_USERNAME .env 2>/dev/null | cut -d '=' -f2) -p $(shell grep MONGO_INITDB_ROOT_PASSWORD .env 2>/dev/null | cut -d '=' -f2) || \
	$(COMPOSE_CMD) exec mongo mongosh

# Convenience Aliases (Production)
prod-up:
	$(MAKE) up MODE=prod

prod-down:
	$(MAKE) down MODE=prod

prod-build:
	$(MAKE) build MODE=prod

prod-logs:
	$(MAKE) logs MODE=prod

prod-restart:
	$(MAKE) restart MODE=prod

# Backend Utilities
backend-build:
	cd backend && pnpm run build

backend-install:
	cd backend && pnpm install

backend-type-check:
	cd backend && pnpm run type-check

backend-dev:
	cd backend && pnpm run dev

# Database Utilities
db-reset:
	@echo "WARNING: This will delete all data in the MongoDB database!"
	@read -p "Are you sure? [y/N] " -n 1 -r; \
	echo; \
	if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
		$(COMPOSE_CMD) exec mongo mongosh -u $(shell grep MONGO_INITDB_ROOT_USERNAME .env 2>/dev/null | cut -d '=' -f2) -p $(shell grep MONGO_INITDB_ROOT_PASSWORD .env 2>/dev/null | cut -d '=' -f2) --eval "db.getSiblingDB('$(shell grep MONGO_DATABASE .env 2>/dev/null | cut -d '=' -f2)').dropDatabase()" || \
		$(COMPOSE_CMD) exec mongo mongosh --eval "db.getSiblingDB('$(shell grep MONGO_DATABASE .env 2>/dev/null | cut -d '=' -f2)').dropDatabase()"; \
	fi

db-backup:
	@mkdir -p backups
	@BACKUP_FILE=backups/mongo_backup_$$(date +%Y%m%d_%H%M%S).tar.gz; \
	$(COMPOSE_CMD) exec -T mongo mongodump --archive --gzip -u $(shell grep MONGO_INITDB_ROOT_USERNAME .env 2>/dev/null | cut -d '=' -f2) -p $(shell grep MONGO_INITDB_ROOT_PASSWORD .env 2>/dev/null | cut -d '=' -f2) | \
	cat > $$BACKUP_FILE || \
	$(COMPOSE_CMD) exec -T mongo mongodump --archive --gzip | cat > $$BACKUP_FILE; \
	echo "Backup saved to $$BACKUP_FILE"

# Cleanup
clean:
	$(MAKE) down MODE=dev ARGS="--remove-orphans" || true
	$(MAKE) down MODE=prod ARGS="--remove-orphans" || true
	docker network prune -f

clean-all: clean
	$(MAKE) down MODE=dev ARGS="--volumes --remove-orphans" || true
	$(MAKE) down MODE=prod ARGS="--volumes --remove-orphans" || true
	docker system prune -af --volumes

clean-volumes:
	$(MAKE) down MODE=dev ARGS="--volumes" || true
	$(MAKE) down MODE=prod ARGS="--volumes" || true

# Utilities
status: ps

health:
	@echo "Checking service health..."
	@echo "Gateway:"
	@curl -s http://localhost:5921/health | jq . || echo "Gateway not responding"
	@echo ""
	@echo "Backend (via Gateway):"
	@curl -s http://localhost:5921/api/health | jq . || echo "Backend not responding"
	@echo ""
	@echo "Direct Backend (should fail):"
	@curl -s http://localhost:3847/api/health 2>&1 | head -1 || echo "Backend correctly not exposed"

# Testing
test:
	@bash scripts/run-all-tests.sh

test-integration:
	@bash scripts/test.sh

test-api:
	@bash scripts/test-api.sh

test-docker:
	@bash scripts/test-docker.sh

test-makefile:
	@bash scripts/test-makefile.sh

# Help
help:
	@cat $(MAKEFILE_LIST) | grep -E "^#\s" | sed 's/^#\s*//' | head -50

# Prevent make from treating targets as files
%:
	@:
