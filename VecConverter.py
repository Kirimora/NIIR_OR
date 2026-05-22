import os

def process_file(input_filename, output_names):
    # Это нужно, чтобы программа автоматически работала из правильной папки
    script_dir = os.path.dirname(os.path.abspath(__file__))
    full_path = os.path.join(script_dir, input_filename)

    vectors = {name: [] for name in output_names}

    # Чтение данных (используем полный путь full_path)
    with open(full_path, 'r', encoding='utf-8') as file:
        for line in file:
            line = line.strip()
            if not line:
                continue
                
            parts = line.split()
            if len(parts) == 4:
                values = [float(p.replace(',', '.')) for p in parts]
                for i, name in enumerate(output_names):
                    vectors[name].append(values[i])
    
    # Сохранение в файлы (сохраняем тоже в папку со скриптом)
    for name, data in vectors.items():
        out_path = os.path.join(script_dir, f"{name}.txt")
        with open(out_path, "w", encoding='utf-8') as f:
            f.write(f"{name} = {data}")
    
    print(f"Файл '{input_filename}' обработан. Созданы файлы: {', '.join([f'{n}.txt' for n in output_names])}")

# ==========================================
# ЗАПУСК
# ==========================================

# Убедитесь, что файлы data.txt и data2.txt лежат в папке со скриптом
process_file('data.txt', ['A', 'B', 'C', 'D'])
process_file('data2.txt', ['E', 'F', 'G', 'H'])

print("ВСЕ ФАЙЛЫ УСПЕШНО СОЗДАНЫ!")