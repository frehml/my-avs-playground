import pathlib 
import shutil 
import subprocess
import toml
import os 
import json
from web3 import Web3

thisdir = pathlib.Path(__file__).resolve().parent
home = pathlib.Path.home()
rpc = os.getenv('RPC_URL', 'http://localhost:8545')
w3 = Web3(Web3.HTTPProvider(rpc))

if "CODESPACE_NAME" in os.environ:
    ENDPOINT = f"https://{os.environ['CODESPACE_NAME']}-3000.githubpreview.dev"
elif "GITPOD_WORKSPACE_URL" in os.environ:
    ENDPOINT = f"https://3000-{os.environ['GITPOD_WORKSPACE_URL']}"
else:
    ENDPOINT = "*"

def setup_contract():
    addresspath = thisdir.parent.joinpath("script", "output", "5", "playground_avs_deployment_output.json")
    if not addresspath.exists():
        raise FileNotFoundError(f"{addresspath} does not exist!")
    
    with open(addresspath, 'r') as f:
        address = json.load(f)

    if 'addresses' in address and 'registryCoordinator' in address['addresses']:
        address = address['addresses']['registryCoordinator']
    else:
        raise KeyError("Key 'addresses' or 'registryCoordinator' not found in the JSON file!")
    

    abipath = thisdir.parent.joinpath("out", "BLSRegistryCoordinatorWithIndices.sol", "BLSRegistryCoordinatorWithIndices.json")
    if not abipath.exists():
        raise FileNotFoundError(f"{abipath} does not exist!")
    
    with open(abipath, 'r') as f:
        abi = json.load(f)

    if 'abi' in abi:
        abi = abi['abi']
    else:
        raise KeyError("Key 'abi' not found in the JSON file!")
    
    return w3.eth.contract(address=address, abi=abi)

def main():
    tendermint = home.joinpath(".tendermint")
    contract = setup_contract()

    print(contract.functions.operatorList().call())
    if tendermint.exists():
        shutil.rmtree(tendermint)

    subprocess.Popen(["tendermint", "init"]).wait()
    


    config_path = tendermint.joinpath("config", "config.toml")
    config = toml.loads(config_path.read_text())
    config["rpc"]["cors_allowed_origins"] = [ENDPOINT]
    config_path.write_text(toml.dumps(config))

    
    subprocess.Popen(["tendermint", "node"]).wait()

    

if __name__ == "__main__":
    main()
