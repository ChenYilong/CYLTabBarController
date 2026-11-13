import { createHash } from "node:crypto";

export const FOREST_IDENTITIES = Object.freeze([
  { avatar: "pinecone-squirrel", nickname: "松果松鼠" },
  { avatar: "sleepy-fox", nickname: "困困狐狸" },
  { avatar: "moon-fawn", nickname: "月光小鹿" },
  { avatar: "cloud-bear", nickname: "云朵小熊" },
  { avatar: "mushroom-rabbit", nickname: "蘑菇小兔" },
  { avatar: "dew-hedgehog", nickname: "露珠刺猬" },
  { avatar: "berry-raccoon", nickname: "浆果浣熊" },
  { avatar: "tree-owl", nickname: "树洞猫头鹰" },
  { avatar: "honey-badger", nickname: "蜂蜜小獾" },
  { avatar: "shell-otter", nickname: "贝壳水獭" },
  { avatar: "dandelion-lamb", nickname: "蒲公英小羊" },
  { avatar: "moss-mole", nickname: "苔藓鼹鼠" },
  { avatar: "star-tanuki", nickname: "星星狸猫" },
  { avatar: "raindrop-frog", nickname: "雨滴青蛙" },
  { avatar: "flower-mouse", nickname: "花环田鼠" },
  { avatar: "chestnut-hamster", nickname: "栗子仓鼠" },
  { avatar: "autumn-wolf", nickname: "落叶小狼" },
  { avatar: "cotton-puppy", nickname: "棉花小狗" },
  { avatar: "gummy-panda", nickname: "软糖熊猫" },
  { avatar: "firefly-kitten", nickname: "萤火虫小猫" },
  { avatar: "windchime-ferret", nickname: "风铃雪貂" },
  { avatar: "peach-chipmunk", nickname: "桃子花栗鼠" },
  { avatar: "scarf-penguin", nickname: "围巾小企鹅" },
  { avatar: "lantern-tanuki", nickname: "灯笼小貉" },
  { avatar: "acorn-piglet", nickname: "橡果小猪" },
  { avatar: "sunset-pony", nickname: "晚霞小马" },
  { avatar: "mint-snake", nickname: "薄荷小蛇" },
  { avatar: "hawthorn-red-panda", nickname: "山楂小熊猫" },
  { avatar: "pine-tit", nickname: "松针小山雀" },
  { avatar: "snow-marten", nickname: "雪团小貂" },
  { avatar: "mooncake-monkey", nickname: "月饼小猕猴" },
  { avatar: "persimmon-wildcat", nickname: "柿子小野猫" },
]);

const AVATAR_KEYS = new Set(FOREST_IDENTITIES.map((identity) => identity.avatar));

export function isForestAvatar(value) {
  return AVATAR_KEYS.has(value);
}

export function pickForestIdentity(source) {
  const digest = createHash("sha256").update(String(source)).digest();
  return FOREST_IDENTITIES[digest.readUInt32BE(0) % FOREST_IDENTITIES.length];
}
