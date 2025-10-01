import { createRouter, createWebHistory } from 'vue-router';
import Home from '@/components/Home.vue';
import Share from '@/components/Share.vue';
import Members from '@/components/Members.vue';
import TeamLevel from '@/components/TeamLevel.vue';
import Announcements from '@/components/Announcements.vue';
import AdminPanel from '@/components/AdminPanel.vue';


const routes = [
  { path: '/', component: Home },
  { path: '/share', component: Share },
  { path: '/members', component: Members },
  { path: '/team-level', component: TeamLevel },
  { path: '/announcements', component: Announcements },
  { path: '/admin', component: AdminPanel },

];

const router = createRouter({
  history: createWebHistory(),
  routes,
});

export default router;