<template>
  <div class="sidebar-container">
    <button class="hamburger" @click="toggleSidebar">
      <span class="hamburger-icon">{{ isCollapsed ? '☰' : '✕' }}</span>
    </button>

    <div class="sidebar" :class="{ collapsed: isCollapsed }">
      <div class="logo">
        <img src="@/assets/near-logo2.png" alt="NEAR Logo" />
      </div>
      <div class="menu-content">
        <div class="menu">
          <button :class="{ active: activeComponent === 'Home' }" @click="select('Home')">首页</button>
          <button :class="{ active: activeComponent === 'Share' }" @click="select('Share')">分享</button>
          <button :class="{ active: activeComponent === 'Members' }" @click="select('Members')">成员</button>
          <button :class="{ active: activeComponent === 'TeamLevel' }" @click="select('TeamLevel')">团队</button>
          <button :class="{ active: activeComponent === 'Announcements' }" @click="select('Announcements')">公告</button>

          <button @click="goTo('https://near.org/')">官网</button>
          <button @click="goTo('https://wallet.near.org/')">钱包</button>
          <button @click="goTo('https://discovery-domain.org/papers/the-official-near-white-paper.pdf')">白皮书</button>
          <button @click="goTo('https://github.com/near')">Github</button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref } from 'vue';

// 定义 props 接收来自父组件 App.vue 的状态和数据
const props = defineProps({
  isCollapsed: Boolean, // 侧边栏是否折叠
  activeComponent: String // 当前激活的组件名
});

// 定义 emits，用于向父组件 App.vue 发送事件
const emit = defineEmits(['select', 'toggle']);

// 内部方法，当点击按钮时，通过 emit 通知父组件
function select(componentName) {
  emit('select', componentName);
}

function toggleSidebar() {
  emit('toggle');
}

function goTo(url) {
  // 使用 window.open 在新标签页打开外部链接，体验更好
  window.open(url, '_blank', 'noopener,noreferrer');
}
</script>

<style scoped>
/* 样式基本保持不变，做了一些小的代码格式化和注释 */
.sidebar-container {
  position: relative;
  height: 100%;
  /* 确保在移动端，汉堡菜单按钮能显示在最上层 */
  z-index: 1100;
}

.sidebar {
  width: 200px; /* 使用一个固定的宽度，而不是百分比 */
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
  border-left: 1px solid #e0e0e0;
}

.sidebar.collapsed {
  transform: translateX(100%);
}

.hamburger {
  display: none; /* 默认在桌面端隐藏 */
  position: fixed;
  top: 15px;
  right: 15px;
  background: #00c08b;
  border: none;
  border-radius: 8px;
  padding: 10px;
  cursor: pointer;
  z-index: 1100;
  box-shadow: 0 2px 8px rgba(0,0,0,0.2);
}

.hamburger-icon {
  color: white;
  font-size: 24px;
  line-height: 1;
}

.logo {
  display: flex;
  justify-content: center;
  margin-bottom: 20px;
  padding: 10px 0;
}

.logo img {
  width: 100%;
  max-width: 100px;
}

.menu-content {
  flex: 1;
  overflow-y: auto;
}

.menu {
  display: flex;
  flex-direction: column;
  gap: 5px; /* 使用 gap 替代 margin */
}

.menu button {
  padding: 12px 15px;
  background: none;
  border: none;
  text-align: left;
  cursor: pointer;
  border-radius: 8px;
  font-size: 16px;
  transition: background-color 0.2s ease, color 0.2s ease;
  color: #333;
}

.menu button:hover {
  background-color: #e0e0e0;
}

.menu button.active {
  background-color: #00c08b;
  color: white;
  font-weight: 600;
}

/* 响应式设计：当屏幕宽度小于等于 768px 时 */
@media (max-width: 768px) {
  .sidebar {
    width: 250px; /* 在移动端提供一个更宽的侧边栏 */
  }

  .hamburger {
    display: block; /* 在移动端显示汉堡菜单 */
  }
}
</style>