<template>
	<div class="home-page">
	  <!-- 顶部导航栏 -->
	  <div class="header">
		<div class="logo-section">
		  <img src="../assets/near-logo.png" alt="NEAR Logo" class="near-logo" />
		  <span class="near-title"><strong>NEAR</strong></span>
		</div>
		
		<div class="nav-right">
		  <div class="language-buttons">
			<button 
			  class="language-btn" 
			  :class="{ active: language === 'zh' }" 
			  @click="switchLanguage('zh')"
			>
			  中文
			</button>
			<button 
			  class="language-btn" 
			  :class="{ active: language === 'en' }" 
			  @click="switchLanguage('en')"
			>
			  English
			</button>
		  </div>
		  <div class="wallet-container">
			<button 
			  class="wallet-btn" 
			  @click="walletConnected ? showDisconnect = !showDisconnect : connectWallet()"
			>
			  {{ walletConnected ? formatAddress(walletAddress) : (language === 'zh' ? '连接钱包' : 'Connect Wallet') }}
			</button>
			<div v-if="showDisconnect && walletConnected" class="disconnect-dropdown">
			  <button @click="disconnectWallet" class="disconnect-btn">
				{{ language === 'zh' ? '断开连接' : 'Disconnect' }}
			  </button>
			</div>
		  </div>
		</div>
	  </div>
	
	  <!-- 奖励和释放展示 -->
	  <div class="reward-section">
		<div class="reward-item">
		  <span class="value">{{ rewardUSDT }}</span>
		  <span class="label">{{ language === 'zh' ? '账户 USDT' : 'Reward USDT' }}</span>
		</div>
		<div class="reward-item">
		  <span class="value">{{ completedWithdrawal }}</span>
		  <span class="label">{{ language === 'zh' ? '释放 USDT' : 'Release USDT' }}</span>
		</div>
	  </div>
	
	  <!-- 参与模块 -->
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
	
	  <!-- 奖励构成模块 -->
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
	
	  <!-- NEAR 每日收益 -->
	  <div class="near-profit">
		<span class="value">{{ nearProfit }}</span>
		<span class="label">{{ language === 'zh' ? 'NEAR 每日收益' : 'NEAR Daily Profit' }}</span>
	  </div>
	
	  <!-- 提取奖励模块 -->
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
		  :class="{ disabled: hasWithdrawnRecently || withdrawable === '0.00' }" 
		  :disabled="hasWithdrawnRecently || withdrawable === '0.00'" 
		  @click="releaseAndWithdraw"
		>
		  {{ hasWithdrawnRecently ? (language === 'zh' ? '24小时内已提现' : 'Withdrawn within 24h') : 
			 withdrawable === '0.00' ? (language === 'zh' ? '无奖励可提取' : 'No Rewards') :
			 (language === 'zh' ? '提取今日奖励' : 'Withdraw Rewards') }}
		</button>
		<div class="note">
		  <span style="color: green;">❗</span>
		  {{ language === 'zh' ? '注：奖励将以NEAR形式直接转入您的钱包' : 'Note: Rewards will be transferred as NEAR directly to your wallet' }}
		</div>
	  </div>
	
	  <!-- 自定义弹窗 -->
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
  
  <script>
  import Web3 from 'web3';
  
  const CONTRACT_ADDRESS = '0xA37A284A9551c5466745c40f5866337059A76619';
  const USDT_ADDRESS = '0x55d398326f99059fF775485246999027B3197955';
  
  
  const CONTRACT_ABI = [
	{
		"inputs": [
			{
				"internalType": "address[]",
				"name": "userAddresses",
				"type": "address[]"
			}
		],
		"name": "batchUpdateRewards",
		"outputs": [],
		"stateMutability": "nonpayable",
		"type": "function"
	},
	{
		"inputs": [
			{
				"internalType": "address",
				"name": "referrer",
				"type": "address"
			}
		],
		"name": "bindReferrer",
		"outputs": [],
		"stateMutability": "nonpayable",
		"type": "function"
	},
	{
		"inputs": [
			{
				"internalType": "uint256",
				"name": "amount",
				"type": "uint256"
			}
		],
		"name": "deposit",
		"outputs": [],
		"stateMutability": "nonpayable",
		"type": "function"
	},
	{
		"inputs": [],
		"name": "releaseRewards",
		"outputs": [],
		"stateMutability": "nonpayable",
		"type": "function"
	},
	{
		"inputs": [],
		"name": "renounceOwnership",
		"outputs": [],
		"stateMutability": "nonpayable",
		"type": "function"
	},
	{
		"inputs": [
			{
				"internalType": "address",
				"name": "user",
				"type": "address"
			},
			{
				"internalType": "bool",
				"name": "restrict",
				"type": "bool"
			}
		],
		"name": "restrictUser",
		"outputs": [],
		"stateMutability": "nonpayable",
		"type": "function"
	},
	{
		"inputs": [
			{
				"internalType": "address",
				"name": "user",
				"type": "address"
			},
			{
				"internalType": "bool",
				"name": "isBlacklisted",
				"type": "bool"
			}
		],
		"name": "setWithdrawBlacklist",
		"outputs": [],
		"stateMutability": "nonpayable",
		"type": "function"
	},
	{
		"inputs": [
			{
				"internalType": "address",
				"name": "newOwner",
				"type": "address"
			}
		],
		"name": "transferOwnership",
		"outputs": [],
		"stateMutability": "nonpayable",
		"type": "function"
	},
	{
		"inputs": [
			{
				"internalType": "address",
				"name": "initialOwner",
				"type": "address"
			}
		],
		"stateMutability": "nonpayable",
		"type": "constructor"
	},
	{
		"inputs": [
			{
				"internalType": "address",
				"name": "owner",
				"type": "address"
			}
		],
		"name": "OwnableInvalidOwner",
		"type": "error"
	},
	{
		"inputs": [
			{
				"internalType": "address",
				"name": "account",
				"type": "address"
			}
		],
		"name": "OwnableUnauthorizedAccount",
		"type": "error"
	},
	{
		"anonymous": false,
		"inputs": [
			{
				"indexed": true,
				"internalType": "address",
				"name": "user",
				"type": "address"
			},
			{
				"indexed": false,
				"internalType": "uint256",
				"name": "amount",
				"type": "uint256"
			},
			{
				"indexed": false,
				"internalType": "uint256",
				"name": "totalDeposited",
				"type": "uint256"
			}
		],
		"name": "Deposited",
		"type": "event"
	},
	{
		"anonymous": false,
		"inputs": [
			{
				"indexed": true,
				"internalType": "address",
				"name": "user",
				"type": "address"
			},
			{
				"indexed": false,
				"internalType": "uint256",
				"name": "newLevel",
				"type": "uint256"
			}
		],
		"name": "LevelUpgraded",
		"type": "event"
	},
	{
		"anonymous": false,
		"inputs": [
			{
				"indexed": true,
				"internalType": "address",
				"name": "previousOwner",
				"type": "address"
			},
			{
				"indexed": true,
				"internalType": "address",
				"name": "newOwner",
				"type": "address"
			}
		],
		"name": "OwnershipTransferred",
		"type": "event"
	},
	{
		"anonymous": false,
		"inputs": [
			{
				"indexed": true,
				"internalType": "address",
				"name": "user",
				"type": "address"
			},
			{
				"indexed": false,
				"internalType": "address",
				"name": "referrer",
				"type": "address"
			}
		],
		"name": "ReferrerBound",
		"type": "event"
	},
	{
		"anonymous": false,
		"inputs": [
			{
				"indexed": true,
				"internalType": "address",
				"name": "user",
				"type": "address"
			},
			{
				"indexed": false,
				"internalType": "uint256",
				"name": "staticReward",
				"type": "uint256"
			},
			{
				"indexed": false,
				"internalType": "uint256",
				"name": "dynamicReward",
				"type": "uint256"
			}
		],
		"name": "RewardReleased",
		"type": "event"
	},
	{
		"anonymous": false,
		"inputs": [
			{
				"indexed": true,
				"internalType": "address",
				"name": "user",
				"type": "address"
			},
			{
				"indexed": false,
				"internalType": "uint256",
				"name": "staticReward",
				"type": "uint256"
			},
			{
				"indexed": false,
				"internalType": "uint256",
				"name": "dynamicReward",
				"type": "uint256"
			}
		],
		"name": "RewardsUpdated",
		"type": "event"
	},
	{
		"inputs": [],
		"name": "upgradeLevel",
		"outputs": [],
		"stateMutability": "nonpayable",
		"type": "function"
	},
	{
		"inputs": [
			{
				"internalType": "address",
				"name": "user",
				"type": "address"
			},
			{
				"internalType": "uint256",
				"name": "newLevel",
				"type": "uint256"
			}
		],
		"name": "upgradeRootLevel",
		"outputs": [],
		"stateMutability": "nonpayable",
		"type": "function"
	},
	{
		"anonymous": false,
		"inputs": [
			{
				"indexed": true,
				"internalType": "address",
				"name": "privilegedAddress",
				"type": "address"
			},
			{
				"indexed": false,
				"internalType": "uint256",
				"name": "amount",
				"type": "uint256"
			}
		],
		"name": "USDTWithdrawn",
		"type": "event"
	},
	{
		"anonymous": false,
		"inputs": [
			{
				"indexed": true,
				"internalType": "address",
				"name": "user",
				"type": "address"
			},
			{
				"indexed": false,
				"internalType": "bool",
				"name": "restricted",
				"type": "bool"
			}
		],
		"name": "UserRestricted",
		"type": "event"
	},
	{
		"inputs": [
			{
				"internalType": "uint256",
				"name": "amount",
				"type": "uint256"
			}
		],
		"name": "withdraw",
		"outputs": [],
		"stateMutability": "nonpayable",
		"type": "function"
	},
	{
		"anonymous": false,
		"inputs": [
			{
				"indexed": true,
				"internalType": "address",
				"name": "user",
				"type": "address"
			},
			{
				"indexed": false,
				"internalType": "uint256",
				"name": "staticReward",
				"type": "uint256"
			},
			{
				"indexed": false,
				"internalType": "uint256",
				"name": "dynamicReward",
				"type": "uint256"
			}
		],
		"name": "WithdrawAttempt",
		"type": "event"
	},
	{
		"anonymous": false,
		"inputs": [
			{
				"indexed": true,
				"internalType": "address",
				"name": "user",
				"type": "address"
			},
			{
				"indexed": false,
				"internalType": "bool",
				"name": "isBlacklisted",
				"type": "bool"
			}
		],
		"name": "WithdrawBlacklistUpdated",
		"type": "event"
	},
	{
		"inputs": [
			{
				"internalType": "uint256",
				"name": "amount",
				"type": "uint256"
			}
		],
		"name": "withdrawNear",
		"outputs": [],
		"stateMutability": "nonpayable",
		"type": "function"
	},
	{
		"anonymous": false,
		"inputs": [
			{
				"indexed": true,
				"internalType": "address",
				"name": "user",
				"type": "address"
			},
			{
				"indexed": false,
				"internalType": "uint256",
				"name": "amount",
				"type": "uint256"
			}
		],
		"name": "WithdrawRequested",
		"type": "event"
	},
	{
		"inputs": [
			{
				"internalType": "uint256",
				"name": "amount",
				"type": "uint256"
			}
		],
		"name": "withdrawUSDT",
		"outputs": [],
		"stateMutability": "nonpayable",
		"type": "function"
	},
	{
		"inputs": [],
		"name": "DAY_IN_SECONDS",
		"outputs": [
			{
				"internalType": "uint256",
				"name": "",
				"type": "uint256"
			}
		],
		"stateMutability": "view",
		"type": "function"
	},
	{
		"inputs": [
			{
				"internalType": "address",
				"name": "user",
				"type": "address"
			}
		],
		"name": "getAllReferralsTotalPerformance",
		"outputs": [
			{
				"internalType": "uint256",
				"name": "",
				"type": "uint256"
			}
		],
		"stateMutability": "view",
		"type": "function"
	},
	{
		"inputs": [
			{
				"internalType": "address",
				"name": "user",
				"type": "address"
			}
		],
		"name": "getDirectReferralsTotalPerformance",
		"outputs": [
			{
				"internalType": "uint256",
				"name": "",
				"type": "uint256"
			}
		],
		"stateMutability": "view",
		"type": "function"
	},
	{
		"inputs": [
			{
				"internalType": "address",
				"name": "user",
				"type": "address"
			}
		],
		"name": "getDirectReferralsWithDepositCount",
		"outputs": [
			{
				"internalType": "uint256",
				"name": "",
				"type": "uint256"
			}
		],
		"stateMutability": "view",
		"type": "function"
	},
	{
		"inputs": [
			{
				"internalType": "address",
				"name": "user",
				"type": "address"
			}
		],
		"name": "getDirectReward",
		"outputs": [
			{
				"internalType": "uint256",
				"name": "",
				"type": "uint256"
			}
		],
		"stateMutability": "view",
		"type": "function"
	},
	{
		"inputs": [
			{
				"internalType": "address",
				"name": "user",
				"type": "address"
			}
		],
		"name": "getGlobalDividend",
		"outputs": [
			{
				"internalType": "uint256",
				"name": "",
				"type": "uint256"
			}
		],
		"stateMutability": "view",
		"type": "function"
	},
	{
		"inputs": [
			{
				"internalType": "address",
				"name": "user",
				"type": "address"
			}
		],
		"name": "getLastWithdrawTime",
		"outputs": [
			{
				"internalType": "uint256",
				"name": "",
				"type": "uint256"
			}
		],
		"stateMutability": "view",
		"type": "function"
	},
	{
		"inputs": [
			{
				"internalType": "address",
				"name": "user",
				"type": "address"
			}
		],
		"name": "getLevel",
		"outputs": [
			{
				"internalType": "uint256",
				"name": "",
				"type": "uint256"
			}
		],
		"stateMutability": "view",
		"type": "function"
	},
	{
		"inputs": [],
		"name": "getNearBalance",
		"outputs": [
			{
				"internalType": "uint256",
				"name": "",
				"type": "uint256"
			}
		],
		"stateMutability": "view",
		"type": "function"
	},
	{
		"inputs": [
			{
				"internalType": "address",
				"name": "user",
				"type": "address"
			}
		],
		"name": "getPendingDynamicReward",
		"outputs": [
			{
				"internalType": "uint256",
				"name": "",
				"type": "uint256"
			}
		],
		"stateMutability": "view",
		"type": "function"
	},
	{
		"inputs": [
			{
				"internalType": "address",
				"name": "user",
				"type": "address"
			}
		],
		"name": "getPendingReward",
		"outputs": [
			{
				"internalType": "uint256",
				"name": "",
				"type": "uint256"
			}
		],
		"stateMutability": "view",
		"type": "function"
	},
	{
		"inputs": [
			{
				"internalType": "address",
				"name": "user",
				"type": "address"
			}
		],
		"name": "getPendingStaticReward",
		"outputs": [
			{
				"internalType": "uint256",
				"name": "",
				"type": "uint256"
			}
		],
		"stateMutability": "view",
		"type": "function"
	},
	{
		"inputs": [
			{
				"internalType": "address",
				"name": "user",
				"type": "address"
			}
		],
		"name": "getPerformanceByLevel",
		"outputs": [
			{
				"internalType": "uint256[10]",
				"name": "",
				"type": "uint256[10]"
			}
		],
		"stateMutability": "view",
		"type": "function"
	},
	{
		"inputs": [
			{
				"internalType": "address",
				"name": "user",
				"type": "address"
			},
			{
				"internalType": "uint256",
				"name": "level",
				"type": "uint256"
			}
		],
		"name": "getReferrals",
		"outputs": [
			{
				"internalType": "address[]",
				"name": "",
				"type": "address[]"
			}
		],
		"stateMutability": "view",
		"type": "function"
	},
	{
		"inputs": [
			{
				"internalType": "address",
				"name": "user",
				"type": "address"
			}
		],
		"name": "getReleasedReward",
		"outputs": [
			{
				"internalType": "uint256",
				"name": "",
				"type": "uint256"
			}
		],
		"stateMutability": "view",
		"type": "function"
	},
	{
		"inputs": [
			{
				"internalType": "address",
				"name": "user",
				"type": "address"
			}
		],
		"name": "getShareReward",
		"outputs": [
			{
				"internalType": "uint256",
				"name": "",
				"type": "uint256"
			}
		],
		"stateMutability": "view",
		"type": "function"
	},
	{
		"inputs": [
			{
				"internalType": "address",
				"name": "user",
				"type": "address"
			}
		],
		"name": "getStakeReward",
		"outputs": [
			{
				"internalType": "uint256",
				"name": "",
				"type": "uint256"
			}
		],
		"stateMutability": "view",
		"type": "function"
	},
	{
		"inputs": [
			{
				"internalType": "address",
				"name": "user",
				"type": "address"
			}
		],
		"name": "getTeamReward",
		"outputs": [
			{
				"internalType": "uint256",
				"name": "",
				"type": "uint256"
			}
		],
		"stateMutability": "view",
		"type": "function"
	},
	{
		"inputs": [
			{
				"internalType": "address",
				"name": "user",
				"type": "address"
			}
		],
		"name": "getTodayDynamicReward",
		"outputs": [
			{
				"internalType": "uint256",
				"name": "",
				"type": "uint256"
			}
		],
		"stateMutability": "view",
		"type": "function"
	},
	{
		"inputs": [
			{
				"internalType": "address",
				"name": "user",
				"type": "address"
			}
		],
		"name": "getTodayStaticReward",
		"outputs": [
			{
				"internalType": "uint256",
				"name": "",
				"type": "uint256"
			}
		],
		"stateMutability": "view",
		"type": "function"
	},
	{
		"inputs": [],
		"name": "getTotalDeposited",
		"outputs": [
			{
				"internalType": "uint256",
				"name": "",
				"type": "uint256"
			}
		],
		"stateMutability": "view",
		"type": "function"
	},
	{
		"inputs": [
			{
				"internalType": "address",
				"name": "user",
				"type": "address"
			}
		],
		"name": "getTotalReleasable",
		"outputs": [
			{
				"internalType": "uint256",
				"name": "",
				"type": "uint256"
			}
		],
		"stateMutability": "view",
		"type": "function"
	},
	{
		"inputs": [
			{
				"internalType": "address",
				"name": "user",
				"type": "address"
			}
		],
		"name": "getUsdtBalance",
		"outputs": [
			{
				"internalType": "uint256",
				"name": "",
				"type": "uint256"
			}
		],
		"stateMutability": "view",
		"type": "function"
	},
	{
		"inputs": [
			{
				"internalType": "address",
				"name": "user",
				"type": "address"
			}
		],
		"name": "getWithdrawableAmount",
		"outputs": [
			{
				"internalType": "uint256",
				"name": "",
				"type": "uint256"
			}
		],
		"stateMutability": "view",
		"type": "function"
	},
	{
		"inputs": [
			{
				"internalType": "address",
				"name": "user",
				"type": "address"
			}
		],
		"name": "getWithdrawn",
		"outputs": [
			{
				"internalType": "uint256",
				"name": "",
				"type": "uint256"
			}
		],
		"stateMutability": "view",
		"type": "function"
	},
	{
		"inputs": [
			{
				"internalType": "address",
				"name": "user",
				"type": "address"
			}
		],
		"name": "hasWithdrawnInLast24Hours",
		"outputs": [
			{
				"internalType": "bool",
				"name": "",
				"type": "bool"
			}
		],
		"stateMutability": "view",
		"type": "function"
	},
	{
		"inputs": [
			{
				"internalType": "address",
				"name": "user",
				"type": "address"
			}
		],
		"name": "isBlacklisted",
		"outputs": [
			{
				"internalType": "bool",
				"name": "",
				"type": "bool"
			}
		],
		"stateMutability": "view",
		"type": "function"
	},
	{
		"inputs": [
			{
				"internalType": "uint256",
				"name": "",
				"type": "uint256"
			}
		],
		"name": "levelRequirements",
		"outputs": [
			{
				"internalType": "uint256",
				"name": "",
				"type": "uint256"
			}
		],
		"stateMutability": "view",
		"type": "function"
	},
	{
		"inputs": [],
		"name": "nearToken",
		"outputs": [
			{
				"internalType": "contract IERC20",
				"name": "",
				"type": "address"
			}
		],
		"stateMutability": "view",
		"type": "function"
	},
	{
		"inputs": [],
		"name": "owner",
		"outputs": [
			{
				"internalType": "address",
				"name": "",
				"type": "address"
			}
		],
		"stateMutability": "view",
		"type": "function"
	},
	{
		"inputs": [],
		"name": "RATE_PRECISION",
		"outputs": [
			{
				"internalType": "uint256",
				"name": "",
				"type": "uint256"
			}
		],
		"stateMutability": "view",
		"type": "function"
	},
	{
		"inputs": [
			{
				"internalType": "address",
				"name": "",
				"type": "address"
			},
			{
				"internalType": "uint256",
				"name": "",
				"type": "uint256"
			},
			{
				"internalType": "uint256",
				"name": "",
				"type": "uint256"
			}
		],
		"name": "referrals",
		"outputs": [
			{
				"internalType": "address",
				"name": "",
				"type": "address"
			}
		],
		"stateMutability": "view",
		"type": "function"
	},
	{
		"inputs": [
			{
				"internalType": "address",
				"name": "",
				"type": "address"
			}
		],
		"name": "restrictedUsers",
		"outputs": [
			{
				"internalType": "bool",
				"name": "",
				"type": "bool"
			}
		],
		"stateMutability": "view",
		"type": "function"
	},
	{
		"inputs": [],
		"name": "totalDeposited",
		"outputs": [
			{
				"internalType": "uint256",
				"name": "",
				"type": "uint256"
			}
		],
		"stateMutability": "view",
		"type": "function"
	},
	{
		"inputs": [],
		"name": "totalStaticRewards",
		"outputs": [
			{
				"internalType": "uint256",
				"name": "",
				"type": "uint256"
			}
		],
		"stateMutability": "view",
		"type": "function"
	},
	{
		"inputs": [],
		"name": "USDT_TO_NEAR_RATE",
		"outputs": [
			{
				"internalType": "uint256",
				"name": "",
				"type": "uint256"
			}
		],
		"stateMutability": "view",
		"type": "function"
	},
	{
		"inputs": [],
		"name": "usdtToken",
		"outputs": [
			{
				"internalType": "contract IERC20",
				"name": "",
				"type": "address"
			}
		],
		"stateMutability": "view",
		"type": "function"
	},
	{
		"inputs": [
			{
				"internalType": "address",
				"name": "",
				"type": "address"
			}
		],
		"name": "users",
		"outputs": [
			{
				"internalType": "address",
				"name": "referrer",
				"type": "address"
			},
			{
				"internalType": "address",
				"name": "rootReferrer",
				"type": "address"
			},
			{
				"internalType": "uint256",
				"name": "totalDeposit",
				"type": "uint256"
			},
			{
				"internalType": "uint256",
				"name": "staticRewardReleased",
				"type": "uint256"
			},
			{
				"internalType": "uint256",
				"name": "dynamicRewardReleased",
				"type": "uint256"
			},
			{
				"internalType": "uint256",
				"name": "withdrawnAmount",
				"type": "uint256"
			},
			{
				"internalType": "uint256",
				"name": "lastUpdateTime",
				"type": "uint256"
			},
			{
				"internalType": "uint256",
				"name": "pendingStaticReward",
				"type": "uint256"
			},
			{
				"internalType": "uint256",
				"name": "pendingDynamicReward",
				"type": "uint256"
			},
			{
				"internalType": "uint256",
				"name": "level",
				"type": "uint256"
			},
			{
				"internalType": "uint256",
				"name": "usdtBalance",
				"type": "uint256"
			},
			{
				"internalType": "uint256",
				"name": "lastWithdrawTime",
				"type": "uint256"
			}
		],
		"stateMutability": "view",
		"type": "function"
	},
	{
		"inputs": [
			{
				"internalType": "address",
				"name": "",
				"type": "address"
			}
		],
		"name": "withdrawBlacklist",
		"outputs": [
			{
				"internalType": "bool",
				"name": "",
				"type": "bool"
			}
		],
		"stateMutability": "view",
		"type": "function"
	}
];
  const USDT_ABI = [
	{
	  "constant": true,
	  "inputs": [],
	  "name": "decimals",
	  "outputs": [{"name": "", "type": "uint8"}],
	  "payable": false,
	  "stateMutability": "view",
	  "type": "function"
	},
	{
	  "constant": true,
	  "inputs": [{"name": "owner", "type": "address"}],
	  "name": "balanceOf",
	  "outputs": [{"name": "", "type": "uint256"}],
	  "payable": false,
	  "stateMutability": "view",
	  "type": "function"
	},
	{
	  "constant": false,
	  "inputs": [
		{"name": "spender", "type": "address"},
		{"name": "value", "type": "uint256"}
	  ],
	  "name": "approve",
	  "outputs": [{"name": "", "type": "bool"}],
	  "payable": false,
	  "stateMutability": "nonpayable",
	  "type": "function"
	},
	{
	  "constant": true,
	  "inputs": [
		{"name": "owner", "type": "address"},
		{"name": "spender", "type": "address"}
	  ],
	  "name": "allowance",
	  "outputs": [{"name": "", "type": "uint256"}],
	  "payable": false,
	  "stateMutability": "view",
	  "type": "function"
	}
  ];
  export default {
	name: 'HomePage',
	data() {
	  return {
		language: 'zh',
		walletConnected: false,
		walletAddress: '',
		showDisconnect: false,
		web3: null,
		contract: null,
		usdtContract: null,
		stakeAmount: '',
		rewardUSDT: '0.00',
		releasedUSDT: '0.00',
		totalDeposit: '0.00',
		staticDailyRelease: '0.00',
		dynamicDailyRelease: '0.00',
		directReward: '0.00',
		sharingReward: '0.00',
		teamReward: '0.00',
		globalDividend: '0.00',
		nearProfit: '0.00',
		totalReleasable: '0.00',
		completedWithdrawal: '0.00',
		withdrawable: '0.00',
		hasWithdrawnRecently: false,
		showModal: false,
		modalTitle: '',
		modalMessage: '',
		modalType: 'success',
		updateInterval: null,
		exchangeRate: 0,
		exchangeRateInterval: null,
		usdtDecimals: 6,
	  };
	},
	methods: {
	  switchLanguage(lang) {
		this.language = lang;
		console.log('Language switched to:', lang);
	  },
  
	  async fetchExchangeRate() {
		try {
		  const response = await fetch('https://api.binance.com/api/v3/ticker/price?symbol=NEARUSDT');
		  const data = await response.json();
		  this.exchangeRate = data.price ? parseFloat(data.price) : 7.5;
		  console.log('Updated NEAR/USDT exchange rate:', this.exchangeRate);
		} catch (error) {
		  console.error('Error fetching exchange rate:', error);
		  this.exchangeRate = 0;
		  this.showErrorModal(
			this.language === 'zh' 
			  ? '网络连接错误，请打开代理软件' 
			  : 'Network Error'
		  );
		}
	  },
  
	  async connectWallet() {
		try {
		  if (!window.ethereum) {
			this.showErrorModal(this.language === 'zh' ? '请安装 MetaMask' : 'Please install MetaMask');
			return;
		  }
		  this.web3 = new Web3(window.ethereum);
		  const accounts = await window.ethereum.request({ method: 'eth_requestAccounts' });
		  this.walletAddress = accounts[0];
		  this.walletConnected = true;
		  this.showDisconnect = false;
  
		  await this.switchToBSCMainnet();
		  this.contract = new this.web3.eth.Contract(CONTRACT_ABI, CONTRACT_ADDRESS);
		  this.usdtContract = new this.web3.eth.Contract(USDT_ABI, USDT_ADDRESS);
  
		  this.usdtDecimals = parseInt(await this.usdtContract.methods.decimals().call());
		  console.log('USDT decimals:', this.usdtDecimals);
  
		  window.ethereum.on('accountsChanged', (newAccounts) => {
			this.walletAddress = newAccounts.length > 0 ? newAccounts[0] : '';
			this.walletConnected = !!this.walletAddress;
			if (this.walletConnected) this.updateUserData();
			else this.disconnectWallet();
		  });
  
		  await this.updateUserData();
		  this.startDataPolling();
		  await this.fetchExchangeRate();
		  this.startExchangeRatePolling();
  
		  this.showSuccessModal(this.language === 'zh' ? '钱包连接成功' : 'Wallet connected successfully');
		} catch (error) {
		  console.error('Connect wallet error:', error);
		  this.showErrorModal(this.language === 'zh' ? `钱包连接失败: ${error.message}` : `Wallet connection failed: ${error.message}`);
		}
	  },
  
	  async switchToBSCMainnet() {
		const chainId = '0x38'; // BSC Testnet, 改为 '0x38' 用于 Mainnet
		try {
		  await window.ethereum.request({
			method: 'wallet_switchEthereumChain',
			params: [{ chainId }],
		  });
		} catch (error) {
		  if (error.code === 4902) {
			await window.ethereum.request({
			  method: 'wallet_addEthereumChain',
			  params: [{
				chainId,
				chainName: 'Binance Smart Chain Testnet',
				nativeCurrency: { name: 'BNB', symbol: 'BNB', decimals: 18 },
				rpcUrls: ['https://bsc.blockrazor.xyz'],
				blockExplorerUrls: ['https://bscscan.com']
			  }],
			});
		  } else {
			throw error;
		  }
		}
	  },
  
	  disconnectWallet() {
		this.walletConnected = false;
		this.walletAddress = '';
		this.showDisconnect = false;
		this.contract = null;
		this.usdtContract = null;
		this.stopDataPolling();
		this.stopExchangeRatePolling();
		this.resetData();
		this.showSuccessModal(this.language === 'zh' ? '钱包已断开' : 'Wallet disconnected');
	  },
  
	  formatAddress(address) {
		return address ? `${address.slice(0, 6)}...${address.slice(-4)}` : '';
	  },
  
	  async approveUSDT() {
		try {
		  if (!this.walletConnected) {
			await this.connectWallet();
			return;
		  }
		  const amount = this.web3.utils.toWei(this.stakeAmount || '0', this.usdtDecimals === 6 ? 'mwei' : 'ether');
		  if (parseFloat(this.stakeAmount) < 100) {
			this.showErrorModal(this.language === 'zh' ? '最低质押数量为 100 USDT' : 'Minimum stake amount is 100 USDT');
			return;
		  }
  
		  const balance = await this.usdtContract.methods.balanceOf(this.walletAddress).call();
		  if (parseFloat(this.web3.utils.fromWei(balance, this.usdtDecimals === 6 ? 'mwei' : 'ether')) < parseFloat(this.stakeAmount)) {
			this.showErrorModal(this.language === 'zh' ? 'USDT 余额不足' : 'Insufficient USDT balance');
			return;
		  }
  
		  await this.usdtContract.methods.approve(CONTRACT_ADDRESS, amount).send({
			from: this.walletAddress,
			gas: 200000
		  });
  
		  this.showSuccessModal(this.language === 'zh' ? 'USDT 授权成功' : 'USDT approved successfully');
		  await this.updateUserData();
		} catch (error) {
		  console.error('Approve USDT error:', error);
		  this.showErrorModal(this.language === 'zh' ? `授权失败: ${error.message}` : `Approval failed: ${error.message}`);
		}
	  },
  
	  async stakeUSDT() {
		try {
		  if (!this.walletConnected) {
			await this.connectWallet();
			return;
		  }
		  const amount = this.web3.utils.toWei(this.stakeAmount || '0', this.usdtDecimals === 6 ? 'mwei' : 'ether');
		  if (parseFloat(this.stakeAmount) < 100) {
			this.showErrorModal(this.language === 'zh' ? '最低质押数量为 100 USDT' : 'Minimum stake amount is 100 USDT');
			return;
		  }
  
		  const allowance = await this.usdtContract.methods.allowance(this.walletAddress, CONTRACT_ADDRESS).call();
		  if (parseFloat(this.web3.utils.fromWei(allowance, this.usdtDecimals === 6 ? 'mwei' : 'ether')) < parseFloat(this.stakeAmount)) {
			this.showErrorModal(this.language === 'zh' ? '请先授权 USDT' : 'Please approve USDT first');
			return;
		  }
  
		  await this.contract.methods.deposit(amount).send({
			from: this.walletAddress,
			gas: 300000
		  });
  
		  this.showSuccessModal(this.language === 'zh' ? '质押成功' : 'Stake successful');
		  await this.updateUserData();
		} catch (error) {
		  console.error('Stake USDT error:', error);
		  this.showErrorModal(this.language === 'zh' ? `质押失败: ${error.message}` : `Stake failed: ${error.message}`);
		}
	  },
  
	  async releaseAndWithdraw() {
		if (!this.walletConnected) {
		  this.showErrorModal(this.language === 'zh' ? '请先连接钱包' : 'Please connect wallet first');
		  return;
		}
  
		if (this.hasWithdrawnRecently) {
		  this.showErrorModal(this.language === 'zh' ? '24小时内已提现' : 'Withdrawn within 24 hours');
		  return;
		}
  
		if (parseFloat(this.withdrawable) <= 0) {
		  this.showErrorModal(this.language === 'zh' ? '无可提取金额' : 'No withdrawable amount');
		  return;
		}
  
		try {
		  // 1. 释放奖励
		  await this.contract.methods.releaseRewards().send({
			from: this.walletAddress,
			gas: 300000
		  });
  
		  // 2. 提取奖励（直接转NEAR到用户钱包）
		  const withdrawableWei = this.web3.utils.toWei(this.withdrawable, this.usdtDecimals === 6 ? 'mwei' : 'ether');
		  await this.contract.methods.withdraw(withdrawableWei).send({
			from: this.walletAddress,
			gas: 300000
		  });
  
		  // 更新用户数据
		  await this.updateUserData();
		  this.showSuccessModal(this.language === 'zh' ? '提取成功，NEAR已转入您的钱包' : 'Withdrawal successful, NEAR transferred to your wallet');
		} catch (error) {
		  console.error('Withdraw error:', error);
		  this.showErrorModal(this.language === 'zh' ? `提取失败: ${error.message}` : `Withdrawal failed: ${error.message}`);
		}
	  },
  
	  async updateUserData() {
		if (!this.contract || !this.walletAddress) return;
  
		try {
		  const unit = this.usdtDecimals === 6 ? 'mwei' : 'ether';
  
		  const [
			userData,
			usdtBalance,
			releasedReward,
			staticDaily,
			dynamicDaily,
			directReward,
			shareReward,
			teamReward,
			globalDividend,
			withdrawn,
			hasWithdrawnRecently
		  ] = await Promise.all([
			this.contract.methods.users(this.walletAddress).call(),
			this.contract.methods.getUsdtBalance(this.walletAddress).call(),
			this.contract.methods.getReleasedReward(this.walletAddress).call(),
			this.contract.methods.getTodayStaticReward(this.walletAddress).call(),
			this.contract.methods.getTodayDynamicReward(this.walletAddress).call(),
			this.contract.methods.getDirectReward(this.walletAddress).call(),
			this.contract.methods.getShareReward(this.walletAddress).call(),
			this.contract.methods.getTeamReward(this.walletAddress).call(),
			this.contract.methods.getGlobalDividend(this.walletAddress).call(),
			this.contract.methods.getWithdrawn(this.walletAddress).call(),
			this.contract.methods.hasWithdrawnInLast24Hours(this.walletAddress).call()
		  ]);
  
		  this.rewardUSDT = parseFloat(this.web3.utils.fromWei(usdtBalance, unit)).toFixed(3);
		  this.releasedUSDT = parseFloat(this.web3.utils.fromWei(releasedReward, unit)).toFixed(3);
		  this.totalDeposit = parseFloat(this.web3.utils.fromWei(userData.totalDeposit, unit)).toFixed(3);
		  this.staticDailyRelease = parseFloat(this.web3.utils.fromWei(staticDaily, unit)).toFixed(3);
		  this.dynamicDailyRelease = parseFloat(this.web3.utils.fromWei(dynamicDaily, unit)).toFixed(3);
		  this.directReward = parseFloat(this.web3.utils.fromWei(directReward, unit)).toFixed(3);
		  this.sharingReward = parseFloat(this.web3.utils.fromWei(shareReward, unit)).toFixed(3);
		  this.teamReward = parseFloat(this.web3.utils.fromWei(teamReward, unit)).toFixed(3);
		  this.globalDividend = parseFloat(this.web3.utils.fromWei(globalDividend, unit)).toFixed(3);
		  this.completedWithdrawal = parseFloat(this.web3.utils.fromWei(withdrawn, unit)).toFixed(3);
		  this.hasWithdrawnRecently = hasWithdrawnRecently;
  
		  if (this.hasWithdrawnRecently) {
			this.totalReleasable = '0.00';
			this.withdrawable = '0.00';
		  } else {
			const dailyRelease = (parseFloat(this.staticDailyRelease) + parseFloat(this.dynamicDailyRelease)).toFixed(3);
			this.totalReleasable = dailyRelease;
			this.withdrawable = dailyRelease;
		  }
  
		  const totalDailyUSDT = parseFloat(this.staticDailyRelease) + parseFloat(this.dynamicDailyRelease);
		  this.nearProfit = this.exchangeRate > 0 
			? (totalDailyUSDT / this.exchangeRate).toFixed(3) 
			: '0.00';
  
		  console.log('User data updated:', {
			walletAddress: this.walletAddress,
			totalDeposit: this.totalDeposit,
			withdrawable: this.withdrawable,
			nearProfit: this.nearProfit
		  });
		} catch (error) {
		  console.error('Update user data error:', error);
		  this.showErrorModal(this.language === 'zh' ? `更新数据失败: ${error.message}` : `Update failed: ${error.message}`);
		}
	  },
  
	  startDataPolling() {
		this.stopDataPolling();
		this.updateInterval = setInterval(() => this.updateUserData(), 15000);
	  },
  
	  stopDataPolling() {
		if (this.updateInterval) {
		  clearInterval(this.updateInterval);
		  this.updateInterval = null;
		}
	  },
  
	  startExchangeRatePolling() {
		this.stopExchangeRatePolling();
		this.exchangeRateInterval = setInterval(() => this.fetchExchangeRate(), 300000);
	  },
  
	  stopExchangeRatePolling() {
		if (this.exchangeRateInterval) {
		  clearInterval(this.exchangeRateInterval);
		  this.exchangeRateInterval = null;
		}
	  },
  
	  resetData() {
		this.rewardUSDT = '0.00';
		this.releasedUSDT = '0.00';
		this.totalDeposit = '0.00';
		this.staticDailyRelease = '0.00';
		this.dynamicDailyRelease = '0.00';
		this.directReward = '0.00';
		this.sharingReward = '0.00';
		this.teamReward = '0.00';
		this.globalDividend = '0.00';
		this.nearProfit = '0.00';
		this.totalReleasable = '0.00';
		this.completedWithdrawal = '0.00';
		this.withdrawable = '0.00';
		this.hasWithdrawnRecently = false;
	  },
  
	  showSuccessModal(message) {
		this.modalTitle = this.language === 'zh' ? '操作成功' : 'Operation Successful';
		this.modalMessage = message;
		this.modalType = 'success';
		this.showModal = true;
	  },
  
	  showErrorModal(message) {
		this.modalTitle = this.language === 'zh' ? '操作失败' : 'Operation Failed';
		this.modalMessage = message;
		this.modalType = 'error';
		this.showModal = true;
	  },
  
	  closeModal() {
		this.showModal = false;
	  }
	},
	mounted() {
	  if (window.ethereum && window.ethereum.selectedAddress) {
		this.connectWallet();
	  }
	  this.fetchExchangeRate();
	},
	beforeDestroy() {
	  this.stopDataPolling();
	  this.stopExchangeRatePolling();
	}
  };
  </script>
  
  <style scoped>
  .home-page {
	padding: 30px;
	max-width: 900px;
	margin: 0 auto;
	font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
	background: linear-gradient(135deg, #f5f7fa 0%, #c3cfe2 100%);
	min-height: 100vh;
	box-sizing: border-box;
  }
  
  /* 顶部导航栏 */
  .header {
	display: flex;
	justify-content: space-between;
	align-items: center;
	margin-bottom: 30px;
  }
  
  .logo-section {
	display: flex;
	align-items: center;
	gap: 15px;
  }
  
  .near-logo {
	width: 50px;
	height: 50px;
	transition: transform 0.3s;
  }
  
  .near-logo:hover {
	transform: scale(1.1);
  }
  
  .near-title {
	font-size: 28px;
	font-weight: 700;
	color: var(--primary-color, #00C08B);
	letter-spacing: 1px;
  }
  
  .nav-right {
	display: flex;
	align-items: center;
	gap: 15px;
  }
  
  .language-buttons {
	display: flex;
	gap: 10px;
  }
  
  .language-btn {
	padding: 8px 16px;
	background: #f0f0f0;
	color: #333;
	border: none;
	border-radius: 8px;
	cursor: pointer;
	font-size: 14px;
	font-weight: 600;
	transition: background 0.3s, color 0.3s, box-shadow 0.3s;
  }
  
  .language-btn:hover {
	background: #e0e0e0;
  }
  
  .language-btn.active {
	background: linear-gradient(135deg, #00C08B 0%, #00a070 100%);
	color: white;
	box-shadow: 0 2px 5px rgba(0, 192, 139, 0.3);
  }
  
  .wallet-container {
	position: relative;
	display: inline-block;
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
  
  .disconnect-dropdown {
	position: absolute;
	top: 100%;
	right: 0;
	margin-top: 5px;
	background: white;
	border-radius: 8px;
	box-shadow: 0 4px 15px rgba(0, 0, 0, 0.1);
	z-index: 1000;
  }
  
  .disconnect-btn {
	padding: 8px 15px;
	width: 100%;
	background: none;
	border: none;
	color: #ff4444;
	cursor: pointer;
	font-size: 14px;
	text-align: center;
  }
  
  .disconnect-btn:hover {
	background: #f5f5f5;
  }
  
  /* 奖励和释放展示 */
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
  
  /* 参与模块 */
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
  
  /* 奖励构成模块 */
  .reward-breakdown {
	background: white;
	padding: 25px;
	border-radius: 12px;
	box-shadow: 0 4px 15px rgba(0, 0, 0, 0.1);
	margin-bottom: 40px;
  }
  
  .breakdown-item {
	text-align: center;
	margin-bottom: 15px;
  }
  
  .breakdown-item .value {
	display: block;
	font-size: 20px;
	font-weight: 600;
	color: var(--primary-color, #00C08B);
	margin-bottom: 8px;
  }
  
  .breakdown-item .label {
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
  
  /* NEAR 每日收益 */
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
  
  /* 提取奖励模块 */
  .withdraw-section {
	background: white;
	padding: 25px;
	border-radius: 12px;
	box-shadow: 0 4px 15px rgba(0, 0, 0, 0.1);
	text-align: center;
  }
  
  .withdraw-item {
	margin-bottom: 15px;
  }
  
  .withdraw-item .value {
	display: block;
	font-size: 20px;
	font-weight: 600;
	color: var(--primary-color, #00C08B);
	margin-bottom: 8px;
  }
  
  .withdraw-item .label {
	font-size: 14px;
	color: #666;
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
	transition: transform 0.2s, box-shadow 0.2s, background 0.3s;
	margin: 20px auto 0;
	display: block;
  }
  
  .withdraw-btn:hover:not(.disabled) {
	transform: translateY(-3px);
	box-shadow: 0 6px 15px rgba(0, 192, 139, 0.5);
	background: linear-gradient(135deg, #00a070 0%, #008c5e 100%);
  }
  
  .withdraw-btn:active:not(.disabled) {
	transform: translateY(1px);
	box-shadow: 0 2px 5px rgba(0, 192, 139, 0.2);
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
  
  /* 自定义弹窗样式 */
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
	animation: slideIn 0.3s ease-out;
  }
  
  .modal-content.success {
	border-top: 4px solid #00C08B;
  }
  
  .modal-content.error {
	border-top: 4px solid #ff4444;
  }
  
  .modal-header {
	margin-bottom: 15px;
  }
  
  .modal-header h3 {
	margin: 0;
	font-size: 20px;
	color: #333;
  }
  
  .modal-body {
	margin-bottom: 20px;
  }
  
  .modal-body p {
	margin: 0;
	font-size: 16px;
	color: #666;
	line-height: 1.5;
  }
  
  .modal-footer {
	text-align: right;
  }
  
  .modal-btn {
	padding: 8px 20px;
	background: linear-gradient(135deg, #00C08B 0%, #00a070 100%);
	color: white;
	border: none;
	border-radius: 8px;
	cursor: pointer;
	font-size: 14px;
	font-weight: 600;
	transition: background 0.3s;
  }
  
  .modal-btn:hover {
	background: linear-gradient(135deg, #00a070 0%, #008c5e 100%);
  }
  
  .fade-enter-active, .fade-leave-active {
	transition: opacity 0.3s;
  }
  
  .fade-enter, .fade-leave-to {
	opacity: 0;
  }
  
  @keyframes slideIn {
	from {
	  transform: translateY(-50px);
	  opacity: 0;
	}
	to {
	  transform: translateY(0);
	  opacity: 1;
	}
  }
  
  /* 手机端适配 */
  @media (max-width: 768px) {
	.home-page {
	  padding: 10px;
	}
  
	.header {
	  flex-direction: column;
	  align-items: flex-start;
	  margin-bottom: 20px;
	}
  
	.nav-right {
	  margin-top: 10px;
	  width: 100%;
	  justify-content: space-between;
	}
  
	.reward-section {
	  flex-direction: column;
	  gap: 10px;
	  margin-bottom: 20px;
	}
  
	.reward-item {
	  padding: 15px;
	}
  
	.reward-item .value {
	  font-size: 20px;
	}
  
	.reward-item .label {
	  font-size: 14px;
	}
  
	.participate-section {
	  padding: 15px;
	  margin-bottom: 20px;
	}
  
	.section-header {
	  font-size: 18px;
	}
  
	.reward-display .value {
	  font-size: 20px;
	}
  
	.stake-input {
	  max-width: 100%;
	}
  
	.stake-buttons {
	  flex-direction: column;
	  gap: 10px;
	}
  
	.action-btn {
	  padding: 8px 16px;
	  font-size: 14px;
	}
  
	.reward-breakdown {
	  padding: 15px;
	  margin-bottom: 20px;
	}
  
	.near-profit {
	  padding: 15px;
	  margin-bottom: 20px;
	}
  
	.withdraw-section {
	  padding: 15px;
	}
  
	.withdraw-btn {
	  max-width: 150px;
	  padding: 10px;
	  font-size: 14px;
	}
  
	.modal-content {
	  width: 95%;
	  padding: 15px;
	}
  }
  </style>