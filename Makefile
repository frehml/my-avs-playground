deploy-mock-strategy:
	forge script script/ERC20MockAndStrategyDeployer.sol --rpc-url ${RPC_URL}  --private-key ${PRIVATE_KEY} --broadcast -v

deploy-avs:
	forge script script/PlaygroundAVSDeployer.s.sol --rpc-url ${RPC_URL}  --private-key ${PRIVATE_KEY} --broadcast -v

register-operator-avs:
	forge script script/playbooks/RegisterOperatorAVS.s.sol --rpc-url ${RPC_URL}  --private-key ${PRIVATE_KEY} --broadcast -v
