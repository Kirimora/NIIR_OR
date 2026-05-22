function compare_vectors()
    files1 = {'A.txt', 'B.txt', 'C.txt', 'D.txt'};
    files2 = {'E.txt', 'F.txt', 'G.txt', 'H.txt'};
    
    % Загружаем все векторы
    t1 = load_simple(files1{1});
    b  = load_simple(files1{2});
    c  = load_simple(files1{3});
    d  = load_simple(files1{4});
    
    t2 = load_simple(files2{1});
    f  = load_simple(files2{2});
    g  = load_simple(files2{3});
    h  = load_simple(files2{4});
    
    % Проверка длины
    if length(t1) ~= length(t2)
        error('Длины времени не совпадают: t1=%d, t2=%d', length(t1), length(t2));
    end
    
    % Используем t1 как общую ось времени
    time = t1(:);
    
    % Фигура 1: Вибродатчик 1
    plot_separate(time, b, f, 'Вибродатчик 1 (B / F)');
    
    % Фигура 2: Вибродатчик 2
    plot_separate(time, c, g, 'Вибродатчик 2 (C / G)');
    
    % Фигура 3: Акустический датчик
    plot_separate(time, d, h, 'Акустический датчик (D / H)');
    
    disp('Готово! Три окна с графиками открыты.');
end

%Чтение файла
function vec = load_simple(filename)
    fid = fopen(filename, 'r');
    txt = fread(fid, '*char')';
    fclose(fid);
    
    % Удаляем всё до первой скобки и после последней
    openBracket = strfind(txt, '[');
    closeBracket = strfind(txt, ']');
    if isempty(openBracket) || isempty(closeBracket)
        error('Файл %s не содержит скобок [ ]', filename);
    end
    nums_str = txt(openBracket(1)+1 : closeBracket(end)-1);
    
    % Заменяем запятые на пробелы
    nums_str = strrep(nums_str, ',', ' ');
    % Убираем лишние пробелы и переносы строк
    nums_str = regexprep(nums_str, '\s+', ' ');
    % Преобразуем в числа
    vec = str2num(nums_str);
    if isempty(vec)
        error('Не удалось прочитать числа из файла %s', filename);
    end
    vec = vec(:);
end

% Отрисовка отдельного графика 
function plot_separate(t, y1, y2, title_str)
    figure('Name', title_str, 'NumberTitle', 'off');
    plot(t, y1, 'r-', 'LineWidth', 1.5); hold on;
    plot(t, y2, 'b-', 'LineWidth', 1.5);
    xlabel('Время (с)'); ylabel('Амплитуда');
    title(title_str);
    legend('Файл 1', 'Файл 2', 'Location', 'best');
    grid on;
    
    [maxDiff, idx_max] = max(abs(y1 - y2));
    t_max = t(idx_max);
    txt = sprintf('Max diff = %.4f at t = %.4f', maxDiff, t_max);
    text(0.02, 0.92, txt, 'Units', 'normalized', ...
         'BackgroundColor', 'w', 'EdgeColor', 'k', 'FontWeight', 'bold');
    fprintf('%s: max diff = %.6f at t = %.6f\n', title_str, maxDiff, t_max);
end