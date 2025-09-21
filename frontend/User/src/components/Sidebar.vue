<template>
  <div class="sidebar-container">
    <!-- 汉堡菜单按钮 -->
    <button class="hamburger" @click="toggleSidebar">
      <span class="hamburger-icon">{{ isCollapsed ? '☰' : '✕' }}</span>
    </button>

    <!-- Sidebar 内容 -->
    <div class="sidebar" :class="{ collapsed: isCollapsed }">
      <div class="logo">
        <img src="../../public/near.png" alt="NEAR Logo" />
      </div>
      <div class="menu-content">
        <div class="menu">
          <button :class="{ active: active === 'Home' }" @click="select('Home')">首页</button>
          <button :class="{ active: active === 'Share' }" @click="select('Share')">分享</button>
          <button :class="{ active: active === 'Members' }" @click="select('Members')">成员</button>
          <button :class="{ active: active === 'TeamLevel' }" @click="select('TeamLevel')">团队</button>
          <button :class="{ active: active === 'NearOfficial' }" @click="goToNearOfficial">官网</button>
          <button :class="{ active: active === 'NearWallet' }" @click="goToNearWallet">钱包</button>
          <button :class="{ active: active === 'Whitepaper' }" @click="goToWhitepaper">白皮书</button>
          <button :class="{ active: active === 'Github' }" @click="goToGithub">Github</button>
          
          
          <!-- 新增的按钮 -->
          <button :class="{ active: active === 'Announcements' }" @click="select('Announcements')">公告</button>
          
        </div>
      </div>
    </div>
  </div>
</template>

<script>
export default {
  data() {
    return {
      active: 'Home',
      isCollapsed: false
    };
  },
  methods: {
    select(component) {
      this.active = component;
      this.$emit('select', component);
      if (window.innerWidth <= 768) {
        this.isCollapsed = true;
      }
    },
    goToNearOfficial() {
      window.location.href = 'https://near.org/';
    },
    goToNearWallet() {
      window.location.href = 'https://wallet.near.org/';
    },
    goToWhitepaper() {
      window.location.href = 'https://discovery-domain.org/papers/the-official-near-white-paper.pdf';
    },
    goToGithub() {
      window.location.href = 'https://github.com/near';
    },
    toggleSidebar() {
      this.isCollapsed = !this.isCollapsed;
    },
    checkScreenSize() {
      if (window.innerWidth <= 768) {
        this.isCollapsed = true;
      } else {
        this.isCollapsed = false;
      }
    }
  },
  mounted() {
    this.checkScreenSize();
    window.addEventListener('resize', this.checkScreenSize);
  },
  beforeDestroy() {
    window.removeEventListener('resize', this.checkScreenSize);
  }
};
</script>

<style scoped>
.sidebar-container {
  position: relative;
  height: 100%;
}

.sidebar {
  width: 10%; /* 修改处：从 20% 改为 10% */
  background-color: #f5f5f5;
  display: flex;
  flex-direction: column;
  padding: 20px;
  position: fixed;
  top: 0;
  right: 0;
  height: 100vh;
  z-index: 1000;
  transition: transform 0.3s ease;
  transform: translateX(0);
}

.sidebar.collapsed {
  transform: translateX(100%);
}

.menu-content {
  flex: 1;
  overflow-y: auto;
}

.hamburger {
  display: none;
  position: fixed;
  top: 10px;
  right: 10px;
  background: #00c08b;
  border: none;
  border-radius: 5px;
  padding: 10px;
  cursor: pointer;
  z-index: 1100;
}

.hamburger-icon {
  color: white;
  font-size: 24px;
}

.logo {
  display: flex;
  justify-content: center;
  margin-bottom: 20px;
}

.logo img {
  width: 100%;
  max-width: 100px;
}

.menu {
  display: flex;
  flex-direction: column;
}

button {
  padding: 10px;
  margin: 5px 0;
  background: none;
  border: none;
  text-align: left;
  cursor: pointer;
  border-radius: 4px;
  font-size: 16px;
  transition: background-color 0.2s ease;
}

button:hover {
  background-color: #e0e0e0;
}

button.active {
  background-color: #00c08b;
  color: white;
}

@media (max-width: 768px) {
  .sidebar {
    width: 50%; /* 修改处：从 70% 改为 35% */
  }

  .sidebar.collapsed {
    transform: translateX(100%);
  }

  .hamburger {
    display: block;
  }
}

@media (min-width: 769px) {
  .sidebar {
    transform: translateX(0);
  }

  .hamburger {
    display: none;
  }
}
</style>