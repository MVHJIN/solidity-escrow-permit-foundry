# Solidity Starter — Day 1 (Foundry + CI + Lint + Escrow)

**Objectif jour 1** : prendre en main Foundry, écrire/faire tourner des tests, et livrer un petit contrat **Escrow** orienté sécurité avec events, erreurs custom, et garde reentrancy.

## Prérequis (local)
- **Linux/macOS** ou **Windows 11 + WSL2 (Ubuntu recommandé)**.
- **Foundry** : `curl -L https://foundry.paradigm.xyz | bash && foundryup`
- **Node LTS** : https://nodejs.org/en/ (ou via nvm)
- **Python 3.10+ & pipx** : `python3 -m pip install --user pipx && pipx ensurepath`
- **Slither** : `pipx install slither-analyzer`
- **Solhint / Prettier** : `npm i -D solhint prettier prettier-plugin-solidity`

## Installation
```bash
git init
forge init --no-commit .
forge install openzeppelin/openzeppelin-contracts@v5.0.2
npm i -D solhint prettier prettier-plugin-solidity
```

## Commandes utiles
```bash
# Lint & format
npx prettier --write "contracts/**/*.sol"
npx solhint "contracts/**/*.sol"

# Tests (détaillés) + gas + coverage
forge test -vvv --gas-report
forge coverage

# Slither (analyse statique)
slither . --exclude-informational --checklist --solc-remaps $(cat remappings.txt | tr '\n' ',')
```

## Réseaux / Déploiement testnet
- Config `base_sepolia` dans `foundry.toml`.
- Variables env (exemple) :
```bash
export PRIVATE_KEY=0x...
export BASE_SEPOLIA_RPC_URL=https://base-sepolia.g.alchemy.com/v2/<key>
export BASESCAN_API_KEY=<key>
```
- Script : `forge script script/Deploy.s.sol:DeployEscrow --rpc-url base_sepolia --private-key $PRIVATE_KEY --broadcast`

## Structure
```
contracts/
  Escrow.sol
  utils/Errors.sol
script/
  Deploy.s.sol
test/
  Escrow.t.sol
  properties/Escrow.Invariants.t.sol
.github/workflows/ci.yml
foundry.toml
remappings.txt
```
