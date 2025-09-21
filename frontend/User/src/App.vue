<template>
  <div class="app-container">
    <Sidebar @select="handleSelect" :isCollapsed="isSidebarCollapsed" @toggle="toggleSidebar" />
    <div class="content" :class="{ 'sidebar-collapsed': isSidebarCollapsed }">
      <component :is="currentComponent"></component>
    </div>
  </div>
</template>

<script>
import Sidebar from './components/Sidebar.vue';
import Home from './components/Home.vue';
import Share from './components/Share.vue';
import Members from './components/Members.vue';
import TeamLevel from './components/TeamLevel.vue';
import NearOfficial from './components/NearOfficial.vue';
import NearWallet from './components/NearWallet.vue';
import Whitepaper from './components/Whitepaper.vue';
import Github from './components/Github.vue';
import CommunityIntro from './components/CommunityIntro.vue';
import EconomicModel from './components/EconomicModel.vue';
import CommunityPoster from './components/CommunityPoster.vue';
import Announcements from './components/Announcements.vue';
import ContactUs from './components/ContactUs.vue';
import AdminPanel from './components/AdminPanel.vue';

export default {
  components: {
    Sidebar,
    Home,
    Share,
    Members,
    TeamLevel,
    NearOfficial,
    NearWallet,
    Whitepaper,
    Github,
    CommunityIntro,
    EconomicModel,
    CommunityPoster,
    Announcements,
    ContactUs,
    AdminPanel
  },
  data() {
    return {
      currentComponent: 'Home',
      isSidebarCollapsed: window.innerWidth <= 768 // 根据屏幕宽度初始化
    };
  },
  methods: {
    handleSelect(component) {
      // 忽略 'HelpCenter' 点击，只切换具体页面
      if (component !== 'HelpCenter') {
        this.currentComponent = component;
        console.log('Switching to:', component); // 添加日志以调试
      }
    },
    toggleSidebar() {
      this.isSidebarCollapsed = !this.isSidebarCollapsed;
    },
    switchLanguage(lang) {
      this.$i18n.locale = lang;
    }
  },
  created() {
    // 监听窗口大小变化
    window.addEventListener('resize', () => {
      if (window.innerWidth <= 768) {
        this.isSidebarCollapsed = true;
      } else {
        this.isSidebarCollapsed = false;
      }
    });
  },
  beforeDestroy() {
    // 清理事件监听器
    window.removeEventListener('resize', () => {});
  }
};
</script>

<style scoped>
.app-container {
  display: flex;
  width: 100%;
  min-height: 100vh;
}

.content {
  flex: 1;
  padding: 10px;
  overflow-y: auto;
  transition: all 0.3s ease;
}

.content.sidebar-collapsed {
  margin-right: 0; /* 侧边栏收起时内容占满 */
}

/* 手机端适配 */
@media (max-width: 768px) {
  .content {
    padding: 5px;
    width: 100%;
    margin-right: 0;
  }
}

/* 桌面端适配 */
@media (min-width: 769px) {
  .content {
    padding: 20px;
  }
}
</style>