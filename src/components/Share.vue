<template>
	<div class="bind-wallet-page">
    <TheHeader />

	  <div class="background-image">
		<div class="overlay"></div>
	  </div>

	  <div class="bind-section">
		<h1 class="section-header">{{ isChinese ? '推荐人地址' : 'Referral Address' }}</h1>
		<div class="bind-content">
		  <input
			v-model="referralAddress"
			:placeholder="isChinese ? '0x...' : '0x...'"
			class="referral-input"
		  />
		  <button class="bind-btn" @click="bindReferral">
			{{ isChinese ? '绑定推荐人地址' : 'Bind Referral Address' }}
		  </button>
		  <p v-if="error" class="error">{{ error }}</p>

		  <div v-if="walletStore.isConnected && walletStore.walletAddress" class="referral-link-container">
			<label class="referral-link-label">
			  {{ isChinese ? '推荐人链接' : 'Referral Link' }}:
			</label>
			<div class="referral-link-wrapper">
			  <input
				type="text"
				:value="promotionLink"
				readonly
				class="referral-link-input"
			  />
			  <button class="copy-btn" @click="copyPromotionLink">
				{{ isChinese ? '复制' : 'Copy' }}
			  </button>
			</div>
			<p v-if="shareSuccess" class="success">
			  {{ isChinese ? '链接已复制！' : 'Link copied!' }}
			</p>
		  </div>
		</div>
	  </div>
	</div>
</template>

<script setup>
import { ref, computed } from 'vue';
import TheHeader from './layout/TheHeader.vue';
import { useWalletStore } from '../stores/wallet';

const walletStore = useWalletStore();

const referralAddress = ref('');
const error = ref('');
const shareSuccess = ref(false);

const isChinese = computed(() => walletStore.isChinese);

const promotionLink = computed(() => {
  if (walletStore.isConnected && walletStore.walletAddress) {
    return `${window.location.origin}/?ref=${walletStore.walletAddress}`;
  }
  return '';
});

async function bindReferral() {
  try {
    if (!walletStore.isConnected) {
      await walletStore.connect();
      if (!walletStore.contract) return;
    }

    const referral = referralAddress.value.trim();
    if (!referral) {
      error.value = isChinese.value ? '请输入推荐人地址' : 'Please enter a referral address';
      return;
    }
    if (!walletStore.web3.utils.isAddress(referral)) {
      error.value = isChinese.value ? '请输入有效的推荐人地址' : 'Please enter a valid referral address';
      return;
    }
    if (referral.toLowerCase() === walletStore.walletAddress.toLowerCase()) {
      error.value = isChinese.value ? '推荐人地址不能是自己的地址' : 'Referral address cannot be your own address';
      return;
    }

    error.value = '';

    // 动态估算 gas
    const transaction = walletStore.contract.methods.bindReferrer(referral);
    try {
      const estimatedGas = await transaction.estimateGas({ from: walletStore.walletAddress });
      const gasLimit = Math.round(Number(estimatedGas) * 1.5); // 增加50%的缓冲
      console.log(`Estimated Gas: ${estimatedGas}, Gas Limit: ${gasLimit}`);

      const tx = await transaction.send({
        from: walletStore.walletAddress,
        gas: gasLimit,
      });

      console.log('Referral bound successfully:', tx);
      alert(isChinese.value ? '推荐人地址绑定成功！' : 'Referral address bound successfully!');
    } catch (estimateError) {
      console.error('Gas estimation or transaction failed:', estimateError);
      throw estimateError;
    }

  } catch (err) {
    console.error('Bind referral error:', err);
    if (err.code === 4001) {
      error.value = isChinese.value ? '用户拒绝了交易' : 'User rejected the transaction';
    } else {
      try {
        const userData = await walletStore.contract.methods.users(walletStore.walletAddress).call();
        const boundReferrer = userData.referrer;
        if (boundReferrer !== '0x0000000000000000000000000000000000000000') {
            const shortAddr = `${boundReferrer.slice(0, 6)}...${boundReferrer.slice(-4)}`;
            error.value = isChinese.value
            ? `绑定失败，推荐人已绑定为 ${shortAddr}`
            : `Failed to bind, referrer already bound to ${shortAddr}`;
        } else {
            error.value = isChinese.value ? `绑定失败: ${err.message}` : `Failed to bind: ${err.message}`;
        }
      } catch (fetchError) {
        error.value = isChinese.value ? `绑定失败: ${err.message}` : `Failed to bind: ${err.message}`;
      }
    }
  }
}

function copyPromotionLink() {
    if (!promotionLink.value) {
        alert(isChinese.value ? '请先连接钱包以生成推广链接' : 'Please connect wallet to generate promotion link');
        return;
    }
    navigator.clipboard.writeText(promotionLink.value).then(() => {
        shareSuccess.value = true;
        setTimeout(() => {
            shareSuccess.value = false;
        }, 2000);
    }).catch(err => {
        console.error('复制链接失败:', err);
        alert(isChinese.value ? '复制链接失败' : 'Failed to copy link');
    });
}
</script>

<style scoped>
/* 全局样式 */
.bind-wallet-page {
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

/* NEAR 背景图片 */
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

/* 绑定地址部分 */
.bind-section {
	background: white;
	padding: 35px;
	border-radius: 16px;
	box-shadow: 0 8px 25px rgba(0, 0, 0, 0.1);
	width: 100%;
	max-width: 550px;
	text-align: center;
	transform: translateY(-30px);
	z-index: 2;
}

.section-header {
	font-size: 28px;
	font-weight: 600;
	color: var(--primary-color, #00C08B);
	margin-bottom: 25px;
	letter-spacing: 1px;
	animation: fadeIn 0.5s ease-in;
}

.bind-content {
	display: flex;
	flex-direction: column;
	align-items: center;
	gap: 25px;
}

.referral-input {
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
}

.referral-input:focus {
	background: white;
	box-shadow: 0 4px 15px rgba(0, 192, 139, 0.2);
	transform: scale(1.02);
}

.referral-input::placeholder {
	color: #aaa;
}

.bind-btn {
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

.bind-btn:hover {
	transform: translateY(-4px);
	box-shadow: 0 8px 20px rgba(0, 192, 139, 0.5);
	background: linear-gradient(135deg, #00a070 0%, #008c5e 100%);
}

.bind-btn:active {
	transform: translateY(2px);
	box-shadow: 0 3px 10px rgba(0, 192, 139, 0.2);
}

.error {
	color: #e74c3c;
	font-size: 14px;
	margin-top: 15px;
	animation: fadeIn 0.3s ease-in;
}

/* 推荐人链接部分 */
.referral-link-container {
	width: 100%;
	margin-top: 20px;
	text-align: left;
}

.referral-link-label {
	display: block;
	margin-bottom: 8px;
	font-size: 16px;
	font-weight: 600;
	color: #333;
}

.referral-link-wrapper {
	display: flex;
	align-items: center;
}

.referral-link-input {
	flex: 1;
	padding: 10px 15px;
	border: 1px solid #ddd;
	border-radius: 8px;
	font-size: 15px;
	background: #f5f5f5;
	color: #555;
	margin-right: 10px;
}

.copy-btn {
	padding: 10px 20px;
	background: linear-gradient(135deg, #00C08B 0%, #00a070 100%);
	color: white;
	border: none;
	border-radius: 8px;
	font-size: 15px;
	cursor: pointer;
	transition: background 0.3s, transform 0.2s;
}

.copy-btn:hover {
	transform: translateY(-2px);
	background: linear-gradient(135deg, #00a070 0%, #008c5e 100%);
}

.success {
	color: #27ae60;
	font-size: 14px;
	margin-top: 10px;
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
	.bind-wallet-page {
	  padding: 20px;
	}

	.background-image {
	  height: 200px;
	  margin-bottom: 30px;
	}

	.bind-section {
	  padding: 20px;
	  max-width: 100%;
	  transform: none;
	}

	.section-header {
	  font-size: 24px;
	}

	.referral-input, .referral-link-input {
	  max-width: 100%;
	}

	.bind-btn, .copy-btn {
	  max-width: 100%;
	  padding: 12px;
	  font-size: 16px;
	}

	.error, .success {
	  font-size: 12px;
	}
}

@media (max-width: 360px) {
	.section-header {
	  font-size: 20px;
	}

	.referral-input, .referral-link-input {
	  padding: 10px;
	  font-size: 14px;
	}

	.bind-btn, .copy-btn {
	  padding: 10px;
	  font-size: 14px;
	}
}
</style>