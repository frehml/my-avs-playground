# main.py

from app import main as abci_main
from restart_tm_node import main as restart_tm_node_main

def main():
    abci_main()  # This will run the main function from abci.py
    restart_tm_node_main()  # This will run the main function from restart_tm.py
