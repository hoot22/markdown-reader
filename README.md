# Markdown Read

用 Godot 4.7 写的桌面 Markdown 阅读器：选中一个 `.md` 文件，就能以渲染后的样式阅读。

## 功能

- 启动进入主界面，点击按钮弹出文件对话框选择 Markdown 文件
- 读取文件内容后存入 `Content` 自动加载单例，并切换到阅读场景
- 阅读场景用 docrender 提供的 `MarkdownLabel` 渲染正文，可滚动阅读
- 阅读页提供返回按钮回到主界面，主界面提供退出按钮
- 界面样式使用 StyleboxFancy 资源与本地字体，内置 zh_CN / en 两种界面语言

## 目录结构

| 路径 | 说明 |
| --- | --- |
| `project.godot` | 项目配置：1920×1080、`canvas_items` 拉伸、`mobile` 渲染器 |
| `content.gd` | 自动加载单例 `Content`，暂存待阅读的 Markdown 文本 |
| `control.gd` | 主界面逻辑：打开文件对话框、读取文件、切换场景、退出 |
| `read.gd` | 阅读界面逻辑：把 `Content.markdown_content` 交给 `MarkdownLabel` 显示 |
| `main.tscn` | 主界面场景 |
| `read.tscn` | 阅读界面场景 |
| `assets/` | StyleBox 资源与打包字体，字体授权见 `assets/fonts/licenses/` |
| `languages/` | 翻译源 `languages.csv` 及导出的 `.translation` |
| `export_presets.cfg` | Windows Desktop 导出预设 |

## 依赖的第三方插件

本仓库**不包含** `addons/` 目录。克隆后需要按下面两个上游仓库自行安装，否则编辑器插件和 Markdown 渲染都不可用。

| 插件 | 上游仓库 | 作用 |
| --- | --- | --- |
| docrender | <https://github.com/LuYingYiLong/godot-docrender> | GDExtension，提供 `MarkdownLabel` 节点与 Markdown 导入器，负责正文渲染 |
| StyleboxFancy | <https://github.com/MellowDye/StyleBoxFancy> | 提供 `StyleBoxFancy` 资源类型与编辑器工具，负责界面样式（本项目使用 1.3.5） |

安装方式：

1. **docrender** —— 取得与 Godot 4.7 匹配的构建，放到 `addons/docrender/`。目录下必须同时具备 `.gdextension`、`bin/` 中的平台库和 `bin/pdfium.dll`；GDExtension 按 `template_debug` / `template_release` 严格匹配库文件，不会跨回退。
2. **StyleboxFancy** —— 把上游的 `addons/StyleboxFancy/` 复制到本项目同名路径；`project.godot` 的 `[editor_plugins]` 已启用它。

## 运行

用 Godot 4.7.x 打开 `project.godot`，按 F5 运行。项目使用 `mobile` 渲染器，未申请任何特殊输入映射。

## 已知限制

- 仓库不含插件二进制。若 `addons/docrender/bin/` 缺少 `template_debug` 对应的库，编辑器内的 docrender 功能与 debug 导出都不可用。
- 阅读内容来自本地文件，未做外部链接、图片等资源的加载处理。

## 许可证

本项目采用 MIT 许可证，详见仓库根目录的 `LICENSE`（Copyright (c) 2026 hoot22）。第三方组件（免费字体、插件）的授权声明分别保留在 `assets/fonts/licenses/` 与各自插件目录中。
