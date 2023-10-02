// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";

import "@eigenlayer/contracts/interfaces/IStrategyManager.sol";
import "@eigenlayer/contracts/interfaces/ISlasher.sol";
import "@eigenlayer/contracts/middleware/example/ECDSARegistry.sol";
import "@eigenlayer/contracts/middleware/VoteWeigherBase.sol";

import "@eigenlayer/test/mocks/EmptyContract.sol";

import "../src/contracts/PlaygroundAVSServiceManagerV1.sol";

import "forge-std/Test.sol";
import "./utils/Utils.sol";

import "forge-std/Script.sol";
import "forge-std/StdJson.sol";

contract PlaygroundAVSDeployer is Script, Utils {
    ProxyAdmin public playgroundAVSProxyAdmin;
    PlaygroundAVSServiceManagerV1 public playgroundAVSServiceManagerV1;
    ECDSARegistry public registryCoordinator;

    ECDSARegistry public registryCoordinatorImplementation;

    address operatorWhitelister = msg.sender;

    function run() external {
        string memory configData = readOutput("mock_strategy_output");

        IStrategy strat = IStrategy(
            stdJson.readAddress(configData, ".addresses.ERC20MockStrategy")
        );

        configData = readOutput("M2_from_scratch_deployment_data");

        IStrategyManager strategyManager = IStrategyManager(
            stdJson.readAddress(configData, ".addresses.strategyManager")
        );

        ISlasher slasher = ISlasher(
            stdJson.readAddress(configData, ".addresses.slasher")
        );

        vm.startBroadcast();
        _deployPlaygroundAVSContracts(strategyManager, strat, slasher);
        vm.stopBroadcast();
    }

    function _deployPlaygroundAVSContracts(
        IStrategyManager strategyManager,
        IStrategy strat,
        ISlasher slasher
    ) internal {
        // Adding this as a temporary fix to make the rest of the script work with a single strategy
        // since it was originally written to work with an array of strategies
        IStrategy[1] memory deployedStrategyArray = [strat];
        uint numStrategies = deployedStrategyArray.length;

        // deploy proxy admin for ability to upgrade proxy contracts
        playgroundAVSProxyAdmin = new ProxyAdmin();

        EmptyContract emptyContract = new EmptyContract();

        // first
        registryCoordinator = ECDSARegistry(
            address(
                new TransparentUpgradeableProxy(
                    address(emptyContract),
                    address(playgroundAVSProxyAdmin),
                    ""
                )
            )
        );

        // Stock HASH AVS isn't upgradeable
        playgroundAVSServiceManagerV1 = new PlaygroundAVSServiceManagerV1(
            slasher,
            registryCoordinator
        );

        // second

        // create impl
        registryCoordinatorImplementation = new ECDSARegistry(
            strategyManager,
            playgroundAVSServiceManagerV1
        );

        {
            // set up a quorum with each strategy that needs to be set up
            uint256[] memory minimumStakeForQuorum = new uint256[](
                numStrategies
            );

            VoteWeigherBase.StrategyAndWeightingMultiplier[][]
                memory strategyAndWeightingMultipliers = new VoteWeigherBase.StrategyAndWeightingMultiplier[][](
                    numStrategies
                );
            for (uint i = 0; i < numStrategies; i++) {
                minimumStakeForQuorum[i] = 10000 / numStrategies;
                strategyAndWeightingMultipliers[
                    i
                ] = new VoteWeigherBase.StrategyAndWeightingMultiplier[](1);

                strategyAndWeightingMultipliers[i][0] = VoteWeigherBaseStorage
                    .StrategyAndWeightingMultiplier({
                        strategy: deployedStrategyArray[i],
                        // setting this to 1 ether since the divisor is also 1 ether
                        // therefore this allows an operator to register with even just 1 token
                        // see ./eigenlayer-contracts/src/contracts/middleware/VoteWeigherBase.sol#L81
                        //    weight += uint96(sharesAmount * strategyAndMultiplier.multiplier / WEIGHTING_DIVISOR);
                        multiplier: 1 ether
                    });
            }

            // update proxy w impl
            playgroundAVSProxyAdmin.upgradeAndCall(
                TransparentUpgradeableProxy(
                    payable(address(registryCoordinator))
                ),
                address(registryCoordinatorImplementation),
                abi.encodeWithSelector(
                    ECDSARegistry.initialize.selector,
                    operatorWhitelister,
                    false,
                    minimumStakeForQuorum,
                    strategyAndWeightingMultipliers
                )
            );

            // WRITE JSON DATA
            string memory parent_object = "parent object";

            string memory deployed_addresses = "addresses";
            vm.serializeAddress(
                deployed_addresses,
                "tendermintServiceManager",
                address(playgroundAVSServiceManagerV1)
            );

            vm.serializeAddress(
                deployed_addresses,
                "registryCoordinator",
                address(registryCoordinator)
            );

            string memory deployed_addresses_output = vm.serializeAddress(
                deployed_addresses,
                "registryCoordinatorImplementation",
                address(registryCoordinatorImplementation)
            );

            string memory finalJson = vm.serializeString(
                parent_object,
                deployed_addresses,
                deployed_addresses_output
            );

            writeOutput(finalJson, "playground_avs_deployment_output");
        }
    }
}
