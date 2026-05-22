input_file = 'data.txt'

A = []
B = []
C = []
D = []

with open(input_file, 'r', encoding='utf-8') as file:
    for line in file:
        line = line.strip()
        if not line:
            continue
            
        parts = line.split()
        
        if len(parts) == 4:
            val1 = float(parts[0].replace(',', '.'))
            val2 = float(parts[1].replace(',', '.'))
            val3 = float(parts[2].replace(',', '.'))
            val4 = float(parts[3].replace(',', '.'))
            
            A.append(val1)
            B.append(val2)
            C.append(val3)
            D.append(val4)

vectors = {
    "A": A,
    "B": B,
    "C": C,
    "D": D
}

for name, data in vectors.items():
    with open(f"{name}.txt", "w", encoding='utf-8') as f:
        formatted_str = f"{name} = {data}"
        f.write(formatted_str)

print("Готово! Файлы A.txt, B.txt, C.txt, D.txt успешно созданы.")