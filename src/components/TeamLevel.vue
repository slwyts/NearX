<template>
	<div class="team-level-page">
    <TheHeader />

	  <section class="performance-section">
		<div class="performance-card">
		  <span class="value">{{ totalAreaPerformance }}</span>
		  <span class="label">{{ isChinese ? '全区业绩' : 'Total Area Performance' }}</span>
		</div>
		<div class="performance-card">
		  <span class="value">{{ smallAreaPerformance }}</span>
		  <span class="label">{{ isChinese ? '小区业绩(不包括团长)' : 'Small Area Performance' }}</span>
		</div>
	  </section>

	  <section class="team-level-section">
		<h2 class="section-header">{{ isChinese ? '团队级别' : 'Team Level' }}</h2>
		<div class="level-display">
		  <span class="level">V{{ teamLevel }} ({{ levelName }})</span>
		  <span class="sub-label">{{ isChinese ? '我的级别' : 'My Level' }}</span>
		</div>
		<button
		  v-if="isRootUser"
		  :class="['upgrade-btn', { 'disabled': !canUpgrade }]"
		  :disabled="!canUpgrade"
		  @click="upgradeLevel"
		>
		  {{ isChinese ? '升级' : 'Upgrade' }}
		</button>
		<div v-else class="note">
		  <span class="icon">ℹ️</span>
		  <p>{{ isChinese ? '仅团长地址可升级' : 'Only team root can upgrade' }}</p>
		</div>
		<div class="note">
		  <span class="icon">❗</span>
		  <p>{{ isChinese ? '小区业绩达标后可升级' : 'Upgrade when small area performance meets target' }}</p>
		</div>
	  </section>
	</div>
</template>

<script setup>
import { ref, computed, watch } from 'vue';
// 2. 引入布局组件和 Store
import TheHeader from './layout/TheHeader.vue';
import { useWalletStore } from '../stores/wallet';

// 3. 初始化 Store
const walletStore = useWalletStore();

// 4. 定义 TeamLevel 组件自身的本地状态
const totalAreaPerformance = ref('0');
const smallAreaPerformance = ref('0');
const teamLevel = ref('0');
const canUpgrade = ref(false);
const isRootUser = ref(false);

// 5. 从 Store 中获取共享状态
const isChinese = computed(() => walletStore.isChinese);
const isConnected = computed(() => walletStore.isConnected);

// 6. 定义计算属性，用于显示级别名称
const levelName = computed(() => {
    const levelNames = {
      '0': { zh: '普通', en: 'Normal' },
      '1': { zh: '初使', en: 'Initiate' },
      '2': { zh: '晋使', en: 'Promoter' },
      '3': { zh: '信使', en: 'Messenger' },
      '4': { zh: '大使', en: 'Ambassador' },
      '5': { zh: '特使', en: 'Envoy' }
    };
    return levelNames[teamLevel.value] ? levelNames[teamLevel.value][isChinese.value ? 'zh' : 'en'] : (isChinese.value ? '普通' : 'Normal');
});

// 7. 监听钱包连接状态，连接后自动获取数据
watch(isConnected, (newVal) => {
  if (newVal) {
    fetchContractData();
  } else {
    resetData();
  }
}, { immediate: true });

// 8. 重构核心业务逻辑
function fromWei(value) {
    if (!walletStore.web3 || !value) return '0';
    const unit = walletStore.usdtDecimals === 6 ? 'mwei' : 'ether';
    return parseFloat(walletStore.web3.utils.fromWei(value.toString(), unit)).toFixed(2);
}

async function fetchContractData() {
  if (!walletStore.contract || !walletStore.walletAddress) return;
  try {
    const address = walletStore.walletAddress;
    const contract = walletStore.contract;

    const [
        totalDeposited,
        allReferralsPerf,
        level,
        userData
    ] = await Promise.all([
        contract.methods.getTotalDeposited().call(),
        contract.methods.getAllReferralsTotalPerformance(address).call(),
        contract.methods.getLevel(address).call(),
        contract.methods.users(address).call()
    ]);

    totalAreaPerformance.value = fromWei(totalDeposited);
    smallAreaPerformance.value = fromWei(allReferralsPerf);
    teamLevel.value = level.toString();
    isRootUser.value = userData.referrer === '0x0000000000000000000000000000000000000000';

    await checkUpgradeEligibility();

  } catch (error) {
    console.error('Error fetching contract data:', error);
    alert(isChinese.value ? '获取合约数据失败: ' + error.message : 'Failed to fetch contract data: ' + error.message);
  }
}

async function checkUpgradeEligibility() {
  if (!walletStore.contract || !isRootUser.value) {
    canUpgrade.value = false;
    return;
  }
  try {
    const currentLevel = parseInt(teamLevel.value);
    if (currentLevel >= 5) {
        canUpgrade.value = false;
        return;
    }
    const smallAreaPerf = parseFloat(smallAreaPerformance.value);
    
    // 从合约获取当前级别的升级要求
    const requirement = await walletStore.contract.methods.levelRequirements(currentLevel).call();
    const requiredPerf = parseFloat(fromWei(requirement));

    canUpgrade.value = smallAreaPerf >= requiredPerf;
  } catch (error) {
    console.error('Error checking upgrade eligibility:', error);
    canUpgrade.value = false;
  }
}

async function upgradeLevel() {
  if (!canUpgrade.value) {
    alert(isChinese.value ? '小区业绩未达标，无法升级' : 'Small area performance not met, cannot upgrade');
    return;
  }
  try {
    await walletStore.contract.methods.upgradeLevel().send({ from: walletStore.walletAddress })
      .on('transactionHash', (hash) => {
        alert(isChinese.value ? `交易已提交: ${hash}` : `Transaction submitted: ${hash}`);
      })
      .on('receipt', (receipt) => {
        alert(isChinese.value ? '升级成功' : 'Upgrade successful');
        fetchContractData(); // 成功后刷新数据
      });
  } catch (error) {
    console.error('Error upgrading level:', error);
    alert(isChinese.value ? `升级失败: ${error.message}` : `Upgrade failed: ${error.message}`);
  }
}

function resetData() {
    totalAreaPerformance.value = '0';
    smallAreaPerformance.value = '0';
    teamLevel.value = '0';
    canUpgrade.value = false;
    isRootUser.value = false;
}

// 注意：所有 connectWallet, disconnectWallet, switchLanguage 等方法和 ABI/地址常量已被彻底移除。
</script>

<style scoped>
/* 9. 移除所有与 header 相关的样式，只保留页面独有样式 */
.team-level-page {
	padding: 20px;
	min-height: 100vh;
	background: linear-gradient(135deg, rgba(245, 247, 250, 0.9) 0%, rgba(195, 207, 226, 0.9) 100%);
	font-family: 'Segoe UI', sans-serif;
	display: flex;
	flex-direction: column;
	align-items: center;
}

/* 移除 .header, .logo-section, .nav-right, .language-buttons, .wallet-btn 等所有头部相关样式 */

/* 全区业绩和小区业绩 */
.performance-section {
	width: 100%;
	display: flex;
	flex-direction: column;
	gap: 15px;
	margin-bottom: 20px;
}

.performance-card {
	width: 100%;
	padding: 15px;
	background: #fff;
	border-radius: 12px;
	box-shadow: 0 3px 10px rgba(0, 0, 0, 0.05);
	text-align: center;
	transition: transform 0.3s ease;
}

.performance-card:hover {
	transform: translateY(-3px);
}

.performance-card .value {
	font-size: 24px;
	font-weight: 600;
	color: #00c08b;
	margin-bottom: 5px;
}

.performance-card .label {
	font-size: 12px;
	color: #78909c;
}

/* 团队级别 */
.team-level-section {
	width: 100%;
	max-width: 360px;
	background: #fff;
	padding: 20px;
	border-radius: 12px;
	box-shadow: 0 3px 10px rgba(0, 0, 0, 0.05);
	text-align: center;
}

.section-header {
	font-size: 20px;
	font-weight: 600;
	color: #00c08b;
	margin-bottom: 15px;
}

.level-display {
	margin-bottom: 15px;
}

.level-display .level {
	font-size: 28px;
	font-weight: 700;
	color: #00c08b;
	margin-bottom: 5px;
}

.level-display .sub-label {
	font-size: 12px;
	color: #78909c;
}

.upgrade-btn {
	width: 100%;
	max-width: 180px;
	padding: 12px;
	background: linear-gradient(135deg, #00c08b 0%, #00A653 100%);
	color: white;
	border: none;
	border-radius: 20px;
	font-size: 16px;
	font-weight: 500;
	cursor: pointer;
	box-shadow: 0 3px 8px rgba(0, 214, 107, 0.2);
	transition: all 0.3s ease;
}

.upgrade-btn:hover:not(.disabled) {
	transform: translateY(-2px);
	box-shadow: 0 5px 12px rgba(0, 214, 107, 0.3);
}

.upgrade-btn.disabled {
	background: #b0bec5;
	cursor: not-allowed;
	box-shadow: none;
}

.note {
	display: flex;
	align-items: center;
	justify-content: center;
	margin-top: 15px;
	color: #78909c;
	font-size: 12px;
	gap: 5px;
}

.note .icon {
	width: 16px;
	height: 16px;
	background: #ffca28;
	color: #fff;
	border-radius: 50%;
	font-size: 10px;
	display: flex;
	align-items: center;
	justify-content: center;
}

@media (min-width: 600px) {
	.performance-section {
	  flex-direction: row;
	  gap: 20px;
	}
	.performance-card {
	  flex: 1;
	}
	.team-level-section {
	  padding: 30px;
	}
}

@media (max-width: 360px) {
	.team-level-page {
	  padding: 15px;
	}
	.performance-card .value {
	  font-size: 20px;
	}
	.level-display .level {
	  font-size: 24px;
	}
}
</style>