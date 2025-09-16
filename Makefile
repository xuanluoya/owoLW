# 编译器和参数
CC = clang
CFLAGS = -fobjc-arc -framework Cocoa -framework AVKit -framework AVFoundation -framework UniformTypeIdentifiers -framework CoreMedia

# 源文件
SRC = src/main.m src/AppDelegate.m
OBJ = $(SRC:.m=.o)
APP = owoLW
TARGET = $(APP).app/Contents/MacOS/$(APP)

# 默认目标
all: $(TARGET)

# 编译源文件
%.o: %.m
	$(CC) -c $< -o $@ -fobjc-arc

# 链接生成可执行文件
$(TARGET): $(OBJ)
	@mkdir -p $(dir $@)
	$(CC) -o $@ $^ $(CFLAGS)

# 清理
clean:
	rm -rf $(OBJ) $(APP).app

