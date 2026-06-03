#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
解析 boot_items.yaml 配置文件，生成启动命令列表
用法: python parse_config.py <config_file> <output_file>
输出格式: module|script|wait_time|status (每行一个启动项)
"""

import sys
import os

try:
    import yaml
except ImportError:
    print("[ERROR] 需要安装 PyYAML: pip install pyyaml", file=sys.stderr)
    sys.exit(1)


def parse_wait_time(wait_str):
    """解析等待时间字符串，如 '3s' 或 '3'，返回整数秒数"""
    wait_str = wait_str.strip()
    if wait_str.endswith('s'):
        return int(wait_str[:-1])
    return int(wait_str)


def parse_config(config_file, output_file):
    """解析 YAML 配置并写入输出文件"""
    
    # 读取配置文件
    try:
        with open(config_file, 'r', encoding='utf-8') as f:
            config = yaml.safe_load(f)
    except Exception as e:
        print(f"[ERROR] 解析 YAML 失败: {e}", file=sys.stderr)
        sys.exit(1)
    
    items = config.get('items', [])
    if not items:
        print("[WARN] 配置文件中没有定义启动项", file=sys.stderr)
        # 创建空文件
        with open(output_file, 'w', encoding='utf-8') as f:
            pass
        return
    
    launch_commands = []
    
    for item in items:
        if isinstance(item, str):
            # 简单字符串模块名: "xiaobei-backend"
            # 默认使用 run 脚本，等待 1 秒
            launch_commands.append(f"{item}|run|1|run")
        
        elif isinstance(item, dict):
            # 统一字典格式: {module_name: {status: skip/run, scripts: [...]}}
            for module_name, module_config in item.items():
                # 检查是否有 status 字段
                status = module_config.get('status', 'run') if isinstance(module_config, dict) else 'run'
                
                if status == 'skip':
                    # 跳过整个模块
                    launch_commands.append(f"{module_name}|__skip__|0|skip")
                
                elif isinstance(module_config, dict):
                    # 有 scripts 列表
                    scripts = module_config.get('scripts', [])
                    for sub_item in scripts:
                        if isinstance(sub_item, str):
                            # 简单字符串格式: "run" 或 "run_ms, 3s"
                            parts = sub_item.split(',')
                            script = parts[0].strip()
                            
                            # 默认等待时间 1 秒
                            wait_time = 1
                            if len(parts) > 1:
                                wait_str = parts[1].strip()
                                try:
                                    wait_time = parse_wait_time(wait_str)
                                except ValueError:
                                    print(f"[WARN] 无效的等待时间格式: {wait_str}，使用默认值 1s", 
                                          file=sys.stderr)
                            
                            launch_commands.append(f"{module_name}|{script}|{wait_time}|run")
                        
                        elif isinstance(sub_item, dict):
                            # 字典格式: {script_name: status}
                            for script_name, script_status in sub_item.items():
                                if script_status == 'skip':
                                    # 跳过该脚本
                                    launch_commands.append(f"{module_name}|{script_name}|0|skip")
                                else:
                                    # 正常运行（可以指定等待时间）
                                    parts = str(script_status).split(',')
                                    wait_time = 1
                                    if len(parts) > 1:
                                        try:
                                            wait_time = parse_wait_time(parts[1].strip())
                                        except ValueError:
                                            pass
                                    launch_commands.append(f"{module_name}|{script_name}|{wait_time}|run")
    
    # 写入输出文件
    try:
        with open(output_file, 'w', encoding='utf-8') as f:
            for cmd in launch_commands:
                f.write(cmd + '\n')
        print(f"[INFO] 已生成 {len(launch_commands)} 个启动项")
    except Exception as e:
        print(f"[ERROR] 写入输出文件失败: {e}", file=sys.stderr)
        sys.exit(1)


def main():
    if len(sys.argv) != 3:
        print("用法: python parse_config.py <config_file> <output_file>", file=sys.stderr)
        sys.exit(1)
    
    config_file = sys.argv[1]
    output_file = sys.argv[2]
    
    if not os.path.exists(config_file):
        print(f"[ERROR] 配置文件不存在: {config_file}", file=sys.stderr)
        sys.exit(1)
    
    parse_config(config_file, output_file)


if __name__ == '__main__':
    main()
