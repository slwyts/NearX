<template>
  <div class="app-container">
    <main class="content" :class="{ 'sidebar-collapsed': isSidebarCollapsed }">
      <component :is="pages[currentComponent]"></component>
    </main>

    <Sidebar
      :is-collapsed="isSidebarCollapsed"
      :active-component="currentComponent"
      @toggle="handleToggleSidebar"
      @select="handleSelect"
    />
  </div>
</template>

<script setup>
import { ref, onMounted, onBeforeUnmount } from 'vue';

// 3. 引入所有页面组件和 Sidebar
import Sidebar from './components/Sidebar.vue';
import Home from './components/Home.vue';
import Share from './components/Share.vue';
import Members from './components/Members.vue';
import TeamLevel from './components/TeamLevel.vue';
import CommunityIntro from './components/CommunityIntro.vue';
import EconomicModel from './components/EconomicModel.vue';
import CommunityPoster from './components/CommunityPoster.vue';
import Announcements from './components/Announcements.vue';
import ContactUs from './components/ContactUs.vue';

// 4. 创建一个页面组件的映射，方便动态渲染
const pages = {
  Home,
  Share,
  Members,
  TeamLevel,
  CommunityIntro,
  EconomicModel,
  CommunityPoster,
  Announcements,
  ContactUs,
};

// 5. 管理应用的核心状态
const currentComponent = ref('Home'); // 默认显示的页面
const isSidebarCollapsed = ref(window.innerWidth <= 768); // 侧边栏是否折叠

// 6. 定义事件处理函数，用于响应 Sidebar 组件发出的事件
function handleSelect(componentName) {
  if (pages[componentName]) {
    currentComponent.value = componentName;
    // 在移动端，选择页面后自动折叠侧边栏
    if (window.innerWidth <= 768) {
      isSidebarCollapsed.value = true;
    }
  }
}

function handleToggleSidebar() {
  isSidebarCollapsed.value = !isSidebarCollapsed.value;
}

// 7. 添加窗口大小变化的监听，以实现响应式布局
function handleResize() {
  isSidebarCollapsed.value = window.innerWidth <= 768;
}

onMounted(() => {
  window.addEventListener('resize', handleResize);
});

onBeforeUnmount(() => {
  window.removeEventListener('resize', handleResize);
});
</script>

<style scoped>
/* 8. 定义应用的主布局样式 */
.app-container {
  display: flex;
  width: 100%;
  min-height: 100vh;
  /* 将侧边栏的宽度作为 CSS 变量，方便维护 */
  --sidebar-width: 200px; 
}

.content {
  flex: 1;
  padding: 20px;
  overflow-y: auto;
  transition: margin-right 0.3s ease;
  /* 默认给右边留出侧边栏的宽度 */
  margin-right: var(--sidebar-width);
}

.content.sidebar-collapsed {
  margin-right: 0; /* 当侧边栏折叠时，内容区域占满宽度 */
}

/* 移动端适配 */
@media (max-width: 768px) {
  .content {
    padding: 10px;
    margin-right: 0; /* 移动端内容区域始终占满 */
  }
}
</style>