<template>
  <div class="announcements">
    <!-- 头部 -->
    <header class="header">
      <div class="logo-section">
        <img src="../assets/near-logo.png" alt="NEAR Logo" class="near-logo" />
        <span class="near-text">NEAR</span>
      </div>
      <div class="language-buttons">
        <button 
          class="language-btn" 
          :class="{ active: isChinese }" 
          @click="switchLanguage('zh')"
        >
          中文
        </button>
        <button 
          class="language-btn" 
          :class="{ active: !isChinese }" 
          @click="switchLanguage('en')"
        >
          English
        </button>
      </div>
      <div class="wallet-container">
        <button class="wallet-btn" @click="toggleWallet">
          {{ walletAddress ? shortenAddress(walletAddress) : (isChinese ? '连接钱包' : 'Connect Wallet') }}
        </button>
      </div>
    </header>

    <!-- 公告部分 -->
    <section class="announcement-section">
      <h2 class="title">{{ isChinese ? '公告' : 'Announcement' }}</h2>
      <!-- <div class="content-box">
        <p class="intro-text">
          {{ isChinese ? 
            '会员个人投入不低于3000u，小区业绩达到15000u，注册地址达到50个，即可向社区申请每月450u的办公室补贴（持续12个月），限前200名。此活动于4月30日前提交申请有效。' : 
            'Members with a personal investment of no less than 3,000u, a community performance of 15,000u, and 50 registered addresses can apply to the community for a monthly office subsidy of 450u (for 12 months), limited to the first 200 applicants. Applications must be submitted by April 30.' }}
        </p>
      </div> -->
    </section>
  </div>
</template>

<script>
export default {
  name: 'Announcements',
  data() {
    return {
      walletAddress: null,
      isChinese: true
    };
  },
  methods: {
    switchLanguage(lang) {
      this.isChinese = lang === 'zh';
    },
    async toggleWallet() {
      if (this.walletAddress) {
        const confirmDisconnect = confirm(this.isChinese ? '确定断开钱包吗？' : 'Are you sure you want to disconnect the wallet?');
        if (confirmDisconnect) {
          this.walletAddress = null;
        }
      } else {
        try {
          if (window.ethereum) {
            const accounts = await window.ethereum.request({ method: 'eth_requestAccounts' });
            this.walletAddress = accounts[0];
          } else {
            alert(this.isChinese ? '请安装 MetaMask 或其他 Web3 钱包' : 'Please install MetaMask or another Web3 wallet');
          }
        } catch (error) {
          console.error('连接钱包失败:', error);
        }
      }
    },
    shortenAddress(address) {
      if (!address) return '';
      return `${address.slice(0, 6)}...${address.slice(-4)}`;
    }
  }
};
</script>

<style scoped>
.announcements {
  padding: 20px;
  max-width: 100%;
  box-sizing: border-box;
  background-color: #f9f9f9;
}

/* 头部样式 */
.header {
  display: flex;
  flex-direction: column;
  align-items: flex-start;
  gap: 10px;
  margin-bottom: 25px;
}

.logo-section {
  display: flex;
  align-items: center;
}

.near-logo {
  width: 40px;
  height: 40px;
  margin-right: 10px;
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

.language-buttons {
  width: 100%;
  display: flex;
  justify-content: center;
}

.language-btn {
  flex: 1;
  max-width: 200px; /* 可根据需要调整按钮最大宽度 */
  padding: 8px 16px;
  background: #f0f0f0;
  color: #333;
  border: none;
  border-radius: 4px;
  cursor: pointer;
  font-size: 14px;
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
  width: 100%;
  display: flex;
  justify-content: center;
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
  text-align: center;
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

/* 公告部分 */
.announcement-section {
  max-width: 700px;
  margin: 0 auto;
}

.title {
  text-align: center;
  font-size: 26px;
  font-weight: bold;
  color: #333;
  margin: 20px 0 25px;
  padding-bottom: 8px;
  border-bottom: 2px solid #00c08b;
}

.content-box {
  background-color: #fff;
  padding: 20px;
  border-radius: 8px;
  box-shadow: 0 4px 6px rgba(0, 0, 0, 0.05);
}

.intro-text {
  font-size: 15px;
  line-height: 1.5;
  color: #555;
  margin-bottom: 15px;
  text-align: center;
}

/* 响应式设计 - 手机屏幕 */
@media (max-width: 360px) {
  .announcements {
    padding: 10px;
  }

  .header {
    align-items: flex-start;
    gap: 10px;
    margin-bottom: 20px;
  }

  .language-buttons {
    display: flex;
    justify-content: center;
  }

  .language-btn {
    padding: 8px 0;
    font-size: 12px;
  }

  .wallet-container {
    display: flex;
    justify-content: center;
  }

  .wallet-btn {
    font-size: 12px;
    padding: 8px;
    min-width: 100px;
  }

  .title {
    font-size: 22px;
    margin: 15px 0 20px;
  }

  .content-box {
    padding: 15px;
  }

  .intro-text {
    font-size: 13px;
    line-height: 1.4;
  }
}
</style>
