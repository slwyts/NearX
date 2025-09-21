<template>
  <div class="admin-panel">
    <div class="header">
      <div class="logo-section">
        <img src="../assets/near.webp" alt="NEAR Logo" class="near-logo" />
        <span class="near-title"><strong>NEAR</strong> </span>
      </div>
      <div class="nav-right">
        <button v-if="account" class="wallet-btn" @click="openDisconnectModal">
          {{ formatAddress(account) }}
        </button>
      </div>
    </div>

    <div class="background-image">
      <div class="overlay"></div>
    </div>

    <div class="admin-content">
      <h1 class="section-header">{{ language === 'zh' ? '管理' : 'Admin Panel' }}</h1>

      <div v-if="!account" class="content-box">
        <p class="info-text">
          {{ language === 'zh' ? '管理员地址:' : 'Admin Address:' }}
          {{ ownerAddress ? formatAdminAddress(ownerAddress) : (language === 'zh' ? '加载中...' : 'Loading...') }}
        </p>
        <p class="info-text">
          {{ language === 'zh' ? '请连接钱包以访问管理功能' : 'Please connect wallet to access admin features' }}
        </p>
        <button class="action-btn" @click="connectWallet">
          {{ language === 'zh' ? '连接钱包' : 'Connect Wallet' }}
        </button>
      </div>

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
          {{ ownerAddress ? formatAdminAddress(ownerAddress) : '' }}
        </p>

      </div>
    </div>

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
      // [修改] 将 privilegedAddress 重命名为 ownerAddress
      ownerAddress: null,
      // [注意] 请确保这是您部署的正确合约地址
      contractAddress: '0x77e480689AD623dcf02Ec328cAbe521c703A3B88', 
      usdtAddress: '0x55d398326f99059fF775485246999027B3197955',
      language: 'zh',
      web3: null,
      contract: null,
      usdtContract: null,
      showDisconnectModal: false,
      contractABI: [
        // [修改] 使用 owner() 函数的ABI
        {
          "constant": true,
          "inputs": [],
          "name": "owner",
          "outputs": [{ "name": "", "type": "address" }],
          "stateMutability": "view",
          "type": "function"
        },
        // 保留其他ABI
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
    // [修改] 调用新的函数名
    await this.fetchOwnerAddress();
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
    // [修改] 重命名函数并更新内部调用
    async fetchOwnerAddress() {
      if (this.contract) {
        try {
          // 调用新的 owner() 方法
          this.ownerAddress = await this.contract.methods.owner().call();
        } catch (error) {
          console.error('获取管理员地址失败:', error);
          this.ownerAddress = '未知';
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
      if (!this.ownerAddress) {
        // [修改] 确保调用的是新函数
        await this.fetchOwnerAddress();
      }
      // [修改] 使用新的 ownerAddress 变量进行比较
      this.isAdmin = this.account && this.ownerAddress &&
        (this.account.toLowerCase() === this.ownerAddress.toLowerCase());
      if (this.isAdmin) {
        await this.fetchContractData();
      }
    },
    async fetchContractData() {
      try {
        const totalDeposited = await this.contract.methods.totalDeposited().call();
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
          // Gas a little higher for safety, can be adjusted
          gas: 300000, 
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
    formatAddress(address) {
      if (!address) return '';
      return `${address.slice(0, 6)}...${address.slice(-4)}`;
    },
    formatAdminAddress(address) {
      if (!address) return '';
      return `${address.slice(0, 3)}...${address.slice(-3)}`;
    }
  }
};
</script>

<style scoped>
/* 您的样式代码无需改动，直接复制粘贴到这里 */
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
  background: url('http://cqplus.bsccoin.org/nera/img/neraBanner.jpg') no-repeat center center;
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