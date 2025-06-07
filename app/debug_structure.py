import os

print("🚨 Diagnóstico de Estrutura de Diretórios 🚨")
root_dir = os.getcwd()
print(f"🔍 Diretório de trabalho: {root_dir}")

print("\n🔎 Estrutura de pastas e ficheiros:")
for dirpath, dirnames, filenames in os.walk(root_dir):
    level = dirpath.replace(root_dir, '').count(os.sep)
    indent = ' ' * 2 * level
    print(f"{indent}{os.path.basename(dirpath)}/")
    subindent = ' ' * 2 * (level + 1)
    for f in filenames:
        print(f"{subindent}{f}")
