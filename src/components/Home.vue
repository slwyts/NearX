<template>
	<div class="home-page">
    <TheHeader />

	  <div class="reward-section">
		<div class="reward-item">
		  <span class="value">{{ rewardUSDT }}</span>
		  <span class="label">{{ language === 'zh' ? '账户 USDT' : 'Reward USDT' }}</span>
		</div>
		<div class="reward-item">
		  <span class="value">{{ completedWithdrawal }}</span>
		  <span class="label">{{ language === 'zh' ? '已释放 USDT' : 'Released USDT' }}</span>
		</div>
	  </div>

	  <div class="participate-section">
		<h2 class="section-header">{{ language === 'zh' ? '参与' : 'Participate' }}</h2>
		<div class="participate-content">
		  <div class="reward-display">
			<span class="value">{{ totalDeposit }}</span>
			<span class="label">{{ language === 'zh' ? '总存款 (USDT)' : 'Total Deposit (USDT)' }}</span>
		  </div>
		  <div class="stake-display">
			<span class="label">{{ language === 'zh' ? '质押数量' : 'Stake Amount' }}</span>
			<input
			  v-model="stakeAmount"
			  type="number"
			  min="100"
			  step="1"
			  :placeholder="language === 'zh' ? '质押数量 (最低 100 USDT)' : 'Enter stake amount (min 100 USDT)'"
			  class="stake-input"
			/>
			<div class="stake-buttons">
			  <button class="action-btn" @click="approveUSDT">{{ language === 'zh' ? '允许 USDT' : 'Approve USDT' }}</button>
			  <button class="action-btn" @click="stakeUSDT">{{ language === 'zh' ? '质押' : 'Stake' }}</button>
			</div>
		  </div>
		</div>
	  </div>

	  <div class="reward-breakdown">
		<h2 class="section-header">{{ language === 'zh' ? '奖励构成' : 'Reward Breakdown' }}</h2>
		<div class="breakdown-item">
		  <span class="value">{{ staticDailyRelease }}</span>
		  <span class="label">{{ language === 'zh' ? '静态每日释放 (USDT)' : 'Static Daily Release (USDT)' }}</span>
		</div>
		<div class="breakdown-item">
		  <span class="value">{{ dynamicDailyRelease }}</span>
		  <span class="label">{{ language === 'zh' ? '动态每日释放 (USDT)' : 'Dynamic Daily Release (USDT)' }}</span>
		</div>
		<div class="breakdown-list">
		  <div class="breakdown-row">
			<span>{{ language === 'zh' ? '直推奖励' : 'Direct Referral Reward' }}</span>
			<span class="green-value">{{ directReward }} USDT</span>
		  </div>
		  <div class="breakdown-row">
			<span>{{ language === 'zh' ? '分享奖励' : 'Sharing Reward' }}</span>
			<span class="green-value">{{ sharingReward }} USDT</span>
		  </div>
		  <div class="breakdown-row">
			<span>{{ language === 'zh' ? '团队奖励' : 'Team Reward' }}</span>
			<span class="green-value">{{ teamReward }} USDT</span>
		  </div>
		  <div class="breakdown-row">
			<span>{{ language === 'zh' ? '全球分红' : 'Global Dividend' }}</span>
			<span class="green-value">{{ globalDividend }} USDT</span>
		  </div>
		</div>
	  </div>

	  <div class="near-profit">
		<span class="value">{{ nearProfit }}</span>
		<span class="label">{{ language === 'zh' ? 'NEAR 每日收益' : 'NEAR Daily Profit' }}</span>
	  </div>

	  <div class="withdraw-section">
		<h2 class="section-header">{{ language === 'zh' ? '提取奖励' : 'Withdraw Reward' }}</h2>
		<div class="withdraw-item">
		  <span class="value">{{ totalReleasable }}</span>
		  <span class="label">{{ language === 'zh' ? '可释放总量(USDT)' : 'Total Releasable (USDT)' }}</span>
		</div>
		<div class="withdraw-item">
		  <span class="value">{{ completedWithdrawal }}</span>
		  <span class="label">{{ language === 'zh' ? '完成提取(USDT)' : 'Completed Withdrawal (USDT)' }}</span>
		</div>
		<div class="withdraw-item">
		  <span class="value">{{ withdrawable }}</span>
		  <span class="label">{{ language === 'zh' ? '可提取(USDT)' : 'Withdrawable (USDT)' }}</span>
		</div>

				<button
					class="withdraw-btn"
					:class="{ disabled: hasWithdrawnRecently || !hasClaimable }"
					:disabled="hasWithdrawnRecently || !hasClaimable"
					@click="claimAndWithdraw"
				>
					{{ hasWithdrawnRecently ? (language === 'zh' ? '24小时内已提现' : 'Withdrawn within 24h') :
						 (!hasClaimable ? (language === 'zh' ? '无奖励可提取' : 'No Rewards') :
						 (language === 'zh' ? '一键提取全部收益' : 'Withdraw All Rewards')) }}
				</button>
        <div class="note">
		  <span style="color: green;">❗</span>
		  {{ language === 'zh' ? '注：奖励将以NEAR形式直接转入您的钱包' : 'Note: Rewards will be transferred as NEAR directly to your wallet' }}
		</div>
	  </div>

	  <transition name="fade">
		<div v-if="showModal" class="modal-overlay">
		  <div class="modal-content" :class="modalType">
			<div class="modal-header">
			  <h3>{{ modalTitle }}</h3>
			</div>
			<div class="modal-body">
			  <p>{{ modalMessage }}</p>
			</div>
			<div class="modal-footer">
			  <button @click="closeModal" class="modal-btn">
				{{ language === 'zh' ? '关闭' : 'Close' }}
			  </button>
			</div>
		  </div>
		</div>
	  </transition>
	</div>
</template>

<script setup>
import { ref, onMounted, computed, watch } from 'vue';
import TheHeader from './layout/TheHeader.vue';
import { useWalletStore } from '../stores/wallet';

const walletStore = useWalletStore();

// Home.vue 组件自身的本地状态
const stakeAmount = ref('');
const rewardUSDT = ref('0.00');
const releasedUSDT = ref('0.00');
const totalDeposit = ref('0.00');
const staticDailyRelease = ref('0.00');
const dynamicDailyRelease = ref('0.00');
const directReward = ref('0.00');
const sharingReward = ref('0.00');
const teamReward = ref('0.00');
const globalDividend = ref('0.00');
const nearProfit = ref('0.00');
const totalReleasable = ref('0.00');
const completedWithdrawal = ref('0.00');
const withdrawable = ref('0.000'); // 改为3位小数以匹配 fromWei
const hasClaimable = ref(false);   // 精确判断可提金额（避免四舍五入显示为0）
const hasWithdrawnRecently = ref(false);
const showModal = ref(false);
const modalTitle = ref('');
const modalMessage = ref('');
const modalType = ref('success');
const exchangeRate = ref(0);
let updateInterval = null;
let exchangeRateInterval = null;

// 从 Store 中获取共享的状态
const language = computed(() => walletStore.isChinese ? 'zh' : 'en');
const isConnected = computed(() => walletStore.isConnected);

// 监听钱包连接状态，一旦连接成功，就加载用户数据
watch(isConnected, (newVal) => {
  if (newVal) {
    updateUserData();
    startDataPolling();
  } else {
    resetData();
    stopDataPolling();
  }
}, { immediate: true });

// 将 wei 单位的数值转换为 ether/mwei 单位的字符串
function fromWei(value) {
    if (!walletStore.web3 || !value) return '0.000';
    const unit = walletStore.usdtDecimals === 6 ? 'mwei' : 'ether';
    return parseFloat(walletStore.web3.utils.fromWei(value.toString(), unit)).toFixed(3);
}

// 核心方法
async function approveUSDT() {
  if (!isConnected.value) {
    await walletStore.connect();
    return;
  }
  try {
    const unit = walletStore.usdtDecimals === 6 ? 'mwei' : 'ether';
    const amount = walletStore.web3.utils.toWei(stakeAmount.value || '0', unit);

    if (parseFloat(stakeAmount.value) < 100) {
      showErrorModal(language.value === 'zh' ? '最低质押数量为 100 USDT' : 'Minimum stake amount is 100 USDT');
      return;
    }

    const balance = await walletStore.usdtContract.methods.balanceOf(walletStore.walletAddress).call();
    if (BigInt(balance) < BigInt(amount)) {
        showErrorModal(language.value === 'zh' ? 'USDT 余额不足' : 'Insufficient USDT balance');
        return;
    }

    await walletStore.usdtContract.methods.approve(walletStore.contract.options.address, amount).send({ from: walletStore.walletAddress, gas: 200000 });
    showSuccessModal(language.value === 'zh' ? 'USDT 授权成功' : 'USDT approved successfully');
    await updateUserData();
  } catch (error) {
    console.error('Approve USDT error:', error);
    showErrorModal(language.value === 'zh' ? `授权失败: ${error.message}` : `Approval failed: ${error.message}`);
  }
}

async function stakeUSDT() {
  if (!isConnected.value) {
    await walletStore.connect();
    return;
  }
  try {
    const unit = walletStore.usdtDecimals === 6 ? 'mwei' : 'ether';
    const amount = walletStore.web3.utils.toWei(stakeAmount.value || '0', unit);
    if (parseFloat(stakeAmount.value) < 100) {
      showErrorModal(language.value === 'zh' ? '最低质押数量为 100 USDT' : 'Minimum stake amount is 100 USDT');
      return;
    }

    const allowance = await walletStore.usdtContract.methods.allowance(walletStore.walletAddress, walletStore.contract.options.address).call();
    if (BigInt(allowance) < BigInt(amount)) {
      showErrorModal(language.value === 'zh' ? '请先授权 USDT' : 'Please approve USDT first');
      return;
    }
    
    await walletStore.contract.methods.deposit(amount).send({ from: walletStore.walletAddress, gas: 300000 });
    showSuccessModal(language.value === 'zh' ? '质押成功' : 'Stake successful');
    await updateUserData();
  } catch (error) {
    console.error('Stake USDT error:', error);
    showErrorModal(language.value === 'zh' ? `质押失败: ${error.message}` : `Stake failed: ${error.message}`);
  }
}

async function claimAndWithdraw() {
  if (!isConnected.value) {
    showErrorModal(language.value === 'zh' ? '请先连接钱包' : 'Please connect wallet first');
    return;
  }
  if (hasWithdrawnRecently.value) {
    showErrorModal(language.value === 'zh' ? '24小时内已提现' : 'Withdrawn within 24 hours');
    return;
  }
	if (!hasClaimable.value) {
    showErrorModal(language.value === 'zh' ? '无可提取金额' : 'No withdrawable amount');
    return;
  }

  try {
    const transaction = walletStore.contract.methods.claimAndWithdraw();
    const estimatedGas = await transaction.estimateGas({ from: walletStore.walletAddress });
    const gasLimit = Math.round(Number(estimatedGas) * 1.2);
    console.log(`Estimated Gas for claimAndWithdraw: ${estimatedGas}, Gas Limit with buffer: ${gasLimit}`);
    await transaction.send({ from: walletStore.walletAddress, gas: gasLimit });
    await updateUserData();
    showSuccessModal(language.value === 'zh' ? '提取成功，NEAR已转入您的钱包' : 'Withdrawal successful, NEAR transferred to your wallet');

  } catch (error) {
    console.error('Claim and Withdraw error:', error);
    if (error.message.includes('gas required exceeds allowance') || error.message.includes('out of gas')) {
         showErrorModal(language.value === 'zh' ? `提现失败：交易Gas超出预算。` : `Withdrawal failed: Transaction is too complex and requires more gas.`);
    } else {
         showErrorModal(language.value === 'zh' ? `提取失败: ${error.message}` : `Withdrawal failed: ${error.message}`);
    }
  }
}

async function updateUserData() {
  if (!walletStore.contract || !walletStore.walletAddress) return;
  try {
    const address = walletStore.walletAddress;
    const contract = walletStore.contract;

			const [
				userData, usdtBalance, releasedReward, staticDaily, dynamicDaily,
				direct, share, team, global, withdrawn, hasWithdrawn, latestBlock
			] = await Promise.all([
			contract.methods.users(address).call(),
			contract.methods.getUsdtBalance(address).call(),
			contract.methods.getReleasedReward(address).call(),
			contract.methods.getTodayStaticReward(address).call(),
			contract.methods.getTodayDynamicReward(address).call(),
			contract.methods.getDirectReward(address).call(),
			contract.methods.getShareReward(address).call(),
			contract.methods.getTeamReward(address).call(),
			contract.methods.getGlobalDividend(address).call(),
			contract.methods.getWithdrawn(address).call(),
				contract.methods.hasWithdrawnInLast24Hours(address).call(),
				walletStore.web3.eth.getBlock('latest')
		]);

    rewardUSDT.value = fromWei(usdtBalance);
    releasedUSDT.value = fromWei(releasedReward);
    totalDeposit.value = fromWei(userData.totalDeposit);
    staticDailyRelease.value = fromWei(staticDaily);
    dynamicDailyRelease.value = fromWei(dynamicDaily);
    directReward.value = fromWei(direct);
    sharingReward.value = fromWei(share);
    teamReward.value = fromWei(team);
    globalDividend.value = fromWei(global);
	completedWithdrawal.value = fromWei(withdrawn);
	hasWithdrawnRecently.value = hasWithdrawn;
		// 优先调用合约的 previewClaimable；若不存在则使用回退算法
		let claimableRaw = '0';
		let staticToAddBI = 0n;
		let dynamicToAddBI = 0n;
		try {
			if (contract.methods.previewClaimable) {
				const preview = await contract.methods.previewClaimable(address).call();
				claimableRaw = preview?.claimableUSDT ?? (Array.isArray(preview) ? preview[0] : '0');
				staticToAddBI = BigInt((preview?.staticToAdd ?? (Array.isArray(preview) ? preview[2] : '0')) || '0');
				dynamicToAddBI = BigInt((preview?.dynamicToAdd ?? (Array.isArray(preview) ? preview[3] : '0')) || '0');
			} else {
				throw new Error('previewClaimable not available');
			}
		} catch (e) {
			// 回退：在前端计算预览结果
			const nowTs = BigInt(latestBlock.timestamp || Math.floor(Date.now() / 1000));
			const lastUpdate = BigInt(userData.lastUpdateTime || '0');
			const daysPassed = nowTs > lastUpdate ? (nowTs - lastUpdate) / 86400n : 0n;

			const totalDepositBI = BigInt(userData.totalDeposit || '0');
			const usdtBalanceBI = BigInt(usdtBalance || '0');
			const pendingStaticBI = BigInt(userData.pendingStaticReward || '0');
			const pendingDynamicBI = BigInt(userData.pendingDynamicReward || '0');
			const staticDailyBI = BigInt(staticDaily || '0');
			const dynamicDailyBI = BigInt(dynamicDaily || '0');

			let newStaticBI = staticDailyBI * daysPassed;
			const stageMultiplier = (totalDepositBI >= 3001n * 10n ** 18n) ? 30n
														: (totalDepositBI >= 1001n * 10n ** 18n) ? 25n
														: (totalDepositBI >= 501n * 10n ** 18n) ? 20n
														: (totalDepositBI >= 100n * 10n ** 18n) ? 15n
														: 0n;
			const maxReward = (totalDepositBI * stageMultiplier) / 10n;
			const staticReleasedBI = BigInt(userData.staticRewardReleased || '0');
			const totalStaticBefore = staticReleasedBI + pendingStaticBI;
			if (totalStaticBefore >= maxReward) {
				newStaticBI = 0n;
			} else {
				const headroom = maxReward - totalStaticBefore;
				if (newStaticBI > headroom) newStaticBI = headroom;
			}
			const newDynamicBI = dynamicDailyBI * daysPassed;

			staticToAddBI = pendingStaticBI + newStaticBI;
			dynamicToAddBI = pendingDynamicBI + newDynamicBI;
			const claimableBI = usdtBalanceBI + staticToAddBI + dynamicToAddBI;
			claimableRaw = claimableBI.toString();
		}

		withdrawable.value = fromWei(claimableRaw || '0');
		hasClaimable.value = BigInt(claimableRaw || '0') > 0n;
		const toReleaseSum = (staticToAddBI + dynamicToAddBI).toString();
		totalReleasable.value = fromWei(toReleaseSum);

	// 估算每日 NEAR 收益（基于每日静态+动态，和汇率）
	const dailyRelease = parseFloat(fromWei(staticDaily)) + parseFloat(fromWei(dynamicDaily));
	nearProfit.value = exchangeRate.value > 0 ? (dailyRelease / exchangeRate.value).toFixed(3) : '0.000';

  } catch (error) {
    console.error('Update user data error:', error);
  }
}

// 弹窗控制方法
function showSuccessModal(message) {
  modalTitle.value = language.value === 'zh' ? '操作成功' : 'Operation Successful';
  modalMessage.value = message;
  modalType.value = 'success';
  showModal.value = true;
}

function showErrorModal(message) {
  modalTitle.value = language.value === 'zh' ? '操作失败' : 'Operation Failed';
  modalMessage.value = message;
  modalType.value = 'error';
  showModal.value = true;
}

function closeModal() {
  showModal.value = false;
}

// 数据轮询
function startDataPolling() {
  stopDataPolling();
  updateInterval = setInterval(updateUserData, 15000);
}

function stopDataPolling() {
  if (updateInterval) clearInterval(updateInterval);
}

// 汇率获取
async function fetchExchangeRate() {
  try {
    const response = await fetch('https://api.binance.com/api/v3/ticker/price?symbol=NEARUSDT');
    const data = await response.json();
    exchangeRate.value = data.price ? parseFloat(data.price) : 7.5;
  } catch (error) {
    console.error('Error fetching exchange rate:', error);
    exchangeRate.value = 7.5; // Fallback
  }
}

// 重置数据
function resetData() {
    rewardUSDT.value = '0.00';
    releasedUSDT.value = '0.00';
    totalDeposit.value = '0.00';
    staticDailyRelease.value = '0.00';
    dynamicDailyRelease.value = '0.00';
    directReward.value = '0.00';
    sharingReward.value = '0.00';
    teamReward.value = '0.00';
    globalDividend.value = '0.00';
    nearProfit.value = '0.00';
    totalReleasable.value = '0.00';
    completedWithdrawal.value = '0.00';
    withdrawable.value = '0.000';
	hasClaimable.value = false;
    hasWithdrawnRecently.value = false;
}

// 组件生命周期钩子
onMounted(() => {
  fetchExchangeRate();
  exchangeRateInterval = setInterval(fetchExchangeRate, 300000);
});

</script>

<style scoped>
/* 样式部分保持不变，无需修改 */
.home-page {
	padding: 30px;
	max-width: 900px;
	margin: 0 auto;
	font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
	background: linear-gradient(135deg, #f5f7fa 0%, #c3cfe2 100%);
	min-height: 100vh;
	box-sizing: border-box;
}

.reward-section {
	display: flex;
	justify-content: space-between;
	gap: 20px;
	margin-bottom: 40px;
}

.reward-item {
	flex: 1;
	text-align: center;
	padding: 20px;
	background: white;
	border-radius: 12px;
	box-shadow: 0 4px 15px rgba(0, 0, 0, 0.1);
	transition: transform 0.3s;
}

.reward-item:hover {
	transform: translateY(-5px);
}

.reward-item .value {
	display: block;
	font-size: 24px;
	font-weight: 700;
	color: var(--primary-color, #00C08B);
	margin-bottom: 10px;
}

.reward-item .label {
	font-size: 16px;
	color: #555;
}

.participate-section {
	background: white;
	padding: 25px;
	border-radius: 12px;
	box-shadow: 0 4px 15px rgba(0, 0, 0, 0.1);
	margin-bottom: 40px;
}

.section-header {
	font-size: 22px;
	font-weight: 600;
	color: var(--primary-color, #00C08B);
	text-align: center;
	margin-bottom: 20px;
}

.participate-content {
	text-align: center;
}

.reward-display .value {
	display: block;
	font-size: 24px;
	font-weight: 700;
	color: var(--primary-color, #00C08B);
	margin-bottom: 10px;
}

.reward-display .label {
	font-size: 16px;
	color: #555;
}

.stake-display {
	margin-top: 20px;
}

.stake-display .label {
	display: block;
	font-size: 18px;
	color: #333;
	margin-bottom: 15px;
}

.stake-input {
	width: 100%;
	max-width: 300px;
	padding: 10px;
	margin: 10px auto;
	border: 1px solid #ccc;
	border-radius: 8px;
	font-size: 16px;
	text-align: center;
	display: block;
	box-sizing: border-box;
}

.stake-input::-webkit-inner-spin-button,
.stake-input::-webkit-outer-spin-button {
	-webkit-appearance: none;
	margin: 0;
}

.stake-input {
	appearance: textfield;
	-moz-appearance: textfield;
}

.stake-input:focus {
	outline: none;
	border-color: #00C08B;
	box-shadow: 0 0 5px rgba(0, 192, 139, 0.5);
}

.stake-buttons {
	display: flex;
	justify-content: center;
	gap: 15px;
}

.action-btn {
	padding: 10px 20px;
	background: linear-gradient(135deg, #00C08B 0%, #00a070 100%);
	color: white;
	border: none;
	border-radius: 10px;
	cursor: pointer;
	font-size: 16px;
	font-weight: 600;
	box-shadow: 0 4px 10px rgba(0, 192, 139, 0.3);
	transition: transform 0.2s, box-shadow 0.2s, background 0.3s;
}

.action-btn:hover {
	transform: translateY(-3px);
	box-shadow: 0 6px 15px rgba(0, 192, 139, 0.5);
	background: linear-gradient(135deg, #00a070 0%, #008c5e 100%);
}

.action-btn:active {
	transform: translateY(1px);
	box-shadow: 0 2px 5px rgba(0, 192, 139, 0.2);
}

.reward-breakdown, .withdraw-section {
	background: white;
	padding: 25px;
	border-radius: 12px;
	box-shadow: 0 4px 15px rgba(0, 0, 0, 0.1);
	margin-bottom: 40px;
}

.breakdown-item, .withdraw-item {
	text-align: center;
	margin-bottom: 15px;
}

.breakdown-item .value, .withdraw-item .value {
	display: block;
	font-size: 20px;
	font-weight: 600;
	color: var(--primary-color, #00C08B);
	margin-bottom: 8px;
}

.breakdown-item .label, .withdraw-item .label {
	font-size: 14px;
	color: #666;
}

.breakdown-list {
	margin-top: 20px;
}

.breakdown-row {
	display: flex;
	justify-content: space-between;
	align-items: center;
	margin: 8px 0;
	font-size: 14px;
	color: #777;
}

.green-value {
	color: var(--primary-color, #00C08B);
	font-weight: 600;
}

.near-profit {
	display: flex;
	flex-direction: column;
	align-items: center;
	padding: 20px;
	background: white;
	border-radius: 12px;
	box-shadow: 0 4px 15px rgba(0, 0, 0, 0.1);
	margin-bottom: 40px;
}

.near-profit .value {
	font-size: 24px;
	font-weight: 700;
	color: var(--primary-color, #00C08B);
	margin-bottom: 10px;
}

.near-profit .label {
	font-size: 16px;
	color: #555;
}

.withdraw-btn {
	width: 100%;
	max-width: 200px;
	padding: 12px;
	background: linear-gradient(135deg, #00C08B 0%, #00a070 100%);
	color: white;
	border: none;
	border-radius: 10px;
	cursor: pointer;
	font-size: 16px;
	font-weight: 600;
	box-shadow: 0 4px 10px rgba(0, 192, 139, 0.3);
	transition: all 0.2s ease-in-out;
	margin: 20px auto 0;
	display: block;
}

.withdraw-btn:hover:not(.disabled) {
	transform: translateY(-3px);
	box-shadow: 0 6px 15px rgba(0, 192, 139, 0.5);
}

.withdraw-btn.disabled {
	background: #cccccc;
	cursor: not-allowed;
	box-shadow: none;
}

.note {
	margin-top: 15px;
	font-size: 12px;
	color: #888;
}

.modal-overlay {
	position: fixed;
	top: 0;
	left: 0;
	right: 0;
	bottom: 0;
	background: rgba(0, 0, 0, 0.5);
	display: flex;
	justify-content: center;
	align-items: center;
	z-index: 1000;
}

.modal-content {
	background: white;
	border-radius: 12px;
	padding: 20px;
	width: 90%;
	max-width: 400px;
	box-shadow: 0 5px 15px rgba(0, 0, 0, 0.3);
}

.modal-content.success {
	border-top: 4px solid #00C08B;
}

.modal-content.error {
	border-top: 4px solid #ff4444;
}

.modal-header h3 {
	margin: 0;
	font-size: 20px;
}

.modal-body p {
	margin: 15px 0;
	font-size: 16px;
}

.modal-footer {
	text-align: right;
}

.modal-btn {
	padding: 8px 20px;
	background: #00C08B;
	color: white;
	border: none;
	border-radius: 8px;
	cursor: pointer;
}

.fade-enter-active, .fade-leave-active {
	transition: opacity 0.3s;
}

.fade-enter, .fade-leave-to {
	opacity: 0;
}
</style>