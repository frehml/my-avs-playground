import "@eigenlayer/contracts/middleware/example/ECDSARegistry.sol";

import "forge-std/Test.sol";
import "../utils/Utils.sol";

import "forge-std/Script.sol";
import "forge-std/StdJson.sol";

contract RegisterOperatorAVS is Script, Utils {
    function run () external {
        string memory configData = readOutput("playground_avs_deployment_output");

        ECDSARegistry registry = ECDSARegistry(
            stdJson.readAddress(configData, ".addresses.registryCoordinator")
        );

        console.log(msg.sender);

        vm.startBroadcast();
        registry.registerOperator("IP address");
        vm.stopBroadcast();
    }
}
