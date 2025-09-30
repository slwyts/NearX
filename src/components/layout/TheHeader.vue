<template>
  <header class="header">
    <div class="logo-section">
      <img src="@/assets/near-logo.png" alt="NEAR Logo" class="near-logo" />
      <span class="near-text">NEAR</span>
    </div>

    <div class="actions">
      <button @click="walletStore.switchLanguage('zh')" :class="{ active: walletStore.isChinese }">中文</button>
      <button @click="walletStore.switchLanguage('en')" :class="{ active: !walletStore.isChinese }">English</button>
      
      <button class="wallet-btn" @click="walletStore.toggleWallet">
        {{ walletButtonText }}
      </button>
    </div>
  </header>
</template>

<script setup>
import { computed } from 'vue';
import { useWalletStore } from '../../stores/wallet';

const walletStore = useWalletStore();

const walletButtonText = computed(() => {
  if (!walletStore.isConnected || !walletStore.walletAddress) {
    return walletStore.isChinese ? '连接钱包' : 'Connect Wallet';
  }
  const addr = walletStore.walletAddress;
  return `${addr.slice(0, 6)}...${addr.slice(-4)}`;
});
</script>

<style scoped>
.header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 15px 20px;
  background-color: #ffffff;
  border-radius: 12px;
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.08);
  margin-bottom: 25px;
  flex-wrap: wrap;
}

.logo-section {
  display: flex;
  align-items: center;
  gap: 12px;
}

.near-logo {
  width: 40px;
  height: 40px;
  transition: transform 0.3s ease;
}

.near-logo:hover {
  transform: scale(1.1);
}

.near-text {
  font-size: 24px;
  font-weight: bold;
  color: #333;
}

.actions {
  display: flex;
  align-items: center;
  gap: 15px;
}

/* 语言切换按钮的样式 */
.actions button {
  padding: 8px 16px;
  border: 1px solid #ddd;
  border-radius: 8px;
  background-color: #f8f8f8;
  cursor: pointer;
  font-size: 14px;
  font-weight: 500;
  transition: all 0.2s ease-in-out;
  color: #333;
}

.actions button:hover {
  border-color: #00c08b;
  color: #00c08b;
}

.actions button.active {
  background-color: #00c08b;
  color: white;
  border-color: #00c08b;
}

.wallet-btn {
  background: linear-gradient(135deg, #00C08B 0%, #00a070 100%);
  color: white;
  border: none;
  border-radius: 10px;
  white-space: nowrap;
  box-shadow: 0 4px 10px rgba(0, 192, 139, 0.3);
}

.wallet-btn:hover {
  background: linear-gradient(135deg, #00a070 0%, #008c5e 100%);
  color: white !important; /* 确保文字颜色不变 */
  box-shadow: 0 6px 15px rgba(0, 192, 139, 0.5);
  transform: translateY(-2px);
}


@media (max-width: 600px) {
  .header {
    flex-direction: column;
    align-items: flex-start;
    gap: 15px;
  }
  .actions {
    width: 100%;
    justify-content: space-between;
  }
}
</style>