<template>
  <div class="admin-panel">
    <div class="header">
      <div class="logo-section">
        <img src="../assets/near1.png" alt="NEAR Logo" class="near-logo" />
        <span class="near-title"><strong>NEAR</strong></span>
      </div>
      <div class="nav-right">
        <button v-if="walletStore.isConnected" class="wallet-btn" @click="showDisconnectModal = true">
          {{ formatAddress(walletStore.walletAddress) }}
        </button>
      </div>
    </div>

    <div class="background-image">
      <div class="overlay"></div>
    </div>

    <div class="admin-content">
      <h1 class="section-header">{{ isChinese ? '管理' : 'Admin Panel' }}</h1>

      <div v-if="!walletStore.isConnected" class="content-box">
        <p class="info-text">
          {{ isChinese ? '管理员地址:' : 'Admin Address:' }}
          {{ adminAddress ? formatAdminAddress(adminAddress) : (isChinese ? '加载中...' : 'Loading...') }}
        </p>
        <p class="info-text">
          {{ isChinese ? '请连接钱包以访问管理功能' : 'Please connect wallet to access admin features' }}
        </p>
        <button class="action-btn" @click="walletStore.connect()">
          {{ isChinese ? '连接钱包' : 'Connect Wallet' }}
        </button>
      </div>

      <div v-else-if="isAdmin" class="content-box">
        <p class="info-text">
          {{ isChinese ? '欢迎，管理员:' : 'Welcome, Admin:' }}
          {{ formatAddress(walletStore.walletAddress) }}
        </p>
        <p class="info-text">
          {{ isChinese ? '合约中总质押 USDT:' : 'Total Deposited USDT:' }}
          {{ totalDeposited }} USDT
        </p>
        <p class="info-text">
          {{ isChinese ? '合约 USDT 余额:' : 'Contract USDT Balance:' }}
          {{ contractBalance }} USDT
        </p>
        <button class="action-btn" @click="withdrawAllUSDT">
          {{ isChinese ? '提取所有 USDT' : 'Withdraw All USDT' }}
        </button>

        <hr class="separator" />

        <p class="info-text">
          {{ isChinese ? '合约 NEAR 余额:' : 'Contract NEAR Balance:' }}
          {{ contractNearBalance }} NEAR
        </p>
        <div class="input-group">
          <input type="text" v-model="nearAmount" :placeholder="isChinese ? '输入提取的NEAR数量' : 'Enter NEAR amount to withdraw'" />
          <button class="action-btn" @click="withdrawNear">
            {{ isChinese ? '提取 NEAR' : 'Withdraw NEAR' }}
          </button>
        </div>

        <hr class="separator" />

        <div class="input-group">
          <input type="text" v-model="blacklistAddress" :placeholder="isChinese ? '输入用户地址' : 'Enter user address'" />
          <div class="button-group">
            <button class="action-btn" @click="checkBlacklistStatus">
              {{ isChinese ? '检查状态' : 'Check Status' }}
            </button>
            <button class="action-btn" @click="blacklistUser(true)">
              {{ isChinese ? '加入黑名单' : 'Blacklist' }}
            </button>
            <button class="action-btn secondary" @click="blacklistUser(false)">
              {{ isChinese ? '移除黑名单' : 'Unblacklist' }}
            </button>
          </div>
        </div>
      </div>

      <div v-else class="content-box">
        <p class="error-text">
          {{ isChinese ? '访问被拒绝' : 'Access Denied' }}
        </p>
        <p class="info-text">
          {{ isChinese ? '当前账户:' : 'Current Account:' }}
          {{ formatAddress(walletStore.walletAddress) }}
        </p>
        <p class="info-text">
          {{ isChinese ? '您不是管理员，无法访问此页面' : 'You are not an admin and cannot access this page' }}
        </p>
        <p class="info-text">
          {{ isChinese ? '管理员地址:' : 'Admin Address:' }}
          {{ adminAddress ? formatAdminAddress(adminAddress) : '' }}
        </p>
      </div>
    </div>

    <div v-if="showDisconnectModal" class="modal-overlay" @click.self="showDisconnectModal = false">
      <div class="modal">
        <h3>{{ isChinese ? '确认断开连接' : 'Confirm Disconnect' }}</h3>
        <p>{{ isChinese ? '您确定要断开钱包连接吗？' : 'Are you sure you want to disconnect your wallet?' }}</p>
        <div class="modal-actions">
          <button class="modal-btn" @click="handleDisconnect">
            {{ isChinese ? '断开' : 'Disconnect' }}
          </button>
          <button class="modal-btn secondary" @click="showDisconnectModal = false">
            {{ isChinese ? '取消' : 'Cancel' }}
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, watch, onMounted } from 'vue';
import { useWalletStore } from '../stores/wallet';

// --- 初始化 Pinia Store ---
const walletStore = useWalletStore();

// --- 组件本地状态 ---
const adminAddress = ref(null);
const totalDeposited = ref('0.00');
const contractBalance = ref('0.00');
const contractNearBalance = ref('0.00');
const nearAmount = ref('');
const blacklistAddress = ref('');
const showDisconnectModal = ref(false);

// --- 计算属性 ---
const isChinese = computed(() => walletStore.isChinese);

const isAdmin = computed(() => {
  return walletStore.isConnected &&
         adminAddress.value &&
         walletStore.walletAddress.toLowerCase() === adminAddress.value.toLowerCase();
});

// --- 核心方法 ---

// 格式化数字（从 wei 单位）
function fromWei(value, decimals = 18) {
  if (!walletStore.web3 || !value) return '0.00';
  const unit = decimals === 6 ? 'mwei' : 'ether';
  return parseFloat(walletStore.web3.utils.fromWei(value.toString(), unit)).toFixed(2);
}

// 获取管理员和合约数据
async function fetchAdminData() {
  if (!walletStore.contract || !walletStore.usdtContract) {
    console.error("合约实例尚未初始化。");
    return;
  }
  try {
    adminAddress.value = await walletStore.contract.methods.owner().call();

    if (walletStore.walletAddress.toLowerCase() === adminAddress.value.toLowerCase()) {
      const [deposited, balance, nearBalance] = await Promise.all([
        walletStore.contract.methods.getTotalDeposited().call(),
        walletStore.usdtContract.methods.balanceOf(walletStore.contract.options.address).call(),
        walletStore.contract.methods.getNearBalance().call()
      ]);
      totalDeposited.value = fromWei(deposited, 18);
      contractBalance.value = fromWei(balance, walletStore.usdtDecimals);
      contractNearBalance.value = fromWei(nearBalance, 18);
    }
  } catch (error) {
    console.error('获取管理员数据失败:', error);
    alert(isChinese.value ? '获取管理员数据失败' : 'Failed to fetch admin data');
  }
}

// 提取合约中所有的USDT
async function withdrawAllUSDT() {
  if (!isAdmin.value) {
    alert(isChinese.value ? '您不是管理员' : 'You are not an admin');
    return;
  }
  try {
    const balanceInWei = await walletStore.usdtContract.methods.balanceOf(walletStore.contract.options.address).call();
    // if (balanceInWei.toString() === '0') {
    //   alert(isChinese.value ? '合约余额为0，无需提取' : 'Contract balance is 0, no need to withdraw');
    //   return;
    // }
    await walletStore.contract.methods.withdrawUSDT(balanceInWei).send({ from: walletStore.walletAddress });
    alert(isChinese.value ? '提取成功！' : 'Withdrawal successful!');
    await fetchAdminData();
  } catch (error) {
    console.error('提取失败:', error);
    alert(isChinese.value ? `提取失败: ${error.message}` : `Withdrawal failed: ${error.message}`);
  }
}

// 提取NEAR
async function withdrawNear() {
  if (!isAdmin.value) return;
  if (!nearAmount.value || isNaN(nearAmount.value) || parseFloat(nearAmount.value) <= 0) {
    alert(isChinese.value ? '请输入有效的NEAR数量' : 'Please enter a valid NEAR amount');
    return;
  }
  try {
    const amountInWei = walletStore.web3.utils.toWei(nearAmount.value, 'ether');
    await walletStore.contract.methods.withdrawNear(amountInWei).send({ from: walletStore.walletAddress });
    alert(isChinese.value ? 'NEAR提取成功' : 'NEAR withdrawal successful');
    nearAmount.value = '';
    await fetchAdminData();
  } catch (error) {
    console.error('提取NEAR失败:', error);
    alert(isChinese.value ? `提取NEAR失败: ${error.message}` : `NEAR withdrawal failed: ${error.message}`);
  }
}

// 设置用户黑名单状态
async function blacklistUser(isBlacklisted) {
  if (!isAdmin.value) return;
  const userAddress = blacklistAddress.value.trim();
  if (!walletStore.web3.utils.isAddress(userAddress)) {
    alert(isChinese.value ? '请输入有效的用户地址' : 'Please enter a valid user address');
    return;
  }
  try {
    await walletStore.contract.methods.setWithdrawBlacklist(userAddress, isBlacklisted).send({ from: walletStore.walletAddress });
    const action = isBlacklisted ? (isChinese.value ? '加入黑名单' : 'blacklisted') : (isChinese.value ? '解除黑名单' : 'unblacklisted');
    alert(`${userAddress} ${isChinese.value ? '已' : 'has been'} ${action}`);
    blacklistAddress.value = '';
  } catch (error) {
    console.error('黑名单操作失败:', error);
    alert(isChinese.value ? `操作失败: ${error.message}` : `Operation failed: ${error.message}`);
  }
}

// 检查用户黑名单状态
async function checkBlacklistStatus() {
  if (!isAdmin.value) return;
  const userAddress = blacklistAddress.value.trim();
  if (!walletStore.web3.utils.isAddress(userAddress)) {
    alert(isChinese.value ? '请输入有效的用户地址' : 'Please enter a valid user address');
    return;
  }
  try {
    const isBlacklisted = await walletStore.contract.methods.isBlacklisted(userAddress).call();
    alert(`${userAddress} ${isChinese.value ? '的黑名单状态是' : 'blacklist status is'}: ${isBlacklisted}`);
  } catch (error) {
    console.error('检查黑名单状态失败:', error);
    alert(isChinese.value ? `检查失败: ${error.message}` : `Check failed: ${error.message}`);
  }
}

// 处理断开连接
function handleDisconnect() {
  walletStore.disconnect();
  showDisconnectModal.value = false;
  adminAddress.value = null;
  totalDeposited.value = '0.00';
  contractBalance.value = '0.00';
  contractNearBalance.value = '0.00';
}

// --- 地址格式化工具函数 ---
function formatAddress(address) {
  if (!address) return '';
  return `${address.slice(0, 6)}...${address.slice(-4)}`;
}

function formatAdminAddress(address) {
  if (!address) return '';
  return `${address.slice(0, 3)}...${address.slice(-3)}`;
}

// --- 监听器 ---
watch(() => walletStore.isConnected, (connected) => {
  if (connected) {
    fetchAdminData();
  } else {
    totalDeposited.value = '0.00';
    contractBalance.value = '0.00';
    contractNearBalance.value = '0.00';
  }
}, { immediate: true });

onMounted(() => {
    if(!walletStore.isConnected && walletStore.web3 && walletStore.contract) {
        fetchAdminData();
    }
});
</script>

<style scoped>
  /* 样式与你之前提供的保持一致，这里省略，你可以直接复制粘贴 */
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
  
  .background-image {
    position: relative;
    width: 100%;
    height: 350px;
    background: url('@/assets/near-background.jpg') no-repeat center center;
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

  .input-group {
    width: 100%;
    display: flex;
    flex-direction: column;
    gap: 10px;
    align-items: center;
  }

  .input-group input {
    width: 100%;
    max-width: 450px;
    padding: 14px 20px;
    font-size: 16px;
    border: none;
    border-radius: 10px;
    background: #f9f9f9;
    box-shadow: inset 0 2px 5px rgba(0, 0, 0, 0.05);
    outline: none;
    transition: all 0.3s ease;
    text-align: center;
  }
  
  .button-group {
    display: flex;
    gap: 10px;
    justify-content: center;
    flex-wrap: wrap;
  }
  
  .separator {
    width: 80%;
    border: 0;
    height: 1px;
    background-color: #e0e0e0;
    margin: 20px 0;
  }
  
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