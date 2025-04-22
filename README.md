# v4-template & Contract for Defi Course  
In this README.md you can find all the sources mentioned in the course:  

1. [Foundry](https://book.getfoundry.sh/) is a smart contract development toolchain.
2. [Uniswap Foundation Template](https://github.com/uniswapfoundation/v4-template/generate) that was used.
3. Source code:
    - contract is in the `./src/BlackListHook.sol`; 
    - contract's tests are in the  `./test/BlackListHook.t.sol`; 
    - deployment script is in the `./script/Deploy_BlackLIstHookScript.s.sol` folder.
4. Deployed contract https://arbiscan.io/address/0xdb7644dc0b963b0ef1ff732f028e8adb9f310080
5. [First video presentation](./Uniswap_Overview.pdf)

## Deploy hook
```shell
$ # Prepare Environment Variables (Linux)
$ source .env
$
$ # Run deployment script for Arbitrum chain
$ forge script ./script/Deploy_BlackLIstHookScript.s.sol:Deploy_BlackLIstHookScript --account three --sender 0x97ba7778dD9CE27bD4953c136F3B3b7b087E14c1 --rpc-url arbitrum --verify  --etherscan-api-key $ARBISCAN_TOKEN --broadcast

$ # For verify  just deployed
$ forge script ./script/Deploy_BlackLIstHookScript.s.sol:Deploy_BlackLIstHookScript   --account three --sender 0x97ba7778dD9CE27bD4953c136F3B3b7b087E14c1 --rpc-url arbitrum --verify  --etherscan-api-key $ARBISCAN_TOKEN --resume
```
---
<summary><h2>Troubleshooting</h2></summary>
<details>

### *Permission Denied*

When installing dependencies with `forge install`, Github may throw a `Permission Denied` error

Typically caused by missing Github SSH keys, and can be resolved by following the steps [here](https://docs.github.com/en/github/authenticating-to-github/connecting-to-github-with-ssh) 

Or [adding the keys to your ssh-agent](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent#adding-your-ssh-key-to-the-ssh-agent), if you have already uploaded SSH keys

### Hook deployment failures

Hook deployment failures are caused by incorrect flags or incorrect salt mining

1. Verify the flags are in agreement:
    * `getHookCalls()` returns the correct flags
    * `flags` provided to `HookMiner.find(...)`
2. Verify salt mining is correct:
    * In **forge test**: the *deployer* for: `new Hook{salt: salt}(...)` and `HookMiner.find(deployer, ...)` are the same. This will be `address(this)`. If using `vm.prank`, the deployer will be the pranking address
    * In **forge script**: the deployer must be the CREATE2 Proxy: `0x4e59b44847b379578588920cA78FbF26c0B4956C`
        * If anvil does not have the CREATE2 deployer, your foundry may be out of date. You can update it with `foundryup`

</details>

---

## Additional resources:
[Uniswap v4 docs](https://docs.uniswap.org/contracts/v4/overview)  
[v4-periphery](https://github.com/uniswap/v4-periphery) contains advanced hook implementations that serve as a great reference  
[v4-core](https://github.com/uniswap/v4-core)  
[v4-by-example](https://v4-by-example.org)  
[About hooks](https://github.com/ora-io/awesome-uniswap-hooks)

