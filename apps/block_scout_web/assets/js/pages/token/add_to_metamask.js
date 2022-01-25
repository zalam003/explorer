import $ from 'jquery'
import { registerToken, compareChainIDs } from '../../lib/smart_contract/common_helpers.js'
import { walletEnabled } from '../../lib/smart_contract/connect.js'

const addTokenToMM = $('[add-token]')

addTokenToMM.on('click',() => {
  const _symbol = addTokenToMM.data('token-symbol')

  const data = {
    address: addTokenToMM.data('token-address'),
    decimals: addTokenToMM.data('token-decimals'),
    symbol: _symbol,
  }

  if(!_symbol.includes('/')) {
    if(_symbol == 'WNRG' || _symbol == 'MNRG') {
      data.image = `https://explorer.energi.network/images/tokens/NRG.svg`
    } else {
      data.image = `https://explorer.energi.network/images/tokens/${_symbol}.svg`
    }
  }

  walletEnabled()
  .then((isWalletEnabled) => {
    const explorerChainID = addTokenToMM.data('chain-id')
    if(isWalletEnabled) {
      window.web3.eth.getChainId()
      .then((walletChainId) => {
        compareChainIDs(explorerChainID, walletChainId)
          .then(() => registerToken(data))
          .catch(() => {
            addTokenToMM
            .attr('data-original-title', "You're not connected to Energi network")
            .tooltip('show')

            setTimeout(() => {
              addTokenToMM
                .attr('data-original-title', null)
                .tooltip('dispose')
            }, 3000)
          })
        })
    } else {
      console.log('Please install MetaMask wallet')
    }  
  })
})
