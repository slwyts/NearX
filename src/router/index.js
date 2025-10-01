import { createRouter, createWebHistory } from 'vue-router';
import Home from '@/components/Home.vue';
import Share from '@/components/Share.vue';
import Members from '@/components/Members.vue';
import TeamLevel from '@/components/TeamLevel.vue';
import Announcements from '@/components/Announcements.vue';
import AdminPanel from '@/components/AdminPanel.vue';


const routes = [
  { path: '/', name: 'Home', component: Home },
  { path: '/share', name: 'Share', component: Share },
  { path: '/members', name: 'Members', component: Members },
  { path: '/teamlevel', name: 'TeamLevel', component: TeamLevel },
  { path: '/announcements', name: 'Announcements', component: Announcements },
  { path: '/admin', name: 'Admin', component: AdminPanel },

];

const router = createRouter({
  history: createWebHistory(),
  routes,
});

export default router;