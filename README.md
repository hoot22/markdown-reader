# Markdown Reader

用 Godot 4.7 写的Windows Markdown 阅读器：打开一个 `.md` 文件，就能以渲染后的样式阅读。

## 功能

- 启动进入主界面，支持通过点击文件选择按钮/拖放/命令行打开.md文件
- 读取文件内容后存入 `Content` 自动加载单例，并切换到阅读场景
- 阅读场景用 docrender 提供的 `MarkdownLabel` 渲染正文，可滚动阅读
- 阅读页提供返回按钮回到主界面，主界面提供退出按钮
- 界面样式使用 StyleboxFancy 资源与本地字体，内置 zh_CN / en 两种界面语言
- 读取时自动识别编码，UTF-8、UTF-16 与 GBK 编码的 `.md` 都能正常显示（详见[文件编码](#文件编码)）

## 目录结构

| 路径 | 说明 |
| --- | --- |
| `project.godot` | 项目配置：1920×1080、`canvas_items` 拉伸、`mobile` 渲染器 |
| `content.gd` | 自动加载单例 `Content`，暂存待阅读的 Markdown 文本 |
| `control.gd` | 主界面逻辑：打开文件对话框、读取文件、切换场景、退出 |
| `read.gd` | 阅读界面逻辑：把 `Content.markdown_content` 交给 `MarkdownLabel` 显示 |
| `text_codec.gd` | 编码探测与解码：UTF-8（含 BOM）、UTF-16 LE/BE、GBK |
| `main.tscn` | 主界面场景 |
| `read.tscn` | 阅读界面场景 |
| `assets/` | StyleBox 资源、打包字体（授权见 `assets/fonts/licenses/`）与 GBK 码表 `assets/encoding/gbk_table.bin` |
| `languages/` | 翻译源 `languages.csv` 及导出的 `.translation` |
| `export_presets.cfg` | Windows Desktop 导出预设 |

## 依赖的第三方插件

本仓库**不包含** `addons/` 目录。克隆后需要按下面两个上游仓库自行安装，否则编辑器插件和 Markdown 渲染都不可用。

| 插件 | 上游仓库 | 作用 |
| --- | --- | --- |
| docrender | <https://github.com/LuYingYiLong/godot-docrender> | GDExtension，提供 `MarkdownLabel` 节点与 Markdown 导入器，负责正文渲染 |
| StyleboxFancy | <https://github.com/MellowDye/StyleBoxFancy> | 提供 `StyleBoxFancy` 资源类型与编辑器工具，负责界面样式（本项目使用 1.3.5） |

## 安装

### github releases

从[github releases](https://github.com/hoot22/markdown-reader/releases/latest)下载`markdown-reader.zip`文件，解压后运行`markdown-read.exe`

### 源码运行

仓库不包含 `addons/`。克隆后必须先补齐两个插件，再启动编辑器；否则 GDExtension 与主题插件都加载不上，Markdown 渲染不可用。

**前置要求**：Godot 4.7.x、Git；若要自行编译 docrender，另需 Python、SCons（`python -m pip install scons`）、MSVC 与 Windows SDK。`godot-cpp` 等依赖由子模块提供，不需要单独安装。

**第 1 步：克隆仓库**

```bash
git clone https://github.com/hoot22/markdown-reader.git
cd markdown-reader
```

**第 2 步：安装 docrender**

```bash
git clone https://github.com/LuYingYiLong/godot-docrender.git
```

把上游的 `addons/docrender/` 整体复制到本项目同名路径，然后确认两件事：

- `docrender.gdextension` 中声明的当前平台库存在。Windows 下是 `bin/docrender.windows.template_debug.x86_64.dll` 与 `bin/docrender.windows.template_release.x86_64.dll`
- `bin/pdfium.dll` 存在，`[dependencies]` 里的 `docrender_pdf_reader` 依赖它

GDExtension 的库按 `template_debug` / `template_release` 严格匹配，不会跨 target 回退。只放 release 库时，debug 版编辑器会报 `No Godot GDExtension library found`，`MarkdownLabel`、`PDFTexture` 等类和编辑器插件全部不会注册。

上游只提供源码时需自行编译。进入上游仓库后先拉取子模块，`godot-cpp`、litehtml、MicroTeX、tinyxml2 都在子模块里，未初始化时 SCons 会直接构建失败：

```bash
cd godot-docrender
git submodule update --init --recursive
```

再装可选 SDK。缺 PDFium SDK 时 `bin/pdfium.dll` 不会被生成，`PDFTexture` 等 PDF 相关类注册失败；缺 Merman SDK 时 Mermaid 代码块无法渲染：

```bash
python scripts/fetch_pdfium_sdk.py
python scripts/fetch_merman_sdk.py
```

然后两种 target 各编一次，产物直接落在上游仓库的 `addons/docrender/bin/`：

```bash
scons godot-docrender platform=windows target=template_debug arch=x86_64
scons godot-docrender platform=windows target=template_release arch=x86_64
```

其他平台替换 `platform` / `arch`。`template_debug` 供编辑器和 debug 导出使用，`template_release` 供 release 导出使用，两者互不替代 —— 只编其中一种，另一种场景仍会报 `No Godot GDExtension library found`。编完先按上文两条检查项核对库文件，再把整个 `addons/docrender/` 复制进本项目。

**第 3 步：安装 StyleboxFancy**

从 [StyleBoxFancy](https://github.com/MellowDye/StyleBoxFancy) 取 `addons/StyleBoxFancy/`，放到本项目并保持目录名为 `addons/StyleboxFancy/`（第二个 `b` 小写）。`project.godot` 的 `[editor_plugins]` 已启用 `res://addons/StyleboxFancy/plugin.cfg`，目录名大小写不一致会导致插件加载失败。

**第 4 步：启动与自检**

用 Godot 4.7.x 打开 `project.godot`，等首次导入结束后确认：

- 输出面板没有 `No Godot GDExtension library found` 或 `Failed loading resource` 一类插件相关错误
- 新建节点时能搜到 `MarkdownLabel`，说明 docrender 已注册
- 项目设置 → 插件 中 `StyleboxFancy` 处于启用状态

按 F5 运行，主场景为 `main.tscn`。

## 文件编码

打开文件时会自动识别编码，不要求是 UTF-8。判定按下表顺序进行，命中即停止：

| 顺序 | 判定依据 | 处理 |
| --- | --- | --- |
| 1 | 开头为 `EF BB BF` | 按 UTF-8 解码并去掉 BOM |
| 2 | 开头为 `FF FE` / `FE FF` | 按 UTF-16 LE / BE 解码 |
| 3 | 整份内容通过 UTF-8 校验 | 按 UTF-8 解码 |
| 4 | 其余情况 | 按 GBK 解码 |

GBK 走 `assets/encoding/gbk_table.bin` 码表，收录 21791 个有效的双字节映射，覆盖 GB2312 与 GBK 常用汉字。因此在 Windows 下用记事本以「ANSI」保存、或用 VS Code 以 GBK 保存的中文 Markdown 可以直接打开，不再出现乱码。

码表不是 Godot 资源，不在资源依赖图内。`export_presets.cfg` 的 `include_filter` 已配置 `*.bin`，导出时会一并打包 —— 自行新增或替换码表文件时，注意不要移除该过滤规则，否则导出后的程序会丢失编码支持。

已知边界：

- GB18030 的四字节扩展区未收录，落在该区的生僻字会显示为 `�`
- 编码探测以整份文件为单位。同一文件内混用 UTF-8 与 GBK 时无法正确解码，会整体按其中一种处理
- 无 BOM 的 UTF-16 无法可靠识别，会被当作 UTF-8 或 GBK

## 已知限制

- 仓库不含插件二进制。若 `addons/docrender/bin/` 缺少 `template_debug` 对应的库，编辑器内的 docrender 功能与 debug 导出都不可用。
- 图片按项目根解析。打开文件时没有把该文件所在目录传给渲染器（`image_base_dir` 与 `html_file_base_dir` 均为默认空值），相对路径的图片不会被解析到 `.md` 旁边；只有能被 `ResourceLoader` 在项目内找到的图片才会显示，找不到时回落为破损图标。
- 外部链接会真实打开浏览器。`http` / `https` 链接点击后经 `OS.shell_open()` 交给系统默认浏览器，对应插件属性 `open_external_links` 默认为 `true`，本项目没有关闭它。

## 许可证

本项目采用 MIT 许可证，详见仓库根目录的 `LICENSE`（Copyright (c) 2026 hoot22）。第三方组件（免费字体、插件）的授权声明分别保留在 `assets/fonts/licenses/` 与各自插件目录中。