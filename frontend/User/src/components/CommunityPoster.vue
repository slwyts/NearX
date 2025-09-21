<template>
    <div class="community-poster">
      <!-- 头部 -->
      <header class="header">
        <div class="logo-section">
          <img src="../assets/near-logo.png" alt="NEAR Logo" class="near-logo" />
          <span class="near-text">NEAR</span>
        </div>

        <div class="actions">
  <button @click="switchLanguage('zh')">中文</button>
  <button @click="switchLanguage('en')">English</button>
  <button class="wallet-btn" @click="toggleWallet">
    {{ walletAddress ? shortenAddress(walletAddress) : (isChinese ? '连接钱包' : 'Connect Wallet') }}
  </button>
</div>


      </header>
  
      <!-- 社区海报部分 -->
      <section class="poster-section">
        <h2 class="title">{{ isChinese ? '社区海报' : 'Community Posters' }}</h2>
        <div class="poster-grid community-grid">
          <img v-for="(poster, index) in communityPosters" :key="index" :src="poster" alt="Community Poster" />
        </div>
      </section>
  
      <!-- 宣传海报部分 -->
      <section class="poster-section">
        <h2 class="title">{{ isChinese ? '宣传海报' : 'Promotional Posters' }}</h2>
        <div class="poster-grid promo-grid">
          <img v-for="(poster, index) in promoPosters" :key="index" :src="poster" alt="Promotional Poster" />
        </div>
      </section>
    </div>
  </template>
  
  <script>
  export default {
    name: 'CommunityPoster',
    data() {
      return {
        communityPosters: [
          'http://cqplus.bsccoin.org/nera/img/hb/1.jpg',
          'http://cqplus.bsccoin.org/nera/img/hb/2.jpg',
          'http://cqplus.bsccoin.org/nera/img/hb/3.jpg',
          'http://cqplus.bsccoin.org/nera/img/hb/4.jpg',
          'http://cqplus.bsccoin.org/nera/img/hb/5.jpg'
        ],
        promoPosters: [
          'http://cqplus.bsccoin.org/nera/img/hb/6.jpg',
          'http://cqplus.bsccoin.org/nera/img/hb/7.jpg',
          'http://cqplus.bsccoin.org/nera/img/hb/8.jpg',
          'http://cqplus.bsccoin.org/nera/img/hb/9.jpg',
          'http://cqplus.bsccoin.org/nera/img/hb/11.jpg',
          'http://cqplus.bsccoin.org/nera/img/hb/12.jpg',
          'http://cqplus.bsccoin.org/nera/img/hb/13.jpg',
          'http://cqplus.bsccoin.org/nera/img/hb/14.jpg',
          'http://cqplus.bsccoin.org/nera/img/hb/15.jpg',
          'http://cqplus.bsccoin.org/nera/img/hb/16.jpg'
        ],
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
  .community-poster {
    padding: 20px;
    max-width: 100%;
    box-sizing: border-box;
  }
  
  /* 头部样式 */
  .header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-bottom: 20px;
  }
  
  .logo-section {
    display: flex;
    align-items: center;
  }
  
  .near-logo {
    width: 40px;
    height: 40px;
    margin-right: 10px;
  }
  
  .near-text {
    font-size: 24px;
    font-weight: bold;
    color: #333;
  }
  
  .actions {
    display: flex;
    align-items: center;
    gap: 10px;
  }
  
  .language-switcher {
    padding: 5px;
    border: 1px solid #ccc;
    border-radius: 4px;
    font-size: 14px;
    cursor: pointer;
  }
  
  .wallet-btn {
    padding: 8px 16px;
    background-color: #00c08b;
    color: white;
    border: none;
    border-radius: 4px;
    cursor: pointer;
    font-size: 14px;
    transition: background-color 0.2s ease;
    white-space: nowrap;
    min-width: 100px;
  }
  
  .wallet-btn:hover {
    background-color: #009e73;
  }
  
  /* 海报部分 */
  .poster-section {
    margin-bottom: 30px;
  }
  
  .title {
    text-align: center;
    font-size: 24px;
    font-weight: bold;
    margin: 20px 0;
    color: #333;
  }
  
  .poster-grid {
    display: grid;
    gap: 10px;
  }
  
  .community-grid {
    grid-template-columns: repeat(2, 1fr); /* 2 列 */
    grid-template-rows: repeat(3, 1fr); /* 3 行，固定比例 */
  }
  
  .promo-grid {
    grid-template-columns: repeat(2, 1fr); /* 2 列 */
    grid-template-rows: repeat(5, 1fr); /* 5 行，固定比例 */
  }
  
  .poster-grid img {
    width: 100%;
    height: 100%; /* 确保高度填充网格 */
    border-radius: 8px;
    object-fit: cover; /* 保持图片比例，裁剪多余部分 */
    aspect-ratio: 1 / 1; /* 强制宽高比为 1:1，正方形 */
  }
  
  /* 响应式设计 - 手机屏幕 */
  @media (max-width: 360px) {
    .community-poster {
      padding: 10px;
    }
  
    .header {
      flex-direction: column;
      align-items: flex-start;
      gap: 10px;
    }
  
    .near-logo {
      width: 30px;
      height: 30px;
    }
  
    .near-text {
      font-size: 20px;
    }
  
    .actions {
      width: 100%;
      justify-content: space-between;
    }
  
    .language-switcher {
      font-size: 12px;
      padding: 4px;
    }
  
    .wallet-btn {
      font-size: 12px;
      padding: 6px 12px;
      min-width: 80px;
    }
  
    .title {
      font-size: 20px;
      margin: 15px 0;
    }
  
    .poster-section {
      margin-bottom: 20px;
    }
  
    .community-grid,
    .promo-grid {
      grid-template-columns: 1fr; /* 手机端改为 1 列 */
      grid-template-rows: auto; /* 自动行数 */
    }
  
    .poster-grid img {
      aspect-ratio: 1 / 1; /* 保持正方形 */
    }
  }
  </style>