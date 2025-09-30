<template>
    <div class="community-intro">
      <TheHeader />

      <div class="carousel">
        <div class="carousel-inner" :style="{ transform: `translateX(-${currentIndex * 100}%)` }">
          <img v-for="(image, index) in images" :key="index" :src="image" alt="Community Poster" />
        </div>
        <div class="carousel-dots">
          <span
            v-for="(image, index) in images"
            :key="index"
            :class="{ active: index === currentIndex }"
            @click="goToSlide(index)"
          ></span>
        </div>
      </div>

      <h2 class="title">{{ isChinese ? '社区介绍' : 'Community Introduction' }}</h2>

      <p class="description">
        {{ isChinese ?
          'NearX是一个由NEAR社区主导的创新型项目，旨在通过激励协作、生态系统发展来强化和扩展NEAR协议的使用场景和价值。该项目的核心是建立一个高活跃、低门槛、参与度强的社区，通过共创和共享价值来实现整个NEAR生态系统的共同繁荣。' :
          'NearX is an innovative project led by the NEAR community, aimed at enhancing and expanding the use cases and value of the NEAR protocol through incentivized collaboration and ecosystem development. The core of this project is to build a highly active, low-barrier, and highly engaged community, achieving collective prosperity for the entire NEAR ecosystem through co-creation and value sharing.' }}
      </p>
    </div>
</template>

<script setup>
import { ref, onMounted, onBeforeUnmount, computed } from 'vue';
// 2. 引入布局组件和 Store
import TheHeader from './layout/TheHeader.vue';
import { useWalletStore } from '../stores/wallet';

// 3. 初始化 Store
const walletStore = useWalletStore();

// 4. 定义组件自身的本地状态 (轮播图逻辑)
const images = ref([
  'http://cqplus.bsccoin.org/nera/img/lb/1.jpg',
  'http://cqplus.bsccoin.org/nera/img/lb/2.jpg',
  'http://cqplus.bsccoin.org/nera/img/lb/3.jpg',
  'http://cqplus.bsccoin.org/nera/img/lb/4.jpg'
]);
const currentIndex = ref(0);
let intervalId = null;

// 5. 从 Store 获取共享状态
const isChinese = computed(() => walletStore.isChinese);

// 6. 保留组件独有的方法 (轮播图控制)
function goToSlide(index) {
  currentIndex.value = index;
}

function nextSlide() {
  currentIndex.value = (currentIndex.value + 1) % images.value.length;
}

function startAutoPlay() {
  stopAutoPlay(); // 先停止已有的计时器，防止重复
  intervalId = setInterval(nextSlide, 3000);
}

function stopAutoPlay() {
  if (intervalId) {
    clearInterval(intervalId);
  }
}

onMounted(() => {
  startAutoPlay();
});

onBeforeUnmount(() => {
  stopAutoPlay();
});

// 注意：所有和钱包相关的 data (walletAddress) 和 methods (toggleWallet, shortenAddress) 已被彻底移除。
</script>

<style scoped>
/* 7. 移除所有与 header 相关的样式，只保留页面独有样式 */
.community-intro {
  padding: 20px;
  max-width: 100%;
  box-sizing: border-box;
}

/* 移除 .header, .logo-section, .actions, .wallet-btn 等所有头部相关样式 */

/* 轮播图样式 */
.carousel {
  position: relative;
  width: 100%;
  overflow: hidden;
  margin-bottom: 20px;
  border-radius: 8px;
}

.carousel-inner {
  display: flex;
  transition: transform 0.5s ease;
}

.carousel-inner img {
  width: 100%;
  height: auto;
  flex-shrink: 0;
  object-fit: cover;
  aspect-ratio: 16 / 9;
}

/* 导航点 */
.carousel-dots {
  position: absolute;
  bottom: 10px;
  left: 50%;
  transform: translateX(-50%);
  display: flex;
  gap: 8px;
}

.carousel-dots span {
  width: 8px;
  height: 8px;
  background-color: #ccc;
  border-radius: 50%;
  cursor: pointer;
  transition: background-color 0.3s ease;
}

.carousel-dots span.active {
  background-color: #00c08b;
}

/* 标题 */
.title {
  text-align: center;
  font-size: 24px;
  font-weight: bold;
  margin: 20px 0;
  color: #333;
}

/* 描述文字 */
.description {
  font-size: 16px;
  line-height: 1.6;
  color: #666;
  text-align: justify;
}

/* 响应式设计 - 手机屏幕 */
@media (max-width: 360px) {
  .community-intro {
    padding: 10px;
  }
  .carousel {
    margin-bottom: 15px;
  }
  .carousel-inner img {
    aspect-ratio: 4 / 3;
  }
  .title {
    font-size: 20px;
    margin: 15px 0;
  }
  .description {
    font-size: 14px;
    line-height: 1.5;
  }
  .carousel-dots {
    gap: 6px;
  }
  .carousel-dots span {
    width: 6px;
    height: 6px;
  }
}
</style>