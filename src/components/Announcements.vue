<template>
  <div class="announcements">
    <TheHeader />

    <section class="announcement-section">
      <h2 class="title">{{ isChinese ? '公告' : 'Announcement' }}</h2>
      <div class="content-box">
        <!-- <p class="intro-text">
          {{ isChinese ?
            '会员个人投入不低于3000u，小区业绩达到15000u，注册地址达到50个，即可向社区申请每月450u的办公室补贴（持续12个月），限前200名。此活动于4月30日前提交申请有效。' :
            'Members with a personal investment of no less than 3,000u, a community performance of 15,000u, and 50 registered addresses can apply to the community for a monthly office subsidy of 450u (for 12 months), limited to the first 200 applicants. Applications must be submitted by April 30.' }}
        </p> -->
      </div>
    </section>
  </div>
</template>

<script setup>
import { computed } from 'vue';
// 2. 引入布局组件和状态管理 Store
import TheHeader from './layout/TheHeader.vue';
import { useWalletStore } from '../stores/wallet';

// 3. 初始化 store
const walletStore = useWalletStore();

// 4. 从 store 中获取语言状态，代码量大大减少
const isChinese = computed(() => walletStore.isChinese);

// 注意：所有关于 walletAddress, toggleWallet, switchLanguage 的本地 data 和 methods 都已被彻底移除。
</script>

<style scoped>
/* 5. 移除了所有与 .header, .logo-section, .actions, .wallet-btn 相关的样式 */
/* 只保留 Announcements 组件自己需要的样式 */
.announcements {
  padding: 20px;
  max-width: 100%;
  box-sizing: border-box;
  background-color: #f9f9f9;
}

.announcement-section {
  max-width: 700px;
  margin: 0 auto;
}

.title {
  text-align: center;
  font-size: 26px;
  font-weight: bold;
  color: #333;
  margin: 20px 0 25px;
  padding-bottom: 8px;
  border-bottom: 2px solid #00c08b;
}

.content-box {
  background-color: #fff;
  padding: 20px;
  border-radius: 8px;
  box-shadow: 0 4px 6px rgba(0, 0, 0, 0.05);
}

.intro-text {
  font-size: 15px;
  line-height: 1.5;
  color: #555;
  margin-bottom: 15px;
  text-align: center;
}

/* 响应式设计 - 手机屏幕 */
@media (max-width: 360px) {
  .announcements {
    padding: 10px;
  }

  .title {
    font-size: 22px;
    margin: 15px 0 20px;
  }

  .content-box {
    padding: 15px;
  }

  .intro-text {
    font-size: 13px;
    line-height: 1.4;
  }
}
</style>