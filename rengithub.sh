#!/bin/bash

R='\033[1;31m'
G='\033[1;32m'
Y='\033[1;33m'
B='\033[1;34m'
P='\033[1;35m'
C='\033[1;36m'
N='\033[0m'

# 配置
CONFIG_DIR="$HOME/.git-toolkit"
CONFIG_FILE="$CONFIG_DIR/config"

# 初始化
init() {
    mkdir -p "$CONFIG_DIR"
    touch "$CONFIG_FILE"
    
    if ! command -v git >/dev/null 2>&1; then
        echo -e "${R}✗ 未检测到 Git${N}"
        echo "在 Termux 中: pkg install git"
        exit 1
    fi
}

# 清屏
clear_screen() {
    printf "\033[2J\033[H"
}

# 显示标题
show_title() {
    clear_screen
    echo -e "${P}╔══════════════════════════════════════╗${N}"
    echo -e "${P}║         github工具箱 v1.0      ║${N}"
    echo -e "${P}╚══════════════════════════════════════╝${N}"
    echo ""
}

# 手机输入
mobile_input() {
    local prompt="$1"
    local default="$2"
    
    echo -ne "${C}$prompt${N}"
    [[ -n "$default" ]] && echo -ne " [${Y}$default${N}]"
    echo -ne ": "
    
    while read -t 0.1 -n 100 discard; do true; done
    local input=""
    read -t 60 input
    
    if [[ $? -ne 0 ]] || [[ -z "$input" ]]; then
        input="$default"
    fi
    
    echo "$(echo "$input" | tr -d '\r\n')"
}

# 数字选择
number_select() {
    local prompt="$1"
    local min="$2"
    local max="$3"
    local default="$4"
    
    while true; do
        echo -ne "${B}$prompt${N}"
        [[ -n "$default" ]] && echo -ne " (${Y}$min-$max${N}, 默认:${G}$default${N})"
        echo -ne ": "
        
        local choice
        read -n 1 -t 30 choice
        echo ""
        
        [[ $? -ne 0 ]] || [[ -z "$choice" ]] && choice="$default"
        
        if [[ "$choice" =~ ^[0-9]$ ]] && [[ "$choice" -ge "$min" ]] && [[ "$choice" -le "$max" ]]; then
            echo "$choice"
            return 0
        fi
        
        echo -e "${R}无效选择，请按 $min-$max 之间的数字${N}"
        sleep 1
    done
}

# 确认
confirm() {
    local message="$1"
    echo -ne "${Y}$message${N} [${G}y${N}/${R}n${N}]: "
    
    local choice
    read -n 1 -t 30 choice
    echo ""
    
    choice=$(echo "$choice" | tr '[:upper:]' '[:lower:]')
    [[ "$choice" == "y" ]]
}

# ================= 核心功能 =================
quick_upload() {

if ! command -v git &> /dev/null; then
    echo "❌ 未找到 Git，请先安装 Git"
    exit 1
fi

# 获取仓库路径
read -p "请输入本地仓库路径（直接回车使用当前目录）: " repo_path
repo_path=${repo_path:-$(pwd)}

# 检查路径
if [ ! -d "$repo_path" ]; then
    echo "❌ 路径不存在: $repo_path"
    exit 1
fi

cd "$repo_path" || exit 1

# 检查是否是 Git 仓库
if [ ! -d ".git" ]; then
    echo "❌ 当前目录不是 Git 仓库"
    exit 1
fi

# 显示信息
echo ""
echo "📁 当前目录: $(pwd)"
echo "🌿 当前分支: $(git branch --show-current 2>/dev/null || echo '无')"
echo "📊 提交数量: $(git rev-list --count HEAD 2>/dev/null || echo '0')"
echo "📦 文件数量: $(git ls-files 2>/dev/null | wc -l)"
echo ""

# 确认


read -p "是否继续y/n " confirm

if [ "$confirm" != "y" ]; then
    echo "操作已取消"
    exit 0
fi

# 执行增量上传
echo ""
echo "🔄 开始上传..."

# 1. 清空缓存并重新添加
echo "1. 清空暂存区并重新添加文件..."
git rm -r --cached . 2>/dev/null
git add -A

# 2. 提交
echo "2. 提交当前状态..."
git commit -m "上传于 $(date '+%Y-%m-%d %H:%M:%S')"

# 3. 推送
remote_url=$(git remote get-url origin 2>/dev/null || echo "")
if [ -n "$remote_url" ]; then
    echo "3. 推送到远程仓库..."
    read -p "是否推送到远程？(y/N): " push_confirm
    if [[ $push_confirm =~ ^[Yy]$ ]]; then
        timeout 30 git push origin HEAD --progress
        push_exit_code=$?

        if [ $push_exit_code -eq 0 ]; then
            echo "✅ 已推送到远程仓库"
        elif [ $push_exit_code -eq 124 ]; then
            echo "⚠️  推送超时，请手动检查网络连接或认证"
            echo "   可以使用命令手动推送: git push"
        else
            echo "⚠️  推送失败，退出码: $push_exit_code"
            echo "   请检查远程仓库权限或网络连接"
        fi
    else
        echo "⏸️  跳过远程推送，仅更新本地仓库"
    fi
fi

# 完成
echo ""
echo "✅ 增量上传完成！"
echo ""
echo "📊 最终状态："
echo "   分支: $(git branch --show-current)"
echo "   提交: $(git log --oneline -1)"
echo "   文件: $(git ls-files | wc -l) 个"
echo "========================================"
}

# 2. 清空并上传（按路径）
# 2. 清空并上传（完全修复版）
clean_and_upload() {
   
if ! command -v git &> /dev/null; then
    echo "❌ 未找到 Git，请先安装 Git"
    exit 1
fi

# 获取仓库路径
read -p "请输入本地仓库路径（直接回车使用当前目录）: " repo_path
repo_path=${repo_path:-$(pwd)}

# 检查路径
if [ ! -d "$repo_path" ]; then
    echo "❌ 路径不存在: $repo_path"
    exit 1
fi

# 进入目录
cd "$repo_path" || exit 1

# 检查是否是 Git 仓库
if [ ! -d ".git" ]; then
    echo "❌ 当前目录不是 Git 仓库"
    exit 1
fi

# 显示信息
echo ""
echo "📁 当前目录: $(pwd)"
echo "🌿 当前分支: $(git branch --show-current 2>/dev/null || echo '无')"
echo "📊 提交数量: $(git rev-list --count HEAD 2>/dev/null || echo '0')"
echo "📦 文件数量: $(git ls-files 2>/dev/null | wc -l)"
echo ""

# 确认
echo "⚠️  ⚠️  ⚠️  严重警告 ⚠️  ⚠️  ⚠️"
echo "此操作将："
echo "1. 删除所有历史提交（本地和远程）"
echo "2. 只保留当前工作区的文件"
echo "3. 强制覆盖远程仓库"
echo ""
read -p "是否继续？(输入 'YES' 确认): " confirm

if [ "$confirm" != "YES" ]; then
    echo "操作已取消"
    exit 0
fi

# 执行重置
echo ""
echo "🔄 开始重置仓库..."

# 1. 创建孤儿分支
echo "1. 创建全新分支起点..."
git checkout --orphan fresh-start

# 2. 添加文件
echo "2. 添加当前所有文件..."
git add -A

# 3. 提交
echo "3. 提交当前状态..."
git commit -m "仓库重置于 $(date '+%Y-%m-%d %H:%M:%S')"

# 4. 删除原分支
echo "4. 删除原主分支..."
git branch -D main 2>/dev/null || git branch -D master 2>/dev/null || true

# 5. 重命名
echo "5. 重命名分支..."
git branch -M main

# 6. 推送
remote_url=$(git remote get-url origin 2>/dev/null || echo "")


if [ -n "$remote_url" ]; then
    echo "6. 推送到远程仓库..."
    read -p "是否强制推送到远程？(y/N): " push_confirm
    if [[ $push_confirm =~ ^[Yy]$ ]]; then
        # 添加 --progress 和超时设置
        timeout 30 git push -f origin main --progress
        push_exit_code=$?
        
        if [ $push_exit_code -eq 0 ]; then
            echo "✅ 已强制推送到远程仓库"
        elif [ $push_exit_code -eq 124 ]; then
            echo "⚠️  推送超时，请手动检查网络连接或认证"
            echo "   可以使用命令手动推送: git push -f origin main"
        else
            echo "⚠️  推送失败，退出码: $push_exit_code"
            echo "   请检查远程仓库权限或网络连接"
        fi
    else
        echo "⏸️  跳过远程推送，只重置本地仓库"
    fi
fi


# 完成
echo ""
echo "✅ 仓库重置完成！"
echo ""
echo "📊 最终状态："
echo "   分支: $(git branch --show-current)"
echo "   提交: $(git log --oneline -1)"
echo "   文件: $(git ls-files | wc -l) 个"
echo "========================================"
}


create_github_repo() {
    
  # ---- 工具检查 ----
  if ! command -v git &>/dev/null; then
    echo "❌ 请先安装 git"
    return 1
  fi

  # ---- 1. 读仓库地址 ----
  read -p "请输入仓库地址（https 或 ssh）: " repo_url
  if [[ -z "$repo_url" ]]; then
    echo "❌ 仓库地址不能为空"
    return 1
  fi

  # 解析仓库名（去掉 .git 后缀）
  repo_name=${repo_url##*/}      # 去掉左侧最后一个 /
  repo_name=${repo_name%.git}    # 去掉 .git

  target_dir="/storage/emulated/0/${repo_name}"

  # ---- 2. 克隆 ----
  echo "⏬ 开始克隆到 ${target_dir} ..."
  git clone "$repo_url" "$target_dir" || {
    echo "❌ 克隆失败"
    return 1
  }

  # ---- 3. 读额外文件夹 ----
  read -p "请输入你的程序的路径: " import_dir
  if [[ -n "$import_dir" ]]; then
    if [[ ! -d "$import_dir" ]]; then
      echo "❌ 目录不存在: $import_dir"
      return 1
    fi

    echo "📂 正在处理文件..."
    # 用 rsync 优先，没有就用 cp -r
    if command -v rsync &>/dev/null; then
      rsync -a --remove-source-files "$import_dir"/ "$target_dir"/ 2>/dev/null
    else
      cp -r "$import_dir"/* "$target_dir"/ 2>/dev/null
    fi
  fi
  sleep 5
rm -rf "$import_dir"
  # ---- 4. 输出结果 ----
  echo ""
  echo "✅ 完成！"
  echo "新程序路径:$target_dir"


}

git_config_fixed() {
    show_title
    echo -e "${C}⚙️  Git 配置管理${N}"
    echo ""
    
    # 先检查当前配置
    echo -e "${Y}当前 Git 配置：${N}"
    echo "用户名: $(git config --global user.name 2>/dev/null || echo '未设置')"
    echo "邮箱: $(git config --global user.email 2>/dev/null || echo '未设置')"
    echo ""
    
    # 配置选项
    echo "请选择要配置的项目："
    echo "1. 设置用户名和邮箱"
    echo "2. 设置 GitHub 令牌"
    echo "3. 设置 SSH 密钥"
    echo "4. 设置凭证存储"
    echo "5. 查看全部配置"
    echo "6. 返回主菜单"
    echo ""
    
    local choice
    read -n 1 -t 30 choice
    echo ""
    
    case $choice in
        1)
            config_user_info
            ;;
        2)
            config_github_token
            ;;
        3)
            config_ssh_key
            ;;
        4)
            config_credential_store
            ;;
        5)
            view_all_configs
            ;;
        6|0)
            return  # 返回主菜单
            ;;
        *)
            echo -e "${R}✗ 无效选择${N}"
            sleep 1
            ;;
    esac
    
    # 返回配置菜单
    echo ""
    if confirm "是否继续配置其他项目"; then
        git_config_fixed
    fi
}

# 子功能：配置用户信息
config_user_info() {
    echo ""
    echo -e "${G}👤 设置用户信息${N}"
    echo ""
    
    local current_name=$(git config --global user.name 2>/dev/null)
    local current_email=$(git config --global user.email 2>/dev/null)
    
    echo -e "${Y}当前设置：${N}"
    echo "用户名: ${current_name:-未设置}"
    echo "邮箱: ${current_email:-未设置}"
    echo ""
    
    # 输入新用户名
    local new_name
    while true; do
        echo -ne "${C}请输入新的用户名（必填）: ${N}"
        read new_name
        if [[ -n "$new_name" ]]; then
            break
        fi
        echo -e "${R}用户名不能为空！${N}"
    done
    
    # 输入新邮箱
    local new_email
    while true; do
        echo -ne "${C}请输入新的邮箱地址（必填）: ${N}"
        read new_email
        if [[ -n "$new_email" ]] && [[ "$new_email" =~ @ ]]; then
            break
        fi
        echo -e "${R}邮箱不能为空且必须包含 @ 符号！${N}"
    done
    
    # 确认设置
    echo ""
    echo -e "${Y}确认设置：${N}"
    echo "用户名: $new_name"
    echo "邮箱: $new_email"
    echo ""
    
    if confirm "是否保存这些设置"; then
        git config --global user.name "$new_name"
        git config --global user.email "$new_email"
        
        if [[ $? -eq 0 ]]; then
            echo -e "${G}✅ 用户信息设置成功！${N}"
        else
            echo -e "${R}❌ 设置失败，请检查 Git 安装${N}"
        fi
    else
        echo -e "${Y}⚠ 已取消设置${N}"
    fi
}

# 子功能：配置 GitHub 令牌（修复版）
config_github_token() {
    echo ""
    echo -e "${G}🔑 配置 GitHub 令牌${N}"
    echo ""
    
    echo -e "${Y}说明：${N}"
    echo "1. GitHub 令牌用于代替密码进行身份验证"
    echo "2. 可以在 https://github.com/settings/tokens 创建"
    echo "3. 创建时需要选择权限：repo, workflow, write:packages"
    echo ""
    
    echo "请选择操作："
    echo "1. 打开浏览器创建令牌（如果支持）"
    echo "2. 输入已有令牌"
    echo "3. 查看已保存的令牌"
    echo "4. 删除已保存的令牌"
    echo "5. 返回"
    echo ""
    
    local token_choice
    read -n 1 -t 30 token_choice
    echo ""
    
    case $token_choice in
        1)
            # 尝试打开浏览器
            echo -e "${Y}请在浏览器中创建令牌...${N}"
            echo "访问：https://github.com/settings/tokens"
            echo "点击 'Generate new token (classic)'"
            echo "勾选权限：repo, workflow, write:packages"
            echo "生成后复制令牌，然后返回这里输入"
            echo ""
            read -p "按回车键继续..." dummy
            
            # 继续输入令牌
            config_github_token_input
            ;;
        2)
            config_github_token_input
            ;;
        3)
            view_saved_token
            ;;
        4)
            delete_saved_token
            ;;
        5)
            return
            ;;
        *)
            echo -e "${R}✗ 无效选择${N}"
            ;;
    esac
}

# 子功能：输入 GitHub 令牌
config_github_token_input() {
    local token
    echo -ne "${C}请输入 GitHub 令牌（输入 q 返回）: ${N}"
    read token
    
    if [[ "$token" == "q" ]] || [[ "$token" == "Q" ]]; then
        return
    fi
    
    if [[ -z "$token" ]]; then
        echo -e "${R}❌ 令牌不能为空${N}"
        return
    fi
    
    # 验证令牌格式（基本验证）
    if [[ ${#token} -lt 20 ]]; then
        echo -e "${R}❌ 令牌格式不正确，长度太短${N}"
        return
    fi
    
    # 保存令牌到文件
    local token_file="$CONFIG_DIR/github_token"
    echo "$token" > "$token_file"
    chmod 600 "$token_file"
    
    if [[ $? -eq 0 ]]; then
        echo -e "${G}✅ 令牌已保存到安全文件${N}"
        echo "位置: $token_file"
        
        # 测试令牌（可选）
        if confirm "是否测试令牌有效性（需要网络）"; then
            echo -e "${Y}正在测试令牌...${N}"
            local response=$(curl -s -H "Authorization: token $token" https://api.github.com/user)
            
            if echo "$response" | grep -q '"login"'; then
                local username=$(echo "$response" | grep '"login"' | head -1 | cut -d'"' -f4)
                echo -e "${G}✅ 令牌有效！用户: $username${N}"
            else
                echo -e "${R}❌ 令牌无效或网络错误${N}"
                echo -e "${Y}提示：请检查令牌权限或网络连接${N}"
            fi
        fi
    else
        echo -e "${R}❌ 保存令牌失败${N}"
    fi
}

# 子功能：查看已保存的令牌
view_saved_token() {
    local token_file="$CONFIG_DIR/github_token"
    
    if [[ -f "$token_file" ]]; then
        echo ""
        echo -e "${Y}已保存的令牌信息：${N}"
        echo "位置: $token_file"
        echo "权限: $(stat -c %a "$token_file" 2>/dev/null || echo "600")"
        echo "大小: $(wc -c < "$token_file") 字节"
        echo ""
        
        if confirm "是否显示令牌内容（前16位）"; then
            local token=$(head -1 "$token_file")
            local masked_token="${token:0:16}****************"
            echo "令牌: $masked_token"
        fi
    else
        echo -e "${Y}⚠ 未找到已保存的令牌${N}"
    fi
}

# 子功能：删除已保存的令牌
delete_saved_token() {
    local token_file="$CONFIG_DIR/github_token"
    
    if [[ -f "$token_file" ]]; then
        echo ""
        echo -e "${Y}找到令牌文件：${N}"
        echo "$token_file"
        echo ""
        
        if confirm "${R}确定要删除令牌吗？${N}"; then
            rm -f "$token_file"
            if [[ $? -eq 0 ]]; then
                echo -e "${G}✅ 令牌已删除${N}"
            else
                echo -e "${R}❌ 删除失败${N}"
            fi
        fi
    else
        echo -e "${Y}⚠ 未找到令牌文件${N}"
    fi
}

# 子功能：配置 SSH 密钥（修复版）
config_ssh_key() {
    echo ""
    echo -e "${G}🔐 配置 SSH 密钥${N}"
    echo ""
    
    echo -e "${Y}说明：${N}"
    echo "1. SSH 密钥比令牌更安全，推荐使用"
    echo "2. 需要将公钥上传到 GitHub"
    echo "3. 可以在 https://github.com/settings/keys 管理"
    echo ""
    
    # 检查现有密钥
    local ssh_dir="$HOME/.ssh"
    local key_file="$ssh_dir/id_ed25519"
    local pub_file="$key_file.pub"
    
    if [[ -f "$key_file" ]]; then
        echo -e "${G}✓ 检测到现有 SSH 密钥${N}"
        echo "位置: $key_file"
        echo ""
        
        if confirm "是否生成新密钥（现有密钥将被覆盖）"; then
            generate_new_ssh_key
        else
            show_ssh_public_key
        fi
    else
        echo -e "${Y}⚠ 未检测到 SSH 密钥${N}"
        echo ""
        
        if confirm "是否生成新的 SSH 密钥"; then
            generate_new_ssh_key
        else
            return
        fi
    fi
}

# 子功能：生成新 SSH 密钥
generate_new_ssh_key() {
    echo ""
    echo -e "${Y}🔧 生成 SSH 密钥...${N}"
    
    # 输入邮箱
    local email
    echo -ne "${C}请输入邮箱地址（用于标识密钥）: ${N}"
    read email
    
    if [[ -z "$email" ]]; then
        email="$(whoami)@$(hostname 2>/dev/null || echo localhost)"
    fi
    
    # 创建 .ssh 目录
    mkdir -p ~/.ssh
    chmod 700 ~/.ssh
    
    # 生成密钥
    echo -e "${Y}正在生成密钥，请按照提示操作...${N}"
    ssh-keygen -t ed25519 -C "$email" -f ~/.ssh/id_ed25519
    
    if [[ $? -eq 0 ]]; then
        echo -e "${G}✅ SSH 密钥生成成功！${N}"
        show_ssh_public_key
    else
        echo -e "${R}❌ 密钥生成失败${N}"
    fi
}

# 子功能：显示 SSH 公钥
show_ssh_public_key() {
    local pub_file="$HOME/.ssh/id_ed25519.pub"
    
    if [[ -f "$pub_file" ]]; then
        echo ""
        echo -e "${G}📋 SSH 公钥：${N}"
        echo "========================================"
        cat "$pub_file"
        echo "========================================"
        echo ""
        echo -e "${Y}📝 操作指南：${N}"
        echo "1. 复制上面的全部内容"
        echo "2. 访问 https://github.com/settings/keys"
        echo "3. 点击 'New SSH key'"
        echo "4. 粘贴公钥，设置标题"
        echo "5. 点击 'Add SSH key'"
        echo ""
        
        if confirm "是否测试 SSH 连接"; then
            echo -e "${Y}正在测试连接...${N}"
            ssh -T git@github.com
        fi
    else
        echo -e "${R}❌ 未找到公钥文件${N}"
    fi
}

# 子功能：配置凭证存储（修复版）
config_credential_store() {
    echo ""
    echo -e "${G}💾 配置凭证存储${N}"
    echo ""
    
    echo -e "${Y}说明：${N}"
    echo "凭证存储决定 Git 如何记住你的密码/令牌"
    echo ""
    
    echo "请选择凭证存储方式："
    echo "1. 缓存（15分钟）"
    echo "2. 缓存（1小时）"
    echo "3. 缓存（1天）"
    echo "4. 存储（永久，较不安全）"
    echo "5. 系统钥匙串（如果可用）"
    echo "6. 清除现有配置"
    echo "7. 返回"
    echo ""
    
    local store_choice
    read -n 1 -t 30 store_choice
    echo ""
    
    case $store_choice in
        1)
            git config --global credential.helper "cache --timeout=900"
            echo -e "${G}✅ 已设置缓存15分钟${N}"
            ;;
        2)
            git config --global credential.helper "cache --timeout=3600"
            echo -e "${G}✅ 已设置缓存1小时${N}"
            ;;
        3)
            git config --global credential.helper "cache --timeout=86400"
            echo -e "${G}✅ 已设置缓存1天${N}"
            ;;
        4)
            git config --global credential.helper "store"
            echo -e "${G}✅ 已设置永久存储${N}"
            echo -e "${Y}⚠ 注意：凭证将明文存储在 ~/.git-credentials${N}"
            ;;
        5)
            # 检测系统类型
            if [[ "$(uname)" == "Darwin" ]]; then
                git config --global credential.helper "osxkeychain"
                echo -e "${G}✅ 已设置 macOS 钥匙串${N}"
            elif [[ -d "/data/data/com.termux" ]]; then
                git config --global credential.helper "store"
                echo -e "${G}✅ Termux 环境使用永久存储${N}"
            else
                git config --global credential.helper "cache --timeout=3600"
                echo -e "${G}✅ 系统钥匙串不可用，改用1小时缓存${N}"
            fi
            ;;
        6)
            git config --global --unset credential.helper
            echo -e "${G}✅ 已清除凭证存储配置${N}"
            ;;
        7)
            return
            ;;
        *)
            echo -e "${R}✗ 无效选择${N}"
            ;;
    esac
    
    # 显示当前设置
    echo ""
    local current_helper=$(git config --global credential.helper)
    if [[ -n "$current_helper" ]]; then
        echo -e "${Y}当前凭证存储：${N} $current_helper"
    else
        echo -e "${Y}当前凭证存储：${N} 未设置"
    fi
}

# 子功能：查看全部配置
view_all_configs() {
    echo ""
    echo -e "${G}📋 全部 Git 配置${N}"
    echo ""
    
    local configs=$(git config --global --list)
    
    if [[ -n "$configs" ]]; then
        echo "$configs" | while IFS= read -r line; do
            # 隐藏敏感信息
            if [[ "$line" == *token* ]] || [[ "$line" == *password* ]] || [[ "$line" == *secret* ]]; then
                local key=$(echo "$line" | cut -d= -f1)
                echo "$key=***隐藏***"
            else
                echo "$line"
            fi
        done
    else
        echo -e "${Y}未找到全局配置${N}"
    fi
    
    echo ""
    echo -e "${Y}配置文件位置：${N}"
    echo "全局: ~/.gitconfig"
    echo "系统: /etc/gitconfig"
    echo "项目: .git/config"
}

# 5. 一键设置（修复版）
quick_setup_fixed() {
    show_title
    echo -e "${G}⚡ 一键快速设置${N}"
    echo ""
    
    echo "此功能将配置："
    echo "• Git用户信息（需要手动输入）"
    echo "• 凭证缓存"
    echo "• 常用别名"
    echo "• 行尾设置"
    echo "• 大文件支持"
    echo "• 其他优化"
    echo ""
    
    if ! confirm "开始快速设置吗"; then
        return
    fi
    
    # 1. 用户信息（完全由用户输入）
    echo ""
    echo -e "${Y}1. 设置用户信息${N}"
    echo ""
    
    # 用户名输入
    local name=""
    while [[ -z "$name" ]]; do
        echo -ne "${C}请输入Git用户名（必填）: ${N}"
        read name
        if [[ -z "$name" ]]; then
            echo -e "${R}用户名不能为空，请重新输入${N}"
        fi
    done
    
    # 邮箱输入
    local email=""
    while [[ -z "$email" ]] || [[ ! "$email" =~ @ ]]; do
        echo -ne "${C}请输入Git邮箱（必填，格式：name@example.com）: ${N}"
        read email
        if [[ -z "$email" ]]; then
            echo -e "${R}邮箱不能为空，请重新输入${N}"
        elif [[ ! "$email" =~ @ ]]; then
            echo -e "${R}邮箱格式不正确，请重新输入${N}"
        fi
    done
    
    # 设置配置
    echo ""
    git config --global user.name "$name"
    git config --global user.email "$email"
    
    if [[ $? -eq 0 ]]; then
        echo -e "${G}✓ 用户信息设置完成${N}"
        echo "  用户名: $name"
        echo "  邮箱: $email"
    else
        echo -e "${R}✗ 用户信息设置失败${N}"
        return 1
    fi
    
    # 2. 凭证缓存
    echo ""
    echo -e "${Y}2. 设置凭证缓存${N}"
    echo ""
    
    echo "请选择凭证存储方式："
    echo "1. 缓存（15分钟）"
    echo "2. 缓存（1小时）"
    echo "3. 缓存（1天）"
    echo "4. 存储（永久）"
    echo "5. 不设置"
    
    local cred_choice=$(number_select "选择（1-5）" 1 5 2)
    
    case $cred_choice in
        1)
            git config --global credential.helper "cache --timeout=900"
            echo -e "${G}✓ 凭证缓存15分钟${N}"
            ;;
        2)
            git config --global credential.helper "cache --timeout=3600"
            echo -e "${G}✓ 凭证缓存1小时${N}"
            ;;
        3)
            git config --global credential.helper "cache --timeout=86400"
            echo -e "${G}✓ 凭证缓存1天${N}"
            ;;
        4)
            git config --global credential.helper "store"
            echo -e "${G}✓ 永久存储（凭证保存在 ~/.git-credentials）${N}"
            echo -e "${Y}注意：请确保该文件的安全${N}"
            ;;
        5)
            echo -e "${Y}⚠ 跳过凭证设置${N}"
            ;;
    esac
    
    # 3. 别名设置
    echo ""
    echo -e "${Y}3. 设置常用别名${N}"
    echo ""
    
    echo "是否设置常用Git别名？"
    echo "这些别名可以让你更快地使用Git命令。"
    echo ""
    
    if confirm "设置常用别名（y/n）"; then
        # 基础别名
        git config --global alias.s "status --short"
        git config --global alias.ss "status"
        git config --global alias.l "log --oneline -10"
        git config --global alias.ll "log --oneline --graph --all -20"
        git config --global alias.la "log --oneline --graph --all"
        
        # 提交相关
        git config --global alias.aa "add ."
        git config --global alias.cm "commit -m"
        git config --global alias.ca "commit -am"
        git config --global alias.amend "commit --amend"
        
        # 分支相关
        git config --global alias.co "checkout"
        git config --global alias.cob "checkout -b"
        git config --global alias.br "branch"
        git config --global alias.brd "branch -d"
        git config --global alias.brD "branch -D"
        
        # 推送相关
        git config --global alias.pu "push"
        git config --global alias.puf "push --force-with-lease"
        git config --global alias.pl "pull"
        
        # 其他
        git config --global alias.df "diff"
        git config --global alias.dc "diff --cached"
        git config --global alias.rs "reset"
        git config --global alias.rsh "reset --hard"
        git config --global alias.stash-all "stash push --all"
        
        echo -e "${G}✓ 已设置常用别名${N}"
        echo ""
        echo -e "${C}常用别名示例：${N}"
        echo "  git s    查看简洁状态"
        echo "  git aa   添加所有文件"
        echo "  git cm   提交更改"
        echo "  git pu   推送到远程"
        echo "  git pl   拉取更新"
    else
        echo -e "${Y}⚠ 跳过别名设置${N}"
    fi
    
    # 4. 行尾设置
    echo ""
    echo -e "${Y}4. 设置行尾处理${N}"
    echo ""
    
    echo "请选择行尾处理方式："
    echo "1. 自动转换（Windows推荐）"
    echo "2. 输入时转换，输出为LF（macOS/Linux推荐）"
    echo "3. 不转换（纯文本项目）"
    echo "4. 跳过"
    
    local line_choice=$(number_select "选择（1-4）" 1 4 3)
    
    case $line_choice in
        1)
            git config --global core.autocrlf true
            echo -e "${G}✓ 已设置自动转换行尾${N}"
            ;;
        2)
            git config --global core.autocrlf input
            echo -e "${G}✓ 已设置输入转换${N}"
            ;;
        3)
            git config --global core.autocrlf false
            echo -e "${G}✓ 已禁用行尾转换${N}"
            ;;
        4)
            echo -e "${Y}⚠ 跳过行尾设置${N}"
            ;;
    esac
    
    # 5. 大文件支持
    echo ""
    echo -e "${Y}5. 设置大文件支持${N}"
    echo ""
    
    echo "是否优化Git以支持大文件？"
    echo "这可以帮助推送大文件时避免超时。"
    echo ""
    
    if confirm "设置大文件支持（y/n）"; then
        git config --global http.postBuffer 104857600    # 100MB
        git config --global pack.windowMemory 512m
        git config --global pack.packSizeLimit 512m
        git config --global core.compression 9
        
        echo -e "${G}✓ 大文件支持设置完成${N}"
        echo "  缓冲区: 100MB"
        echo "  内存限制: 512MB"
        echo "  压缩级别: 最高"
    else
        echo -e "${Y}⚠ 跳过大文件优化${N}"
    fi
    
    # 6. 其他优化
    echo ""
    echo -e "${Y}6. 其他优化设置${N}"
    echo ""
    
    echo "应用其他优化设置："
    git config --global pull.rebase false
    git config --global push.default simple
    git config --global init.defaultBranch main
    git config --global core.quotepath false
    
    echo -e "${G}✓ 其他优化完成${N}"
    echo "  拉取模式: merge（非rebase）"
    echo "  推送模式: simple"
    echo "  默认分支: main"
    echo "  路径显示: 正常（非转义）"
    
    # 完成
    echo ""
    echo -e "${G}✅ 一键设置完成！${N}"
    echo ""
    echo -e "${Y}配置摘要：${N}"
    echo "用户名: $name"
    echo "邮箱: $email"
    
    if [[ $cred_choice -ne 5 ]]; then
        echo "凭证: 已设置（选项$cred_choice）"
    else
        echo "凭证: 未设置"
    fi
    
    echo "行尾: 选项$line_choice"
    echo "大文件: $( [[ $cred_choice -ne 5 ]] && echo "已启用" || echo "未启用" )"
    echo ""
    echo -e "${C}配置保存在：~/.gitconfig${N}"
    echo ""
    
    read -p "按回车键返回主菜单..." dummy
}
# ================= 主菜单 =================
main_menu() {
    init
    
    while true; do
        show_title
        
        echo -e "${C}📱 Git 工具箱 v1.0${N}"
        echo ""
        echo -e "${B}[1]${N} 简单上传"
        echo -e "${B}[2]${N} 清空原仓库并上传"
        echo -e "${B}[3]${N} 程序初始化（刚建好仓库用我）"
        echo -e "${B}[4]${N} Git配置管理"
        echo -e "${B}[5]${N} 一键快速设置"
        echo -e "${B}[0]${N} 退出"
        echo ""
        echo -e "${Y}提示：直接按数字键选择${N}"
        
        local choice
        read -n 1 -t 60 choice
        
        
        
        echo ""
        
        case $choice in
            1) quick_upload ;;
            2) clean_and_upload ;;
            3) create_github_repo ;;
            4) git_config_fixed ;;
            5) quick_setup_fixed ;;
            0)
                echo -e "${G}👋 感谢使用！${N}"
                exit 0
                ;;
            *)
                echo -e "${R}✗ 无效选择${N}"
                sleep 1
                continue
                ;;
        esac
        
        echo ""
        if confirm "返回主菜单"; then
            continue
        else
            echo -e "${G}👋 再见！${N}"
            exit 0
        fi
    done
}

# 启动
main_menu