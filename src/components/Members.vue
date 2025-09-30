<template>
	<div class="members-page">
    <TheHeader />

	  <div class="performance-section">
		<div class="performance-card merged">
		  <div class="performance-metric">
			<div class="value">{{ directPerformance }}</div>
			<div class="label">
			  {{ isChinese ? '直推业绩（USDT）' : 'Direct Referral Performance (USDT)' }}
			</div>
		  </div>
		  <div class="divider"></div>
		  <div class="performance-metric">
			<div class="value">{{ totalPerformance }}</div>
			<div class="label">
			  {{ isChinese ? '总业绩（USDT）' : 'Total Performance (USDT)' }}
			</div>
		  </div>
		</div>
	  </div>

	  <div class="direct-referrals-section">
		<h2 class="section-header">{{ isChinese ? '直推列表' : 'Direct Referrals List' }}</h2>
		<div class="table-container" v-if="directReferrals.length > 0">
		  <table>
			<thead>
			  <tr>
				<th>{{ isChinese ? '地址' : 'Address' }}</th>
				<th>{{ isChinese ? '质押量' : 'Stake Amount' }}</th>
			  </tr>
			</thead>
			<tbody>
			  <tr v-for="(referral, index) in directReferrals" :key="index">
				<td>{{ referral.address }}</td>
				<td>{{ referral.stake }}</td>
			  </tr>
			</tbody>
		  </table>
		</div>
		<div class="no-data" v-else>
		  <span class="icon">🚫</span>
		  <p>{{ isChinese ? '没有推荐数据' : 'No Referral Data' }}</p>
		</div>
	  </div>

	  <div class="valid-referrals">
		<span class="value">{{ validDirectCount }}</span>
		<span class="label">{{ isChinese ? '有效直推数' : 'Valid Direct Referrals' }}</span>
	  </div>

	  <div class="share-performance-section">
		<h2 class="section-header">{{ isChinese ? '分享业绩' : 'Share Performance' }}</h2>
		<div class="table-container">
		  <table>
			<thead>
			  <tr>
				<th>{{ isChinese ? '层次' : 'Level' }}</th>
				<th>{{ isChinese ? '业绩（USDT）' : 'Performance (USDT)' }}</th>
			  </tr>
			</thead>
			<tbody>
			  <tr v-for="(perf, index) in levelPerformance" :key="index">
				<td>{{ index + 1 }}</td>
				<td><span class="green-value">{{ perf }}</span></td>
			  </tr>
			</tbody>
		  </table>
		</div>
	  </div>
	</div>
</template>

<script setup>
import { ref, computed, watch } from 'vue';
// 2. 引入布局组件和 Store
import TheHeader from './layout/TheHeader.vue';
import { useWalletStore } from '../stores/wallet';

// 3. 初始化 Store
const walletStore = useWalletStore();

// 4. 定义 Members 组件自身的本地状态
const directPerformance = ref('0.00');
const totalPerformance = ref('0.00');
const directReferrals = ref([]);
const validDirectCount = ref('0');
const levelPerformance = ref(Array(10).fill('0.00'));

// 5. 从 Store 中获取共享状态
const isChinese = computed(() => walletStore.isChinese);
const isConnected = computed(() => walletStore.isConnected);

// 6. 监听钱包连接状态，一旦连接成功，就获取成员数据
watch(isConnected, (newVal) => {
  if (newVal) {
    fetchMemberData();
  } else {
    // 如果断开连接，清空数据
    resetData();
  }
}, { immediate: true }); // immediate: true 保证组件加载时如果已连接也会立即执行

// 7. 重构核心业务逻辑
function fromWei(value) {
    if (!walletStore.web3 || !value) return '0.00';
    // 注意：用户的质押和业绩通常是 USDT，使用 USDT 的小数位数
    const unit = walletStore.usdtDecimals === 6 ? 'mwei' : 'ether';
    return parseFloat(walletStore.web3.utils.fromWei(value.toString(), unit)).toFixed(2);
}

function formatAddress(address) {
    if (!address) return '';
    return `${address.slice(0, 6)}...${address.slice(-4)}`;
}

async function fetchMemberData() {
  if (!walletStore.contract || !walletStore.walletAddress) return;
  try {
    const address = walletStore.walletAddress;
    const contract = walletStore.contract;

    // 并行获取所有需要的数据
    const [
      directPerf,
      levelPerf,
      referrals,
      validCount
    ] = await Promise.all([
      contract.methods.getDirectReferralsTotalPerformance(address).call(),
      contract.methods.getPerformanceByLevel(address).call(),
      contract.methods.getReferrals(address, 1).call(), // 获取第一层推荐人
      contract.methods.getDirectReferralsWithDepositCount(address).call()
    ]);

    // 更新直推和总业绩
    directPerformance.value = fromWei(directPerf);
    levelPerformance.value = levelPerf.map(perf => fromWei(perf));
    const totalPerfWei = levelPerf.reduce((sum, perf) => BigInt(sum) + BigInt(perf), BigInt(0));
    totalPerformance.value = fromWei(totalPerfWei);

    // 更新有效直推数
    validDirectCount.value = validCount.toString();

    // 获取每个推荐人的质押数据
    const referralsWithStake = await Promise.all(
      referrals
        .filter(addr => addr !== '0x0000000000000000000000000000000000000000')
        .map(async (addr) => {
          const userData = await contract.methods.users(addr).call();
          return {
            address: formatAddress(addr),
            stake: fromWei(userData.totalDeposit)
          };
        })
    );
    directReferrals.value = referralsWithStake;

  } catch (error) {
    console.error('Error fetching member data:', error);
    alert(isChinese.value ? '获取数据失败: ' + error.message : 'Failed to fetch data: ' + error.message);
  }
}

function resetData() {
    directPerformance.value = '0.00';
    totalPerformance.value = '0.00';
    directReferrals.value = [];
    validDirectCount.value = '0';
    levelPerformance.value = Array(10).fill('0.00');
}

// 注意：所有 connectWallet, disconnectWallet, switchLanguage, contract/web3 初始化等逻辑已被彻底移除。
</script>

<style scoped>
/* 8. 移除所有与 header 相关的样式，只保留页面独有样式 */
.members-page {
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

/* 移除 .header, .logo-section, .nav-right, .language-buttons, .wallet-btn 等所有头部相关样式 */

/* 直推业绩和总业绩（合并后） */
.performance-section {
	display: flex;
	justify-content: stretch;
	align-items: center;
	width: 100%;
	margin-bottom: 40px;
}

.performance-card.merged {
	display: grid;
	grid-template-columns: 1fr 1px 1fr;
	align-items: center;
	justify-items: center;
	background: white;
	border-radius: 12px;
	box-shadow: 0 6px 15px rgba(0, 0, 0, 0.1);
	padding: 20px;
	width: 100%;
}

.performance-metric {
	text-align: center;
}

.performance-metric .value {
	font-size: 28px;
	font-weight: 700;
	color: var(--primary-color, #00C08B);
	margin-bottom: 5px;
}

.performance-metric .label {
	font-size: 16px;
	color: #555;
}

.divider {
	width: 1px;
	background: #eee;
	height: 50px;
	margin: 0 10px;
}

/* 直推列表 */
.direct-referrals-section, .share-performance-section {
	width: 100%;
	background: white;
	padding: 25px;
	border-radius: 12px;
	box-shadow: 0 6px 15px rgba(0, 0, 0, 0.1);
	margin-bottom: 40px;
}

.section-header {
	font-size: 24px;
	font-weight: 600;
	color: var(--primary-color, #00C08B);
	text-align: center;
	margin-bottom: 20px;
	letter-spacing: 1px;
}

.table-container {
	overflow-x: auto;
}

table {
	width: 100%;
	border-collapse: collapse;
}

th, td {
	padding: 12px 15px;
	text-align: left;
	font-size: 14px;
}

th {
	background: #e0f2e9;
	color: #333;
	font-weight: 600;
}

td {
	border-bottom: 1px solid #eee;
	color: #666;
}

tr:hover {
	background: #f9f9f9;
	transition: background 0.2s ease;
}

.no-data {
	text-align: center;
	padding: 20px;
	color: #888;
}

.no-data .icon {
	font-size: 24px;
	margin-bottom: 10px;
	display: block;
}

/* 有效直推数 */
.valid-referrals {
	width: 100%;
	text-align: center;
	padding: 20px;
	background: white;
	border-radius: 12px;
	box-shadow: 0 6px 15px rgba(0, 0, 0, 0.1);
	margin-bottom: 40px;
}

.valid-referrals .value {
	display: block;
	font-size: 28px;
	font-weight: 700;
	color: var(--primary-color, #00C08B);
	margin-bottom: 10px;
}

.valid-referrals .label {
	font-size: 16px;
	color: #555;
}

.green-value {
	color: #27ae60;
	font-weight: 600;
}

/* 响应式设计 */
@media (max-width: 768px) {
	.members-page {
	  padding: 20px;
	}

	.performance-card.merged {
	  grid-template-columns: 1fr;
	  row-gap: 20px;
	}

	.divider {
	  display: none;
	}

	.direct-referrals-section, .share-performance-section {
	  padding: 15px;
	}

	.section-header {
	  font-size: 20px;
	}

	th, td {
	  font-size: 12px;
	  padding: 10px;
	}
}

@media (max-width: 360px) {
	.section-header {
	  font-size: 18px;
	}

	.performance-metric .value {
	  font-size: 24px;
	}

	.performance-metric .label {
	  font-size: 14px;
	}

	th, td {
	  font-size: 10px;
	  padding: 8px;
	}

	.valid-referrals .value {
	  font-size: 24px;
	}

	.valid-referrals .label {
	  font-size: 14px;
	}
}
</style>