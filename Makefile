# 版本，编译器和参数
VERSION = 0.1.0

CC = clang
CFLAGS = -fobjc-arc -framework Cocoa -framework AVKit -framework AVFoundation -framework UniformTypeIdentifiers -framework CoreMedia

# 源文件
SRC = src/main.m src/AppDelegate.m
OBJ = $(SRC:.m=.o)
APP = owoLW
TARGET = $(APP).app/Contents/MacOS/$(APP)

# 图标和资源
ASSET_DIR = asset
ICON_PNG = $(ASSET_DIR)/icon.png
ICONSET = $(ASSET_DIR)/AppIcon.iconset
ICON_ICNS = $(APP).icns

# 默认目标
all: $(TARGET) plist icon

# 编译源文件
%.o: %.m
	$(CC) -c $< -o $@ -fobjc-arc

# 链接生成可执行文件
$(TARGET): $(OBJ)
	@mkdir -p $(dir $@)
	$(CC) -o $@ $^ $(CFLAGS)

# 生成 Info.plist
plist:
	@mkdir -p $(APP).app/Contents
	@echo "<?xml version=\"1.0\" encoding=\"UTF-8\"?>" > $(APP).app/Contents/Info.plist
	@echo "<!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">" >> $(APP).app/Contents/Info.plist
	@echo "<plist version=\"1.0\">" >> $(APP).app/Contents/Info.plist
	@echo "<dict>" >> $(APP).app/Contents/Info.plist
	@echo "  <key>CFBundleExecutable</key>" >> $(APP).app/Contents/Info.plist
	@echo "  <string>$(APP)</string>" >> $(APP).app/Contents/Info.plist
	@echo "  <key>CFBundleIdentifier</key>" >> $(APP).app/Contents/Info.plist
	@echo "  <string>cc.owobit.$(APP)</string>" >> $(APP).app/Contents/Info.plist
	@echo "  <key>CFBundleName</key>" >> $(APP).app/Contents/Info.plist
	@echo "  <string>$(APP)</string>" >> $(APP).app/Contents/Info.plist
	@echo "  <key>CFBundleVersion</key>" >> $(APP).app/Contents/Info.plist
	@echo "  <string>$(VERSION)</string>" >> $(APP).app/Contents/Info.plist
	@echo "  <key>CFBundlePackageType</key>" >> $(APP).app/Contents/Info.plist
	@echo "  <string>APPL</string>" >> $(APP).app/Contents/Info.plist
	@echo "  <key>CFBundleIconFile</key>" >> $(APP).app/Contents/Info.plist
	@echo "  <string>$(APP).icns</string>" >> $(APP).app/Contents/Info.plist
	@echo "</dict>" >> $(APP).app/Contents/Info.plist
	@echo "</plist>" >> $(APP).app/Contents/Info.plist

# 生成 .icns 图标
icon: $(ICON_PNG)
	@mkdir -p $(ICONSET)
	@sips -z 16 16     $< --out $(ICONSET)/icon_16x16.png
	@sips -z 32 32     $< --out $(ICONSET)/icon_16x16@2x.png
	@sips -z 32 32     $< --out $(ICONSET)/icon_32x32.png
	@sips -z 64 64     $< --out $(ICONSET)/icon_32x32@2x.png
	@sips -z 128 128   $< --out $(ICONSET)/icon_128x128.png
	@sips -z 256 256   $< --out $(ICONSET)/icon_128x128@2x.png
	@sips -z 256 256   $< --out $(ICONSET)/icon_256x256.png
	@sips -z 512 512   $< --out $(ICONSET)/icon_256x256@2x.png
	@sips -z 512 512   $< --out $(ICONSET)/icon_512x512.png
	cp $< $(ICONSET)/icon_512x512@2x.png
	iconutil -c icns $(ICONSET) -o $(ICON_ICNS)
	@mkdir -p $(APP).app/Contents/Resources
	cp $(ICON_ICNS) $(APP).app/Contents/Resources/

# 清理
clean:
	rm -rf $(OBJ) $(APP).app $(ICONSET) $(ICON_ICNS)

