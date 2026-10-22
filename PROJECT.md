# coreforge —— 独立项目

本项目从 zan-lang 仓库的 `templates/game/coreforge` 导出（导出日期：2026-10-20）。
该模板已搬出语言仓库（体量超出示例级模板位），历史版本在 `archive/coreforge-2026-10-20` 标签上；逻辑层仍是仓库的 `packages/Zan.Game.Factory` 包（公共包，规则 14），项目通过 --package-project $env:ZAN_HOME 直接吃仓库的包。
语言仓库只放 SDK、公共包与**示例级**模板；产品级游戏在这里自己演进。

## 目录

    coreforge/
      client/      客户端：src/ assets/ data/ tools/
                   客户端用例在 client/tests/
                   assets/sprites/coreforge/{items,terrain,buildings,tech}/*.png
                   assets/audio/*.wav（27 个音效，WAV 16bit PCM 44.1kHz 单声道）
                   assets/manifest.csv（素材清单，63 行数据 = 53 个精灵 + 27 个音效）

所有命令都在**项目根**下执行（路径一律相对项目根）。

## 编译

```powershell
$env:ZAN_HOME = 'D:/path/to/zan-lang'   # 编译器与 stdlib 同源
pwsh -File client/tools/build.ps1
```

ZAN_HOME 指向 zan-lang 仓库时用它的 `build/zanc.exe` 与 `stdlib/`；
不设则用 PATH 上的 `zanc`。stdlib 也可用 ZAN_STDLIB 单独指定。

## 公共包

包从三处解析：`<项目根>/packages/`、`<项目根>/.zan-packages/`、
全局 `%LOCALAPPDATA%\Zan\packages`。需要某个包时：

```powershell
Copy-Item -Recurse <zan-lang>/packages/<Name> packages/<Name>
```

或编译时加 `--package-project <zan-lang>`（直接吃仓库里的 packages/）。

## 测试

```powershell
pwsh -File client/tools/test.ps1     # 客户端用例
```

## 素材管线

位图层由 `client/src/ForgeArt.zan` 负责，素材本身由工作区共享的 `tools/artkit/` 生成。

> **注意**：`tools/artkit/` 是多项目工作区层面的共享美术工具包，**不随本仓发布**。
> 本仓 `client/assets/` 里的 PNG / WAV 都是它生成后**入库**的结果，
> 所以**克隆本仓即可直接构建、运行、游戏本体完整**；
> 只有「想重新生成素材」这一步需要另外取得该工具包。

### 资源定位

`ForgeArt.zan` **不依赖** `Game.Kit.Assets`，自己找资源：以 `ProcessHost.SelfExe()` 的父目录为锚，
向上最多 4 级找 `client/assets/`；找不到再退化到 `Directory.GetCurrentDirectory()` 向上找。
命中后缓存 `assetRoot`，后续 `Canvas.SpriteHandle(path)` 直接吃绝对路径。

### 降级约定

**贴图是加分项，不是「能不能跑」的开关**：

- 句柄 <= 0 一律静默跳过，渲染器继续走程序化画法。
- 资源定位失败 → 全程序化退化，**不报错、不崩**。

### 建筑 sprite 图集

18 个建筑格位打进**单张 256×96 图集**（`assets/sprites/coreforge/buildings/atlas.png`），
格位序号 = `BlockKind` 序号（0..22），`Empty`/`Belt`/`Wall`/`Pipe`/`Relay` 5 格留空。

- **单图集 = 单一 bitmap 纹理** → 逐格交错提交不触发 texture flush，z 序 = 调用序。
- `ForgeRenderer.Building()` 入口算好目标矩形，`SubmitBuilding()` 提交贴图；
  随后该建筑的**动态部分**（旋转 / 火焰 / 炮管 / 进度弧 / 辉光）仍走程序化。
- **ghost 预览强制回退程序化**：tint 是乘法，无法复刻 ghost 的混合色。
- 改建筑外观后必跑 `python tools\artkit\verify_buildings.py`——它逐层断言
  `BlockKind` → 生成器 `SLOTS` → `ForgeArt.buildingSlots` → `palette.json` → `atlas.png` 像素全链一致。

### 科技图标（HUD Image 控件）

15 枚 24×24 PNG（`assets/sprites/coreforge/tech/<slug>_icon.png`）挂在科技面板上，
slug 顺序 = `ForgeCatalog.TechDef` 的 `techs[0..14]`。

- **`techs[0]`（基础工程）** 挂面板标题行旁，**`techs[1..14]`** 挂各科技行左侧。
- **走 `Image` 控件，不走贴图批**：CSS `background-image` 在本引擎不可用；
  `Button.Icon` / `IconView` 是 SVG 字形名也承载不了 PNG，只有 `<img>` 能显示位图。
- **`<img>` 必须是 `<button>` 的兄弟节点**（塞进按钮里会和按钮自绘文字重叠/抢位），
  按钮加 `.grow` 吃掉剩余宽度。
- **源图尺寸 = 显示尺寸**（24px 源图 = 24 CSS px）：`Canvas.BlitImage` 缩小时走面积平均
  （box filter），像素画被缩一次就糊。`skin.css` 的 `image.cf-techicon` 把底色覆写为
  `transparent`——`base.css` 给 `image` 兜了 `--bg-tertiary` 底，不覆掉会变成一块方砖。
- **src 必须运行时注入**：路径随安装位置变，设计稿里写不死。
  `CoreforgeHud.ApplyTechIcons()` 用 `ForgeArt.AssetPath()` 求绝对路径再
  `SetProp("src", path)`；路径为空（文件缺失）则整枚 `visible = false` 静默隐藏
  ——`Image` 加载失败会画 alt 文本或 `"..."` 占位，挂在列表里很难看。

> ⚠ **自建宿主必须自己调 `OnLoad`**：`OnLoad` 是生成器的装载钩子，只有走生成的
> `CreateWindow()` 才会被调。coreforge 自建 `Form`/`App`/帧循环，不走那条路，
> 不补这一句钩子里的一切都不执行（科技图标就挂在这）。
> 顺序与生成器一致：建树 → 入树 → `OnLoad` → `__WireForm`。

### 音效管线

音效与位图层**互不依赖**，各自独立降级：贴图缺失照旧画程序化，音效缺失照旧静音。

| 层 | 文件 | 职责 |
|---|---|---|
| 播放层 | `client/src/ForgeAudio.zan` | 打开音频设备、载入 27 个 WAV、维护 voice 账本、冷却、静音开关 |
| 映射层 | `client/src/ForgeSfx.zan` | 把逻辑层事件 / 特效 / 开火信号翻译成 27 个 SFX 编号 |

素材在 `client/assets/audio/*.wav`（WAV 16bit PCM 44.1kHz 单声道），
由工作区共享的 `tools/artkit/audio_coreforge.py` 合成入库。

运行时链路：`System.Media.AudioClip.LoadWav` → `AudioClip.Play()`，底层是 `zan_audio` 原生
驱动（Windows 走 WASAPI）。`Game.Audio` 是**离线合成包**，不在运行时链路上；
`Game.Foundation.AudioBus` 虽有分级音量/淡入淡出，但 coreforge **禁 import `Game.Foundation`**
（见 6.4 的 `SpriteBatch` 同名撞车），故播放层自研。

#### 降级约定（硬规则）

- `Audio.Open()` 失败 → 整层静默降级（`Opened() == false`），所有 `Play()` 变成 no-op，**不报错、不崩**。
- 单个 clip 载入失败（`LoadWav` 返回非 null 但 `IsValid() == false`）→ 跳过该音效，其余照常。
- `COREFORGE_AUDIO=0` 是**正式产品级调试开关**：整层关掉（与 `COREFORGE_ART=0` 同级）。
- 音效缺失**绝不刷错误日志**——coreforge 跑在游戏里，不是诊断工具。

#### 静音的禁忌

**静音不能靠 `Audio.SetVolume(0)`**：原生主音量为 0 时混音循环不推进游标
（`g = gain * master / 32767`，只有 `g != 0` 才推进），等于把每个 voice 冻在原地、槽位永不回收
（发满 256 次后永久静音）。`ForgeAudio.SetMuted(true)` 改为**切本层 `muted` 开关 + `Audio.StopAll()`**，
不动引擎音量。

#### 采样粒度

开火 / 爆炸类音效靠**信号跃升**检测（`cooldown` 跃升、特效环增量），
必须在 **sim step 粒度**采样 —— 即 `main.zan` 的 `while (clock.HasStep())` 循环内调 `game.TickAudio()`。
放在渲染帧上采样会漏掉一帧内多次开火。

#### 其它硬规则

- **运行时绝不阻塞等待 `IsPlaying()`**：只管起播，播放时长由本层 voice 账本记账，到期主动 `Stop()` 释放原生 slot。
- **并发上限 48**（`VOICE_SLOTS`），超出的请求丢弃并计入 `Dropped()`。
- **同 tick 同 key 合并**：`ForgeSfx.Flush()` 把同一 tick 的同类信号并成一次播放，增益 `BaseGain * (1 + 0.12 * (n - 1))`，上限 1.0。
- **特效色比较只比低 24 位**（`(color & 0xFFFFFF) == rgb`）——高字节是 alpha，参与比较会漏判。

### 环境变量

| 变量 | 作用 |
|---|---|
| `COREFORGE_ART=0` | **关掉整个位图层**（句柄全 0），用于与程序化画法做前后对照、验证降级路径 |
| `COREFORGE_SMOKE=1` | 无头冒烟模式，跑到指定帧数后自行退出 |
| `COREFORGE_CAPTURE=<path.zpx>` | 冒烟时把某一帧存成 `.zpx` 截图 |
| `COREFORGE_TECH_PANEL=1` | **科技面板常开**（审阅/截图用）。科技图标只在面板里可见，默认收起就看不到它们 |
| `COREFORGE_AUDIO=0` | **关掉整个音效层**（不打开音频设备、不载入 WAV），用于与有声路径做前后对照、验证降级路径 |
| `COREFORGE_AUDIO_SELFTEST=1` | **音频自检**：逐个起播 27 个音效并打印统计后退出（不开窗口） |

### 素材生成

```powershell
cd <工作区根目录>          # 共享素材工具 tools\artkit 在这里（不随本仓发布）
python tools\artkit\gen_coreforge.py        # 重新生成 36 个 PNG（53 个精灵）+ 27 个 WAV + manifest.csv
python tools\artkit\verify_buildings.py     # 建筑全链一致性核对（改建筑/图集后必跑）
python tools\artkit\tech_preview.py coreforge\build\coreforge-tests --scale 9 --cols 3
python tools\artkit\verify_audio.py         # 音频质量门（13 项：时长/峰值/RMS/直流/削波/静音…）
python tools\artkit\audio_preview.py        # 27 条波形 + 频谱联系表，供目视验收
```

`gen_coreforge.py` 一次跑完图 + 音 + `manifest.csv`（63 行数据 = 36 图 + 27 音频）。
音频可单独重生成：`python tools\artkit\audio_coreforge.py`。

`tools/artkit/` 是全工作区共享的美术规范包（**不随本仓发布**，见上文「素材管线」下的说明）：

| 文件 | 作用 |
|---|---|
| `palette.json` | 色阶常量表（base3 / decal / 描边 `#4a4b53` / 光源右上）+ `buildings` 段（18 组建筑色槽）+ `techs` 段（15 组图标主色） |
| `artkit.py` | 生成器库：描边、斜面光照、可平铺地形、manifest 读写；`ramp3`/`edge_classes`/`shade_by_class`/`PixelCanvas` |
| `gen_coreforge.py` | coreforge 专用的产出脚本（物品 12 + 地形 8 + 建筑图集 + 科技 15） |
| `buildings_coreforge.py` | 18 个建筑像素画配方 + 底板绘制 + 图集打包 |
| `tech_coreforge.py` | 15 个科技图标配方（24×24）+ `TECH_ORDER`（= `ForgeCatalog.TechDef` 顺序） |
| `verify_buildings.py` | **建筑全链核对**：`BlockKind` → `SLOTS` → `ForgeArt.buildingSlots` → `palette.json` → `atlas.png` 逐层断言 |
| `tech_preview.py` | 科技图标联系表（棋盘底 + NEAREST 放大 + 中文名/slug 标签），供目视验收 |
| `frame_diff.py` | 两张截帧的像素差异统计 + 上下拼接对照图 |
| `zpx2png.py` | `.zpx` → PNG，支持 `--crop x,y,w,h` 与 `--scale N`（把运行时截图转成可看的对比图） |
| `audio_coreforge.py` | 27 个 SFX 的 DSP 配方（建造 8 / 武器 8 / 爆炸 5 / UI 6）；纯 numpy + `wave`，种子确定性可复现，输出 WAV 16bit PCM 44.1kHz 单声道 |
| `verify_audio.py` | **音频质量门**：13 项检查（时长、峰值、RMS、直流偏置、削波、起始静音、频谱…）任一不过即失败退出 |
| `audio_preview.py` | 27 行波形 + 频谱联系表，供目视验收 |

> ⚠ **`.zpx` 像素是 BGRA 内存序**（B,G,R,A），不是 RGBA。`zpx2png.py` 必须用
> `Image.frombytes("RGBA", (w,h), raw, "raw", "BGRA", 0, 1)` 解码；
> 直接 `frombytes("RGBA", ...)` 会让 R/B 逐字节对调、截图颜色全反。

素材清单与授权红线见 `client/ASSETS.md`；全工作区总账见 `..\ASSET-PIPELINE.md`。

## 冒烟

GUI 程序**必须**用 `Start-Process -NoNewWindow -Wait -PassThru` + `RedirectStandardOutput` 才拿得到 stdout：

```powershell
$env:ZAN_HOME = 'D:/path/to/zan-lang'
$env:COREFORGE_SMOKE = '1'
$env:COREFORGE_CAPTURE = "$PWD\build\coreforge-tests\after.zpx"
$p = Start-Process -FilePath "$PWD\build\coreforge\Coreforge.exe" -NoNewWindow -Wait -PassThru `
     -RedirectStandardOutput "$PWD\build\coreforge-tests\after.out.txt" `
     -RedirectStandardError  "$PWD\build\coreforge-tests\after.err.txt"
```

成功时 stdout 出现 `COREFORGE_GUI_PASS frames=...` 与
`COREFORGE_CAM zoom=... x=... y=... map=48x36 client=...`，
外加一行音效统计 `COREFORGE_AUDIO opened=1 played=... dropped=... driver=wasapi`。

音效单独自检（不开窗口，逐个起播 27 个）：

```powershell
$env:COREFORGE_AUDIO_SELFTEST = '1'
# 期望 stdout: COREFORGE_AUDIO_SELFTEST opened=1 started=27/27 driver=wasapi played=27 dropped=0
```

> 全工作区批量冒烟（不含 coreforge，coreforge 走上面的独立流程）：
> `pwsh -File tools/smoke-all.ps1` → 期望 `SMOKE-SUMMARY fail=0 / total=10`。
