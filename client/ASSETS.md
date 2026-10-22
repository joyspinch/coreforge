# coreforge · 熔炉纪元 · 素材清单

对标 Mindustry 的工厂自动化玩法（采矿 → 冶炼 → 装配 → 防御）。
**Mindustry 素材不可取用**（GPLv3 传染 + 第三方素材无逐件许可声明），
本项目**全部像素画自研**，只把 Mindustry 当**规格**参考（画布尺寸 / 描边 / 光源 / 色槽）。

**总量**：图片 102 张 / 音频 35 个
**P0 图片**：71 张（物品 12 + 地形 8 + 建筑 18 + 朝向 18 + 科技 15）
**已完成**：图片 53 张（物品 12 + 地形 8 + 建筑 18 + 科技 15）+ 音频 27 个（建造 8 + 武器 8 + 爆炸 5 + UI 6）
——批次 0/1/4 已产出并入库 `client/assets/`，待做 图片 49 张 + 音频 8 个
**参考源**：Mindustry `core/assets-raw/sprites/` —— 仅规格参考，不取像素
**逻辑依据**：`zan-lang/packages/Zan.Game.Factory` 的 23 BlockKind / 6 ItemKind / 4 TerrainKind / 15 Tech / 5 敌人

## 一、需要自制的图片

| 类别 | 数量 | 规格 | 用途 | 优先级 | 状态 |
|---|---|---|---|---|---|
| 物品图标 | 6 | 32×32 | 铜/铅/石墨/硅/钢/钛，库存面板与提示 | P0 | 已完成 |
| 传送带货物 | 6 | 16×16 | 带上 6 种物品的小图标 | P0 | 已完成 |
| 地形材质 | 8 | 32×32 | 地面/岩层/水/油各 2 变体，可无缝平铺 | P0 | 已完成 |
| 建筑本体 | 18 | 32×32 × 18 格 | 18 种 BlockKind（单张 256×96 图集，格位序号=BlockKind 序号；Empty/Belt/Wall/Pipe/Relay 走程序化） | P0 | 已完成 |
| 建筑朝向变体 | 18 | 32×32 | 真正有方向差异的**静态件**：出料口 4 向 × 3 类（钻头/熔炉/装配机）= 12 + 路由分向标 4 向 = 4 + 传送带端标 2（入口帽/出口帽，4 向共用 + 运行时旋转）= 2 | P0 | 待做 |
| 科技图标 | 15 | 24×24 | 15 个 Tech 节点（HUD 科技面板，`Image` 控件 1:1 显示） | P0 | 已完成 |
| 地形扩展变体 | 8 | 32×32 | 4 种地形各补 2 变体（现各 2 个） | P1 | 待做 |
| UI 面板 | 6 | — | 建造面板/科技树/小地图/资源条/波次条/配方图 | P1 | 待做 |
| 特效帧 | 12 | 32×32 | 爆炸 4 + 烟尘 4 + 建造落地 4 | P2 | 待做 |
| 敌人 sprite | 5 | 48×48 | 5 种敌人（程序化已达标，可选替换） | P2 | 待做 |

## 二、需要自制的音频

| 类别 | 数量 | 规格 | 用途 | 优先级 | 状态 |
|---|---|---|---|---|---|
| 建造 SFX | 8 | WAV 16bit PCM 44.1kHz 单声道 | 放置/拆除/拒绝/旋转/蓝图/选中/产出/投料 | P1 | 已完成 |
| 武器 SFX | 8 | WAV 16bit PCM 44.1kHz 单声道 | 脉冲/散射/狙炮/臼炮/棱镜/无人机/命中/护盾 | P1 | 已完成 |
| 爆炸 SFX | 5 | WAV 16bit PCM 44.1kHz 单声道 | 敌人死亡/自爆/建筑损毁/无人机损毁/敌巢摧毁 | P1 | 已完成 |
| UI SFX | 6 | WAV 16bit PCM 44.1kHz 单声道 | 点击/研究/错误/波次开始/波次清除/炉心陷落 | P1 | 已完成 |
| 机械 loop | 6 | OGG Vorbis 2–4s 循环 | 传送带/钻头/熔炉/装配机/发电/蜂群 | P1 | 待做 |
| BGM | 2 | OGG Vorbis 60–120s 立体声 | 建造期 / 战斗期 | P2 | 待做 |

## 三、规格要点（本项目特有）

- **全部建筑都是 1×1**：23 种 BlockKind 在逻辑层都占 1 格 → 统一 32×32 画布，
  **不需要** 64/96/128 多尺寸分支（Mindustry 才有 2×2~5×5 建筑）。
- **朝向变体的真实边界（已按渲染层核实）**：炮塔底座是「圆盘 + 环」，径向对称，身管随
  `AimVector` 动态转动 → **炮塔不产朝向变体**；传送带弯道由**邻接驱动**（直/左弯/右弯
  三形态），不是「4 向」能覆盖 → 只有**出料口 / 接口类静态件**需要按方向出图。
  故 P0 朝向变体 = 出料口 3 类 × 4 向 + 路由 4 向 + 传送带端标 2 = **18 张**
  （原「传送带 3 + 钻头 3 + 炮塔 4 型 × 3」= 18 的拆法与渲染层事实不符，已订正）。
- **描边 3px、光源右上、底色 `#4a4b53`**：与 `tools/artkit/palette.json` 一致；
  `artkit` 已实现 `bevel_shade` + `add_outline`，新图直接走生成器，不手绘。
- **地形贴图必须可无缝平铺**：`artkit.terrain_tile` 用可平铺值噪声生成，32×32 边界连续；
  渲染时按格哈希取 0/1 变体破除重复。
- **物品图标 32px 不可再压**：渲染层 `Cargo` 用 `max(6, round(12*zoom))` 缩放，最小 6px；
  16px 版本只给传送带货物格。
- **敌人暂不做 sprite**：现有程序化绘制含步态、扇翅、自爆体前摇，质量已达标；
  敌人若做需连续 8 向（渲染器按 `atan2` 转向）× 4 帧 = 5 × 8 × 4 = 160 张，
  远超当前预算，故列 P2 待评估。
- **音频格式**：SFX = **WAV 16bit PCM 44.1kHz 单声道**（`System.Media.AudioClip.LoadWav`
  直接可载，纯 numpy + `wave` 即可生成，无需 ffmpeg 依赖）；loop / BGM = OGG Vorbis
  （loop 2–4s 首尾波形对齐、BGM 60–120s 立体声，总账 §1.2）。
- **音效运行时链路**：逻辑层事件（`ForgeEvents` 9 类 / `ForgeEffect` 6 类 / 建筑与单位
  `cooldown` 跃升）→ 客户端 `ForgeSfx` 映射成 27 个 SFX 编号 → `ForgeAudio` 播放
  （`System.Media.AudioClip.Play`）。**不能用 `Game.Foundation.AudioBus`**：coreforge 禁
  import `Game.Foundation`（否则 `Gui.SpriteBatch` 与 `Game.Kit.SpriteBatch` 简单名撞车），
  故播放层自研。
- **音效是加分项，绝不能成为「能不能跑」的开关**：`Audio.Open()` 失败或 clip 解不出来都
  静默降级；`COREFORGE_AUDIO=0` 整层关掉（与 `COREFORGE_ART=0` 同级的产品级调试开关）。
- **静音不能用 `Audio.SetVolume(0)`**：原生主音量为 0 时混音循环不推进游标
  （`g = gain * master / 32767`，只有 `g != 0` 才推进），等于把每个 voice 冻在原地、
  槽位永不回收 → 静音改在本层拦播放 + `Audio.StopAll()`。
- **音效触发点必须落在 sim step 粒度**（`while (clock.HasStep())` 内采样），
  否则一帧内多次开火会被漏掉；**运行时不得阻塞等待 `AudioVoice.IsPlaying()`**。
- **建筑本体合成 1 张图集**：18 个建筑格位打进**单张 256×96 图集**（8 列 × 3 行 × 32px），
  格位序号 = `BlockKind` 序号（0..22），Empty/Belt/Wall/Pipe/Relay 5 格留空。
  单图集 = 单一 bitmap 纹理 → 逐格交错提交不触发 texture flush，z 序 = 调用序。
- **科技图标 24px 走 `Image` 控件，不走贴图批**：15 枚独立 PNG（不走图集）。
  源图尺寸必须 = 显示尺寸（24px 源图 = 24 CSS px）——`Canvas.BlitImage` 缩小时
  走面积平均（box filter），像素画被缩一次就糊。
  接入路径只能是 `<img>` 控件：CSS `background-image` 在本引擎不可用，
  `Button.Icon` / `IconView` 是 SVG 字形名也承载不了 PNG。
  `<img>` 必须是 `<button>` 的**兄弟**节点（塞进按钮里会和按钮自绘文字重叠），
  按钮加 `.grow` 吃掉剩余宽度。
- **科技图标 src 必须运行时注入**：路径随安装位置变，设计稿里写不死；
  `CoreforgeHud.ApplyTechIcons()` 在 `OnLoad` 时用 `ForgeArt.AssetPath` 求绝对路径
  再 `SetProp("src", path)`，缺图则整枚 `visible = false` 静默隐藏
  （`Image` 加载失败会画 alt 文本或 "..." 占位）。
- **估算**：像素画 102 张 ≈ 51–102 + SFX 27 ≈ 8.1 + loop 6 ≈ 3 + BGM 2 ≈ 6 ≈ **68.1–119.1 人日**
  （口径：0.5–1 人日/张、0.3/SFX、0.5/loop、3/BGM）。已完成的 53 张图 + 27 个 SFX 不占剩余人力，
  **实际待做 ≈ 33.5–58 人日**（像素画 49 张 ≈ 24.5–49 + 音频 8 个 ≈ 9）。

## 四、可直接取用（仅本项目相关的）

| 来源 | 素材 | 授权 | 限制 |
|---|---|---|---|
| Mindustry `core/assets-raw/sprites/` | png 2208 | 仅根 GPL-3.0，素材无独立条款 | **只当规格参考**（32/64/96/128/160 画布、3–4px 描边、光源方向、色槽结构），**不取任何像素** |
| `tools/artkit/`（本工作区自研） | 生成器 + 色阶常量表 | 自有版权 | 已产出 53 张图（物品 12 + 地形 8 + 建筑 18 格图集 + 科技 15）；`bevel_shade`/`add_outline`/`terrain_tile`/`palette.json` 对其余 10 个项目通用 |
| `tools/artkit/audio_coreforge.py`（本工作区自研） | 27 个 SFX 的 DSP 配方 | 自有版权 | numpy 逐样本生成、种子确定性可复现；`verify_audio.py` 13 项质量门把关；WAV 入 `client/assets/audio/`，`manifest.csv` 记 27 条 `audio` 记录 |

## 五、红线（仅本项目相关的）

| 来源 | 问题 | 处置 |
|---|---|---|
| Mindustry 像素 | GPLv3 传染 + 第三方素材许可未逐件声明 | 只当规范参考，不取像素 |
| 第三方转存的 Mindustry 素材包 | 来源与许可不可追溯 | 一律排除 |
| Mindustry `core/assets/sprites/` | 只有 13 张运行时大图，不是素材源 | 别去那儿找素材 |

## 六、制作批次

- 批次 0（已完成，2026-10-20）：`tools/artkit` 规范包 + 38 张（物品 12 + 地形 8 + 建筑 18 格图集），
  已入库 `client/assets/`（`manifest.csv` 21 行数据）并接进 `ForgeArt.zan` 贴图层。
  建筑部分由 `tools/artkit/buildings_coreforge.py` 生成，`tools/artkit/verify_buildings.py`
  逐格核对「BlockKind → 生成器 SLOTS → `ForgeArt.buildingSlots` → `palette.json` → `atlas.png`」全链。
- 批次 1（已完成，2026-10-20）：15 张科技图标（24×24）→ 已接进 HUD 科技面板。
  由 `tools/artkit/tech_coreforge.py` 生成（15 个配方 + `palette.json` 的 `techs` 段），
  `tools/artkit/tech_preview.py` 出联系表供目视验收；
  `manifest.csv` 增至 36 行数据（新增 15 条 `tech` 记录）。
  落地要点：`<img>` 控件 + 运行时 `SetProp("src", 绝对路径)`，缺图静默隐藏。
- 批次 2（P0 剩余）：18 张朝向变体（**规格已按渲染层订正**，见 §三）。
  走 `artkit` 生成器，单张 0.5–1 人日，可与 `platformer` / `rail` 同批做。
- 批次 3（P1/P2）：地形扩展 8 张 + UI 面板 6 张 + 特效帧 12 张 + 敌人 sprite 5 张（合计 31 张）。
- 批次 4（音频，**SFX 段已完成，2026-10-21**）：27 个 SFX → 6 个 loop → 2 首 BGM（音频合计 35 个）。
  27 个 SFX 已由 `tools/artkit/audio_coreforge.py` 产出并入库 `client/assets/audio/`
  （WAV 16bit PCM 44.1kHz 单声道，总时长 11,610 ms），`manifest.csv` 增至 63 行数据
  （新增 27 条 `audio` 记录）；运行时链路 `ForgeSfx` + `ForgeAudio` 已接进
  `ForgeInterface` / `main.zan`，自检 27/27 起播、自动测试实发 23 个。
  剩余 6 个 loop + 2 首 BGM 留待下一批。
- 可复用：本作地形明度阶与建筑色阶可与 `rail` / `crawler` 共用；`artkit` 全套工具对其余 10 个项目通用。
