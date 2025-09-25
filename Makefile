.PHONY: setup test lint slither cov fmt ci

setup:
	forge install openzeppelin/openzeppelin-contracts@v5.0.2 --no-commit
	npm i -D solhint prettier prettier-plugin-solidity

test:
	forge test -vvv --gas-report

cov:
	forge coverage

lint:
	npx prettier --write "contracts/**/*.sol"
	npx solhint "contracts/**/*.sol"

slither:
	slither . --exclude-informational --solc-remaps "$(tr '\n' ',' < remappings.txt)"
