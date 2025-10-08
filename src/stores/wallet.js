import { defineStore } from 'pinia';
import Web3 from 'web3';
import { ref } from 'vue';

import {
  CONTRACT_ADDRESS,
  CONTRACT_ABI,
  USDT_ADDRESS,
  USDT_ABI
} from '../services/contractService';

// 使用一个公开的 BSC RPC 节点地址
const BSC_RPC_URL = 'https://binance.llamarpc.com';

export const useWalletStore = defineStore('wallet', () => {
  // --- State ---
  const web3 = ref(null);
  const contract = ref(null);
  const usdtContract = ref(null);
  const walletAddress = ref('');
  const isConnected = ref(false);
  const isChinese = ref(true);
  const usdtDecimals = ref(6); // 默认值

  // --- 内部初始化函数 ---
  function initializeProvider() {
    // 默认使用公开的 RPC 提供商进行只读操作
    const provider = new Web3.providers.HttpProvider(BSC_RPC_URL);
    web3.value = new Web3(provider);
    contract.value = new web3.value.eth.Contract(CONTRACT_ABI, CONTRACT_ADDRESS);
    usdtContract.value = new web3.value.eth.Contract(USDT_ABI, USDT_ADDRESS);
    console.log('Default read-only provider initialized.');
  }
  
  // --- Actions ---
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
    // 断开连接时，恢复为只读的 provider
    initializeProvider(); 
    walletAddress.value = '';
    isConnected.value = false;
    console.log('Wallet disconnected. Switched back to read-only provider.');
  }

  async function connect() {
    if (typeof window.ethereum === 'undefined') {
      alert(isChinese.value ? '请先安装以太坊钱包扩展（如MetaMask）' : 'Please install an Ethereum wallet extension (e.g., MetaMask)');
      return;
    }

    try {
      console.log('🔄 [1/6] 开始连接钱包...');
      
      // 切换为钱包的 provider 以便进行交易
      web3.value = new Web3(window.ethereum);
      const accounts = await window.ethereum.request({ method: 'eth_requestAccounts' });
      if (accounts.length === 0) {
        throw new Error('No accounts found. Please unlock your wallet.');
      }
      walletAddress.value = accounts[0];
      console.log('✅ [2/6] 钱包地址获取成功:', walletAddress.value);
      
      await switchToBSCMainnet();
      console.log('✅ [3/6] 网络切换完成 (BSC Mainnet)');

      // 使用钱包的 provider 重新初始化合约实例
      contract.value = new web3.value.eth.Contract(CONTRACT_ABI, CONTRACT_ADDRESS);
      usdtContract.value = new web3.value.eth.Contract(USDT_ABI, USDT_ADDRESS);
      console.log('✅ [4/6] 合约实例创建完成');
      console.log('   📍 NearX 合约:', CONTRACT_ADDRESS);

      usdtDecimals.value = Number(await usdtContract.value.methods.decimals().call());
      console.log('✅ [5/6] USDT 精度:', usdtDecimals.value);

      // 确保合约实例完全初始化后再设置 isConnected
      await new Promise(resolve => setTimeout(resolve, 100));
      isConnected.value = true;
      console.log('✅ [6/6] 钱包连接完成，即将触发数据更新...');

      window.ethereum.on('accountsChanged', (newAccounts) => {
        if (newAccounts.length > 0) {
          walletAddress.value = newAccounts[0];
          console.log('🔄 账户切换:', newAccounts[0]);
        } else {
          disconnect();
        }
      });

    } catch (error) {
      console.error('❌ 钱包连接失败:', error);
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

  // --- 初始化 ---
  // store 创建时立即执行
  initializeProvider();

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