# Blacklist token contracts
This guide outlines how to add token contracts in the blacklist in order to remove duplicated token entries.

Go to `apps/indexer/lib/indexer/blacklisted_tokens.ex`.

*For mainnet*, paste the token contract(impl) address `"0x.."` in the array shown below:

```
    if chain_id == 39797 do
        # mainnet: eAssets(impl contracts)
        [
          "0xb880e3da550bd421cd6ab9aacdb0d3351390af1a",	        #  eETH
          ...
        ]
```

*For testnet*, scroll down and paste the token contracts(impl) address `"0x.."` in the array shown below:

```
    else
        # testnet: eAssets(impl contracts)
        [
          "0x33cd121c2e167fcc9a3327e8271e52a373ca3d69",         # eETH
          ...
        ]
```

*Note*

To remove the duplicate entries from all the previous blocks, please clear the database and re-run the explorer after adding token contract addresses in the list(as explained above).
