import { defineStore } from 'pinia';
import Web3 from 'web3';
import { ref } from 'vue';

import {
  CONTRACT_ADDRESS,
  CONTRACT_ABI,
  USDT_ADDRESS,
  USDT_ABI
} from '../services/contractService';

export const useWalletStore = defineStore('wallet', () => {
  const web3 = ref(null);
  const contract = ref(null);
  const usdtContract = ref(null);
  const walletAddress = ref('');
  const isConnected = ref(false);
  const isChinese = ref(true);
  const usdtDecimals = ref(6);   


  function switchLanguage(lang) {
    isChinese.value = lang === 'zh';
  }

  async function toggleWallet() {
    if (isConnected.value) {
      const confirmationMessage = isChinese.value ? '确定要断开钱包连接吗？' : 'Are you sure you want to disconnect your wallet?';
      if (confirm(confirmationMessage)) {
        disconnect();
      }
    } else {
      await connect();
    }
  }

  function disconnect() {
    web3.value = null;
    contract.value = null;
    usdtContract.value = null;
    walletAddress.value = '';
    isConnected.value = false;
    console.log('Wallet disconnected.');
  }

  async function connect() {
    if (typeof window.ethereum === 'undefined') {
      alert(isChinese.value ? '请先安装以太坊钱包扩展（如MetaMask）' : 'Please install an Ethereum wallet extension (e.g., MetaMask)');
      return;
    }

    try {
      web3.value = new Web3(window.ethereum);
      const accounts = await window.ethereum.request({ method: 'eth_requestAccounts' });
      if (accounts.length === 0) {
        throw new Error('No accounts found. Please unlock your wallet.');
      }
      walletAddress.value = accounts[0];
      isConnected.value = true;
      await switchToBSCMainnet();
      contract.value = new web3.value.eth.Contract(CONTRACT_ABI, CONTRACT_ADDRESS);
      usdtContract.value = new web3.value.eth.Contract(USDT_ABI, USDT_ADDRESS);

      usdtDecimals.value = Number(await usdtContract.value.methods.decimals().call());

      console.log('Wallet connected:', walletAddress.value);
      console.log('USDT Decimals:', usdtDecimals.value);

      window.ethereum.on('accountsChanged', (newAccounts) => {
        if (newAccounts.length > 0) {
          walletAddress.value = newAccounts[0];
          console.log('Account switched to:', newAccounts[0]);
        } else {
          disconnect();
        }
      });

    } catch (error) {
      console.error('Failed to connect wallet:', error);
      alert(isChinese.value ? `钱包连接失败: ${error.message}` : `Failed to connect wallet: ${error.message}`);
      disconnect();
    }
  }

  async function switchToBSCMainnet() {
    const chainId = '0x38'; // BSC Mainnet
    try {
      await window.ethereum.request({
        method: 'wallet_switchEthereumChain',
        params: [{ chainId }],
      });
    } catch (switchError) {
      if (switchError.code === 4902) {
        try {
          await window.ethereum.request({
            method: 'wallet_addEthereumChain',
            params: [{
              chainId,
              chainName: 'Binance Smart Chain',
              nativeCurrency: { name: 'BNB', symbol: 'BNB', decimals: 18 },
              rpcUrls: ['https://bsc-dataseed.binance.org/'],
              blockExplorerUrls: ['https://bscscan.com']
            }],
          });
        } catch (addError) {
          console.error('Failed to add BSC Mainnet:', addError);
          throw addError;
        }
      } else {
        console.error('Failed to switch to BSC Mainnet:', switchError);
        throw switchError;
      }
    }
  }


  return {
    // State
    web3,
    contract,
    usdtContract,
    walletAddress,
    isConnected,
    isChinese,
    usdtDecimals,

    // Actions
    connect,
    disconnect,
    toggleWallet,
    switchLanguage,
  };
});