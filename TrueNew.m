% =========================================================================
% СРАВНЕНИЕ ДВУХ ЭКСПЕРИМЕНТОВ (4500 об/мин и 3000 об/мин)
% Только каналы 1 и 2
% Три типа спектров: прямой, виброскорость, огибающая
% На каждом графике: красный - 4500, синий - 3000
% Вертикальные линии - расчётные собственные частоты дефектов подшипника
% Вывод амплитуд на этих частотах
% =========================================================================

clc; clear; close all;

%% 1. ВЫБОР ФАЙЛОВ
% Это интерактив если нужно
% [file4500, path4500] = uigetfile('*.lvm', 'Выберите LVM файл для 4500 об/мин');
% if file4500 == 0; error('Файл не выбран'); end
% [file3000, path3000] = uigetfile('*.lvm', 'Выберите LVM файл для 3000 об/мин');
% if file3000 == 0; error('Файл не выбран'); end
% filename_4500 = fullfile(path4500, file4500);
% filename_3000 = fullfile(path3000, file3000);

% Или задайте имена прямо:
filename_4500 = 'data1.lvm'; % Для 4500 оборотов
filename_3000 = 'data2.lvm'; % Для 3000 оборотов

%% 2. ЧТЕНИЕ И ОБРАБОТКА КАЖДОГО ЭКСПЕРИМЕНТА
fprintf('=== ОБРАБОТКА %s ===\n', filename_4500);
data4500 = loadAndProcess(filename_4500);
fs4500 = data4500.fs;
fprintf('=== ОБРАБОТКА %s ===\n', filename_3000);
data3000 = loadAndProcess(filename_3000);
fs3000 = data3000.fs;

if abs(fs4500 - fs3000) > 1e-3
    warning('Частоты дискретизации отличаются. Берём fs = %.2f Гц', fs4500);
end
fs = fs4500;

%% 3. ПАРАМЕТРЫ ШПИНДЕЛЯ И ГЕОМЕТРИЯ ПОДШИПНИКА
RPM4500 = 4500; RPM3000 = 3000;
f_rot4500 = RPM4500 / 60; f_rot3000 = RPM3000 / 60;

% Геометрия подшипника 
n       = 20;      % число тел качения
d_ball  = 10.0;    % мм
D_pitch = 89.0;    % мм
phi_deg = 15;      % градусы

[k_FTF, k_BPFO, k_BPFI, k_BSF] = bearing_coeffs(n, d_ball, D_pitch, phi_deg);

% Частоты дефектов для каждого режима
f_FTF4500  = k_FTF  * f_rot4500; f_FTF3000  = k_FTF  * f_rot3000;
f_BPFO4500 = k_BPFO * f_rot4500; f_BPFO3000 = k_BPFO * f_rot3000;
f_BPFI4500 = k_BPFI * f_rot4500; f_BPFI3000 = k_BPFI * f_rot3000;
f_BSF4500  = k_BSF  * f_rot4500; f_BSF3000  = k_BSF  * f_rot3000;

freqs4500 = [f_FTF4500, f_BPFO4500, f_BPFI4500, f_BSF4500];
freqs3000 = [f_FTF3000, f_BPFO3000, f_BPFI3000, f_BSF3000];
freqNames = {'FTF', 'BPFO', 'BPFI', 'BSF'};

fprintf('\nРасчётные частоты (4500 об/мин): FTF=%.2f, BPFO=%.2f, BPFI=%.2f, BSF=%.2f Гц\n', freqs4500);
fprintf('Расчётные частоты (3000 об/мин): FTF=%.2f, BPFO=%.2f, BPFI=%.2f, BSF=%.2f Гц\n', freqs3000);

%% 4. ВЫЧИСЛЕНИЕ СПЕКТРОВ (каналы 1 и 2)
target_duration = 2.0;   % 2 секунды стационарного участка

[spec4500, f_hz4500] = computeSpectra(data4500, fs, target_duration, [1,2]);
[spec3000, f_hz3000] = computeSpectra(data3000, fs, target_duration, [1,2]);

if length(f_hz4500) ~= length(f_hz3000)
    error('Размеры частотных сеток не совпадают. Проверьте одинаковость fs и target_duration.');
end
f_hz = f_hz4500;

%% 5. ПОСТРОЕНИЕ ГРАФИКОВ (3 строки × 2 столбца)
% Типы спектров: 1 - ускорение, 2 - виброскорость, 3 - огибающая
plotTitles = {'Прямой спектр (ускорение)', 'Спектр виброскорости', 'Спектр огибающей'};
yLabels   = {'Амплитуда, м/с^2', 'Амплитуда, мм/с', 'Амплитуда, у.е.'};
xLimits   = {[0 500], [0 1200], [0 1500]};

figure('Name', 'Сравнение 4500 vs 3000 (каналы 1 и 2)', 'Color', 'w', 'Position', [100, 50, 1300, 900]);
tlayout = tiledlayout(3, 2, 'TileSpacing', 'compact', 'Padding', 'compact');
title(tlayout, 'Сравнение спектров: 4500 об/мин (красный)  —  3000 об/мин (синий)', 'Color', 'k', 'FontWeight', 'bold');


for iType = 1:3
    for iChan = 1:2
        ax = nexttile;
        set(ax, 'Color', 'w');                 % белый фон
        set(ax, 'XColor', 'k', 'YColor', 'k'); % чёрные оси и деления
        set(ax, 'FontWeight', 'bold');         % жирные цифры на осях
        hold on; grid on;
        set(gca, 'GridColor', [0.3 0.3 0.3], 'GridAlpha', 0.7, 'GridLineStyle', '-');
        % Выбор данных для текущего типа спектра
        switch iType
            case 1
                y4500 = spec4500.acc(:, iChan);
                y3000 = spec3000.acc(:, iChan);
            case 2
                y4500 = spec4500.vel(:, iChan);
                y3000 = spec3000.vel(:, iChan);
            case 3
                y4500 = spec4500.env(:, iChan);
                y3000 = spec3000.env(:, iChan);
        end
        
        % Спектры
        plot(f_hz, y4500, 'r-', 'LineWidth', 1.2, 'DisplayName', '4500 об/мин');
        plot(f_hz, y3000, 'b-', 'LineWidth', 1.2, 'DisplayName', '3000 об/мин');
        
        % Находим максимальную амплитуду для текущего графика (для подписи частот)
        maxAmp = max([y4500; y3000]);
        
        % Для каждой расчётной частоты: линии, маркеры, сбор амплитуд
        amp4500_vals = zeros(length(freqs4500),1);
        amp3000_vals = zeros(length(freqs3000),1);
        
        for k = 1:length(freqs4500)
            [~, idx4500] = min(abs(f_hz - freqs4500(k)));
            [~, idx3000] = min(abs(f_hz - freqs3000(k)));
            amp4500_vals(k) = y4500(idx4500);
            amp3000_vals(k) = y3000(idx3000);
            
            % Вертикальные линии
            xline(freqs4500(k), '--r', 'LineWidth', 0.8, 'HandleVisibility', 'off');
            xline(freqs3000(k), '--b', 'LineWidth', 0.8, 'HandleVisibility', 'off');
            % Маркеры на кривых
            plot(freqs4500(k), amp4500_vals(k), 'ro', 'MarkerSize', 6, 'LineWidth', 1.5, 'HandleVisibility', 'off');
            plot(freqs3000(k), amp3000_vals(k), 'bo', 'MarkerSize', 6, 'LineWidth', 1.5, 'HandleVisibility', 'off');
            % Подпись частоты (цифра) для 4500
            text(freqs4500(k), maxAmp*0.9, sprintf('%.0f', freqs4500(k)), ...
                'Color', 'r', 'FontSize', 7, 'HorizontalAlignment', 'center');
        end
        
        % Текстовый блок с амплитудами
        txt = {};
        for k = 1:length(freqNames)
            txt{end+1} = sprintf('%s: 4500=%.2e, 3000=%.2e', ...
                freqNames{k}, amp4500_vals(k), amp3000_vals(k));
        end
        annotation('textbox', [ax.Position(1)+ax.Position(3)*0.55, ax.Position(2)+ax.Position(4)*0.75, 0.4, 0.2], ...
            'String', txt, 'FontSize', 8, 'BackgroundColor', [0.95 0.95 0.95], ...
            'EdgeColor', 'none', 'FitBoxToText', 'on', 'Color', 'k');
        
        xlim(xLimits{iType});
        xlabel('Частота, Гц');
        ylabel(yLabels{iType});
        title(sprintf('%s — Канал %d', plotTitles{iType}, iChan), 'Color', 'k', 'FontWeight', 'bold');
        legend('Location', 'northeast');
        set(legend, 'Color', 'w', 'TextColor', 'k');
        hold off;
    end
end

%  ЛОКАЛЬНЫЕ ФУНКЦИИ 
function data = loadAndProcess(filename)
% Чтение LVM и возврат структуры с .y1, .y2, .t, .fs, а также .t_seg, .y1_seg, .y2_seg
% Используется алгоритм выбора стационарного участка из True.m
    fileID = fopen(filename, 'r');
    if fileID == -1
        error('Не удалось открыть файл: %s', filename);
    end
    fileContent = fread(fileID, '*char')';
    fclose(fileID);
    fileContent = strrep(fileContent, ',', '.');
    dataCell = textscan(fileContent, '%f %f %f %f', 'Delimiter', '\t', 'CollectOutput', true);
    dataMatrix = dataCell{1};
    if size(dataMatrix,2) < 4
        error('Файл должен содержать минимум 4 столбца: время, канал1, канал2, канал3');
    end
    
    t = dataMatrix(:,1);
    t = t - t(1);
    dt = median(diff(t));
    fs = 1 / dt;
    fprintf('  Частота дискретизации fs = %.2f Гц, длительность = %.2f с\n', fs, t(end));
    
    raw1 = dataMatrix(:,2);
    raw2 = dataMatrix(:,3);
    % raw3 = dataMatrix(:,4); - не используем
    
    % Детренд
    y1_raw = detrend(detrend(raw1,0),1);
    y2_raw = detrend(detrend(raw2,0),1);
    
    % Выбор стационарного участка
    target_duration = 2.0;
    target_len = min(round(target_duration * fs), length(y1_raw));
    if length(y1_raw) > target_len
        rms_win = max(round(0.1 * fs), 10);
        rms1 = sqrt(movmean(y1_raw.^2, rms_win));
        rms2 = sqrt(movmean(y2_raw.^2, rms_win));
        rms_mean = (rms1 + rms2) / 2;   % усредняем по двум каналам
        rms_threshold = 0.2 * max(rms_mean);
        min_std = inf;
        best_start_idx = 1;
        step = max(round(0.05 * fs), 1);
        for i = 1:step:(length(y1_raw)-target_len+1)
            seg = rms_mean(i:i+target_len-1);
            if mean(seg) > rms_threshold
                seg_std = std(seg);
                if seg_std < min_std
                    min_std = seg_std;
                    best_start_idx = i;
                end
            end
        end
        best_end_idx = best_start_idx + target_len - 1;
        y1 = y1_raw(best_start_idx:best_end_idx);
        y2 = y2_raw(best_start_idx:best_end_idx);
        t_seg = t(best_start_idx:best_end_idx);
        t_seg = t_seg - t_seg(1);
        fprintf('  Выбран стационарный участок: %.3f ... %.3f с\n', t(best_start_idx), t(best_end_idx));
    else
        y1 = y1_raw;
        y2 = y2_raw;
        t_seg = t;
    end
    
    data.y1 = y1;
    data.y2 = y2;
    data.t = t_seg;
    data.fs = fs;
end

function [spec, f_hz] = computeSpectra(data, fs, target_duration, channels)
% Вычисляет спектры ускорения, виброскорости и огибающей для заданных каналов
% channels - вектор из 1 и/или 2
    y_all = [data.y1, data.y2];
    t_seg = data.t;
    N = length(t_seg);
    if N < round(target_duration * fs)
        warning('Длина сигнала меньше %g с, используем весь сигнал', target_duration);
    end
    
    w = hann(N);
    cg = mean(w);
    halfN = floor(N/2) + 1;
    f_hz = (0:halfN-1)' * fs / N;
    
    nCh = length(channels);
    spec.acc = zeros(halfN, nCh);
    spec.vel = zeros(halfN, nCh);
    spec.env = zeros(halfN, nCh);
    
    %  Фильтры для виброскорости 
    fc_hp = 5;
    [b_hp, a_hp] = butter(4, fc_hp/(fs/2), 'high');
    f_low_vel = 10;
    f_high_vel = min(1000, 0.95*(fs/2));
    if f_high_vel <= f_low_vel
        error('Слишком низкая fs для полосы 10-1000 Гц');
    end
    [b_bp_vel, a_bp_vel] = butter(4, [f_low_vel f_high_vel]/(fs/2), 'bandpass');
    
    %  Полоса для огибающей 
    f_low_env = 2000;
    f_high_env = min(8000, 0.8*(fs/2));
    if f_low_env >= f_high_env
        error('Неверные границы для огибающей. Проверьте fs.');
    end
    
    for idx = 1:nCh
        ch = channels(idx);
        y = y_all(:, ch);
        % Детренд (уже сделан, но на всякий случай)
        y = detrend(y, 'constant');
        y = detrend(y, 'linear');
        
        %  Прямой спектр ускорения 
        Y = fft(y .* w);
        amp_acc = abs(Y(1:halfN)) * 2 / (N * cg);
        amp_acc(1) = amp_acc(1)/2;
        spec.acc(:, idx) = amp_acc;
        
        %  Виброскорость 
        acc_hp = filtfilt(b_hp, a_hp, y);
        vel_ms = cumtrapz(t_seg, acc_hp);
        vel_ms = detrend(vel_ms, 'constant');
        vel_ms = detrend(vel_ms, 'linear');
        vel_gost_ms = filtfilt(b_bp_vel, a_bp_vel, vel_ms);
        vel_gost_mms = vel_gost_ms * 1000;  % м/с -> мм/с
        V = fft(vel_gost_mms .* w);
        amp_vel = abs(V(1:halfN)) * 2 / (N * cg);
        amp_vel(1) = amp_vel(1)/2;
        spec.vel(:, idx) = amp_vel;
        
        %  Огибающая 
        y_env = abs(hilbert(bandpass(y, [f_low_env f_high_env], fs)));
        y_env = detrend(y_env, 'constant');
        Yenv = fft(y_env .* w);
        amp_env = abs(Yenv(1:halfN)) * 2 / (N * cg);
        amp_env(1) = amp_env(1)/2;
        amp_env(f_hz < 1) = 0;
        spec.env(:, idx) = amp_env;
    end
end

function [k_FTF, k_BPFO, k_BPFI, k_BSF] = bearing_coeffs(n, d, D, phi_deg)
    phi = deg2rad(phi_deg);
    ratio = (d / D) * cos(phi);
    k_FTF  = 0.5 * (1 - ratio);
    k_BPFO = 0.5 * n * (1 - ratio);
    k_BPFI = 0.5 * n * (1 + ratio);
    k_BSF  = (D / (2*d)) * (1 - ratio^2);
end
%% 6. СВОДНЫЕ ТАБЛИЦЫ И АВТОМАТИЧЕСКАЯ ИНТЕРПРЕТАЦИЯ (как в True.m)
peak_band = 2.0;  % полоса поиска пика ±2 Гц
get_peak = @(freq, fvec, avec, bw) max([0; avec(abs(fvec - freq) <= bw)]);

% --- для эксперимента 4500 ---
f_rot = f_rot4500;
ch1_acc = spec4500.acc(:,1);
ch2_acc = spec4500.acc(:,2);
ch1_vel = spec4500.vel(:,1);
ch2_vel = spec4500.vel(:,2);
ch1_env = spec4500.env(:,1);
ch2_env = spec4500.env(:,2);

% Оборотные гармоники (по спектру ускорения)
ch1_05X = get_peak(0.5*f_rot, f_hz, ch1_acc, peak_band);
ch2_05X = get_peak(0.5*f_rot, f_hz, ch2_acc, peak_band);
ch1_1X  = get_peak(1.0*f_rot, f_hz, ch1_acc, peak_band);
ch2_1X  = get_peak(1.0*f_rot, f_hz, ch2_acc, peak_band);
ch1_2X  = get_peak(2.0*f_rot, f_hz, ch1_acc, peak_band);
ch2_2X  = get_peak(2.0*f_rot, f_hz, ch2_acc, peak_band);
ch1_3X  = get_peak(3.0*f_rot, f_hz, ch1_acc, peak_band);
ch2_3X  = get_peak(3.0*f_rot, f_hz, ch2_acc, peak_band);

% Подшипниковые частоты (по спектру огибающей)
ch1_BPFO = get_peak(f_BPFO4500, f_hz, ch1_env, peak_band);
ch2_BPFO = get_peak(f_BPFO4500, f_hz, ch2_env, peak_band);
ch1_BPFI = get_peak(f_BPFI4500, f_hz, ch1_env, peak_band);
ch2_BPFI = get_peak(f_BPFI4500, f_hz, ch2_env, peak_band);
ch1_BSF  = get_peak(f_BSF4500,  f_hz, ch1_env, peak_band);
ch2_BSF  = get_peak(f_BSF4500,  f_hz, ch2_env, peak_band);
ch1_FTF  = get_peak(f_FTF4500,  f_hz, ch1_env, peak_band);
ch2_FTF  = get_peak(f_FTF4500,  f_hz, ch2_env, peak_band);

Metric = {'0.5X';'1X';'2X';'3X';'BPFO';'BPFI';'BSF';'FTF'};
Freq_Hz = [0.5*f_rot; f_rot; 2*f_rot; 3*f_rot; f_BPFO4500; f_BPFI4500; f_BSF4500; f_FTF4500];
Channel_1 = [ch1_05X; ch1_1X; ch1_2X; ch1_3X; ch1_BPFO; ch1_BPFI; ch1_BSF; ch1_FTF];
Channel_2 = [ch2_05X; ch2_1X; ch2_2X; ch2_3X; ch2_BPFO; ch2_BPFI; ch2_BSF; ch2_FTF];

[MaxAmp, idxMax] = max([Channel_1, Channel_2], [], 2);
BestChannel = strings(length(idxMax),1);
for i = 1:length(idxMax)
    BestChannel(i) = sprintf('Канал %d', idxMax(i));
end

summaryTable4500 = table(Metric, Freq_Hz, Channel_1, Channel_2, MaxAmp, BestChannel);
fprintf('\n=============== СВОДНАЯ ТАБЛИЦА ДЛЯ 4500 об/мин ===============\n');
disp(summaryTable4500);
writetable(summaryTable4500, 'summary_4500.csv');

% --- Автоинтерпретация для 4500 ---
rotorMetrics = ismember(Metric, {'0.5X','1X','2X','3X'});
bearingMetrics = ismember(Metric, {'BPFO','BPFI','BSF','FTF'});
rotorEnergy = [sum(Channel_1(rotorMetrics)), sum(Channel_2(rotorMetrics))];
bearingEnergy = [sum(Channel_1(bearingMetrics)), sum(Channel_2(bearingMetrics))];
[~, bestRotorIdx] = max(rotorEnergy);
[~, bestBearingIdx] = max(bearingEnergy);

bearingRows = find(bearingMetrics);
[~, domIdxLocal] = max(MaxAmp(bearingRows));
domIdx = bearingRows(domIdxLocal);
dominantBearingMetric = Metric{domIdx};
dominantBearingChannel = BestChannel(domIdx);
dominantBearingAmp = MaxAmp(domIdx);

fprintf('\n=============== АВТОМАТИЧЕСКАЯ ИНТЕРПРЕТАЦИЯ (4500 об/мин) ===============\n');
fprintf('Лучший канал для контроля оборотных/валовых составляющих: Канал %d\n', bestRotorIdx);
fprintf('Лучший канал для контроля подшипниковых дефектов: Канал %d\n', bestBearingIdx);
switch dominantBearingMetric
    case 'BPFO', bc = 'дефект наружного кольца';
    case 'BPFI', bc = 'дефект внутреннего кольца';
    case 'BSF',  bc = 'дефект тел качения';
    case 'FTF',  bc = 'дефект сепаратора';
    otherwise,   bc = 'не определён';
end
fprintf('Наиболее выражен признак: %s\n', bc);
fprintf('Доминирующая подшипниковая частота: %s, канал %s, амплитуда = %.4f\n', ...
    dominantBearingMetric, dominantBearingChannel, dominantBearingAmp);

% --- для эксперимента 3000 (аналогично) ---
f_rot = f_rot3000;
ch1_acc = spec3000.acc(:,1);
ch2_acc = spec3000.acc(:,2);
ch1_vel = spec3000.vel(:,1);
ch2_vel = spec3000.vel(:,2);
ch1_env = spec3000.env(:,1);
ch2_env = spec3000.env(:,2);

ch1_05X = get_peak(0.5*f_rot, f_hz, ch1_acc, peak_band);
ch2_05X = get_peak(0.5*f_rot, f_hz, ch2_acc, peak_band);
ch1_1X  = get_peak(1.0*f_rot, f_hz, ch1_acc, peak_band);
ch2_1X  = get_peak(1.0*f_rot, f_hz, ch2_acc, peak_band);
ch1_2X  = get_peak(2.0*f_rot, f_hz, ch1_acc, peak_band);
ch2_2X  = get_peak(2.0*f_rot, f_hz, ch2_acc, peak_band);
ch1_3X  = get_peak(3.0*f_rot, f_hz, ch1_acc, peak_band);
ch2_3X  = get_peak(3.0*f_rot, f_hz, ch2_acc, peak_band);

ch1_BPFO = get_peak(f_BPFO3000, f_hz, ch1_env, peak_band);
ch2_BPFO = get_peak(f_BPFO3000, f_hz, ch2_env, peak_band);
ch1_BPFI = get_peak(f_BPFI3000, f_hz, ch1_env, peak_band);
ch2_BPFI = get_peak(f_BPFI3000, f_hz, ch2_env, peak_band);
ch1_BSF  = get_peak(f_BSF3000,  f_hz, ch1_env, peak_band);
ch2_BSF  = get_peak(f_BSF3000,  f_hz, ch2_env, peak_band);
ch1_FTF  = get_peak(f_FTF3000,  f_hz, ch1_env, peak_band);
ch2_FTF  = get_peak(f_FTF3000,  f_hz, ch2_env, peak_band);

Freq_Hz = [0.5*f_rot; f_rot; 2*f_rot; 3*f_rot; f_BPFO3000; f_BPFI3000; f_BSF3000; f_FTF3000];
Channel_1 = [ch1_05X; ch1_1X; ch1_2X; ch1_3X; ch1_BPFO; ch1_BPFI; ch1_BSF; ch1_FTF];
Channel_2 = [ch2_05X; ch2_1X; ch2_2X; ch2_3X; ch2_BPFO; ch2_BPFI; ch2_BSF; ch2_FTF];
[MaxAmp, idxMax] = max([Channel_1, Channel_2], [], 2);
BestChannel = strings(length(idxMax),1);
for i = 1:length(idxMax), BestChannel(i) = sprintf('Канал %d', idxMax(i)); end
summaryTable3000 = table(Metric, Freq_Hz, Channel_1, Channel_2, MaxAmp, BestChannel);
fprintf('\n=============== СВОДНАЯ ТАБЛИЦА ДЛЯ 3000 об/мин ===============\n');
disp(summaryTable3000);
writetable(summaryTable3000, 'summary_3000.csv');

rotorEnergy = [sum(Channel_1(rotorMetrics)), sum(Channel_2(rotorMetrics))];
bearingEnergy = [sum(Channel_1(bearingMetrics)), sum(Channel_2(bearingMetrics))];
[~, bestRotorIdx] = max(rotorEnergy);
[~, bestBearingIdx] = max(bearingEnergy);
bearingRows = find(bearingMetrics);
[~, domIdxLocal] = max(MaxAmp(bearingRows));
domIdx = bearingRows(domIdxLocal);
dominantBearingMetric = Metric{domIdx};
dominantBearingChannel = BestChannel(domIdx);
dominantBearingAmp = MaxAmp(domIdx);

fprintf('\n=============== АВТОМАТИЧЕСКАЯ ИНТЕРПРЕТАЦИЯ (3000 об/мин) ===============\n');
fprintf('Лучший канал для контроля оборотных/валовых составляющих: Канал %d\n', bestRotorIdx);
fprintf('Лучший канал для контроля подшипниковых дефектов: Канал %d\n', bestBearingIdx);
switch dominantBearingMetric
    case 'BPFO', bc = 'дефект наружного кольца';
    case 'BPFI', bc = 'дефект внутреннего кольца';
    case 'BSF',  bc = 'дефект тел качения';
    case 'FTF',  bc = 'дефект сепаратора';
    otherwise,   bc = 'не определён';
end
fprintf('Наиболее выражен признак: %s\n', bc);
fprintf('Доминирующая подшипниковая частота: %s, канал %s, амплитуда = %.4f\n', ...
    dominantBearingMetric, dominantBearingChannel, dominantBearingAmp);

fprintf('\nТаблицы сохранены в summary_4500.csv и summary_3000.csv\n');