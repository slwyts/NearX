import { createApp } from 'vue';
import App from './App.vue';
import { createI18n } from 'vue-i18n';
import ElementPlus from 'element-plus';
import 'element-plus/dist/index.css';

const messages = {
  en: {
    home: 'Home',
    share: 'Share',
    members: 'Members',
    teamLevel: 'Team Level',
    nearOfficial: 'NEAR Official',
    nearWallet: 'NEAR Wallet',
    whitepaper: 'Whitepaper',
    github: 'GitHub',
    helpCenter: 'Help Center',
    systemIntro: 'System Introduction',
    // 其他翻译...
  },
  zh: {
    home: '首页',
    share: '分享',
    members: '成员',
    teamLevel: '团队级别',
    nearOfficial: 'NEAR 官网',
    nearWallet: 'NEAR 钱包',
    whitepaper: '白皮书',
    github: 'GitHub',
    helpCenter: '帮助中心',
    systemIntro: '系统介绍',
    // 其他翻译...
  },
};

const i18n = createI18n({
  locale: 'zh', // 默认中文
  fallbackLocale: 'en',
  messages,
});

const app = createApp(App);
app.use(i18n);
app.use(ElementPlus); // 注册 Element Plus
app.mount('#app');
