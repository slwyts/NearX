<template>
	<div class="bind-wallet-page">
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
		</div>
	  </div>
  
	  <!-- 钱包连接按钮（紧贴语言按钮） -->
	  <div class="wallet-section">
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
  
	  <!-- NEAR 背景图片 -->
	  <div class="background-image">
		<div class="overlay"></div>
	  </div>
  
	  <!-- 绑定地址部分 -->
	  <div class="bind-section">
		<h1 class="section-header">{{ language === 'zh' ? '推荐人地址' : 'Referral Address' }}</h1>
		<div class="bind-content">
		  <input
			v-model="referralAddress"
			:placeholder="language === 'zh' ? '0x...' : '0x...'"
			class="referral-input"
		  />
		  <button class="bind-btn" @click="bindReferral">
			{{ language === 'zh' ? '绑定推荐人地址' : 'Bind Referral Address' }}
		  </button>
		  <p v-if="error" class="error">{{ error }}</p>
  
		  <!-- 新增：推荐人链接展示区域 -->
		  <div v-if="walletConnected && walletAddress" class="referral-link-container">
			<label class="referral-link-label">
			  {{ language === 'zh' ? '推荐人链接' : 'Referral Link' }}:
			</label>
			<div class="referral-link-wrapper">
			  <input
				type="text"
				:value="promotionLink"
				readonly
				class="referral-link-input"
			  />
			  <button class="copy-btn" @click="copyPromotionLink">
				{{ language === 'zh' ? '复制' : 'Copy' }}
			  </button>
			</div>
			<p v-if="shareSuccess" class="success">
			  {{ language === 'zh' ? '链接已复制！' : 'Link copied!' }}
			</p>
		  </div>
		</div>
	  </div>
	</div>
</template>

<script>
import Web3 from 'web3';

const CONTRACT_ADDRESS = '0xA37A284A9551c5466745c40f5866337059A76619';
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
		"inputs": [
			{
				"internalType": "uint256",
				"name": "_newRate",
				"type": "uint256"
			}
		],
		"name": "setUsdtToNearRate",
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
				"indexed": false,
				"internalType": "uint256",
				"name": "oldRate",
				"type": "uint256"
			},
			{
				"indexed": false,
				"internalType": "uint256",
				"name": "newRate",
				"type": "uint256"
			}
		],
		"name": "UsdtToNearRateUpdated",
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
		"inputs": [],
		"name": "usdtToNearRate",
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
	name: 'BindWallet',
	data() {
	  return {
		referralAddress: '',
		error: '',
		language: 'zh',
		walletConnected: false,
		walletAddress: '',
		showDisconnect: false,
		web3: null,
		contract: null,
		shareSuccess: false
	  };
	},
	computed: {
	  promotionLink() {
		if (this.walletConnected && this.walletAddress) {
		  return `${window.location.origin}/?ref=${this.walletAddress}`;
		}
		return '';
	  }
	},
	methods: {
	  switchLanguage(lang) {
		this.language = lang;
		this.error = '';
		console.log('Language switched to:', this.language);
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
			  } else {
				this.disconnectWallet();
			  }
			});
			console.log('Wallet connected successfully:', this.walletAddress);
		  } else {
			throw new Error('No accounts returned from wallet');
		  }
		} catch (error) {
		  console.error('Wallet connection error:', error);
		  alert(this.language === 'zh' ? '钱包连接失败: ' + error.message : 'Wallet connection failed: ' + error.message);
		}
	  },
  
	  async switchToBSCTestnet() {
		const bscTestnetChainId = '0x38'; // BSC Mainnet chainId
		try {
		  await window.ethereum.request({
			method: 'wallet_switchEthereumChain',
			params: [{ chainId: bscTestnetChainId }],
		  });
		} catch (switchError) {
		  if (switchError.code === 4902) {
			try {
			  await window.ethereum.request({
				method: 'wallet_addEthereumChain',
				params: [{
				  chainId: bscTestnetChainId,
				  chainName: 'Binance Smart Chain',
				  nativeCurrency: { name: 'BNB', symbol: 'BNB', decimals: 18 },
				  rpcUrls: ['https://bsc.blockrazor.xyz'],
				  blockExplorerUrls: ['https://bscscan.com']
				}],
			  });
			} catch (addError) {
			  alert(this.language === 'zh' ? `添加 BSC 网络失败: ${addError.message}` : `Failed to add BSC Network: ${addError.message}`);
			  throw addError;
			}
		  } else {
			alert(this.language === 'zh' ? `切换到 BSC 网络失败: ${switchError.message}` : `Failed to switch to BSC Network: ${switchError.message}`);
			throw switchError;
		  }
		}
	  },
  
	  disconnectWallet() {
		this.walletConnected = false;
		this.walletAddress = '';
		this.showDisconnect = false;
		this.contract = null;
		console.log('Wallet disconnected');
	  },
  
	  formatAddress(address) {
		if (!address) return '';
		return `${address.slice(0, 6)}...${address.slice(-4)}`;
	  },
  
	  async bindReferral() {
		try {
		  if (!this.walletConnected || !this.contract) {
			await this.connectWallet();
			if (!this.contract) return;
		  }
  
		  const referral = this.referralAddress.trim();
		  if (!referral) {
			this.error = this.language === 'zh' ? '请输入推荐人地址' : 'Please enter a referral address';
			return;
		  }
		  if (!this.web3.utils.isAddress(referral)) {
			this.error = this.language === 'zh' ? '请输入有效的推荐人地址' : 'Please enter a valid referral address';
			return;
		  }
		  if (referral.toLowerCase() === this.walletAddress.toLowerCase()) {
			this.error = this.language === 'zh' ? '推荐人地址不能是自己的地址' : 'Referral address cannot be your own address';
			return;
		  }
  
		  this.error = '';
		  console.log('Binding referral address:', referral);
  
		  const tx = await this.contract.methods.bindReferrer(referral).send({
			from: this.walletAddress,
			gas: 200000,
			gasPrice: this.web3.utils.toWei('10', 'gwei'),
		  });
  
		  console.log('Referral bound successfully:', tx);
		  this.$notify({
			title: this.language === 'zh' ? '成功' : 'Success',
			message: this.language === 'zh' ? '推荐人地址绑定成功！' : 'Referral address bound successfully!',
			type: 'success',
		  });
		} catch (err) {
		  console.error('Bind referral error:', err);
		  if (err.code === 4001) {
			this.error = this.language === 'zh' ? '用户拒绝了交易' : 'User rejected the transaction';
		  } else {
			try {
			  const userData = await this.contract.methods.users(this.walletAddress).call();
			  const boundReferrer = userData.referrer;
			  if (boundReferrer !== '0x0000000000000000000000000000000000000000') {
				this.error = this.language === 'zh' 
				  ? `绑定推荐人地址失败，推荐人已经绑定为 ${this.formatAddress(boundReferrer)}`
				  : `Failed to bind referral address, referrer already bound to ${this.formatAddress(boundReferrer)}`;
			  } else {
				this.error = this.language === 'zh'
				  ? `绑定推荐人地址失败: ${err.message}`
				  : `Failed to bind referral address: ${err.message}`;
			  }
			} catch (fetchError) {
			  console.error('Error fetching bound referrer:', fetchError);
			  this.error = this.language === 'zh'
				? `绑定推荐人地址失败: ${err.message}`
				: `Failed to bind referral address: ${err.message}`;
			}
		  }
		}
	  },
  
	  copyPromotionLink() {
		if (!this.promotionLink) {
		  alert(this.language === 'zh' ? '请先连接钱包以生成推广链接' : 'Please connect wallet to generate promotion link');
		  return;
		}
		if (navigator.clipboard && navigator.clipboard.writeText) {
		  navigator.clipboard.writeText(this.promotionLink)
			.then(() => {
			  this.shareSuccess = true;
			  setTimeout(() => {
				this.shareSuccess = false;
			  }, 2000);
			})
			.catch(err => {
			  console.error('复制链接失败:', err);
			  alert(this.language === 'zh' ? '复制链接失败' : 'Failed to copy link');
			});
		} else {
		  const tempInput = document.createElement('input');
		  tempInput.value = this.promotionLink;
		  document.body.appendChild(tempInput);
		  tempInput.select();
		  try {
			const successful = document.execCommand('copy');
			if (successful) {
			  this.shareSuccess = true;
			  setTimeout(() => {
				this.shareSuccess = false;
			  }, 2000);
			} else {
			  throw new Error('execCommand failed');
			}
		  } catch (err) {
			console.error('Fallback: 复制链接失败', err);
			alert(this.language === 'zh' ? '复制链接失败' : 'Failed to copy link');
		  }
		  document.body.removeChild(tempInput);
		}
	  }
	}
};
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

/* 顶部导航栏 */
.header {
	display: flex;
	flex-direction: column;
	align-items: center;
	width: 100%;
	margin-bottom: 0; /* 去除下边距，使钱包按钮紧贴 */
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
	color: var(--primary-color, #00C08B);
	letter-spacing: 1.5px;
	text-shadow: 0 2px 4px rgba(0, 192, 139, 0.2);
}

.nav-right {
	margin-top: 15px;
	width: 100%;
}

/* 语言按钮 - 横向平分整个屏幕宽度 */
.language-buttons {
	display: flex;
	flex-direction: row;
	width: 100%;
	gap: 0; /* 移除间隙，让按钮紧贴 */
}

.language-btn {
	flex: 1; /* 每个按钮平分可用空间 */
	padding: 10px 0; /* 调整内边距，垂直居中文字 */
	background: #f0f0f0;
	color: #333;
	border: none;
	border-radius: 12px; /* 添加圆角矩形效果 */
	cursor: pointer;
	font-size: 16px;
	font-weight: 600;
	transition: background 0.3s, color 0.3s, box-shadow 0.3s;
	text-align: center;
}

.language-btn:first-child {
	border-top-right-radius: 0; /* 左侧按钮右上角无圆角 */
	border-bottom-right-radius: 0; /* 左侧按钮右下角无圆角 */
}

.language-btn:last-child {
	border-top-left-radius: 0; /* 右侧按钮左上角无圆角 */
	border-bottom-left-radius: 0; /* 右侧按钮左下角无圆角 */
}

.language-btn:hover {
	background: #e0e0e0;
}

.language-btn.active {
	background: linear-gradient(135deg, #00C08B 0%, #00a070 100%);
	color: white;
	box-shadow: 0 2px 5px rgba(0, 192, 139, 0.3);
}

/* 钱包区域 */
.wallet-section {
	margin: 0; /* 紧贴顶部 */
	width: 100%;
	display: flex;
	justify-content: center;
}

.wallet-container {
	position: relative;
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

	.header {
	  gap: 15px;
	}

	.nav-right {
	  width: 100%;
	}

	.language-buttons {
	  width: 100%;
	}

	.language-btn {
	  font-size: 14px;
	  padding: 8px 0;
	  border-radius: 10px; /* 保持圆角矩形 */
	}

	.language-btn:first-child {
	  border-top-right-radius: 0;
	  border-bottom-right-radius: 0;
	}

	.language-btn:last-child {
	  border-top-left-radius: 0;
	  border-bottom-left-radius: 0;
	}

	.wallet-section {
	  margin: 8px 0;
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
	.near-logo {
	  width: 50px;
	  height: 50px;
	}

	.near-title {
	  font-size: 24px;
	}

	.language-btn {
	  font-size: 12px;
	  padding: 6px 0;
	  border-radius: 8px; /* 保持圆角矩形 */
	}

	.language-btn:first-child {
	  border-top-right-radius: 0;
	  border-bottom-right-radius: 0;
	}

	.language-btn:last-child {
	  border-top-left-radius: 0;
	  border-bottom-left-radius: 0;
	}

	.wallet-btn {
	  padding: 8px 16px;
	  font-size: 12px;
	}

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