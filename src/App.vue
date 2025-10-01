<template>
  <div class="app-container">
    <main class="content" :class="{ 'sidebar-collapsed': isSidebarCollapsed }">
      <router-view></router-view>
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
import { ref, onMounted, onBeforeUnmount, computed } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import Sidebar from './components/Sidebar.vue';

const router = useRouter();
const route = useRoute();

const currentComponent = computed(() => {
  return route.name || 'Home';
});
const isSidebarCollapsed = ref(window.innerWidth <= 768);

function handleSelect(componentName) {
  router.push({ path: `/${componentName.toLowerCase()}` });
  if (window.innerWidth <= 768) {
    isSidebarCollapsed.value = true;
  }
}

function handleToggleSidebar() {
  isSidebarCollapsed.value = !isSidebarCollapsed.value;
}

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
.app-container {
  display: flex;
  width: 100%;
  min-height: 100vh;
  --sidebar-width: 200px; 
}

.content {
  flex: 1;
  padding: 20px;
  overflow-y: auto;
  transition: margin-right 0.3s ease;
  margin-right: var(--sidebar-width);
}

.content.sidebar-collapsed {
  margin-right: 0;
}

@media (max-width: 768px) {
  .content {
    padding: 10px;
    margin-right: 0;
  }
}
</style>