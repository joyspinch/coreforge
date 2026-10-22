# coreforge 诊断报告 —— 对标 Mindustry

> 结论先行：**coreforge 不是系统设计缺失，而是「美术表现层空心 + 网络层结构性缺失」。**
> 它的玩法逻辑层（抽到公共包 `Zan.Game.Factory`）完成度其实不低，差的是外面那层皮。
>
> **2026-10-21 更新**：美术**管线**已打通（`Gui.SpriteBatch` + 真实 PNG + 静默降级），
> 美术**素材**仍缺 **49 张**（朝向变体 18 + 地形扩展 8 + UI 6 + 特效 12 + 敌人 5）。
> 建筑本体 **18 个格位**与**科技图标 15 枚**已落地（256×96 图集 + HUD `Image` 控件）。
> **音效首批 27 个 SFX 也已落地**（自研合成 WAV，播放层 + 映射层已接通，运行时自检 27/27）。
> 下一个最大缺口仍是**网络层**（120–177 人日）。管线细节见第六节，建筑 sprite 见**第七节**，
> 科技图标见**第八节**，音效系统见**第九节**，素材清单见 `client/ASSETS.md`。

---

## 一、体量事实

| 项 | 数值 |
|---|---|
| 客户端源码 | `coreforge/client/src/` **11 文件 4045 行** |
| 分布 | `ForgeRenderer.zan` 1385 / `ForgeInterface.zan` 1077 / `CoreforgeAutoTest.zan` 333 / `ForgeAudio.zan` 280 / `ForgeArt.zan` 246 / `App.html` 206 / `ForgeSfx.zan` 198 / `main.zan` 142 / `ForgeClock.zan` 63 / `ForgeCamera.zan` 58 / `CoreforgeHud.zan` 57 |
| 皮肤 | `skins/coreforge/skin.css` 109 行 |
| 位图素材 | **53 个精灵**（物品 12 + 地形 8 + 建筑 18 格位 + 科技 15，存 36 个 PNG 文件） |
| 音频素材 | **27 个 SFX**（建造 8 / 武器 8 / 爆炸 5 / UI 6，存 27 个 WAV 文件，总时长 11,610 ms） |
| 网络 | **0** |
| 玩法逻辑（外部公共包） | `zan-lang/packages/Zan.Game.Factory/src/Game/Factory` 27 文件 **2567 行** |

**实际玩法规模**（逻辑包内）：48×36 地图、23 个 BlockKind、4 个配方、15 个 Tech、5 种敌人、20 波、6 种物品、4 种地形。

**渲染＝程序化主体 + 位图层（2026-10-20 起）**：`ForgeRenderer.zan` 仍以 `FillRect` / `FillCircle` / `DrawLine` / `Arc` 为主干，敌人步态、扇翅、地面碎石草簇、矿石道具等**精细程序化绘制全部保留**；
但已新增 `ForgeArt.zan` 位图层——地面材质贴图叠加 + 传送带货物真实物品图标 + **建筑静态本体图集**。
位图 53 个精灵（物品 12 + 地形 8 + 建筑 18 格位 + 科技 15），清单见 `coreforge/client/ASSETS.md`，落地细节见**第六节**（管线）、**第七节**（建筑 sprite）、**第八节**（科技图标）。
音频另走**自研合成 + `System.Media` 播放**链路（27 个 SFX，全部自研、不取用第三方音频），落地细节见**第九节**。

> ⚠ **改 coreforge 的玩法 = 跨仓库改动**。逻辑不在 `coreforge/` 里，在 `zan-lang` 的公共包中。

---

## 二、Mindustry 对标硬数据（已逐项核实）

### 2.1 美术

- 精灵源在 **`core/assets-raw/sprites/`**，**2208 张 PNG**
  （blocks 1666 / units 290 / ui 130 / effects 52 / items 33 / statuses 20 / rubble 11 / shapes 5 / teams 4）。
  注意 `core/assets/sprites/` 只有 13 张运行时大图——**别去那儿找素材**。
- **像素画规范**（已逐张核对 PNG 实际尺寸）：

  | 对象 | 画布 |
  |---|---|
  | 1×1 建筑 | 32px |
  | 2×2 建筑 | 64px |
  | 3×3 建筑 | 96px |
  | 4×4 建筑 | 128px |
  | 5×5 建筑 | 160px |
  | 单位 | ≥48px（实测有 56×57、128×128） |
  | 物品 / 液体 / 状态 | ≥32px |

  - 引擎**自动加 3–4px 灰描边**，源图须**留 4px 边距**。
  - **建筑光源右上、阴影左下**，中间一条对角分割；高起=亮调、平地=中调、下陷=暗调。
  - 45° 折线规则适用建筑/炮塔/单位，**不适用环境贴图**。
- **色槽**（每个对象给 3–6 个色值，不自由取色）：

  | 类别 | 色槽 |
  |---|---|
  | 建筑 | base 3 阶 + decal 3 阶 + 底色 `#4a4b53` |
  | 炮塔 | base 2 阶（`#7B7B7B` / `#4D4E58`）+ decal 2 阶（`#FEB380` / `#EA8878`）+ 炮口 `#2C2D38` |
  | 单位 | base 3 阶（`#B0BAC0` / `#989AA4` / `#6E7080`）+ decal 2 阶（黄=产出 / 橙=进攻 / 绿=支援 / 紫=特种） |
  | 地形 | 单一色相 3–4 个明度阶 + 1 个装饰点缀色 |

  单位暗色面积应占 **30–40%**。调色板在 `core/src/mindustry/graphics/Pal.java`（**103 色**）。

### 2.2 音频

- **205 个音效**：shoot 64 / block 38 / explosions 35 / loops 34 / movement 13 / ui 7 / beams 6 / environment 5 / charge 3
- **16 首 BGM**

### 2.3 玩法与数值

| 项 | Mindustry | coreforge |
|---|---|---|
| 建筑 | `Blocks.java` 7037 行 / **390 个** | 23 种 BlockKind |
| 单位 | `UnitTypes.java` 4674 行 / 65 构造（**62 可玩**，hp 70–24000、armor 0–30、speed 0.3–7.5、hitSize 8–66、reload 13–350） | 5 种敌人 |
| 配方 / 科技 | — | 4 配方 / 15 Tech |
| 波次 | `Waves.java` 35 个 SpawnGroup、19 种敌人，公式 `min(unitAmount + (wave-begin)/spacing/unitScaling, max)` | 20 波 |
| 难度 | 5 档 × 3 乘子 | — |

### 2.4 AI 预制基地

- `baseparts/*.msch`（**210 个**）是 **zlib 压缩的二进制 schematic**，是 AI 预制基地蓝图
  （`BaseRegistry` + `BaseBuilderAI`），**不是逻辑电路**。
- 真正可编程的系统是 **Mindustry Logic**：`LExecutor` 2426 行、17 个逻辑方块、
  `instructionsPerTick` 1–40、`maxLinks=6000`、脚本上限 100KB（压缩 16KB）。

### 2.5 联机

- **服务器权威**，客户端仅插值、**无预测**。
- 包 = 1 字节 id + 二进制 payload（`Net.registerPacket`）。
- 快照**限长 800 字节/包**；建筑同步 6s、血量 0.5s、计划 0.5s。
- 服务端是独立 Gradle 子项目 `mindustry.server.ServerLauncher`（headless）。

---

## 三、差距清单与优先级

| 优先级 | 项 | 差距 | 人日 |
|---|---|---|---|
| **D1** | 网络层（协议 / 权威 / 插值） | 完全缺失 | 120–177 |
| **D2** | 联机房间与同步细节 | 完全缺失 | （含 D1） |
| **D3** | 服务端部署与持久化 | 完全缺失 | （含 D1） |
| **A6** | 音效系统 | **SFX 27/27 已落地**，loop 0/6、BGM 0/2 | 剩 8（loop 6 + BGM 2）≈ 9；对齐 Mindustry 级别则 ≈25 + 30–45 |
| **B3** | 波次与难度曲线 | 20 波 vs 35 组 × 19 敌人 | 30–46 |
| **A1** | 建筑 sprite | 管线已通，**本体 18/18 已完成**，朝向 0/18 | 剩 9–18 |
| **A3** | 单位 / 敌人 sprite | 管线已通，素材 0/5（程序化已达标，列 P2） | 3–5 |
| **B1** | 逻辑（可编程）系统 | 无 | 185–294 |
| — | 数值/单位/配方扩表 | 23 建筑 / 5 敌人 vs 390 / 62 | 46–70 |
| — | 像素画规范落地（描边 / 光源 / 色槽） | **已完成**（`tools/artkit` 色阶表 + 生成器） | 0（余量已拆进 A1/A3） |

**总计 ≈ 402–619 人日**（按 coreforge 实际清单量的口径全量补齐，已含 A1 的 9–18、扣掉已落地的 27 个 SFX）。
若把 A6 抬到「对齐 Mindustry 205 SFX + 16 BGM」的级别（≈ 25 + 30–45 = 55–70 人日），
总计变为 **≈ 448–680 人日**。

其中 **coreforge 专属美术剩余 ≈ 25–49 人日**：
P0 待做 18 张朝向变体 ≈ 9–18；P1/P2 31 张（地形扩展 8 + UI 6 + 特效 12 + 敌人 5）≈ 16–31；
科技 15 张已于 2026-10-21 落地，见第八节。
音频剩 8 个（loop 6 + BGM 2）≈ 9 人日 —— **美术 + 音频剩余合计 ≈ 33.5–58 人日**。
（27 个 SFX 已于 2026-10-21 落地，见第九节；口径 0.3/SFX、0.5/loop、3/BGM。）

> ⚠ **美术人日大幅下降的原因**：原表按 Mindustry 的 390 建筑 / 62 单位估，
> 但 coreforge 实际只有 23 建筑（**全部 1×1**）+ 5 敌人，且规格已由 `tools/artkit` 固化为生成器流程。
> **不是把活推后了，是原本就估多了。**

### 建议落地顺序

1. **~~美术管线打通~~ —— ✅ 已完成（2026-10-20）**：`Gui.SpriteBatch` + 真实 PNG 位图已接通，
   落地 32px 画布 + 3px 描边 + 右上光源 + 三色槽；产出物品 12 + 地形 8 入库 `client/assets/`。
   架构、降级约定与踩坑见**第六节**。
2. **~~补建筑本体 sprite~~ —— ✅ 已完成（2026-10-21）**：18 个建筑格位打进单张 256×96 图集，
   逐格交错提交接进 `ForgeArt.zan` / `ForgeRenderer.zan`，详见**第七节**。
3. **~~补科技图标~~ —— ✅ 已完成（2026-10-21）**：15 枚 24×24 图标 + HUD `Image` 控件接入，
   详见**第八节**。HUD 的 PNG 图标控件接口已查清：走 `<img>` 控件（`Button.Icon` 是 SVG 字形名）。
   剩 **18 张朝向变体** = 9–18 人日。
4. **~~音效系统~~ —— ✅ 首批完成（2026-10-21）**：27 个 SFX（建造 8 / 武器 8 / 爆炸 5 / UI 6）已落地，
   自研合成 WAV + `System.Media` 播放层 + 事件映射层，运行时自检 27/27，详见**第九节**。
   剩 **6 个 loop + 2 首 BGM** ≈ 9 人日。
5. **波次与难度**：按 `Waves.java` 公式补 SpawnGroup 与 5 档难度。
6. **网络**：协议 → 权威 → 插值，按 D1/D2/D3 拆。

> **不要推倒重写系统**。coreforge 的逻辑层完成度不低，缺的是外面那层皮。

---

## 四、渲染路线选择（重要）

Mindustry 式 45° 俯视格子游戏，**走 2.5D 等轴测 + 2D 贴图批**：

- `Game.Arpg.IsoTileMap`（2:1 菱形，`GridToWorld` / `WorldToGrid` / `GetVisibleGridBounds`）
- `Game.Arpg.YSortLayer`（容量 2048，按脚底 Y 排序）
- `InputMapper.GetIsoGridMouse`（鼠标 → 格子）
- **`Gui.SpriteBatch`** 画预切好的菱形图块

**不要**走真 3D mesh + 正交相机——那是给 voxel / racekart 这类需要真透视的项目用的。

---

## 五、素材授权红线

Mindustry 素材**不可取用**：

- 仓库根只有 GPL-3.0，**素材没有独立条款**。
- `core/assets/contributors` 点名了 opengameart / freesound 的作者，但**没有逐件许可声明** → 灰区。
- GPL 传染。

**只把 Mindustry 当「规格」参考**（画布尺寸 / 描边半径 / 光源方向 / 色槽结构），
**不取任何像素**。像素画规格已抄进 `工作区根目录的 ASSET-PIPELINE.md` 第一节，全工作区共用。

---

## 六、本轮落地：位图管线（2026-10-20）

**做了什么**：在**不推翻**程序化绘制的前提下，把真实位图接进渲染层，
补掉「货物是纯色方块、地面是平色块」这两个最扎眼的观感缺口。

### 6.1 架构

| 文件 | 职责 |
|---|---|
| `coreforge/client/src/ForgeArt.zan` | 资源定位 + `Canvas.SpriteHandle` 缓存 + `SpriteBatch` 封装 + `COREFORGE_ART` 开关 |
| `coreforge/client/src/ForgeRenderer.zan` | `Terrain()` 拆为 `TerrainBase()`（底色 + 贴图）与 `TerrainDetail()`（液体边缘 / 碎石草簇 / 矿石）；`Cargo()` 改画真实物品贴图 |
| `coreforge/client/src/ForgeClock.zan` | `FixedStepClock` 本地副本（原因见 6.4） |
| `coreforge/client/assets/` | 21 个 PNG（38 个精灵：物品 12 + 地形 8 + 建筑 18 格位）+ `manifest.csv`（21 行数据） |
| `tools/artkit/` | 共享美术规范包：`palette.json` 色阶常量表 + `artkit.py` 生成器 + `gen_coreforge.py` + `zpx2png.py` |

**渲染顺序**（`Draw()`）：`Ensure` → `BeginTerrain` → 底色趟 → `FlushTerrain` → 细节趟 → 网格 → 建筑 →
`BeginItems` → 货物趟 → `FlushItems` → 敌人 → 光束。

**地形贴图夹在底色与细节之间**，tint `0x78FFFFFF`（47% alpha）——既让材质透出来，又不盖住程序化细节。

**资源定位**不依赖 `Game.Kit.Assets`：以 `ProcessHost.SelfExe()` 父目录为锚向上最多 4 级找 `client/assets/`，
再退化到 `Directory.GetCurrentDirectory()` 向上找；命中后缓存 `assetRoot`。

### 6.2 降级约定（硬规则）

**贴图是加分项，绝不能成为「能不能跑」的开关**：

- 句柄 <= 0 一律**静默跳过**，渲染器继续走程序化画法。
- `Canvas.SpriteHandle` 只在句柄 > 0 时才建 `SpriteBatch`（省 native 内存）。
- 资源定位失败 → 退化为全程序化，**不报错、不崩**。
- `COREFORGE_ART=0` 是**正式调试开关**：整体关掉贴图层，用于前后对照与降级自测。

### 6.3 验收证据

| 项 | 结果 |
|---|---|
| 编译 | `Compiled 252 files` → `build/coreforge/Coreforge.exe` |
| 逻辑套件 | `COREFORGE_TESTS_OK assertions=240` / `COREFORGE_VERIFY_OK assertions=240` |
| GUI 冒烟 | `COREFORGE_GUI_PASS frames=125`，`COREFORGE_CAM zoom=1 x=24.5 y=18.5 map=48x36 client=1920x1290` |
| 前后对照 | `before.png`（`COREFORGE_ART=0`）vs `after.png`（默认）：地面出现明显石材纹理，货物由纯色方块变为带描边 / 高光 / 落影的圆角锭块 |
| 差异量化 | 采样 275199 点：weak 70211 / mid 1969 / strong 127 |
| 素材总账 | `tools/verify-assets.ps1` → `VERIFY PASS`（11/11 项目，1095 图 / 162 音频） |
| 全工作区 | `tools/smoke-all.ps1` → `SMOKE-SUMMARY fail=0 / total=10` |

### 6.4 踩坑：`SpriteBatch` 同名去重（勿回退）

Zan 编译器**按简单名全局去重**。`Gui.SpriteBatch`（贴图批）与 `Game.Kit.SpriteBatch`（图元批）
在同一编译单元内双双变成 `undefined type`。

- 污染源是 `using Game.Foundation;`——它连带 `Game.Foundation.Gui`，其中 `GuiHost.zan` 有 `using Game.Kit;`，
  把 `Game.Kit` 拉进来撞名。
- `using Game.Core;` / `using Game.Factory;` **不**触发。
- 规避方案：coreforge **不 import `Game.Foundation`**，把唯一用到的 `FixedStepClock` 本地化为 `ForgeClock`；
  `ForgeArt` 只 `using Gui;`，`SpriteBatch` 一律写**无限定名**。
- 另一条语法事实：**限定名不能出现在数组元素位**（`Gui.SpriteBatch[]` → `undefined type`），
  必须写 `SpriteBatch[]`；数组初始化器必须 `new T[n] { ... }`。

> `ForgeClock.zan` 的源码注释与 `client/tests/verify.py` 的白名单注释都记了这条，
> 防止后人「优化」回 `Game.Foundation`。

### 6.5 已知局限

地形材质贴图虽然铺满全图，但因 `Rock()` 道具覆盖大部分格子，**视觉增益有限**
（前后空地均值 70,86,88 → 70,85,85）。这是道具覆盖率导致的，不是管线 bug。
真正拉开观感差距的是**建筑 sprite**——已在第七节落地。

---

## 七、本轮落地：建筑 sprite（2026-10-21）

**做了什么**：把 18 种建筑的静态本体从「深色矩形底板 + 纯色矩形本体」升级为
**像素画 sprite**，同时**保留全部程序化动态效果**（旋转、火焰、炮管、进度弧、辉光、水晶、叶片、力场泡）。

### 7.1 架构：单图集 + 逐格交错提交

| 项 | 决策 | 理由 |
|---|---|---|
| 图集 | **单张 256×96**（8 列 × 3 行 × 32px），格位序号 = `BlockKind` 序号（0..22） | 单图集 = 单一 bitmap 纹理 → 逐格提交**不触发 texture flush**；z 序 = 调用序 |
| 提交 | **逐格交错**：每格先 `BeginBuildings`+`AddBuilding`+`FlushBuildings`，再画该格动态部分 | 保留现有逐格 z-order；备选「L1 一次提交 + L2 全在最上层」会让炮管被后画建筑盖住 |
| 拆分 | sprite = 原程序化调用中**第一个动态元素之前**的静态前缀 | 动态元素一律留程序化，行为与旧版逐像素等价 |
| 无图 | `Empty` / `Belt` / `Wall` / `Pipe` / `Relay` 5 个 kind 留空 | 程序化画法已够用；Belt 靠货物贴图补质感 |
| ghost | 强制回退程序化 | tint 是**乘法**，无法复刻 ghost 的混合色 |

**关键红线**：sprite 必须**严格对应**程序化版的静态绘制调用，不得加入程序化版不存在的形状。
本轮已按此撤掉 Scatter 双管炮座 / Sniper 镜筒块 / Prism 晶体座 / Repair·Overdrive 底部小块 / Assembler 滑臂导轨。
像素画的三色阶、描边、斜面属既定美术风格（不算发明）。

### 7.2 落点

| 文件 | 改动 |
|---|---|
| `tools/artkit/buildings_coreforge.py` | 新建，18 个建筑像素画配方 + `draw_plate()` + `build_atlas()` |
| `tools/artkit/palette.json` | 新增 `buildings` 段：18 组 `plate` / `body` 三色阶 / `accent`，**逐字**对齐程序化版原色 |
| `tools/artkit/verify_buildings.py` | 新建，**全链一致性核对器**（见 7.4） |
| `tools/artkit/frame_diff.py` | 新建，两图像素差异统计 + 上下拼接对照图 |
| `coreforge/client/src/ForgeArt.zan` | 建筑图集句柄 + `buildingKind` / `buildingSlots` + `BuildingAvailable` / `BeginBuildings` / `AddBuilding` / `FlushBuildings`（批容量 64） |
| `coreforge/client/src/ForgeRenderer.zan` | 字段区加 `art` / `artKind` / `artX` / `artY` / `artW` / `artH`；`Building()` 入口算目标矩形；新增 `SubmitBuilding()`；**18 个建筑函数**各加 `if (art) { SubmitBuilding(); } else { 原静态调用 }` |
| `coreforge/client/assets/sprites/coreforge/buildings/atlas.png` | 256×96 图集，18 格有内容 / 5 格全透明 |

### 7.3 验收证据

| 项 | 结果 |
|---|---|
| 编译 | `Compiled 252 files` → `build/coreforge/Coreforge.exe`（exit 0） |
| 逻辑套件 | `COREFORGE_TESTS_OK assertions=240` / `COREFORGE_VERIFY_OK assertions=240`（exit 0） |
| GUI 冒烟（贴图开） | `COREFORGE_GUI_PASS frames=125 tick=182` / `COREFORGE_CAM zoom=1 x=24.5 y=18.5 map=48x36 client=1920x1290`，stderr 空 |
| GUI 冒烟（`COREFORGE_ART=0`） | `COREFORGE_GUI_PASS frames=125 tick=107`，stderr 空 —— **降级路径仍然可跑** |
| 全链核对 | `tools/artkit/verify_buildings.py` → `ok 分派表覆盖全部 18 个有贴图 kind` / `ok 图集 256x96，18 格有内容、5 格全透明` / `BUILDINGS_VERIFY_OK kinds=23 sprites=18` |
| 前后对照 | `compare_base.png`（改造前 vs 改造后，内建区 2× 放大，changed 9.04%，含两次截图的动画相位差）、`compare_art.png`（贴图开 vs 关，整帧 49.44%） |
| sprite 专属特征量化 | 描边色 `#4a4b53` 在贴图路径 **675 px**、程序化路径 **0 px** —— 描边只可能来自 sprite；炉心金 `#EDA65B` 34 / 30、钻头金 `#D5AE63` 90 / 36（贴图路径多出的是烘进 sprite 的支架与端口） |
| 目视 | `cmp_drill_art/noart`、`cmp_core_art/noart`：贴图版有描边 / 分层底板 / 三色阶 / 金色 X 支架，程序化版是纯色矩形 + 十字 |
| 动态层一致性 | 采样炉心：动态扇区 `0xB6E8CF` 在贴图路径 16 px / 程序化路径 14 px（差异仅来自两次截图的 tick 旋转相位）；中心盘三色阶 `0xEDA65B` / `0xFFDA8F` / `0xFFF2C1` 两条路径均存在 |

### 7.4 永久回归工具：`verify_buildings.py`

一条命令核对**五层**是否一致，命中任一环即失败退出：

```
BlockKind 枚举 → 生成器 SLOTS → ForgeArt.buildingSlots → palette.json buildings → atlas.png 像素
```

另外断言：`palette.json` 的三色是否**逐字出现在**对应程序化函数里；每个有图的建筑函数是否含 `art` 分支；
图集 18 格非空、5 格全透明。

```powershell
cd <工作区根目录>; $env:ZAN_HOME='D:/path/to/zan-lang'; python tools\artkit\verify_buildings.py
```

### 7.5 踩坑：`.zpx` 截图是 **BGRA**，不是 RGBA

引擎帧缓冲 `.zpx` 的像素是**内存序 B,G,R,A**（见 `zan-lang/scripts/zpx2png.py` 的头注释）。
本工作区的 `tools/artkit/zpx2png.py` 原先按 `Image.frombytes("RGBA", ...)` 直解，
导致**所有对照截图 R/B 逐字节对调**（画面颜色全反）。

- 现象：Core 中心金盘 `0xEDA65B` 显示成 `0x5BA6ED`。
- 结论：**游戏渲染本身无 bug**，是转换器解错通道；修法 = `Image.frombytes("RGBA", (w,h), raw, "raw", "BGRA", 0, 1)`。
- 影响：修正前生成的全部截图（`base_buildings` / `base_zoom` / 全部对照图）颜色都是反的，已全部重出。
- 注意：`atlas_preview.png` / `atlas_picks.png` 直接由 `atlas.png` 生成，**不受**此 bug 影响。

### 7.6 已知局限

- **朝向变体 18 张未做**：图集是单朝向，传送带 / 钻头 / 炮塔的旋转变体仍是程序化。
- **逐格交错提交 = 每建筑格 1 次 FFI**（`zan_game_sprite_batch`）：冒烟中性能与基线同量级
  （frames=125，tick 115–197，基线 177），暂不需优化。
- **贴图纹理过滤是 `ZGL_LINEAR`**（`zgl_bitmap_tex` 硬编码）：zoom=1 时 32→32 为 1:1 清晰，
  非整数 zoom 会线性模糊。不改引擎。
- **熔炉辉光次序**：art 模式下 `Glow(16,15,19,...)` 画在 sprite 之后，会轻微冲洗侧柱
  （程序化版侧柱在辉光之后、更锐利）——已接受。
- **炉心扇区与金环重叠**：`Sector(8..10)` 压在烘进 sprite 的金环（内径 8.5）上，
  两条路径次序相同（都在金环之后），行为一致。

---

## 八、本轮落地：科技图标（2026-10-21）

**做了什么**：给科技面板的 15 个科技节点各配一枚 24×24 像素画图标，
并打通「HUD 控件显示 PNG 位图」这条此前没人走通的路。

### 8.1 上一节留的坑：HUD 缺 PNG 图标控件

第七节留下的局限是「科技图标 15 张未做：HUD 缺 PNG 图标控件接口」。
本轮把它查清了——**引擎有 `Gui.Widget.Image` 控件，能显示 PNG 位图**，
问题不在引擎，在于接入姿势。读源码确认的结论：

| 结论 | 依据 |
|---|---|
| `Gui.Widget.Image` 支持文件路径来源，`Canvas.ImageWidth(src)` 同步解码 | `packages/Zan.Gui/src/Gui/Widget/Image.zan` L139-147 |
| **CSS `background-image: url()` 不可用** → 只能用 `<img>` 控件 | `packages/Zan.Gui/src/Gui/skins/base.css` L1661-1666 |
| `Button.Icon` / `IconView` 是 **SVG 字形名**（Tabler 语义名），承载不了 PNG | `Gui/Widget/Button.zan` / `IconView.zan` |
| `<img>` 的**字段名 = 元素 `id`**（AOT 生成 `partial class` 字段） | `stdlib/System/Compiler/GenHtml.zan` L206-212 |
| 运行时改 `src` 用 `SetProp("src", path)`：写 `Binding` + 置 `resolvedSrc = null` 强制重解析 | `Image.zan` L311-320 |
| `Binding<T>.Set` 在**常量绑定**上写 `constVal`（`live == false`）→ 运行时赋值生效 | `stdlib/System/Binding.zan` L28-38 |

### 8.2 接入姿势（四条硬约束）

1. **`<img>` 必须是 `<button>` 的兄弟节点**：塞进按钮里会和按钮自绘文字重叠/抢位
   （`Button.RenderIn` 自绘标签，子控件只在无文字无图标时才居中）。
   按钮加 `.grow` 吃掉剩余宽度。
2. **源图尺寸 = 显示尺寸**（24px 源图 = 24 CSS px）：
   `Canvas.BlitImage` 缩小时走**面积平均（box filter）**，像素画被缩一次就糊。
3. **皮肤必须把 `image` 的底色覆写成 `transparent`**：
   `base.css` 给 `image` 兜了 `--bg-tertiary` 底，不覆掉会在图标背后留一块方砖。
4. **src 必须运行时注入**：路径随安装位置变，设计稿里写不死。
   `CoreforgeHud.ApplyTechIcons()` 用 `ForgeArt.AssetPath()`（找不到返回 `""`）求绝对路径，
   再 `SetProp("src", path)`；路径为空则整枚 `visible = false` 静默隐藏
   ——`Image` 加载失败会画 alt 文本或 `"..."` 占位（`Image.DrawPlaceholder`）。

### 8.3 踩坑：自建宿主必须自己调 `OnLoad`

第一版接完，截帧里 15 个位置画的是 **alt 文本**（"基础工程""热工学"…），不是图标。
逐层排查后确认：**`OnLoad` 从未被调用**。

- `OnLoad` 是生成器的装载钩子，只在生成的 `CreateWindow()` 里被调
  （`stdlib/System/Compiler/GenForm.zan` L538-539）。
- coreforge 是**自建宿主**：`main.zan` 自己 `Form.CreateDark` / `UseSkin` / 管帧循环，
  只用 `CoreforgeHud.Root()` + `__WireForm(window)`，**不走生成器那条路**。
- 于是 `OnLoad` 里的 `ApplyTechIcons()` 一次都没跑 → `src` 恒空 → `Image` 走占位分支。

修法：`main.zan` 在 `window.Add(root)` 之后补一句 `CoreforgeHud.OnLoad(window)`，
顺序与生成器一致（建树 → 入树 → `OnLoad` → `__WireForm`）。

> **教训**：`OnLoad` 不是「设计稿自带的钩子」，是**生成器与宿主之间的约定**。
> 自建宿主时，钩子里的代码会静默不执行，且**不报任何错**——
> 这类「约定缺失」比代码 bug 更难查，症状还长得像资源问题。

### 8.4 美术：整图并集光照 + 暗底可读性

- **一个图标由十几个部件拼成时，必须按整图并集算一次光照方向**
  （`artkit.PixelCanvas` 收集部件后统一 `render`），否则部件接缝处出现明暗接缝。
  `artkit.pixel_shade` 已重构为共用 `edge_classes` + `shade_by_class`，
  重构前后 `atlas.png` 的 SHA256 **字节级一致**（`D1AA78FD…36ADD`）。
- **暗底可读性**是这轮新增的约束：科技面板底色是 `rgba(14,10,5,0.84)`，
  `METAL` 三色阶的暗面（`#2b3037`）和它几乎贴死。据此修了两枚：
  - `siege`（攻城火力）：炮管/底座从 `METAL` 换成 `LIGHT_METAL`，
    爆点加大提亮——原来整枚是一坨黑剪影。
  - `overdrive`（过护力场）：暗金环从压暗 60% 改到 50%。
- **`swarm`（铁蜂编队）** 从「三只等大旋翼」改成「一大两小」，
  且**臂杆必须从机芯连到旋翼中心**（早先只画了机身到 0.82×reach 的一段，
  旋翼浮在杆外头，整只读成"四个孤点"）。

### 8.5 落点

| 文件 | 改动 |
|---|---|
| `tools/artkit/tech_coreforge.py` | 新建，15 个 24×24 配方 + `TECH_ORDER`（= `ForgeCatalog.TechDef` 的 `techs[0..14]` 顺序） |
| `tools/artkit/palette.json` | 新增 `techs` 段（15 组 label + accent 主色） |
| `tools/artkit/artkit.py` | 新增 `ramp3` / `edge_classes` / `shade_by_class` / `PixelCanvas`；`pixel_shade` 重构（字节级等价） |
| `tools/artkit/gen_coreforge.py` | 接入科技图标生成；校验 `palette["techs"]` 键序 == `TECH_ORDER`，不一致直接 `SystemExit` |
| `tools/artkit/tech_preview.py` | 新建，联系表（棋盘底 + NEAREST 放大 + 中文名/slug 标签），供目视验收 |
| `coreforge/client/src/App.html` | 科技面板改为 15 个 `<img class="cf-techicon">` + 14 个 `<button class="cf-techrow grow">`（兄弟节点）；`data-fh` 560 → 600 |
| `coreforge/client/skins/coreforge/skin.css` | 新增 `image.cf-techicon { width: 24; height: 24; background: transparent; border-width: 0; }` |
| `coreforge/client/src/ForgeArt.zan` | 新增 `public static string AssetPath(string rel)`（找不到返回 `""`；**不改** `Resolve` 语义） |
| `coreforge/client/src/CoreforgeHud.zan` | 新增 `ApplyTechIcons()` + `SetTechIcon()`；`OnLoad` 末尾调用 |
| `coreforge/client/src/main.zan` | 补 `CoreforgeHud.OnLoad(window)` 调用（见 8.3） |
| `coreforge/client/src/ForgeInterface.zan` | 新增 `COREFORGE_TECH_PANEL=1` 开关（科技面板常开，供审阅/截图） |
| `coreforge/client/assets/sprites/coreforge/tech/*.png` | 15 张 24×24 RGBA |
| `coreforge/client/assets/manifest.csv` | 增至 36 行数据（新增 15 条 `tech` 记录） |

### 8.6 验收证据

| 项 | 结果 |
|---|---|
| 编译 | `Compiled 253 files` → `build/coreforge/Coreforge.exe`（exit 0） |
| 逻辑测试 | `COREFORGE_TESTS_OK assertions=240` + `COREFORGE_VERIFY_OK assertions=240`（11 组全过） |
| GUI 冒烟 | 贴图开 / 贴图关 / 科技面板开 三通道均 `COREFORGE_GUI_PASS frames=125`，stderr 0 字节 |
| 目视 | 15 枚在 HUD 暗底上全部清晰可辨、1:1 硬边无模糊（源图 24px = 显示 24px，无 box filter 重采样） |
| 联系表 | `tech_preview.png`（15 枚，棋盘底 + 9× 放大）逐枚核对 |
| 素材总账 | `tools/verify-assets.ps1` → `VERIFY PASS`（11/11 项目，1095 图 / 162 音频） |
| 全工作区 | `tools/smoke-all.ps1` → `SMOKE-SUMMARY fail=0 / total=10` |

### 8.7 剩余

- **朝向变体 18 张未做**：图集是单朝向，传送带 / 钻头 / 炮塔的旋转变体仍是程序化。
- **科技图标不进贴图批**：15 枚走 `Image` 控件独立加载（不走图集），
  因此不吃贴图批的 flush 优化，但换来的是能自由换源、缺图可单独隐藏。

---

## 九、本轮落地：音效系统（2026-10-21）

**做了什么**：给 coreforge 接上**第一批真实音效**——27 个 SFX 覆盖建造 / 武器 / 爆炸 / UI 四类。
全部**自研合成**（不取用任何第三方音频），从素材生成一路打通到运行时发声的完整链路。

### 9.1 架构：资产 → 播放层 → 映射层 → 触发点

| 层 | 文件 | 职责 |
|---|---|---|
| 资产 | `tools/artkit/audio_coreforge.py` | 27 个 SFX 的 DSP 配方（numpy 逐样本生成，种子确定性可复现） |
| 资产 | `client/assets/audio/*.wav` | WAV 16bit PCM 44.1kHz 单声道，27 个，总时长 11,610 ms |
| 资产 | `tools/artkit/verify_audio.py` | **质量门**：13 项检查（时长 / 峰值 / RMS / 直流偏置 / 削波 / 起始静音 / 频谱…） |
| 资产 | `tools/artkit/audio_preview.py` | 27 行波形 + 频谱联系表，供目视验收 |
| 播放层 | `coreforge/client/src/ForgeAudio.zan` | 打开设备、载入 clip、voice 账本、冷却、静音开关 |
| 映射层 | `coreforge/client/src/ForgeSfx.zan` | 逻辑层信号 → 27 个 SFX 编号 |
| 接线 | `coreforge/client/src/ForgeInterface.zan` / `main.zan` | UI 点击音、建造 / 研究 / 波次事件音、sim step 采样点 |

**信号源**（全部在客户端侧读，**不改 `zan-lang` 公共包**）：

- `ForgeEvents` 9 类事件（`sequence` + 64 槽环）；
- `ForgeEffect` 6 类特效（`kind` + `color` + `size`，靠 `world.effectCursor` 增量扫）；
- `ForgeBuilding.cooldown` / `ForgeUnit.cooldown` **跃升**（开火必表现为 cooldown 跃升）；
- 客户端直接调用点（`SelectBlock` / `Rotate` / `CaptureRegion` / `PasteAt` / `Feed` /
  `Research` / `Save` / `Load` / `PaintCell`）。

### 9.2 为什么不用 `Game.Foundation.AudioBus`

`Game.Foundation.AudioBus` 本就提供了分级音量 / 静音 / BGM 淡入淡出 / SFX 冷却，
**但 coreforge 不能 import `Game.Foundation`**（见 6.4）——
`using Game.Foundation;` 会连带 `Game.Foundation.Gui` → `Game.Kit` → `Game.Kit.SpriteBatch`
与 `Gui.SpriteBatch` 简单名撞车，直接编译失败。
故播放层自研：这也是 6.4 那条红线的**第二个受害者**。

### 9.3 SFX 映射表（27 项，定稿）

| 类别 | SFX | 触发源 |
|---|---|---|
| 建造 8 | `build_place` / `build_remove` / `build_reject` / `build_rotate` / `build_blueprint` / `build_select` / `build_produce` / `build_feed` | `Built` / `Removed` / `PaintCell` 错误 / `Rotate()` / `CaptureRegion`+`PasteAt` / `SelectBlock()` / `Produced` / `Feed()` |
| 武器 8 | `weapon_turret` / `weapon_scatter` / `weapon_sniper` / `weapon_mortar` / `weapon_prism` / `weapon_drone` / `weapon_hit` / `weapon_shield` | 建筑 cooldown 跃升（按 `kind` 分型）/ effect kind=1 色 `0xFFCF8AF2` / 单位 cooldown 跃升 / effect kind=1 色 `0xFFF5D9A0`·`0xFFD98E4A` / effect kind=1 色 `0xFF7ECAEC` |
| 爆炸 5 | `explode_enemy` / `explode_building` / `explode_nest` / `explode_drone` / `explode_suicide` | effect kind=2 色 `0xFFE8B06A` size 8/16（敌人）/ size 10（建筑）/ `NestDestroyed` / effect kind=2 色 `0xFF9ADCE8` / effect kind=2 色 `0xFFE8935A` |
| UI 6 | `ui_click` / `ui_research` / `ui_error` / `ui_wave_start` / `ui_wave_clear` / `ui_core_lost` | 全部 HUD handler / `Researched` / 失败分支 / `WaveStarted` / `WaveCleared` / `CoreLost` |

`Form.On(name, handler)` 是 name→handler 字典，**没有通配 / 全局点击钩子**，
所以 `ui_click` 必须**逐个 HUD handler 挂**，不能一处兜底。

### 9.4 踩坑五则

1. **`IAudioClient_SetEventHandle` 必须在 `IAudioClient_Initialize` 之后**（不是之前）。
   早先按 MSDN 措辞把 `SetEventHandle` 挪到 `Initialize` 前面 → 直接 `open failed: SetEventHandle failed`。
   MSDN 那句 "before" 是**文档讹误**，上游顺序是对的。
2. **早期「引擎有 bug」的结论被自己的 A/B 推翻了**。曾怀疑 `zan_audio_ready` 发布顺序竞态
   （worker 在 `SetEvent(zan_audio_init_evt)` 之后才进循环，主线程到 `zan_audio_open` 才置 ready）。
   为验证，用 TDM MinGW GCC 编译出 3 个变体（未修复 / 修复 / 追踪）做 A/B：
   **完全未修复的原始逻辑同样正常**（cursor 441→882→1323 推进、voice 正常回收）。
   再做三方对照：暂存 DLL / `zan-lang` CMake 新构建 DLL / GCC 重编译 DLL —— **三者行为一致，全部正常**。
   最终判定：引擎 WASAPI 混音器**没有 bug**，早先失败是**环境瞬态**
   （最可能是探针 1 的 `while (v.IsPlaying())` 死循环被硬杀后，WASAPI 端点残留悬挂客户端，污染了后续所有探针）。
   → **不修改 `zan-lang`、不接入本地补丁驱动**，`tools/zaudio-patch/` 已清理。
3. **静音不能用 `Audio.SetVolume(0)`**。原生主音量为 0 时混音循环不推进游标
   （`g = gain * master / 32767`，只有 `g != 0` 才推进），等于把每个 voice 冻在原地、
   槽位永不回收 → 发满 256 次后**永久静音**。故 `SetMuted` 走本层开关 + `Audio.StopAll()`。
4. **运行时不得阻塞等待 `IsPlaying()`**。播放时长由本层 voice 账本按 clip 时长记账，
   到期主动 `Stop()` 释放原生 slot；并发上限 48。
5. **信号采样必须在 sim step 粒度**。开火检测靠 `cooldown` 跃升，一帧内多次开火在渲染帧上采样会漏；
   故 `main.zan` 在 `while (clock.HasStep())` 循环内调 `game.TickAudio()`。

### 9.5 验收证据

| 项 | 结果 |
|---|---|
| 编译 | `Compiled 259 files` → `build/coreforge/Coreforge.exe`（exit 0，日志含 `bundled driver 'zan_audio'`） |
| 逻辑套件 | `COREFORGE_TESTS_OK assertions=240` / `COREFORGE_VERIFY_OK assertions=240`（exit 0） |
| 音频自检 | `COREFORGE_AUDIO_SELFTEST opened=1 started=27/27 driver=wasapi played=27 dropped=0`，stderr 0 字节 |
| 端到端真实玩法 | `COREFORGE_AUTOTEST_OK frames=265` + `COREFORGE_AUDIO opened=1 played=23 dropped=0`，stderr 0 字节 |
| GUI 冒烟 A（音开 + 贴图开 + 科技面板开） | `COREFORGE_GUI_PASS frames=125 tick=204` + `COREFORGE_AUDIO opened=1 driver=wasapi`，stderr 0 字节 |
| GUI 冒烟 B（`COREFORGE_AUDIO=0`） | `COREFORGE_GUI_PASS frames=125 tick=190` + `COREFORGE_AUDIO opened=0 driver=` —— 降级路径仍可跑 |
| GUI 冒烟 C（`COREFORGE_ART=0`） | `COREFORGE_GUI_PASS frames=125 tick=131` —— 贴图层与音效层互不干扰 |
| 音频质量门 | `tools/artkit/verify_audio.py` → `CORE_FORGE_AUDIO_VERIFY_OK count=27 total_ms=11610 sr=44100 ch=1`（exit 0） |
| 联系表 | `audio_preview.png`（1146×1308，27 条波形 + 频谱）逐条核对 |
| 素材总账 | `tools/verify-assets.ps1` → `VERIFY PASS`（11/11 项目，1095 图 / 162 音频） |

### 9.6 剩余

- **6 个 loop**（传送带 / 钻头 / 熔炉 / 装配机 / 发电 / 蜂群）：需无缝循环 + 首尾波形对齐 → OGG Vorbis。
- **2 首 BGM**（建造期 / 战斗期）：OGG Vorbis 60–120s 立体声，需淡入淡出。
- 两者都要接进播放层的**长音通道**——当前 `ForgeAudio` 是「起播 + 记账 + 释放」模型，
  没有循环与渐变概念，落地前需先扩播放层。

## 十、界面错位根因与修复

### 10.1 取证方法：实测坐标，不是截图目测

错位是像素问题，断言证明不了画面没歪。上一轮"控件树是否对得上设计稿"的排查被推翻重建：
**截图目测无法定位像素错位**，必须拿到控件树的实测矩形。

本轮建立（并长期保留）的取证通道：

| 环节 | 做法 |
|---|---|
| 登记根控件 | `main.zan` 在 `window.Add(root)` 之后调 `UiDriver.SetRoot(root)`——`dump tree` 只遍历 `SetRoot` 登记过的控件；标准宿主 `Form.Run` 会登记，自建循环不登记就永远拿不到树 |
| 取实测坐标 | `ZAN_UI_SCRIPT` 跑 `wait 600 / dump tree tree.json / quit`；`tree.json` 给出每个控件的 `x/y/w/h`（画布物理像素） |
| 与设计稿对账 | `tools/artkit/hud_layout_audit.py`：把设计稿的 `data-fx/fy/fw/fh` 换算到同一坐标系逐控件比对，输出 `offset / missing / hidden / ok` 汇总 |

**对账口径的三条硬规则**（都踩过）：
1. 父子关系按**元素 id** 建栈，不按标签名——设计稿里 `Overlay` 是 `<div>`，按标签名找不到父级，整列坐标会退化成相对 root 算。
2. 设计稿 `body` 的 id（`CoreforgeHud`）与运行时根控件名（`root`）不同，要做别名映射。
3. 祖先不可见时整棵子树跳过几何判定（`Banner`/`Tech`/`Detail` 初始隐藏，不能按 0×0 判偏移）。

### 10.2 结论：控件树没错位，错位在世界层与 HUD 的叠加关系

对账结果 **`offset=0 / missing=0 / ok=43`**（107 个节点，64 个因祖先隐藏跳过）——
**控件树与设计稿逐像素吻合**。所以用户看到的"错位"不在控件树里，而在**画布直绘的世界层**上。

根因：`ForgeInterface.Render()` 里 `camera.SetViewport(0, chromeTop, clientW, clientH - chromeTop)`
——世界视口从标题栏下沿一直铺到窗口底，**整幅地图压在半透明的顶栏（86%）、工具栏（72%）、建造栏（88%）、状态栏（90%）底下**。
顶栏里那个"不明圆形图标"既不是控件也不是图标映射错误，
是**地图顶行（过护标记双 chevron，0xFFF2C06A）透过 86% 暗底被压成暗褐**露出来的。

### 10.3 六处修复

| # | 位置 | 旧 | 新 |
|---|---|---|---|
| 1 | `ForgeInterface.Render()` | 视口 `chromeTop..clientH` | 视口收进 chrome 自由区 `worldTop..worldBottom`；chrome 区补世界底色 `0xFF202D30`（视口裁剪只挡世界绘制，底色得自己铺，否则半透明 chrome 底下会露上一帧残影） |
| 2 | `ForgeInterface.UpdateWorldBand()`（新增） | — | 上界 = `Overlay.by`（顶栏+工具栏之下），下界 = `min(Palette.by, Statusbar.by)`；控件矩形来自上一帧 `Arrange`（帧序 Render 排在 Arrange 之前），允许 1 帧延迟，首帧用设计值兜底（80 / 102） |
| 3 | `ForgeInterface` 的 `uiScale` | `clientW / 1280.0`（单轴推算） | `app.Scale(100) / 100.0`——**与控件树同源**（DPI 150%）；旧口径窗口一变宽就跟控件树分家。`App.Scale(v)=v*dpiScale/100`（`App.zan:4607-4609`） |
| 4 | `WavePreview()` | `y = chromeTop + S(92)`（自有一套位置） | 占设计稿 **Banner 槽位**（`Overlay + fx360/fy62/fw560/fh46` → 540,261 840×69），开波瞬间 HTML 横幅接管同一块矩形——**消灭开波跳位** |
| 5 | `App.html` | 建造栏左对齐；状态栏排在建造栏之后 | 建造栏加 `justify-center`（`base.css` 有 `flex.justify-center`）；**状态栏整块前移**——引擎 bottom 停靠是"按插入顺序自下而上堆叠，先写进来的贴最底"（`Control.zan:2821-2860`），不前移的话贴到窗口底的是建造栏，与设计稿"状态栏（最底）"相反。两块合计仍 102 设计像素，底栏总高不变 |
| 6 | `App.html` 的 `Detail` | `data-fh="230"` 写死 | 去掉固定高，**随内容自适应**（实测 399×345 → 399×146），消掉正文两行时 200 多像素的空面板 |

顺带修掉两处同源的坐标笔误：
- `ThreatArrows()` 里 `mx` 的下界写成了 `chromeTop + S(26)`——**把 Y 值当成了 X 的下界**，西侧箭头被硬推到右边 39px 以外。
- `Minimap()` 的视口框原用 `clientW`/`clientH-chromeTop` 算，改用 `camera.viewportW/viewportH`；小地图 Y 从写死的"底栏 102 设计像素"改为 `worldBottom - miniH - S(12)`。

### 10.4 刻意没动

- **世界层不做 DPI 放大**。`ForgeGrid.TileSize()==32`，建筑 sprite 32×32 在 zoom=1 时是 1:1 物理像素；放大到 1.5 像素画会糊（`Image` 缩放走面积平均）。设计稿 1280×860 只约束 HUD。
- **地图左右 176/208px 的留白差 16px**：`ForgeCamera.Focus()` 对焦炉心**格心**（`x = coreCell%width + 0.5`）的自然结果，不是坐标 bug。
- ~~**面板 84% 半透明**~~：属"可读性/观感"而非坐标错位，单独决策后已落地，见 10.6。

### 10.5 波次预告条：文字掉出条外（第二轮补修）

上一轮把预告条挪进了设计稿 Banner 槽位（540,261 840×69），但**用户复测仍报"文字掉到条子外面"**。
这次不再靠目测，直接**逐像素量**：

- 条子内壁实测 abs **261..330**（高 69 = `S(46)` ✓，槽位本身没错）；
- 橙色文字墨迹实测 abs **309..328**——**整段贴着下沿，字形底边正好切在下边框上**。

根因不是坐标算错，是**用错了 `Canvas.DrawText` 的 y 语义**：
`y` 是**字形墨迹盒的顶边**，栅格器按基线摆放字形、墨迹还会整体下移一个 leading
（`Canvas.zan:899-909` 的 `FontPadTop`/`FontLeadTop` 就是量这件事的）。
旧代码手算 `cy = y + height/2 + S(5)`，等于把"盒子中心"当成"墨迹中心"，**系统性偏低约 23px**。

引擎其实早就备好了居中helper（`Canvas.zan:889-918`）：

- `Canvas.CenterTextY(rectY, rectH, fontSize)` —— 在盒子里居中一行文本；
- `Canvas.CenterTextYAt(centerY, fontSize)` —— 以中线为准居中，**墨迹盒横跨 centerY**。

修法：`WavePreview()` 里所有文本统一走 `Canvas.CenterTextYAt(midY, fs)`，
字号分 `fsHead=S(14)` / `fsChip=S(13)`，色点圆心仍取 `midY`——**文字与色点共线**。

复测：墨迹 abs **287..306**，中心 296.5，条子中心 295.0，**偏差 1.5px**（修前偏 23px）。

> 教训：**引擎已有 helper 就不要手算常量**。墨迹盒 ≠ 行盒 ≠ 盒子中心，三者差值由字体
> leading 决定，硬编码偏移量必然在某处错位。

### 10.6 侧面板透明度：0.84 → 0.92（观感决策落地）

`flex.cf-panel`（`Objectives` / `Detail` / `Tech`）原先是 `rgba(14,10,5,0.84)`。
先查清一件事：**只有这三个面板真的浮在会动的东西上面**——
顶栏/工具栏/建造栏/状态栏背后在 10.3 已经铺了不透明的世界底色 `0xFF202D30`，
它们的透明度根本不漏地形。所以改 `cf-panel` 精准命中，不动其他四块的玻璃感。

实测（面板右侧无文字留白带的底色波动，衡量地形透出的强度）：

| alpha | 目标面板留白带 | 背景亮度幅度 | stdev |
|---|---|---|---|
| 0.84 | abs 358..376 | 16..37（幅度 21） | 2.67 |
| 0.92 | abs 358..376 | 12..24（幅度 11） | 1.38 |

**地形透出减半**，同时保住一点玻璃感。文字/底色的对比度本就在 9.4:1（远高于 WCAG AA），
这次要解决的是"砖纹在字后面晃"的视觉噪声，不是可读性不达标。

> 皮肤是**运行时读盘**（`app.UseSkin("coreforge")` 相对运行目录解析），
> build.ps1 只负责把 `skins/` 拷到 exe 旁边——**改 skin.css 必须重跑 build** 才生效。

### 10.7 验收证据

| 项 | 结果 |
|---|---|
| 排版对账（最终二进制） | `SUMMARY total=107 offset=0 missing=0 hidden=64 ok=43` |
| 波次条像素实测 | 墨迹 287..306 / 中心 296.5 vs 条心 295.0，偏差 1.5px（修前偏 23px） |
| 引擎 LayoutLint | 仅 3 条"固定尺寸"（顶栏 `data-fh="32"` 的三个按钮，设计如此）；**无重叠、无裁剪告警** |
| 编译 | `Compiled 259 files` → `build/coreforge/Coreforge.exe`（exit 0） |
| 逻辑套件 | `COREFORGE_TESTS_OK assertions=240` / `COREFORGE_VERIFY_OK assertions=240` |
| GUI 冒烟 | `COREFORGE_GUI_PASS frames=125`，stderr 0 字节 |
| 自动测试 | `COREFORGE_AUTOTEST_OK frames=265` + `played=23 dropped=0` |
| 音频自检 | `opened=1 started=27/27 driver=wasapi played=27 dropped=0` |
| 素材总账 | `tools/verify-assets.ps1` → `VERIFY PASS` |
| 全工作区冒烟 | `tools/smoke-all.ps1` → `SMOKE-SUMMARY fail=0 / total=10` |
| 前后对比图 | `build/coreforge/cf_hud_before_after.png`（左=修复前，右=修复后） |
| 波次条前后对比 | `build/coreforge/cf_banner_before_after.png`（上=修前，下=修后） |
| 面板透明度前后对比 | `build/coreforge/cf_panel_alpha_before_after.png`（左=0.84，右=0.92） |
| 科技面板通道 | `COREFORGE_GUI_PASS frames=125`，15 枚图标 1:1 清晰 |

### 10.8 遗留

- ~~**科技面板行内资源数被截断**~~：**已修**，见第十一节。
- **窗口拉伸**：画布 HUD 与控件树都锚在 DPI 倍率，窗口拉伸时两者同步；但世界层是 1:1 物理像素，放大窗口世界不会跟着变粗（有意为之，护像素清晰度）。

---

## 十一、本轮落地：科技面板收口（2026-10-21）

**做了什么**：把科技面板"8/14 行被截断 + 图标宽度不等 + 图标被拉糊"三个症状一次收掉，
顺带修正"资源不足被标成锁定"的语义错误、目标面板第 5 条的难看断点、以及**顶部两条标题栏重复**。

### 11.1 三个症状，一个根因

| 症状 | 表面现象 | 真实根因 |
|---|---|---|
| 行内资源数被截断 | 8/14 行末尾出现 `…` | 按钮文本自然宽（最坏 tech13 = 487px）> 可用宽（381px），`Ellipsis.Fit` 截断 |
| 图标宽度不等（29/32/35/36 物理像素） | 名称列左缘呈锯齿 | **同一个根因的下游**：文本溢出后按钮按 `flex-shrink` 被压缩，图标跟着按比例被压 |
| 图标被拉糊 | 像素画边缘发虚 | CSS `width:24` × DPI 1.5 = **36 物理像素**，而源图只有 24×24 → `Image` contain 放大 1.5× |

> 第十节末尾写的是"要么加宽面板，要么让行高自适应换行，两者都是设计改动"——
> **前提判断错了**：加宽要动设计稿 `data-fw="330"`，但**压短文本不动任何设计稿**。
> 定案：科技行改成**单行压缩格式**，宽度问题在文本侧解决。

### 11.2 行内格式：`<状态字形> <名称> <紧凑成本串>`

旧格式 `"✔ 已完成 · " + t.name + "　" + Cost(t.cost)` 里，`Cost()` 产出的是
`"名 数字  名 数字"`（双空格分隔、名与数字之间也留白）。压成 `TechCost()`：
`"铜40 铅30 硅12 钢15"`——项名紧跟数字、项间单空格。

**`Cost()` 保持原样**（详情面板够宽、留白更好读），科技行另开一个函数。

| 科技 | 旧自然宽 | 新自然宽 | 可用宽 |
|---|---|---|---|
| tech1 热工学 | 263 | 212 | 385 |
| tech13 过护力场 | **487** | **370** | 385 |

改后 14 行自然宽最大 370 ≤ 可用 385 —— **不再截断**。

### 11.3 四态语义修正（顺带修掉一个逻辑错误）

旧代码只有一个布尔：

```zan
bool ready = !finished && w.researched[t.parent] && w.resources.Has(t.cost);
Text = (finished ? "✔ 已完成 · " : ready ? "▶ 研究 · " : "🔒 锁定 · ") + ...
```

`ready` 把"前置没研究"和"资源不够"混成一种情况，两者都显示"🔒 锁定"——
玩家分不清是差前置还是差材料。拆成两态：

| 状态 | 判定 | 字形 | 文字色 |
|---|---|---|---|
| 已完成 | `researched[i]` | `✔` | `#8fae4e` |
| 可研究 | 前置已完成 + 资源够 | `▶` | `#ffe9c8` |
| 资源不足 | 前置已完成 + 资源不够 | `⚠` | `#d9a13c` |
| 前置未完成 | `!researched[parent]` | `🔒` | `#6a5f49` |

行内**不再放状态词**（宽度预算不够），改用"字形 + 文字色"两重区分，
再在面板标题下加一行图例 `✔已完成 ▶可研究 ⚠缺资源 🔒未解锁`（`label.cf-legend`，font-size 11）补第三重。

### 11.4 状态色必须压过 `button:disabled`

四个状态里有三个对应 `Disabled = true` 的行，而 `base.css:351` 有：

```css
button:disabled { background: var(--disabled-bg); color: var(--disabled-fg); ... }
```

特异性 (0,1,1)。皮肤若只写 `button.cf-tech-done`，同为 (0,1,1)，
**靠后胜出**但 `Style.EasedStateId` 在 disabled 时直接返回 `:disabled` 外观——
状态色根本轮不到生效。皮肤改用**双类选择器** `button.cf-techrow.cf-tech-*`（特异性 0,2,1）压过它。

> `Control.SetClassIn(group, cls)` 的 `cls` **必须是单个类名**：多类字符串会让 `AddClass`
> 因 `Style.Has` 命中而整串跳过。group 里也不放 `cf-techrow`/`grow`，否则会误删基础类。

### 11.5 图标 1:1：CSS 16，不是 24

**像素画缩放会糊 → 源图尺寸必须等于显示尺寸。** 15 枚源图全是 24×24，
CSS 写 24 会被 DPI 放大到 36 物理像素 → 1.5× 重采样。
改 CSS `16`（= 24 物理像素）后 1:1。

实测（屏幕墨迹框 ÷ 源图 alpha 框）：

| | 改前 | 改后 |
|---|---|---|
| 14 枚图标缩放比 | 1.19 / 1.23 / 1.30 / 1.32 / 1.33 / 1.36 / 1.42 / 1.50 | **全部 1.00** |

> `tools/artkit/tech_coreforge.py` 里"24px 源图配 24 CSS px 盒子 = 1:1"的注释
> 在 dpiScale=150 下**不成立**，已一并更正。

### 11.6 目标面板第 5 条：硬换行

改前自动换行断在 `打退第 3` / `波进攻，迎敌按钮提前开战`——断在半句中间。
改用 `"\n"` 硬换行（`TextWrap.Lines` 把字节 10 当硬断行），断在短语边界：

```
打退第 3 波进攻
迎敌按钮提前开战
```

### 11.7 重复标题栏：只留框架窗口条

框架窗口条（`Form.CreateDark("炉心边境 · COREFORGE", ...)` + `app.RenderChrome(title)`，
自带最小化/最大化/关闭）与应用内 Topbar 的 `cf-brand` / `cf-brand-sub` 并排重复。
删掉应用内那份（`App.html` 两行 + `skin.css` 两条规则），保留框架那条。

> 不用 `app.SetChromeVisible(false)`：那会把最小化/最大化/关闭一并弄没。

### 11.8 验收证据

| 项 | 结果 |
|---|---|
| 科技行自然宽（改后） | 14 行 `prefW` 242..400，最大 400 − 30 = **370 ≤ 可用 385**，无截断 |
| 科技行截断 | 改前 8/14 行带 `…` → 改后 **0** |
| 图标几何 | 14 枚全部 `x=43 w=24 h=24`（左缘完全齐平） |
| 图标像素 | 14 枚缩放比全部 **1.00×1.00**（改前 1.19–1.50） |
| 四态颜色（实拍） | ✔ `#8fae4e` / ⚠ `#d9a13c` / 🔒 `#6a5f49` / ▶ `#ffe9c8`，逐像素命中 |
| 四态字形 | `✔`(U+2714) / `▶`(U+25B6) / `⚠`(U+26A0) / `🔒`(U+1F512) 全部实拍渲染正常（非豆腐块） |
| 目标面板断点 | 断在短语边界（见 11.6 对照图） |
| 顶栏 | 只剩框架窗口条一条标题 |
| 编译 | `Compiled 259 files`（exit 0） |
| 逻辑套件 | `COREFORGE_TESTS_OK assertions=240` / `COREFORGE_VERIFY_OK assertions=240` |
| GUI 冒烟 | `COREFORGE_GUI_PASS frames=125`，stderr 0 字节 |
| 四态实拍方法 | UiDriver `click 286 305` 点一次"热工学"，同一帧拍到 ✔/⚠/🔒 三态 |
| 前后对比图 | `build/coreforge/cf_tech_before_after.png`、`cf_tech_icons_before_after.png`、`cf_objectives_before_after.png`、`cf_topbar_before_after.png` |

### 11.9 踩坑与遗留

1. **截断会顺着 flex 传导到邻居**：文本溢出 → 按钮被 `flex-shrink` 压缩 → 图标跟着被压。
   看到"图标宽度不等"要想到上游是文本，不是样式写歪了。
2. **`SetClassIn` 的 `cls` 只能是单类名**；多类会被 `Style.Has` 命中后整串跳过。
3. **禁用态会吃掉状态色**：`button:disabled` 特异性 (0,1,1)，状态色必须 (0,2,1) 才压得住。
4. **科技表数据源在引擎包 `Zan.Game.Factory`**（禁改区），展示层只能压缩文本、不能改数值。
5. **面板宽度仍是 330 设计像素**（`data-fw="330"` / `data-fh="600"`），本轮未动——
   压缩后右侧留白充裕，但改设计稿值需要另行拍板。
6. **`.zan` 是 CRLF、`.md`/`.html`/`.css` 是 LF**：改文件前先验行尾，
   否则补丁会引入裸 LF 或全文件行尾翻转（本轮补丁脚本按字节读写，逐字节断言"恰好命中一次"）。


## 第十二节 停靠栈被 flex 溢出收缩压扁 8px（2026-10-22）

### 12.1 症状

科技面板打开时，整条停靠栈矮 8 物理像素，连带下方的自由几何面板与波次条一起上移：

| 项 | 改前 | 改后（设计稿） |
|---|---|---|
| Topbar | 0,48 **1920x64** | 0,48 1920x69 |
| Toolbar | 0,112 **1920x48** | 0,117 1920x51 |
| Overlay 顶 | **160** | 168 |
| 科技面板顶 | **181** | 189 |
| 波次条槽位（同时开波） | 540,**247** | 540,261 |

> 波次条同时可见时收缩更多：顶栏 61 / 工具栏 45 / Overlay 顶 154 / 波次条 247，合计 **−14px**。
> 收缩量取决于当帧 Overlay 内容有多高，所以它是**内容驱动**的，不是固定值。

### 12.2 根因：不是 `data-fh` 失效，是 flex 溢出收缩

上一轮记的结论「`data-fh` 对 HTML 容器不生效、容器高度由内容决定」**是错的**，此处更正：

1. **`data-fh` 对这两条栏是生效的**。`<zan-flex data-fh="46">` 的 `prefH = app.Scale(46) = 69`；
   `Control.StyleHeightIn`（`Control.zan:932-950`）在 `declaredH == 0` 时走
   `computedStyle.HeightIn(avail, prefH)` → CSS 未声明 `height` → 回退 `prefH` = 69。
   （`declaredH` 需要 `Control.DeclareHeight()`，只有设计器 JSON 路径会调 —— 那条结论只对「需要
   `declaredH` 的场景」成立，与本例无关。）
2. **真正的塌陷发生在 root 的 flex 列**。`body[data-layout-mode="1"]` 是 flex 列容器；
   科技面板（`data-fh="600"` = 900 物理像素）把 Overlay 的内容高撑到 **1199 > 可用 1242**，
   于是触发 `Control.zan:3527-3567` 的**溢出收缩分支**：把所有 `flex-shrink != 0` 的子项
   按比例压缩。顶栏 69→64、工具栏 51→48（比例 69:51 ≈ 5:3），停靠栈因此矮 8px。
3. **该收缩分支不查 min/max**（`Control.zan:3556` 直接 `sz = sizes[i] * room / flexMain`）。
   本轮先试 CSS `min-height: 46 / 34` —— **无效**，因为根本没走 `ClampHIn`。
   改用 `flex-shrink: 0`（走 `StyleBox.shrink` / `Control.StyleShrink()`）才成。

### 12.3 修法

`client/skins/coreforge/skin.css`：

```css
flex.cf-topbar  { ...; flex-shrink: 0; }
flex.cf-toolbar { ...; flex-shrink: 0; }
```

固定高度的界面骨架（顶栏 / 工具栏）不参与内容驱动的收缩。引擎里 `flex-shrink` 未声明时默认 1
（`Control.zan:1003-1008`），声明 0 即被排除出收缩集合（`Control.zan:3541` 计入 `fixedMain`）。

### 12.4 验收证据

| 项 | 结果 |
|---|---|
| 停靠几何（科技面板开） | Topbar `0,48 1920x69` / Toolbar `0,117 1920x51` / Overlay `0,168 1920x1122` / 科技面板 `21,189 495x900` |
| 停靠几何（面板关） | 同上，Overlay `0,168 1920x1122` / 目标面板 `21,189 357x273` / 详情 `1500,189 399x146` |
| 波次条实测 | `540,261 840x69`（改前 `540,247`）—— 精确落回设计槽位 |
| 顶栏琥珀下缘像素 | 改前 `y=106` → 改后 `y=114`（**+8px**） |
| 面板顶边像素 | 改前 `y=182` → 改后 `y=190`（**+8px**） |
| 布局审计（面板开） | `SUMMARY total=107 offset=0 missing=0 hidden=40 ok=67` |
| 布局审计（面板关） | `SUMMARY total=107 offset=0 missing=0 hidden=64 ok=43` |
| 科技行截断 | 14 行自然宽 212..370 ≤ 可用 385，**0 行截断**（与第十一节一致） |
| 图标几何 | 15 枚全部 `x=43 w=24 h=24`；14 个按钮全部 `x=79 w=415 h=42` |
| 编译 | `Compiled 259 files`（exit 0） |
| 逻辑套件 | `COREFORGE_TESTS_OK assertions=240` / `COREFORGE_VERIFY_OK assertions=240` |
| GUI 冒烟 | `COREFORGE_GUI_PASS frames=125`，stderr 0 字节 |
| 前后对比图 | `cf_dock_before_after.png`、`cf_wavebar_before_after.png`（同代码仅差一行 CSS 的干净 A/B） |

### 12.5 踩坑与遗留

1. **审计盲区**：自由几何面板的期望值由**运行时父节点原点**推导
   （`tools/artkit/hud_layout_audit.py` 第 195-200 行）。顶层停靠行总高一变，
   面板与波次条**一起**平移 → 审计照样报 `offset=0`，看不见停靠行本身被压扁。
   这次能抓到，是因为改前后的**波次条槽位期望值**随 Overlay 顶一起挪了 14px。
2. **「prefH ≠ 实际高」有多种成因**（作者声明高 / flex 收缩 / 容器溢出），
   必须逐层读引擎（`ApplyDeclaredUnits` → `StyleHeightIn` → `DockSize` → flex 收缩分支），
   不能凭现象下结论 —— 上一轮就因为先入为主把收缩误判成「`data-fh` 失效」。
3. **CSS `min-height` 在 flex 收缩路径上无效**：收缩分支不经过 `ClampHIn`。
   要钉住骨架高度得用 `flex-shrink: 0`，不是 `min-height`。
4. **收缩量随当帧内容变化**：科技面板开 → −8px；科技面板 + 波次条同时开 → −14px。
   验收必须覆盖「面板开/关 × 波次开/关」四种组合，不能只看一种。
5. **改皮肤后必须重跑 `build.ps1`**：皮肤是构建期拷到运行目录的，运行时读盘。
6. `DIAGNOSIS.md` / `App.html` / `skin.css` 是 LF 无 BOM，`.zan` 是 CRLF 无 BOM —— 本节追加后行尾不变。
