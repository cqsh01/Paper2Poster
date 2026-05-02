# Paper2Poster Windows Docker Qwen3-VL-Plus 专用版

本项目已精简为只面向以下使用场景：

- 操作系统：Windows
- 运行环境：Docker Desktop
- 模型服务：阿里云 DashScope / Qwen OpenAI-compatible API
- 默认模型：`qwen3-vl-plus`
- 输入：论文 PDF
- 输出：可编辑学术海报 `poster.pptx` / `{paper_name}.pptx`

生成的是 **poster（学术海报）**，保存格式是 **PowerPoint `.pptx`**，因此可以继续用 PowerPoint/WPS 编辑。

---

## 1. 目录说明

保留的主要目录：

```text
Paper2Poster-main/
├── Dockerfile                  # Windows Docker 构建文件
├── run_qwen3_docker.ps1        # Windows PowerShell 一键运行脚本
├── requirements.txt            # Python 依赖
├── .env                        # Qwen API Key
├── .dockerignore               # Docker 构建忽略规则
├── Paper2Poster-data/          # 论文输入目录
├── output_posters/             # 可选输出目录
├── hf_cache/                   # HuggingFace/Docling 模型缓存
├── PosterAgent/                # 海报生成主流程
├── utils/                      # 工具函数
├── camel/                      # 模型调用框架
├── docling/                    # PDF 解析
├── config/                     # 海报样式配置
└── logo_store/                 # 本地 logo 库
```

已移除内容包括旧 demo、eval、旧 Dockerfile、旧脚本、旧说明文档等。

---

## 2. 准备 API Key

在项目根目录创建或编辑 `.env`：

```env
QWEN_API_KEY=你的DashScope_API_Key
DASHSCOPE_API_KEY=你的DashScope_API_Key
```

两个变量建议都写同一个 DashScope Key，兼容项目内部不同读取方式。

---

## 3. 准备论文

推荐结构：

```text
Paper2Poster-data/
└── mypaper/
    └── paper.pdf
```

如果你的论文叫 `1.pdf` 也可以运行。当前输出目录已改为 `output_posters/<model>/<poster_name>/`，不会再把原始论文路径写入输出目录。为了输入路径更整洁，仍然推荐命名为：

```text
paper.pdf
```

---

## 4. 构建 Docker 镜像

在 PowerShell 中进入项目根目录：

```powershell
cd "E:\github_project\Paper2Poster-main"
```

构建镜像：

```powershell
docker build -t paper2poster .
```

首次构建可能需要较长时间。后续如只改代码，构建会复用缓存。

---

## 5. 运行生成海报

### 最简脚本方式

默认读取 `/Paper2Poster-data/mypaper/paper.pdf`：

```powershell
.\run_qwen3_docker.ps1
```

如果你的论文仍叫 `1.pdf`：

```powershell
.\run_qwen3_docker.ps1 -PaperPath "/Paper2Poster-data/mypaper/1.pdf"
```

自定义尺寸，例如 A3 横版：

```powershell
.\run_qwen3_docker.ps1 -PaperPath "/Paper2Poster-data/mypaper/paper.pdf" -Width 16.54 -Height 11.69
```

### 手动命令

```powershell
docker run --rm `
  --env-file ".env" `
  -e HF_HUB_DISABLE_XET=1 `
  -e HF_HUB_ENABLE_HF_TRANSFER=0 `
  -e HF_HOME=/hf_cache `
  -v "${PWD}:/app" `
  -v "${PWD}/hf_cache:/hf_cache" `
  -v "${PWD}/Paper2Poster-data:/Paper2Poster-data" `
  -v "${PWD}/output_posters:/app/output_posters" `
  paper2poster `
  python -m PosterAgent.new_pipeline `
  --poster_path="/Paper2Poster-data/mypaper/paper.pdf" `
  --model_name_t=qwen3-vl-plus `
  --model_name_v=qwen3-vl-plus `
  --poster_width_inches=16.54 `
  --poster_height_inches=11.69 `
  --max_workers=1
```

如果你的文件仍然是 `1.pdf`，把路径改为：

```powershell
--poster_path="/Paper2Poster-data/mypaper/1.pdf"
```

---

## 6. 输出位置

成功后日志会显示类似：

```text
Poster PowerPoint saved to output_posters/qwen3-vl-plus_qwen3-vl-plus/mypaper/mypaper.pptx
```

在 Windows 上对应路径一般是：

```text
E:\github_project\Paper2Poster-main\output_posters\qwen3-vl-plus_qwen3-vl-plus\mypaper\mypaper.pptx
```

输出目录 `output_posters/` 已写入 `.gitignore`，不会被提交到 Git。

---

## 7. 参数说明

常用参数：

```text
--poster_path             输入 PDF 路径，容器内路径
--model_name_t            文本模型，固定推荐 qwen3-vl-plus
--model_name_v            视觉模型，固定推荐 qwen3-vl-plus
--poster_width_inches     海报宽度；A3 横版建议 16.54
--poster_height_inches    海报高度；A3 横版建议 11.69
--max_workers             并发数，建议先用 1，避免 API 限流
--no_blank_detection      跳过空白检测，减少 LibreOffice/视觉修复问题和 API 消耗
```

---

## 8. 为什么使用这些 Docker 环境变量

```powershell
-e HF_HUB_DISABLE_XET=1
-e HF_HUB_ENABLE_HF_TRANSFER=0
-e HF_HOME=/hf_cache
-v "${PWD}/hf_cache:/hf_cache"
```

用途：

- 避免 HuggingFace Xet 下载超时
- 将 Docling/EasyOCR/HuggingFace 模型缓存保存到本机
- 下次运行复用缓存，减少下载时间

---

## 9. 常见问题

### 9.1 API 报 `insufficient_quota`

说明 DashScope/Qwen 额度不足或被限流。

建议：

```powershell
--max_workers=1
--no_blank_detection
```

如果仍报错，需要检查 DashScope 控制台余额/额度。

### 9.2 第一次运行很慢

正常。第一次会下载 EasyOCR、Docling、TableFormer 等模型。下载完成后会缓存在 `hf_cache/`。

### 9.3 输出目录在哪里？

当前版本输出到：

```text
output_posters/qwen3-vl-plus_qwen3-vl-plus/<poster_name>/
```

例如：

```text
output_posters/qwen3-vl-plus_qwen3-vl-plus/mypaper/mypaper.pptx
```

`output_posters/` 已加入 `.gitignore`，不会上传到 Git 仓库。

### 9.4 需要重新 build 吗？

如果运行命令包含：

```powershell
-v "${PWD}:/app"
```

那么修改 Python 代码、配置文件、prompt、README 后通常不需要重新 build，直接重新 `docker run` 或运行脚本即可。

如果修改了 Dockerfile 或 requirements，则需要重新 build：

```powershell
docker build -t paper2poster .
```

### 9.5 关于 `assets/` 被删除后的影响

原始 Paper2Poster 项目中的 `assets/` 不只是普通示例目录，其中至少有两类文件会影响默认流程。

#### 9.5.1 `assets/poster_data/Train`

原始项目的默认 tree layout 流程会读取：

```text
assets/poster_data/Train
```

这个目录表面上像示例/训练数据，但实际会被 `PosterAgent/tree_split_layout.py` 的 `main_train()` 使用，用来临时训练版面布局模型。如果删除该目录，旧逻辑会报错：

```text
FileNotFoundError: [Errno 2] No such file or directory: 'assets/poster_data/Train'
```

当前解决方法是：

- 保持 `assets/poster_data/Train` 删除，减少项目体积；
- 在 `PosterAgent/new_pipeline.py` 中捕获缺失训练数据的情况；
- 自动 fallback 到 `no_tree_get_layout()`，也就是 LLM-only layout；
- 同时修复了 `utils/ablation_utils.py` 中 prompt 模板路径，确保 fallback 在 Docker 中可用。

因此当前版本不再要求存在 `assets/poster_data/Train`。

#### 9.5.2 `assets/overflow_example_v2`

内容生成阶段的视觉 critic 原本会读取：

```text
assets/overflow_example_v2/neg.jpg
assets/overflow_example_v2/pos.jpg
```

这两张图是“坏排版/好排版”的参考示例，用来帮助视觉模型判断文本是否溢出或是否留白过多。如果删除该目录，旧逻辑会报错：

```text
FileNotFoundError: [Errno 2] No such file or directory: '/app/assets/overflow_example_v2/neg.jpg'
```

当前解决方法是：

- 如果这两张示例图存在，则继续把它们传给视觉 critic；
- 如果不存在，则自动只传当前 textbox 截图给视觉 critic；
- 流程不会再因为缺少 `assets/overflow_example_v2` 崩溃。

#### 9.5.3 是否需要恢复 `assets/`

不是必须。

当前精简版仍然保留了 Paper2Poster 的核心流程：PDF 解析、图片/表格抽取、内容规划、图片表格筛选、outline 生成、layout 生成、文本生成、视觉 critic、PPTX 渲染和 logo 匹配。删除 `assets/` 后主要损失的是：

- 原始 tree layout 的本地训练数据；
- overflow critic 的好/坏参考示例图。

如果你追求尽可能接近原项目的布局质量，可以从原仓库恢复下面两个目录：

```text
assets/poster_data/Train
assets/overflow_example_v2
```

恢复后无需改命令，程序会自动优先使用这些 assets；如果它们不存在，则自动使用 fallback 方案。



## 10. 推荐工作流

1. 把论文放入：

```text
Paper2Poster-data/你的论文名/paper.pdf
```

2. 修改运行命令中的：

```powershell
--poster_path="/Paper2Poster-data/你的论文名/paper.pdf"
```

3. 运行 Docker 命令。

4. 在生成目录中打开 `.pptx` 查看海报。
