# lnx.money

Lending protocol used to collateralize and borrow against GLP.
Deposit GLP, borrow any of the tokens that are in GLP.
Lend those tokens and earn LNX rewards as an extra bonus.
Stake LNX to earn a part of protocol generated revenue.


## How to run locally 

```
npx hardhat node
```

### Get test ETH tokens

```
npx hardhat run --network localhost scripts/getTokens.js

```

### Import into metamask

The mnemonic seed is : `test test test test test test test test test test test junk`