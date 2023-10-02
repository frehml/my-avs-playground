#!/bin/bash
export RPC_URL=http://localhost:8545
export PRIVATE_KEY=498c6973c5652ed3b50df640b0a1fa7d072ef73b9ca2e39135fec27e8b8becac

#deploy eigenlayer
cd lib/eigenlayer-contracts
forge script script/testing/M2_Deploy_From_Scratch.s.sol --rpc-url $RPC_URL --private-key $PRIVATE_KEY --broadcast --sig "run(string memory configFile)" -- M2_deploy_from_scratch.anvil.config.json
cp script/output/M2_from_scratch_deployment_data.json ../../script/output/5/
cd ../..

#deploy mock strategy
make deploy-mock-strategy

#deploy avs
make deploy-avs

#Register operator to AVS
make register-operator-avs