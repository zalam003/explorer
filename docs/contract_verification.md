# Smart Contracts Verification

On Energi Block Explorer, go to `/address/${CONTRACT_ADDRESS}/contract_verifications/new`.

Before trying to verify contracts, wait for Blockscout to finish indexing blocks and tokens.

### - Contract Address
The `0x` address supplied during the creation of the smart contract.

### - Contract Name
Name of the class whose constructor was called in the .sol file. For example, in `contract MyContract {..` **MyContract** is the contract name.

You will find the latest <a href="https://git.energi.software/energi/tech/gen3/energi3/-/tree/develop/energi/contracts/src" target="_blank">Core Node Smart Contracts</a> in the repo.

### - Compiler
Select the Solidity compiler version which was used to generate the contract byte-code that was deployed on the blockchain. It is derived from the first line in the contract `pragma solidity X.X.X`. Use the corresponding compiler version rather than the nightly build.

### - EVM Version
Petersburg

### - Optimization
If you enabled optimization during compilation, check `yes`.

Select the number of optimisation runs used to generate the contract byte-code that was deployed on the blockchain (by
default, Solidity Compiler uses 200), or `No` if you explicitly used the `--runs=1` flag when compiling with <a href="https://solidity.readthedocs.io/en/v0.5.3/using-the-compiler.html" target="_blank">Solidity Compiler</a>.

### - Solidity Contract Code
You may need to flatten the solidity code if it utilizes a library or inherits dependencies from another contract. 
We recommend the <a href="https://github.com/poanetwork/solidity-flattener" target="_blank">POA solidity flattener</a> or 
the <a href="https://www.npmjs.com/package/truffle-flattener" target="_blank">truffle flattener</a>.

### - Try to fetch constructor arguments automatically
No

### - ABI-encoded Constructor Arguments
If your contract was deployed with constructor arguments, you will need to enter them in their hex-encoded form
according to your contract’s ABI. Visit <a href="https://abi.hashex.org/" target="_blank">https://abi.hashex.org/</a>. Paste the contract’s ABI and click the `Parse` button.

Then enter the contract arguments you used for contract deployment to generate ABI-encoded constructor arguments. 

Use those in Blockscout to verify your contract.

### - Verify and Publish
Click the `Verify and Publish` button.

You are done!
