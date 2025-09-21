<template>
    <div class="admin-panel">
      <!-- 顶部导航栏 -->
      <div class="header">
        <div class="logo-section">
          <img src="../assets/near-logo.png" alt="NEAR Logo" class="near-logo" />
          <span class="near-title"><strong>NEAR</strong> </span>
        </div>
        <div class="nav-right">
          <!-- 点击钱包按钮弹出断开连接模态框 -->
          <button v-if="account" class="wallet-btn" @click="openDisconnectModal">
            {{ formatAddress(account) }}
          </button>
        </div>
      </div>
  
      <!-- 背景图片 -->
      <div class="background-image">
        <div class="overlay"></div>
      </div>
  
      <!-- 主内容区域 -->
      <div class="admin-content">
        <h1 class="section-header">{{ language === 'zh' ? '管理' : 'Admin Panel' }}</h1>
  
        <!-- 未连接钱包 -->
        <div v-if="!account" class="content-box">
          <p class="info-text">
            {{ language === 'zh' ? '管理员地址:' : 'Admin Address:' }}
            {{ privilegedAddress ? formatAdminAddress(privilegedAddress) : (language === 'zh' ? '加载中...' : 'Loading...') }}
          </p>
          <p class="info-text">
            {{ language === 'zh' ? '请连接钱包以访问管理功能' : 'Please connect wallet to access admin features' }}
          </p>
          <button class="action-btn" @click="connectWallet">
            {{ language === 'zh' ? '连接钱包' : 'Connect Wallet' }}
          </button>
        </div>
  
        <!-- 已连接管理员钱包 -->
        <div v-else-if="isAdmin" class="content-box">
          <p class="info-text">
            {{ language === 'zh' ? '欢迎，管理员:' : 'Welcome, Admin:' }}
            {{ formatAddress(account) }}
          </p>
          <p class="info-text">
            {{ language === 'zh' ? '合约中总质押 USDT:' : 'Total Deposited USDT:' }}
            {{ totalDeposited }} USDT
          </p>
          <p class="info-text">
            {{ language === 'zh' ? '合约余额:' : 'Contract Balance:' }}
            {{ contractBalance }} USDT
          </p>
          <button class="action-btn" @click="withdrawAllUSDT">
            {{ language === 'zh' ? '提取所有 USDT' : 'Withdraw All USDT' }}
          </button>
        </div>
  
        <!-- 已连接NearX员钱包 -->
        <div v-else class="content-box">
          <p class="error-text">
            {{ language === 'zh' ? '访问被拒绝' : 'Access Denied' }}
          </p>
          <p class="info-text">
            {{ language === 'zh' ? '当前账户:' : 'Current Account:' }}
            {{ formatAddress(account) }}
          </p>
          <p class="info-text">
            {{ language === 'zh' ? '您不是管理员，无法访问此页面' : 'You are not an admin and cannot access this page' }}
          </p>
          <p class="info-text">
            {{ language === 'zh' ? '管理员地址:' : 'Admin Address:' }}
            {{ privilegedAddress ? formatAdminAddress(privilegedAddress) : '' }}
          </p>
          
        </div>
      </div>
  
      <!-- 断开钱包连接的模态框 -->
      <div v-if="showDisconnectModal" class="modal-overlay" @click.self="closeModal">
        <div class="modal">
          <h3>{{ language === 'zh' ? '确认断开连接' : 'Confirm Disconnect' }}</h3>
          <p>{{ language === 'zh' ? '您确定要断开钱包连接吗？' : 'Are you sure you want to disconnect your wallet?' }}</p>
          <div class="modal-actions">
            <button class="modal-btn" @click="disconnectWallet">
              {{ language === 'zh' ? '断开' : 'Disconnect' }}
            </button>
            <button class="modal-btn secondary" @click="closeModal">
              {{ language === 'zh' ? '取消' : 'Cancel' }}
            </button>
          </div>
        </div>
      </div>
    </div>
  </template>
  
  <script>
  import Web3 from 'web3';
  
  export default {
    data() {
      return {
        account: null,
        isAdmin: false,
        totalDeposited: '0',
        contractBalance: '0',
        privilegedAddress: null,
        contractAddress: '0xe58d55786ff7a109de4d82305dc5b081b6ac1ca6',
        // 请替换为正确的测试网 USDT 合约地址（18 位精度）
        usdtAddress: '0x55d398326f99059fF775485246999027B3197955',
        language: 'zh',
        web3: null,
        contract: null,
        usdtContract: null,
        showDisconnectModal: false,
        contractABI: [
          {
            "constant": true,
            "inputs": [],
            "name": "privilegedAddress",
            "outputs": [{ "name": "", "type": "address" }],
            "stateMutability": "view",
            "type": "function"
          },
          {
            "constant": true,
            "inputs": [],
            "name": "totalDeposited",
            "outputs": [{ "name": "", "type": "uint256" }],
            "stateMutability": "view",
            "type": "function"
          },
          {
            "constant": false,
            "inputs": [{ "name": "amount", "type": "uint256" }],
            "name": "withdrawUSDT",
            "outputs": [],
            "stateMutability": "nonpayable",
            "type": "function"
          }
        ],
        usdtABI: [
          {
            "constant": true,
            "inputs": [{ "name": "_owner", "type": "address" }],
            "name": "balanceOf",
            "outputs": [{ "name": "balance", "type": "uint256" }],
            "stateMutability": "view",
            "type": "function"
          }
        ]
      };
    },
    async mounted() {
      await this.initializeWeb3();
      await this.fetchPrivilegedAddress();
      await this.checkWalletConnection();
    },
    methods: {
      async initializeWeb3() {
        if (window.ethereum) {
          this.web3 = new Web3(window.ethereum);
          this.contract = new this.web3.eth.Contract(this.contractABI, this.contractAddress);
          this.usdtContract = new this.web3.eth.Contract(this.usdtABI, this.usdtAddress);
        }
      },
      async fetchPrivilegedAddress() {
        if (this.contract) {
          try {
            this.privilegedAddress = await this.contract.methods.privilegedAddress().call();
          } catch (error) {
            console.error('获取管理员地址失败:', error);
            this.privilegedAddress = '未知';
          }
        }
      },
      async checkWalletConnection() {
        if (window.ethereum) {
          const accounts = await this.web3.eth.getAccounts();
          if (accounts.length > 0) {
            this.account = accounts[0];
            await this.checkAdminStatus();
          }
        }
      },
      async connectWallet() {
        if (!window.ethereum) {
          alert(this.language === 'zh' ? '请安装 MetaMask 或其他以太坊钱包' : 'Please install MetaMask or another Ethereum wallet');
          return;
        }
        try {
          const accounts = await window.ethereum.request({ method: 'eth_requestAccounts' });
          if (accounts.length > 0) {
            this.account = accounts[0];
            await this.checkAdminStatus();
          }
        } catch (error) {
          console.error('连接钱包失败:', error);
          alert(this.language === 'zh' ? '连接钱包失败: ' + error.message : 'Wallet connection failed: ' + error.message);
        }
      },
      async checkAdminStatus() {
        if (!this.privilegedAddress) {
          await this.fetchPrivilegedAddress();
        }
        this.isAdmin = this.account && this.privilegedAddress &&
          (this.account.toLowerCase() === this.privilegedAddress.toLowerCase());
        if (this.isAdmin) {
          await this.fetchContractData();
        } else if (this.account) {
          alert(this.language === 'zh' ? '您非管理员，无法访问!' : 'Non-admin account, access to admin panel denied');
          this.$emit('select', 'Home');
        }
      },
      async fetchContractData() {
        try {
          const totalDeposited = await this.contract.methods.totalDeposited().call();
          // 使用 toString() 将 BigInt 转换为字符串，再进行 fromWei 转换
          this.totalDeposited = this.web3.utils.fromWei(totalDeposited.toString(), 'ether');
          
          const balance = await this.usdtContract.methods.balanceOf(this.contractAddress).call();
          this.contractBalance = this.web3.utils.fromWei(balance.toString(), 'ether');
        } catch (error) {
          console.error('获取合约数据失败:', error);
          alert(this.language === 'zh'
            ? '获取合约数据失败: ' + error.message
            : 'Failed to fetch contract data: ' + error.message);
        }
      },
      async withdrawAllUSDT() {
        try {
          const amount = this.web3.utils.toWei(this.contractBalance, 'ether');
          const tx = await this.contract.methods.withdrawUSDT(amount).send({
            from: this.account,
            gas: 200000,
            gasPrice: this.web3.utils.toWei('10', 'gwei')
          });
          console.log('提取成功:', tx);
          alert(this.language === 'zh' ? '提取成功' : 'Withdrawal successful');
          await this.fetchContractData();
        } catch (error) {
          console.error('提取失败:', error);
          alert(this.language === 'zh' ? '提取失败: ' + error.message : 'Withdrawal failed: ' + error.message);
        }
      },
      openDisconnectModal() {
        this.showDisconnectModal = true;
      },
      closeModal() {
        this.showDisconnectModal = false;
      },
      disconnectWallet() {
        this.account = null;
        this.isAdmin = false;
        this.totalDeposited = '0';
        this.contractBalance = '0';
        this.closeModal();
        console.log('钱包已断开');
      },
      // 格式化连接钱包的地址（显示前6后4位）
      formatAddress(address) {
        if (!address) return '';
        return `${address.slice(0, 6)}...${address.slice(-4)}`;
      },
      // 格式化管理员地址（只显示前3位和后3位）
      formatAdminAddress(address) {
        if (!address) return '';
        return `${address.slice(0, 3)}...${address.slice(-3)}`;
      }
    }
  };
  </script>
  
  <style scoped>
  .admin-panel {
    padding: 40px 20px;
    max-width: 1000px;
    margin: 0 auto;
    font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
    background: linear-gradient(135deg, #f5f7fa 0%, #c3cfe2 100%);
    min-height: 100vh;
    display: flex;
    flex-direction: column;
    align-items: center;
    box-sizing: border-box;
  }
  
  /* 顶部导航栏 */
  .header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    width: 100%;
    margin-bottom: 30px;
    padding-bottom: 10px;
    border-bottom: 1px solid rgba(0, 0, 0, 0.1);
    flex-wrap: wrap;
  }
  
  .logo-section {
    display: flex;
    align-items: center;
    gap: 15px;
  }
  
  .near-logo {
    width: 60px;
    height: 60px;
    transition: transform 0.3s ease;
  }
  
  .near-logo:hover {
    transform: scale(1.1);
  }
  
  .near-title {
    font-size: 32px;
    font-weight: 700;
    color: #00C08B;
    letter-spacing: 1.5px;
    text-shadow: 0 2px 4px rgba(0, 192, 139, 0.2);
  }
  
  .nav-right {
    display: flex;
    align-items: center;
    gap: 15px;
  }
  
  .wallet-btn {
    min-width: 120px;
    padding: 10px 20px;
    background: linear-gradient(135deg, #00C08B 0%, #00a070 100%);
    color: white;
    border: none;
    border-radius: 10px;
    cursor: pointer;
    font-size: 14px;
    font-weight: 600;
    box-shadow: 0 4px 10px rgba(0, 192, 139, 0.3);
    transition: transform 0.2s, box-shadow 0.2s, background 0.3s;
  }
  
  .wallet-btn:hover {
    transform: translateY(-3px);
    box-shadow: 0 6px 15px rgba(0, 192, 139, 0.5);
    background: linear-gradient(135deg, #00a070 0%, #008c5e 100%);
  }
  
  .wallet-btn:active {
    transform: translateY(1px);
    box-shadow: 0 2px 5px rgba(0, 192, 139, 0.2);
  }
  
  /* 背景图片 */
  .background-image {
    position: relative;
    width: 100%;
    height: 350px;
    background: url('https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQRwuf_gZpsMRhufTkvRFTR_xWIyFF12mxi9Q&s') no-repeat center center;
    background-size: cover;
    border-radius: 16px;
    box-shadow: 0 6px 20px rgba(0, 0, 0, 0.15);
    margin-bottom: 50px;
    overflow: hidden;
  }
  
  .overlay {
    position: absolute;
    top: 0;
    left: 0;
    width: 100%;
    height: 100%;
    background: linear-gradient(to bottom, rgba(0, 192, 139, 0.1), rgba(0, 0, 0, 0.3));
    z-index: 1;
  }
  
  /* 主内容区域 */
  .admin-content {
    background: #fff;
    padding: 35px;
    border-radius: 16px;
    box-shadow: 0 8px 25px rgba(0, 0, 0, 0.1);
    width: 100%;
    max-width: 550px;
    text-align: center;
    transform: translateY(-30px);
    z-index: 2;
    animation: fadeIn 0.5s ease-in;
  }
  
  .section-header {
    font-size: 28px;
    font-weight: 600;
    color: #00C08B;
    margin-bottom: 25px;
    letter-spacing: 1px;
  }
  
  .content-box {
    display: flex;
    flex-direction: column;
    align-items: center;
    gap: 20px;
  }
  
  .info-text {
    font-size: 16px;
    color: #333;
  }
  
  .error-text {
    font-size: 18px;
    color: #e74c3c;
    font-weight: 600;
  }
  
  .action-btn {
    width: 100%;
    max-width: 250px;
    padding: 14px;
    background: linear-gradient(135deg, #00C08B 0%, #00a070 100%);
    color: white;
    border: none;
    border-radius: 12px;
    cursor: pointer;
    font-size: 18px;
    font-weight: 600;
    box-shadow: 0 6px 15px rgba(0, 192, 139, 0.3);
    transition: all 0.3s ease;
  }
  
  .action-btn:hover {
    transform: translateY(-4px);
    box-shadow: 0 8px 20px rgba(0, 192, 139, 0.5);
    background: linear-gradient(135deg, #00a070 0%, #008c5e 100%);
  }
  
  .action-btn:active {
    transform: translateY(2px);
    box-shadow: 0 3px 10px rgba(0, 192, 139, 0.2);
  }
  
  .action-btn.secondary {
    background: linear-gradient(135deg, #e74c3c 0%, #c0392b 100%);
    box-shadow: 0 6px 15px rgba(231, 76, 60, 0.3);
  }
  
  .action-btn.secondary:hover {
    background: linear-gradient(135deg, #c0392b 0%, #a93226 100%);
  }
  
  /* 模态框样式 */
  .modal-overlay {
    position: fixed;
    top: 0;
    left: 0;
    width: 100%;
    height: 100%;
    background: rgba(0, 0, 0, 0.5);
    display: flex;
    align-items: center;
    justify-content: center;
    z-index: 1000;
  }
  
  .modal {
    background: #fff;
    padding: 30px;
    border-radius: 10px;
    width: 90%;
    max-width: 400px;
    text-align: center;
    box-shadow: 0 8px 25px rgba(0, 0, 0, 0.2);
  }
  
  .modal h3 {
    margin-bottom: 15px;
    color: #00C08B;
  }
  
  .modal p {
    margin-bottom: 20px;
    color: #555;
  }
  
  .modal-actions {
    display: flex;
    justify-content: space-around;
  }
  
  .modal-btn {
    padding: 10px 20px;
    border: none;
    border-radius: 6px;
    font-size: 16px;
    cursor: pointer;
    background: linear-gradient(135deg, #00C08B 0%, #00a070 100%);
    color: white;
    transition: background 0.3s;
  }
  
  .modal-btn:hover {
    background: linear-gradient(135deg, #00a070 0%, #008c5e 100%);
  }
  
  .modal-btn.secondary {
    background: linear-gradient(135deg, #e74c3c 0%, #c0392b 100%);
  }
  
  .modal-btn.secondary:hover {
    background: linear-gradient(135deg, #c0392b 0%, #a93226 100%);
  }
  
  /* 动画 */
  @keyframes fadeIn {
    from {
      opacity: 0;
      transform: translateY(10px);
    }
    to {
      opacity: 1;
      transform: translateY(0);
    }
  }
  
  /* 响应式设计 */
  @media (max-width: 768px) {
    .admin-panel {
      padding: 20px;
    }
  
    .header {
      flex-direction: column;
      align-items: flex-start;
      gap: 10px;
    }
  
    .nav-right {
      width: 100%;
      justify-content: flex-end;
    }
  
    .background-image {
      height: 200px;
      margin-bottom: 30px;
    }
  
    .admin-content {
      padding: 20px;
      max-width: 100%;
      transform: none;
    }
  
    .section-header {
      font-size: 24px;
    }
  
    .action-btn {
      max-width: 100%;
      padding: 12px;
      font-size: 16px;
    }
  }
  
  @media (max-width: 360px) {
    .near-logo {
      width: 50px;
      height: 50px;
    }
  
    .near-title {
      font-size: 24px;
    }
  
    .wallet-btn {
      padding: 8px 16px;
      font-size: 12px;
    }
  
    .section-header {
      font-size: 20px;
    }
  
    .info-text {
      font-size: 14px;
    }
  
    .action-btn {
      padding: 10px;
      font-size: 14px;
    }
  }
  </style>
  