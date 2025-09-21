<template>
	<div class="members-page">
	  <!-- 顶部导航栏 -->
	  <div class="header">
		<div class="logo-section">
		  <img src="../assets/near-logo.png" alt="NEAR Logo" class="near-logo" />
		  <span class="near-title"><strong>NEAR</strong></span>
		</div>
  
		<div class="nav-right">
		  <div class="language-section">
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
		</div>
	  </div>
	
	  <!-- 直推业绩和总业绩（合并后） -->
	  <div class="performance-section">
		<div class="performance-card merged">
		  <div class="performance-metric">
			<div class="value">{{ directPerformance }}</div>
			<div class="label">
			  {{ language === 'zh' ? '直推业绩（USDT）' : 'Direct Referral Performance (USDT)' }}
			</div>
		  </div>
		  <div class="divider"></div>
		  <div class="performance-metric">
			<div class="value">{{ totalPerformance }}</div>
			<div class="label">
			  {{ language === 'zh' ? '总业绩（USDT）' : 'Total Performance (USDT)' }}
			</div>
		  </div>
		</div>
	  </div>
	
	  <!-- 直推列表 -->
	  <div class="direct-referrals-section">
		<h2 class="section-header">{{ language === 'zh' ? '直推列表' : 'Direct Referrals List' }}</h2>
		<div class="table-container" v-if="directReferrals.length > 0">
		  <table>
			<thead>
			  <tr>
				<th>{{ language === 'zh' ? '地址' : 'Address' }}</th>
				<th>{{ language === 'zh' ? '质押量' : 'Stake Amount' }}</th>
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
		  <p>{{ language === 'zh' ? '没有推荐数据' : 'No Referral Data' }}</p>
		</div>
	  </div>
	
	  <!-- 有效直推数 -->
	  <div class="valid-referrals">
		<span class="value">{{ validDirectCount }}</span>
		<span class="label">{{ language === 'zh' ? '有效直推数' : 'Valid Direct Referrals' }}</span>
	  </div>
	
	  <!-- 分享业绩 -->
	  <div class="share-performance-section">
		<h2 class="section-header">{{ language === 'zh' ? '分享业绩' : 'Share Performance' }}</h2>
		<div class="table-container">
		  <table>
			<thead>
			  <tr>
				<th>{{ language === 'zh' ? '层次' : 'Level' }}</th>
				<th>{{ language === 'zh' ? '业绩（USDT）' : 'Performance (USDT)' }}</th>
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
  
  <script>
  import Web3 from 'web3';
  
  const CONTRACT_ADDRESS = '0x3a11b0d9f94ece55d96d37e50c28d41e64ff8a61';
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
				"name": "_usdtToken",
				"type": "address"
			},
			{
				"internalType": "address",
				"name": "_feeReceiver",
				"type": "address"
			},
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
				"name": "netAmount",
				"type": "uint256"
			},
			{
				"indexed": false,
				"internalType": "uint256",
				"name": "fee",
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
		"inputs": [],
		"name": "feeReceiver",
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
		"name": "privilegedAddress",
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
		"inputs": [],
		"name": "WITHDRAW_FEE",
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
]; // 已省略具体的 ABI 内容，实际使用时需替换为完整 ABI
  
  export default {
	name: 'Members',
	data() {
	  return {
		directReferrals: [],
		language: 'zh',
		walletConnected: false,
		walletAddress: '',
		showDisconnect: false,
		web3: null,
		contract: null,
		directPerformance: '0.00',
		totalPerformance: '0.00',
		validDirectCount: '0.00',
		levelPerformance: Array(10).fill('0.00')
	  };
	},
	methods: {
	  switchLanguage(lang) {
		this.language = lang;
		console.log('Language switched to:', this.language);
		this.fetchMemberData();
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
	
			await this.fetchMemberData();
	
			window.ethereum.on('accountsChanged', (newAccounts) => {
			  if (newAccounts.length > 0) {
				this.walletAddress = newAccounts[0];
				this.walletConnected = true;
				this.fetchMemberData();
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
		const bscTestnetChainId = '0x38';
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
			  alert(this.language === 'zh' ? `添加 BSC 主网失败: ${addError.message}` : `Failed to add BSC Testnet: ${addError.message}`);
			  throw addError;
			}
		  } else {
			alert(this.language === 'zh' ? `切换到 BSC 主网失败: ${switchError.message}` : `Failed to switch to BSC Testnet: ${switchError.message}`);
			throw switchError;
		  }
		}
	  },
	
	  disconnectWallet() {
		this.walletConnected = false;
		this.walletAddress = '';
		this.showDisconnect = false;
		this.contract = null;
		this.directPerformance = '0.00';
		this.totalPerformance = '0.00';
		this.directReferrals = [];
		this.validDirectCount = '0.00';
		this.levelPerformance = Array(10).fill('0.00');
		console.log('Wallet disconnected');
	  },
	
	  formatAddress(address) {
		if (!address) return '';
		return `${address.slice(0, 6)}...${address.slice(-4)}`;
	  },
	
	  async fetchMemberData() {
		try {
		  if (!this.contract || !this.walletAddress) return;
	
		  const directPerf = await this.contract.methods.getDirectReferralsTotalPerformance(this.walletAddress).call();
		  this.directPerformance = this.web3.utils.fromWei(directPerf, 'ether');
	
		  const levelPerf = await this.contract.methods.getPerformanceByLevel(this.walletAddress).call();
		  this.levelPerformance = levelPerf.map(perf => this.web3.utils.fromWei(perf, 'ether'));
	
		  const totalPerfWei = levelPerf.reduce((sum, perf) => BigInt(sum) + BigInt(perf), BigInt(0));
		  this.totalPerformance = this.web3.utils.fromWei(totalPerfWei.toString(), 'ether');
	
		  const referrals = await this.contract.methods.getReferrals(this.walletAddress, 1).call();
		  this.directReferrals = [];
		  for (const addr of referrals) {
			if (addr !== '0x0000000000000000000000000000000000000000') {
			  const userData = await this.contract.methods.users(addr).call();
			  this.directReferrals.push({
				address: this.formatAddress(addr),
				stake: this.web3.utils.fromWei(userData.totalDeposit, 'ether')
			  });
			}
		  }
	
		  const validCount = await this.contract.methods.getDirectReferralsWithDepositCount(this.walletAddress).call();
		  this.validDirectCount = validCount.toString();
	
		  console.log('Member data fetched:', {
			directPerformance: this.directPerformance,
			totalPerformance: this.totalPerformance,
			directReferrals: this.directReferrals,
			validDirectCount: this.validDirectCount,
			levelPerformance: this.levelPerformance
		  });
		} catch (error) {
		  console.error('Error fetching member data:', error);
		  alert(this.language === 'zh' ? '获取数据失败: ' + error.message : 'Failed to fetch data: ' + error.message);
		}
	  }
	},
	mounted() {
	  if (this.walletConnected) {
		this.fetchMemberData();
	  }
	}
  };
  </script>
  
  <style scoped>
  /* 全局样式 */
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
  
  /* 顶部导航栏 */
  .header {
	display: flex;
	justify-content: space-between;
	align-items: center;
	width: 100%;
	margin-bottom: 30px;
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
	color: var(--primary-color, #00C08B);
	letter-spacing: 1.5px;
	text-shadow: 0 2px 4px rgba(0, 192, 139, 0.2);
  }
  
  .nav-right {
	display: flex;
	flex-direction: column;
	gap: 15px;
	width: 100%;
  }
  
  .language-section {
	display: flex;
	justify-content: stretch;
	width: 100%;
  }
  
  .language-buttons {
	display: flex;
	gap: 0;
	width: 100%;
  }
  
  .language-btn {
	flex: 1;
	padding: 10px 0;
	background: #f0f0f0;
	color: #333;
	border: none;
	border-radius: 0;
	cursor: pointer;
	font-size: 16px;
	font-weight: 600;
	transition: background 0.3s, color 0.3s, box-shadow 0.3s;
	text-align: center;
  }
  
  .language-btn:first-child {
	border-top-left-radius: 12px;
	border-bottom-left-radius: 12px;
  }
  
  .language-btn:last-child {
	border-top-right-radius: 12px;
	border-bottom-right-radius: 12px;
  }
  
  .language-btn:hover {
	background: #e0e0e0;
  }
  
  .language-btn.active {
	background: linear-gradient(135deg, #00C08B 0%, #00a070 100%);
	color: white;
	box-shadow: 0 2px 5px rgba(0, 192, 139, 0.3);
  }
  
  .wallet-section {
	display: flex;
	justify-content: flex-end;
	width: 100%;
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
  .direct-referrals-section {
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
  
  /* 分享业绩 */
  .share-performance-section {
	width: 100%;
	background: white;
	padding: 25px;
	border-radius: 12px;
	box-shadow: 0 6px 15px rgba(0, 0, 0, 0.1);
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
  
	.header {
	  flex-direction: column;
	  align-items: flex-start;
	  gap: 10px;
	}
  
	.nav-right {
	  align-items: center;
	}
  
	.language-section {
	  justify-content: center;
	}
  
	.wallet-section {
	  justify-content: center;
	}
  
	.language-btn {
	  font-size: 14px;
	  padding: 8px 0;
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
	}
  
	.wallet-btn {
	  padding: 8px 16px;
	  font-size: 12px;
	}
  
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