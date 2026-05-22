function VecConvertor()
    % Переходим в папку со скриптом
    [fileDir, ~, ~] = fileparts(mfilename('fullpath'));
    cd(fileDir);
    fprintf('Рабочая папка: %s\n', fileDir);

    % Обработка data1
    processFast('data1.txt', {'A', 'B', 'C', 'D'});
    fprintf('%s\n', repmat('-', 1, 30));
    % Обработка data2
    processFast('data2.txt', {'E', 'F', 'G', 'H'});
    
    fprintf('\nГотово!\n');
end

function processFast(filename, outputNames)
    if ~exist(filename, 'file')
        warning('Файл %s не найден', filename);
        return;
    end
    
    fprintf('Чтение %s... ', filename);
    
    % --- 1. Читаем файл как текст ---
    fid = fopen(filename, 'r');
    textStr = fread(fid, '*char').'; % Читаем всё в строку
    fclose(fid);
    
    % --- 2. Заменяем запятые на точки ---
    textStr = strrep(textStr, ',', '.');
    
    % --- 3. Читаем 4 столбца чисел ---
    data_cell = textscan(textStr, '%f%f%f%f', ...
        'Delimiter', ' ', ...
        'MultipleDelimsAsOne', true, ...
        'ReturnOnError', false);
    
    % Объединяем в матрицу
    data = [data_cell{:}];
    
    % Проверка, что получилось 4 столбца
    if size(data, 2) < 4
        error('Ошибка: Удалось прочитать только %d столбцов (ожидалось 4). Проверьте формат файла.', size(data, 2));
    end
    
    fprintf('Запись... ');
    for i = 1:length(outputNames)
        col = data(:, i);
        outFile = [outputNames{i} '.txt'];
        fidOut = fopen(outFile, 'w');
        
        % Формат A = [ ... ]
        fprintf(fidOut, '%s = [', outputNames{i});
        
        % Запись чисел с экспонентой (сохраняем E-5 и т.д.)
        if length(col) > 1
            fprintf(fidOut, '%.6e, ', col(1:end-1));
        end
        fprintf(fidOut, '%.6e]', col(end));
        
        fclose(fidOut);
    end
    fprintf('Созданы: %s\n', strjoin(outputNames, ', '));
end