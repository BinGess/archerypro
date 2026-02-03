# AI 教练功能配置指南

本文档介绍如何配置 AI 教练功能所需的 API 密钥。

## 📋 前置条件

1. 拥有扣子（Coze）平台账号
2. 已创建射箭教练智能体
3. 获取了 API Token

## 🔧 配置步骤

### 1. 创建环境变量文件

在项目根目录下，复制 `.env.example` 文件并重命名为 `.env`：

```bash
cp .env.example .env
```

### 2. 填写 API Token

打开 `.env` 文件，填写你的 Coze API Token：

```env
# Coze API Token（必填）
COZE_API_TOKEN=你的API_Token
```

**示例：**
```env
COZE_API_TOKEN=yJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9...
```

### 3. 可选配置

如果你使用的是自定义部署，可以覆盖默认配置：

```env
# 自定义 Base URL（可选）
COZE_BASE_URL=https://your-custom-endpoint.com

# 自定义 Project ID（可选）
COZE_PROJECT_ID=your_project_id
```

## 🔒 安全说明

- ⚠️ **不要将 `.env` 文件提交到 Git！**
- `.env` 文件已添加到 `.gitignore`，确保不会被意外提交
- `.env.example` 是模板文件，可以提交到 Git
- 不要在代码中硬编码 API Token

## 🚀 运行应用

配置完成后，运行应用：

```bash
# 安装依赖
flutter pub get

# 运行应用
flutter run
```

## ✅ 验证配置

启动应用后，可以通过以下方式测试 AI 教练功能：

1. **周期分析**：
   - 打开"分析"页面
   - 点击"AI 教练分析"卡片中的"分析"按钮
   - 等待 AI 分析完成

2. **单次训练分析**：
   - 打开任意训练记录的"详情"页面
   - 点击"AI 教练深度分析"卡片中的"深度分析"按钮
   - 查看分析结果

## 🐛 故障排除

### 问题：应用启动时提示 "Failed to load .env file"

**原因：** `.env` 文件不存在或路径错误

**解决：**
```bash
# 检查文件是否存在
ls -la .env

# 如果不存在，从模板创建
cp .env.example .env
```

### 问题：API 调用失败，提示 "API Token 无效或已过期"

**原因：** Token 配置错误或已过期

**解决：**
1. 检查 `.env` 文件中的 `COZE_API_TOKEN` 是否正确填写
2. 前往扣子平台重新生成 API Token
3. 确保 Token 前后没有多余空格

### 问题：分析功能无响应

**原因：** 网络问题或 API 配置错误

**解决：**
1. 检查网络连接
2. 查看日志文件（位于应用文档目录的 `logs/` 文件夹）
3. 确认 Base URL 和 Project ID 配置正确

## 📚 更多信息

- Coze 平台：https://www.coze.cn/
- API 文档：参考扣子平台开发者文档
- 项目源码：查看 `lib/services/ai_coach/` 目录

## 🤝 获取帮助

如果遇到问题，请：
1. 检查日志文件
2. 查看本文档的故障排除部分
3. 提交 Issue 到项目仓库
