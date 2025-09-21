<template>
  <div id="app">
    <AdminPanel />
  </div>
</template>

<script>
import AdminPanel from './components/AdminPanel.vue';

export default {
  name: 'App',
  components: {
    AdminPanel
  }
};
</script>

<style>
#app {
  margin: 0;
  padding: 0;
  height: 100vh;
}
</style>