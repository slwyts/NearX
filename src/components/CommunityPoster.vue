<template>
    <div class="community-poster">
      <TheHeader />

      <section class="poster-section">
        <h2 class="title">{{ isChinese ? '社区海报' : 'Community Posters' }}</h2>
        <div class="poster-grid community-grid">
          <img v-for="(poster, index) in communityPosters" :key="index" :src="poster" alt="Community Poster" />
        </div>
      </section>

      <section class="poster-section">
        <h2 class="title">{{ isChinese ? '宣传海报' : 'Promotional Posters' }}</h2>
        <div class="poster-grid promo-grid">
          <img v-for="(poster, index) in promoPosters" :key="index" :src="poster" alt="Promotional Poster" />
        </div>
      </section>
    </div>
</template>

<script setup>
import { ref, computed } from 'vue';
// 2. 引入布局组件和 Store
import TheHeader from './layout/TheHeader.vue';
import { useWalletStore } from '../stores/wallet';

// 3. 初始化 Store
const walletStore = useWalletStore();

// 4. 定义组件自身的本地状态 (海报图片列表)
const communityPosters = ref([
  'http://cqplus.bsccoin.org/nera/img/hb/1.jpg',
  'http://cqplus.bsccoin.org/nera/img/hb/2.jpg',
  'http://cqplus.bsccoin.org/nera/img/hb/3.jpg',
  'http://cqplus.bsccoin.org/nera/img/hb/4.jpg',
  'http://cqplus.bsccoin.org/nera/img/hb/5.jpg'
]);

const promoPosters = ref([
  'http://cqplus.bsccoin.org/nera/img/hb/6.jpg',
  'http://cqplus.bsccoin.org/nera/img/hb/7.jpg',
  'http://cqplus.bsccoin.org/nera/img/hb/8.jpg',
  'http://cqplus.bsccoin.org/nera/img/hb/9.jpg',
  'http://cqplus.bsccoin.org/nera/img/hb/11.jpg',
  'http://cqplus.bsccoin.org/nera/img/hb/12.jpg',
  'http://cqplus.bsccoin.org/nera/img/hb/13.jpg',
  'http://cqplus.bsccoin.org/nera/img/hb/14.jpg',
  'http://cqplus.bsccoin.org/nera/img/hb/15.jpg',
  'http://cqplus.bsccoin.org/nera/img/hb/16.jpg'
]);

// 5. 从 Store 获取共享状态
const isChinese = computed(() => walletStore.isChinese);

// 注意：所有和钱包相关的 data 和 methods 已被彻底移除。
</script>

<style scoped>
/* 6. 移除所有与 header 相关的样式，只保留页面独有样式 */
.community-poster {
  padding: 20px;
  max-width: 100%;
  box-sizing: border-box;
}

/* 移除 .header, .logo-section, .actions, .wallet-btn 等所有头部相关样式 */

/* 海报部分 */
.poster-section {
  margin-bottom: 30px;
}

.title {
  text-align: center;
  font-size: 24px;
  font-weight: bold;
  margin: 20px 0;
  color: #333;
}

.poster-grid {
  display: grid;
  gap: 10px;
}

.community-grid {
  grid-template-columns: repeat(2, 1fr); /* 2 列 */
  grid-template-rows: repeat(3, 1fr); /* 3 行，固定比例 */
}

.promo-grid {
  grid-template-columns: repeat(2, 1fr); /* 2 列 */
  grid-template-rows: repeat(5, 1fr); /* 5 行，固定比例 */
}

.poster-grid img {
  width: 100%;
  height: 100%; /* 确保高度填充网格 */
  border-radius: 8px;
  object-fit: cover; /* 保持图片比例，裁剪多余部分 */
  aspect-ratio: 1 / 1; /* 强制宽高比为 1:1，正方形 */
}

/* 响应式设计 - 手机屏幕 */
@media (max-width: 360px) {
  .community-poster {
    padding: 10px;
  }
  .title {
    font-size: 20px;
    margin: 15px 0;
  }
  .poster-section {
    margin-bottom: 20px;
  }
  .community-grid,
  .promo-grid {
    grid-template-columns: 1fr; /* 手机端改为 1 列 */
    grid-template-rows: auto; /* 自动行数 */
  }
  .poster-grid img {
    aspect-ratio: 1 / 1; /* 保持正方形 */
  }
}
</style>