import os
import sys

def split_to_files(filename, headers):
    # Проверяем, существует ли файл
    if not os.path.exists(filename):
        print(f"Ошибка: Файл '{filename}' не найден в папке со скриптом.")
        return

    print(f"Обработка: {filename}...")
    
    try:
        # Создаём файлы для записи (используем 'w' для перезаписи)
        output_files = []
        for h in headers:
            f = open(f"{h}.txt", "w", encoding="utf-8")
            # Пишем начало списка
            f.write(f"{h} = [\n")
            output_files.append(f)

        # Читаем data1.txt или data2.txt построчно
        with open(filename, "r", encoding="utf-8") as infile:
            for line_num, line in enumerate(infile):
                line = line.strip()
                if not line:
                    continue
                
                # Разбиваем строку на столбцы
                parts = line.split()
                
                # Если количество столбцов не 4, пропускаем (для защиты от пустых строк в конце)
                if len(parts) != len(headers):
                    continue

                # Записываем значения в соответствующие файлы
                for i, part in enumerate(parts):
                    # Заменяем ',' на '.' (европейский формат) и сразу записываем
                    cleaned_value = part.replace(',', '.')
                    output_files[i].write(f"{cleaned_value},\n")

        # Закрываем файлы, дописывая закрывающую скобку
        for f in output_files:
            f.write("]\n")
            f.close()
            
        print(f"Готово! Созданы файлы: {headers}")

    except Exception as e:
        print(f"Ошибка во время обработки {filename}: {e}")

# === ГЛАВНАЯ ЧАСТЬ СКРИПТА ===
if __name__ == "__main__":
    # 1. Меняем рабочую папку на папку, где лежит этот скрипт
    # Это решит проблему с "Файл не найден"
    script_dir = os.path.dirname(os.path.abspath(__file__))
    os.chdir(script_dir)

    print(f"Текущая рабочая папка: {os.getcwd()}\n")

    # 2. Обрабатываем файлы
    split_to_files("data1.txt", ["A", "B", "C", "D"])
    print("-" * 30)
    split_to_files("data2.txt", ["E", "F", "G", "H"])
    
    print("\nВсе операции завершены!")