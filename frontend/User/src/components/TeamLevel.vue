<template>
	<div class="team-level-page">
	  <!-- 顶部导航栏 -->
	  <header class="header">
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
	  </header>
  
	  <!-- 全区业绩和小区业绩 -->
	  <section class="performance-section">
		<div class="performance-card">
		  <span class="value">{{ totalAreaPerformance }}</span>
		  <span class="label">{{ language === 'zh' ? '全区业绩' : 'Total Area Performance' }}</span>
		</div>
		<div class="performance-card">
		  <span class="value">{{ smallAreaPerformance }}</span>
		  <span class="label">{{ language === 'zh' ? '小区业绩(不包括团长)' : 'Small Area Performance' }}</span>
		</div>
	  </section>
  
	  <!-- 团队级别 -->
	  <section class="team-level-section">
		<h2 class="section-header">{{ language === 'zh' ? '团队级别' : 'Team Level' }}</h2>
		<div class="level-display">
		  <span class="level">V{{ teamLevel }} ({{ levelName }})</span>
		  <span class="sub-label">{{ language === 'zh' ? '我的级别' : 'My Level' }}</span>
		</div>
		<button 
		  v-if="isRootUser"
		  :class="['upgrade-btn', { 'disabled': !canUpgrade }]" 
		  :disabled="!canUpgrade" 
		  @click="upgradeLevel"
		>
		  {{ language === 'zh' ? '升级' : 'Upgrade' }}
		</button>
		<div v-else class="note">
		  <span class="icon">ℹ️</span>
		  <p>{{ language === 'zh' ? '仅团长地址可升级' : 'Only team root can upgrade' }}</p>
		</div>
		<div class="note">
		  <span class="icon">❗</span>
		  <p>{{ language === 'zh' ? '小区业绩达标后可升级' : 'Upgrade when small area performance meets target' }}</p>
		</div>
	  </section>
	</div>
  </template>
  
  <script>
  import Web3 from 'web3';
  
  const CONTRACT_ADDRESS = '0x77e480689AD623dcf02Ec328cAbe521c703A3B88';
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
  
  export default {
	name: 'TeamLevel',
	data() {
	  return {
		language: 'zh',
		walletConnected: false,
		walletAddress: '',
		showDisconnect: false,
		web3: null,
		contract: null,
		totalAreaPerformance: '0',
		smallAreaPerformance: '0',
		teamLevel: '0',
		canUpgrade: false,
		isRootUser: false
	  };
	},
	computed: {
	  levelName() {
		const levelNames = {
		  '0': { zh: '普通', en: 'Normal' },
		  '1': { zh: '初使', en: 'Initiate' },
		  '2': { zh: '晋使', en: 'Promoter' },
		  '3': { zh: '信使', en: 'Messenger' },
		  '4': { zh: '大使', en: 'Ambassador' },
		  '5': { zh: '特使', en: 'Envoy' }
		};
		return levelNames[this.teamLevel] ? levelNames[this.teamLevel][this.language] : (this.language === 'zh' ? '普通' : 'Normal');
	  }
	},
	mounted() {
	  if (this.walletConnected) {
		this.fetchContractData();
	  }
	},
	methods: {
	  switchLanguage(lang) {
		this.language = lang;
		console.log('Language switched to:', this.language);
		this.fetchContractData();
	  },
	  async connectWallet() {
		try {
		  if (typeof window.ethereum === 'undefined') {
			alert(this.language === 'zh' ? '请先安装以太坊钱包扩展（如MetaMask）' : 'Please install an Ethereum wallet extension (e.g., MetaMask)');
			return;
		  }
		  this.web3 = new Web3(window.ethereum);
		  const accounts = await window.ethereum.request({ method: 'eth_requestAccounts' });
		  if (accounts && accounts.length > 0) {
			this.walletAddress = accounts[0];
			this.walletConnected = true;
			this.showDisconnect = false;
			await this.switchToBSCTestnet();
			this.contract = new this.web3.eth.Contract(CONTRACT_ABI, CONTRACT_ADDRESS);
			window.ethereum.on('accountsChanged', (newAccounts) => {
			  if (newAccounts.length > 0) {
				this.walletAddress = newAccounts[0];
				this.walletConnected = true;
				this.fetchContractData();
			  } else {
				this.disconnectWallet();
			  }
			});
			console.log('Wallet connected:', this.walletAddress);
			await this.fetchContractData();
		  }
		} catch (error) {
		  console.error('Wallet connection error:', error);
		  alert(this.language === 'zh' ? '钱包连接失败: ' + error.message : 'Wallet connection failed: ' + error.message);
		}
	  },
	  async switchToBSCTestnet() {
		const bscTestnetChainId = '0x38';
		try {
		  await window.ethereum.request({ method: 'wallet_switchEthereumChain', params: [{ chainId: bscTestnetChainId }] });
		} catch (switchError) {
		  if (switchError.code === 4902) {
			await window.ethereum.request({
			  method: 'wallet_addEthereumChain',
			  params: [{
				chainId: bscTestnetChainId,
				chainName: 'Binance Smart Chain Testnet',
				nativeCurrency: { name: 'BNB', symbol: 'BNB', decimals: 18 },
				rpcUrls: ['https://bsc.blockrazor.xyz'],
				blockExplorerUrls: ['https://bscscan.com']
			  }],
			});
		  } else {
			throw switchError;
		  }
		}
	  },
	  disconnectWallet() {
		this.walletConnected = false;
		this.walletAddress = '';
		this.showDisconnect = false;
		this.contract = null;
		this.totalAreaPerformance = '0';
		this.smallAreaPerformance = '0';
		this.teamLevel = '0';
		this.canUpgrade = false;
		this.isRootUser = false;
		console.log('Wallet disconnected');
	  },
	  formatAddress(address) {
		return address ? `${address.slice(0, 6)}...${address.slice(-4)}` : '';
	  },
	  async fetchContractData() {
		try {
		  if (!this.contract || !this.walletAddress) {
			console.log('Contract or wallet address not initialized');
			return;
		  }
  
		  console.log('Fetching total deposited...');
		  const totalDeposited = await this.contract.methods.getTotalDeposited().call();
		  this.totalAreaPerformance = this.web3.utils.fromWei(totalDeposited, 'ether');
		  console.log('Total deposited:', this.totalAreaPerformance);
  
		  console.log('Fetching all referrals performance...');
		  const allReferralsPerf = await this.contract.methods.getAllReferralsTotalPerformance(this.walletAddress).call();
		  this.smallAreaPerformance = this.web3.utils.fromWei(allReferralsPerf, 'ether');
		  console.log('Small area performance:', this.smallAreaPerformance);
  
		  console.log('Fetching user level...');
		  const level = await this.contract.methods.getLevel(this.walletAddress).call();
		  this.teamLevel = level.toString();
		  console.log('Team level:', this.teamLevel);
  
		  console.log('Fetching user data...');
		  const userData = await this.contract.methods.users(this.walletAddress).call();
		  this.isRootUser = userData.referrer === '0x0000000000000000000000000000000000000000';
		  console.log('Is root user:', this.isRootUser);
  
		  await this.checkUpgradeEligibility();
		} catch (error) {
		  console.error('Error fetching contract data:', error);
		  alert(this.language === 'zh' ? '获取合约数据失败: ' + error.message : 'Failed to fetch contract data: ' + error.message);
		}
	  },
	  async checkUpgradeEligibility() {
		try {
		  if (!this.contract || !this.walletAddress || !this.isRootUser) {
			this.canUpgrade = false;
			return;
		  }
  
		  const currentLevel = parseInt(this.teamLevel);
		  const smallAreaPerf = parseFloat(this.smallAreaPerformance);
  
		  // 从合约获取升级要求
		  const levelRequirements = [];
		  for (let i = 0; i < 5; i++) {
			const requirement = await this.contract.methods.levelRequirements(i).call();
			levelRequirements.push(parseFloat(this.web3.utils.fromWei(requirement, 'ether')));
		  }
  
		  this.canUpgrade = currentLevel < 5 && smallAreaPerf >= levelRequirements[currentLevel];
		} catch (error) {
		  console.error('Error checking upgrade eligibility:', error);
		  this.canUpgrade = false;
		}
	  },
	  async upgradeLevel() {
		try {
		  if (!this.contract || !this.walletAddress) {
			alert(this.language === 'zh' ? '请先连接钱包' : 'Please connect wallet first');
			return;
		  }
  
		  if (!this.isRootUser) {
			alert(this.language === 'zh' ? '仅团长地址可升级' : 'Only team root can upgrade');
			return;
		  }
  
		  if (!this.canUpgrade) {
			alert(this.language === 'zh' ? '小区业绩未达标，无法升级' : 'Small area performance not met, cannot upgrade');
			return;
		  }
  
		  await this.contract.methods.upgradeLevel().send({ from: this.walletAddress })
			.on('transactionHash', (hash) => {
			  alert(this.language === 'zh' ? '交易已提交: ' + hash : 'Transaction submitted: ' + hash);
			})
			.on('receipt', (receipt) => {
			  alert(this.language === 'zh' ? '升级成功' : 'Upgrade successful');
			  this.fetchContractData(); // 更新数据
			})
			.on('error', (error) => {
			  throw error;
			});
		} catch (error) {
		  console.error('Error upgrading level:', error);
		  alert(this.language === 'zh' ? '升级失败: ' + error.message : 'Upgrade failed: ' + error.message);
		}
	  }
	}
  };
  </script>
  
  <style scoped>
  .team-level-page {
	padding: 20px;
	min-height: 100vh;
	background: linear-gradient(135deg, rgba(245, 247, 250, 0.9) 0%, rgba(195, 207, 226, 0.9) 100%);
	font-family: 'Segoe UI', sans-serif;
	display: flex;
	flex-direction: column;
	align-items: center;
  }
  
  .header {
	width: 100%;
	padding: 15px;
	background: rgba(255, 255, 255, 0.9);
	border-radius: 12px;
	box-shadow: 0 2px 10px rgba(0, 0, 0, 0.05);
	display: flex;
	flex-direction: column;
	align-items: center;
	gap: 15px;
	margin-bottom: 20px;
  }
  
  .logo-section {
	display: flex;
	align-items: center;
	gap: 10px;
  }
  
  .near-logo {
	width: 40px;
	height: 40px;
	transition: transform 0.3s ease;
  }
  
  .near-logo:hover {
	transform: scale(1.1);
  }
  
  .near-title {
	font-size: 24px;
	font-weight: 700;
	color: #00c08b;
	text-shadow: 0 1px 3px rgba(0, 214, 107, 0.2);
  }
  
  .nav-right {
	display: flex;
	flex-direction: column;
	align-items: center;
	gap: 10px;
	width: 100%;
  }
  
  .language-buttons {
	display: flex;
	flex-direction: row;
	width: 100%;
	gap: 0;
  }
  
  .language-btn {
	flex: 1;
	padding: 10px 0;
	background: #f0f0f0;
	color: #333;
	border: none;
	border-radius: 12px;
	cursor: pointer;
	font-size: 16px;
	font-weight: 600;
	transition: background 0.3s, color 0.3s, box-shadow 0.3s;
	text-align: center;
  }
  
  .language-btn:first-child {
	border-top-right-radius: 0;
	border-bottom-right-radius: 0;
  }
  
  .language-btn:last-child {
	border-top-left-radius: 0;
	border-bottom-left-radius: 0;
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
  width: 100%;
  max-width: 200px;
  display: flex; /* 添加 flex 布局 */
  justify-content: center; /* 水平居中 */
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
	background: #fff;
	border-radius: 10px;
	box-shadow: 0 3px 10px rgba(0, 0, 0, 0.1);
	z-index: 1000;
  }
  
  .disconnect-btn {
	padding: 8px 15px;
	width: 100%;
	background: none;
	border: none;
	color: #e57373;
	cursor: pointer;
	font-size: 12px;
  }
  
  .disconnect-btn:hover {
	background: #ffebee;
  }
  
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
  
  .upgrade-btn:active:not(.disabled) {
	transform: translateY(1px);
	box-shadow: 0 2px 5px rgba(0, 214, 107, 0.1);
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
	.header {
	  flex-direction: row;
	  justify-content: space-between;
	  padding: 20px;
	}
	.nav-right {
	  flex-direction: row;
	  gap: 15px;
	  width: auto;
	}
	.language-buttons {
	  width: auto;
	}
	.wallet-container {
	  width: auto;
	}
	.wallet-btn {
	  padding: 10px 20px;
	}
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
	.header {
	  padding: 10px;
	}
	.near-logo {
	  width: 36px;
	  height: 36px;
	}
	.near-title {
	  font-size: 20px;
	}
	.wallet-btn {

	  font-size: 12px;
	  padding: 8px;
	}
	.performance-card .value {
	  font-size: 20px;
	}
	.level-display .level {
	  font-size: 24px;
	}
  }
  </style>