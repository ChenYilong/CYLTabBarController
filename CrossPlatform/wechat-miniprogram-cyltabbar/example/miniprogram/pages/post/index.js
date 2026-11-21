/**
 * [EN] A post of the gallery feed (data/cyl_glass_feed.json), opened from its card: like it, copy its link, comment.
 * [CN] 画廊信息流中的帖子（data/cyl_glass_feed.json），从卡片打开：点赞、复制链接、评论。
 */
const cylTabPage = require('../../utils/cyl_tab_page');
const { cylReadJSON } = require('../../utils/cyl_read_json');

// [EN] Sample comments, made from the post so every post has some. [CN] 由帖子生成的示例评论，每个帖子都有。
function cylSampleComments(post) {
  const authors = ['Lin', 'Mia', 'Kai', 'Ava', 'Leo', 'Zoe'].filter((name) => name !== post.author);
  const texts = ['👍', 'Tried it in the example, works.', `More about ${post.tag}, please.`];
  return texts.slice(0, Math.min(texts.length, (post.comments || 0) > 0 ? 3 : 0))
    .map((text, index) => ({ id: index, author: authors[index], text }));
}

Component({
  behaviors: [cylTabPage],
  data: { post: {}, liked: false, likes: 0, comments: [], draft: '' },
  methods: {
    onLoad(query) {
      const posts = cylReadJSON('/data/cyl_glass_feed.json').posts || [];
      const post = posts.find((candidate) => String(candidate.id) === String(query.id)) || posts[0] || {};
      wx.setNavigationBarTitle({ title: post.title || '' });
      this.setData({ post, likes: post.likes || 0, comments: cylSampleComments(post) });
    },

    cyl_like() {
      const liked = !this.data.liked;
      this.setData({ liked, likes: this.data.likes + (liked ? 1 : -1) });
    },

    cyl_share() {
      wx.setClipboardData({ data: `https://github.com/ChenYilong/CYLTabBarController#post-${this.data.post.id}` });
    },

    // [EN] Tapping a comment starts a reply to its author. [CN] 点击评论开始回复其作者。
    cyl_reply(event) {
      this.setData({ draft: `@${event.currentTarget.dataset.author} ` });
    },
    cyl_draft(event) {
      this.setData({ draft: event.detail.value });
    },

    cyl_send() {
      const text = this.data.draft.trim();
      if (!text) {
        return;
      }
      this.setData({ comments: this.data.comments.concat({ id: Date.now(), author: this.t('Me'), text }), draft: '' });
    },
  },
});
