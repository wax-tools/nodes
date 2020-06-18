################################################################################
#
# Created by Sam Noble for eosdublinwow https://eosdublin.com
# Visit https://github.com/wax-tools for details.
#
#################################################################################
environments:=testnet production
roles:=producer api seed

.PHONY: help

help: ## This help.
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

# TODO - Allow the role to be defined here such that patroneos can be put in front of any node type as this is useful
# for testnets. Additionally, improve the patroneos container by generating the config file at runtime. Only
# the target address changes per container and is related to the name of the nodeos container.
define GEN_RULE_CERBERUS
up-$(environment)-cerberus: ## Starts an API container with patroneos in front of it for the given $(environment).

	echo "Starting Cerberus for WAX $(environment)"

	INIT_MODE=$$(INIT_MODE) \
	INIT_DATA=$$(INIT_DATA) \
	NODEOS_USER="$$(NODEOS_USER)" \
	NODEOS_GROUP="$$(NODEOS_GROUP)" \
	NODEOS_ARGS="$$(NODEOS_ARGS)" \
	PATRONEOS_USER="$$(NODEOS_USER)" \
	EOSIO_IMAGE="$$(EOSIO_IMAGE):$$(EOSIO_VERSION)" \
	NODEOS_CONTAINER_NAME="wax-$(environment)-api" \
	NODEOS_DATA_PATH=$$(DATA_ROOT_PATH)/wax-$(environment)-api \
	NODEOS_SHARED_PATH=$$(CONFIG_ROOT_PATH)/wax-$(environment) \
	NODEOS_CONFIG_PATH=$$(CONFIG_ROOT_PATH)/wax-$(environment)-api \
	PATRONEOS_CONTAINER_NAME="wax-$(environment)-patroneos" \
	PATRONEOS_CONFIG_PATH=$$(CONFIG_ROOT_PATH)/../patroneos/wax-$(environment) \
	docker-compose \
	--file ./docker/compose/docker-compose.wax.yml \
	--file ./docker/compose/docker-compose.patroneos.yml \
	--project-name "wax-$(environment)-cerberus" \
	up \
	--detach \
	--timeout 120
endef

define GEN_RULE_NODEOS_UP
up-$(environment)-$(role):
	
	echo "Starting nodeos for the WAX $(environment) $(role)"

	INIT_MODE="$$(INIT_MODE)" \
	INIT_DATA="$$(INIT_DATA)" \
	NODEOS_USER=$$(NODEOS_USER) \
	NODEOS_GROUP=$$(NODEOS_GROUP) \
	NODEOS_ARGS="$$(NODEOS_ARGS)" \
	EOSIO_IMAGE="$$(EOSIO_IMAGE):$$(EOSIO_VERSION)" \
	NODEOS_CONTAINER_NAME="wax-$(environment)-$(role)" \
	NODEOS_DATA_PATH="$$(DATA_ROOT_PATH)/wax-$(environment)-$(role)" \
	NODEOS_SHARED_PATH="$$(CONFIG_ROOT_PATH)/wax-$(environment)" \
	NODEOS_CONFIG_PATH="$$(CONFIG_ROOT_PATH)/wax-$(environment)-$(role)" \
	docker-compose \
	--file ./docker/compose/docker-compose.wax.yml \
	$$(DOCKER_COMPOSE_ARGS) \
	--project-name "wax-$(environment)-$(role)" \
	up \
	--detach \
	--timeout 120
endef

define GEN_RULE_PAUSE_PRODUCTION
pause-production-$(environment)-$(role):
	docker/scripts/nodeos_production_pause.sh wax-$(environment)-$(role)
endef

define GEN_RULE_RESUME_PRODUCTION
resume-production-$(environment)-$(role):
	docker/scripts/nodeos_production_resume.sh wax-$(environment)-$(role)
endef

$(foreach environment,$(environments), \
	$(foreach role,$(roles), \
		$(eval $(GEN_RULE_NODEOS_UP)) \
	) \
)

$(foreach environment,$(environments), \
	$(eval $(GEN_RULE_CERBERUS)) \
)

$(foreach environment,$(environments), \
	$(foreach role,$(roles), \
		$(eval $(GEN_RULE_PAUSE_PRODUCTION)) \
	) \
) 

$(foreach environment,$(environments), \
	$(foreach role,$(roles), \
		$(eval $(GEN_RULE_RESUME_PRODUCTION)) \
	) \
) 
