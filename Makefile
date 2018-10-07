ROOT_DIR:=$(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))
TEST_INVENTORY_FILE ?= tests/inventory.yml
TEST_PLAYBOOK ?= tests/test.yml
DOCKER_IMAGE ?= hannseman/raspbian

.PHONY: lint test docker

lint:
	@ansible-playbook -i $(TEST_INVENTORY_FILE) $(TEST_PLAYBOOK) --syntax-check
	@yamllint .

docker:
	@docker pull $(DOCKER_IMAGE)
	@docker start raspbian || docker run --name raspbian -d -p 2222:2222 --privileged $(DOCKER_IMAGE)
	@sh $(ROOT_DIR)/tests/files/wait-for-healthy.sh

test: docker
	@ansible-playbook -vvv -i $(TEST_INVENTORY_FILE) $(TEST_PLAYBOOK)

test-idempotence: docker
	@ansible-playbook -vvv -i $(TEST_INVENTORY_FILE) $(TEST_PLAYBOOK) | \
	tee /dev/tty | \
	grep -q 'changed=0.*failed=0' \
    && (echo 'Idempotence test: pass' && exit 0) \
    || (echo 'Idempotence test: fail' && exit 1) \
