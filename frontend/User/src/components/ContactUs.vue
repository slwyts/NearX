<template>
    <div class="contact-us">
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
  
      <!-- 联系我们部分 -->
      <section class="contact-section">
        <div class="contact-card">
          <h2 class="title">{{ isChinese ? '联系我们' : 'Contact Us' }}</h2>
          <div class="email-container">
            <i class="email-icon">✉️</i>
            <p class="email">
              E-mail: <a href="mailto:xxx@gmail.com" class="email-link">xxx@gmail.com</a>
            </p>
          </div>
        </div>
      </section>
    </div>
  </template>
  
  <script>
  export default {
    name: 'ContactUs',
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
  .contact-us {
    padding: 20px;
    max-width: 100%;
    box-sizing: border-box;
    background-color: #f9f9f9; /* 柔和的背景色 */
  }
  
  /* 头部样式 */
  .header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-bottom: 30px;
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
    transform: scale(1.1); /* 悬停时放大 */
  }
  
  .near-text {
    font-size: 24px;
    font-weight: bold;
    color: #333;
  }
  
  .actions {
    display: flex;
    align-items: center;
    gap: 15px;
  }
  
  .language-switcher {
    padding: 6px;
    border: 1px solid #ddd;
    border-radius: 4px;
    font-size: 14px;
    background-color: #fff;
    cursor: pointer;
    transition: border-color 0.3s ease;
  }
  
  .language-switcher:hover {
    border-color: #00c08b; /* NEAR 绿色 */
  }
  
  .wallet-btn {
    padding: 8px 16px;
    background-color: #00c08b;
    color: white;
    border: none;
    border-radius: 4px;
    cursor: pointer;
    font-size: 14px;
    transition: background-color 0.3s ease, transform 0.2s ease;
    white-space: nowrap;
    min-width: 100px;
    box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1); /* 轻微阴影 */
  }
  
  .wallet-btn:hover {
    background-color: #009e73;
    transform: translateY(-2px); /* 悬停时上移 */
  }
  
  /* 联系我们部分 */
  .contact-section {
    display: flex;
    justify-content: center;
    align-items: center;
    min-height: calc(100vh - 150px); /* 垂直居中 */
  }
  
  .contact-card {
    background-color: #fff;
    padding: 40px;
    border-radius: 12px;
    box-shadow: 0 6px 12px rgba(0, 0, 0, 0.1); /* 增强阴影 */
    max-width: 600px;
    width: 100%;
    text-align: center;
    transition: transform 0.3s ease, box-shadow 0.3s ease;
  }
  
  .contact-card:hover {
    transform: translateY(-5px); /* 悬停时上移 */
    box-shadow: 0 8px 16px rgba(0, 0, 0, 0.15); /* 阴影加深 */
  }
  
  .title {
    font-size: 28px;
    font-weight: bold;
    color: #333;
    margin-bottom: 20px;
    position: relative;
  }
  
  .title::after {
    content: '';
    position: absolute;
    bottom: -8px;
    left: 50%;
    transform: translateX(-50%);
    width: 60px;
    height: 3px;
    background-color: #00c08b; /* 标题下划线使用 NEAR 绿色 */
  }
  
  .email-container {
    display: flex;
    align-items: center;
    justify-content: center;
    gap: 10px;
    margin-top: 20px;
  }
  
  .email-icon {
    font-size: 24px;
    color: #00c08b;
  }
  
  .email {
    font-size: 18px;
    color: #555;
  }
  
  .email-link {
    color: #00c08b;
    text-decoration: none;
    transition: color 0.3s ease;
  }
  
  .email-link:hover {
    color: #009e73;
    text-decoration: underline;
  }
  
  /* 响应式设计 - 手机屏幕 */
  @media (max-width: 360px) {
    .contact-us {
      padding: 10px;
    }
  
    .header {
      flex-direction: column;
      align-items: flex-start;
      gap: 10px;
      margin-bottom: 20px;
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
  
    .contact-card {
      padding: 20px;
    }
  
    .title {
      font-size: 24px;
      margin-bottom: 15px;
    }
  
    .title::after {
      width: 40px;
    }
  
    .email-container {
      flex-direction: column;
      gap: 5px;
    }
  
    .email-icon {
      font-size: 20px;
    }
  
    .email {
      font-size: 14px;
    }
  }
  </style>