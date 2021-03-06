#!/usr/bin/env bash
#
# This script is based of the following guide:
# https://www.coincashew.com/coins/overview-ada/guide-how-to-build-a-haskell-stakepool-node
#
# Rotates KES keys and restarts the block producing node (regardless whether it is time or not).
#
# Place this file in a folder named "rotate-keys" inside your cardano-node user home folder.

# Runs the block producing node using port 3000 by default
PORT=3000

# Define path variables
THIS_PATH="$HOME/rotate-keys"
NODE_PATH="$HOME/cardano-my-node"
COLD_PATH="$HOME/cold-keys"

# Export the relevant socket path
export CARDANO_NODE_SOCKET_PATH="$NODE_PATH/db/socket"

# Calculates the current slot, the current KES period, and the next KES period to rotate the keys
CURRENT_SLOT=$(/usr/local/bin/cardano-cli shelley query tip --testnet-magic 42 | grep -oP 'SlotNo = \K\d+')
KES_PERIOD=$(expr $CURRENT_SLOT / 3600)
NEXT_KES_PERIOD=$(expr $KES_PERIOD + 119)

# Unlocks the cold-keys path, rotates the KES keys, locks the cold-keys path
chmod u+rwx $COLD_PATH
cardano-cli shelley node issue-op-cert \
    --kes-verification-key-file $NODE_PATH/kes.vkey \
    --cold-signing-key-file $COLD_PATH/node.skey \
    --operational-certificate-issue-counter $COLD_PATH/node.counter \
    --kes-period $KES_PERIOD \
    --out-file $NODE_PATH/node.cert
chmod a-rwx $COLD_PATH

# Saves the next KES period to the file renewPeriod.txt
echo "$NEXT_KES_PERIOD" > "$THIS_PATH/renewPeriod.txt"

# Kill the block producing node and restarts it with the script startBlockProducingNode.sh
# https://github.com/Kaze-Stake/cardano-haskell-testnet-automatic-startup/blob/master/startBlockProducingNode.sh
kill $(lsof -i:$PORT -sTCP:LISTEN) &>/dev/null
/usr/bin/bash $NODE_PATH/startBlockProducingNode.sh