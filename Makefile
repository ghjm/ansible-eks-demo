default:
	@echo "Main targets in this Makefile:"
	@echo
	@echo "    create:   Create the test site"
	@echo "    destroy:  Destroy the test site"
	@echo
	@echo "    venv:     Create the Python virtualenv to run Ansible in"
	@echo

venv: venv/bin/activate

venv/bin/activate:
	@python3 -m venv venv
	@venv/bin/pip install -U pip wheel
	@venv/bin/pip install -U ansible boto boto3 openshift

clean-venv:
	@rm -rf venv

.unique_id:
	@read -p "Unique id prefix for naming AWS resources? " && echo $$REPLY > .unique_id

inventory.yml: venv/bin/activate inventory.yml.j2 .unique_id
	@venv/bin/ansible -i localhost, -c local -e ansible_python_interpreter=auto_silent -m template localhost -a "src=inventory.yml.j2 dest=inventory.yml" -e unique_id="$$(cat .unique_id)" > /dev/null

ssh_keys/id_rsa:
	@ssh-keygen -f ssh_keys/id_rsa -N "" -C ""

create: venv/bin/activate inventory.yml ssh_keys/id_rsa
	@venv/bin/ansible-playbook -i inventory.yml create.yml

destroy: venv/bin/activate inventory.yml
	@venv/bin/ansible-playbook -i inventory.yml destroy.yml

clean: clean-venv
	@rm .unique_id
	@rm inventory.yml
	@rm ssh_keys/id*

.PHONY: default clean venv clean-venv create destroy
