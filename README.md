# 卜卜桌面宠物

一个原生 macOS 桌面宠物。窗口透明置顶，可以拖动，支持点击互动、自动走动、睡觉/唤醒和大小调整。

## 预览与互动

- 单击：摸摸卜卜
- 双击：捏一下
- 拖动：移动到桌面任意位置
- 右键：打开菜单，可让它走走、睡觉/唤醒、调整大小、切换置顶、退出

## 构建

依赖：

- macOS
- Xcode Command Line Tools
- Python 3
- Pillow

构建：

```bash
python3 -m pip install Pillow
./Scripts/build_app.sh
```

构建完成后打开：

```text
Build/BuBuCarrotPet.app
```

如果系统提示安全拦截，右键这个 app，选择“打开”。

## 项目结构

- `Assets/source.png`：原始参考图
- `Assets/carrot_*.png`：由脚本生成的透明桌宠素材
- `Scripts/prepare_assets.py`：裁剪并生成透明素材
- `Scripts/build_app.sh`：构建 macOS app
- `Sources/main.m`：桌宠窗口与互动逻辑

## 清理

```bash
rm -rf Build
```

## License

发布前请补充许可证文件，例如 MIT License。
