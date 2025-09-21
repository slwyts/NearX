<template>
    <div class="economic-model">
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
  
      <!-- 轮播图 -->
      <div class="carousel">
        <div class="carousel-inner" :style="{ transform: `translateX(-${currentIndex * 100}%)` }">
          <img v-for="(image, index) in images" :key="index" :src="image" alt="Community Poster" />
        </div>
        <!-- 导航点 -->
        <div class="carousel-dots">
          <span 
            v-for="(image, index) in images" 
            :key="index" 
            :class="{ active: index === currentIndex }" 
            @click="goToSlide(index)"
          ></span>
        </div>
      </div>
  
      <!-- 经济模型图片 -->
      <div class="model-image">
        <img src="http://cqplus.bsccoin.org/nera/img/jjmx.jpg" alt="Economic Model" />
      </div>
  
      <!-- 标题和描述 -->
      <h2 class="title">{{ isChinese ? '经济模型' : 'Economic Model' }}</h2>
      <p class="description">
        {{ isChinese ? '经济模型.PDF' : 'Economic Model.PDF' }}
      </p>
    </div>
  </template>
  
  <script>
  export default {
    name: 'EconomicModel',
    data() {
      return {
        images: [
          'http://cqplus.bsccoin.org/nera/img/lb/1.jpg',
          'http://cqplus.bsccoin.org/nera/img/lb/2.jpg',
          'http://cqplus.bsccoin.org/nera/img/lb/3.jpg',
          'http://cqplus.bsccoin.org/nera/img/lb/4.jpg'
        ],
        currentIndex: 0,
        intervalId: null,
        walletAddress: null,
        isChinese: true
      };
    },
    methods: {
      goToSlide(index) {
        this.currentIndex = index;
      },
      nextSlide() {
        this.currentIndex = (this.currentIndex + 1) % this.images.length;
      },
      startAutoPlay() {
        this.intervalId = setInterval(this.nextSlide, 3000);
      },
      stopAutoPlay() {
        if (this.intervalId) {
          clearInterval(this.intervalId);
        }
      },
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
    },
    mounted() {
      this.startAutoPlay();
    },
    beforeDestroy() {
      this.stopAutoPlay();
    }
  };
  </script>
  
  <style scoped>
  .economic-model {
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
  
  /* 轮播图样式 */
  .carousel {
    position: relative;
    width: 100%;
    overflow: hidden;
    margin-bottom: 20px;
    border-radius: 8px;
  }
  
  .carousel-inner {
    display: flex;
    transition: transform 0.5s ease;
  }
  
  .carousel-inner img {
    width: 100%;
    height: auto;
    flex-shrink: 0;
    object-fit: cover;
    aspect-ratio: 16 / 9;
  }
  
  /* 导航点 */
  .carousel-dots {
    position: absolute;
    bottom: 10px;
    left: 50%;
    transform: translateX(-50%);
    display: flex;
    gap: 8px;
  }
  
  .carousel-dots span {
    width: 8px;
    height: 8px;
    background-color: #ccc;
    border-radius: 50%;
    cursor: pointer;
    transition: background-color 0.3s ease;
  }
  
  .carousel-dots span.active {
    background-color: #00c08b;
  }
  
  /* 经济模型图片 */
  .model-image {
    width: 100%;
    margin-bottom: 20px;
  }
  
  .model-image img {
    width: 100%;
    height: auto;
    border-radius: 8px;
  }
  
  /* 标题 */
  .title {
    text-align: center;
    font-size: 24px;
    font-weight: bold;
    margin: 20px 0;
    color: #333;
  }
  
  /* 描述文字 */
  .description {
    font-size: 16px;
    line-height: 1.6;
    color: #666;
    text-align: center;
  }
  
  /* 响应式设计 - 手机屏幕 */
  @media (max-width: 360px) {
    .economic-model {
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
  
    .carousel {
      margin-bottom: 15px;
    }
  
    .carousel-inner img {
      aspect-ratio: 4 / 3;
    }
  
    .model-image {
      margin-bottom: 15px;
    }
  
    .title {
      font-size: 20px;
      margin: 15px 0;
    }
  
    .description {
      font-size: 14px;
      line-height: 1.5;
    }
  
    .carousel-dots {
      gap: 6px;
    }
  
    .carousel-dots span {
      width: 6px;
      height: 6px;
    }
  }
  </style>