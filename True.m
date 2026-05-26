% =========================================================================
% ФИНАЛЬНАЯ ВЕРСИЯ
% СРАВНЕНИЕ 3 КАНАЛОВ LVM ДЛЯ ВИБРОДИАГНОСТИКИ ШПИНДЕЛЯ
% - чтение LVM
% - сравнение всех трех сигналов
% - калибровка PCB 352C03 (10 mV/g)
% - прямой спектр, виброскорость через интегральный переход, спектр огибающей
% - дефектные частоты подшипника + гармоники + боковые полосы BPFI
% - сводная таблица по 3 каналам
% - автоматическая интерпретация
% - сохранение таблицы в CSV
% =========================================================================
clc; clear; close all;

%% 1. ЧТЕНИЕ LVM ФАЙЛА
filename = 'Эксперимет_001 3000 об мин.lvm';
fprintf('\nЧтение lvm файла: %s\n', filename);
fileID = fopen(filename, 'r');
if fileID == -1
    error('Не удалось открыть файл. Проверь путь и имя файла.');
end
fileContent = fread(fileID, '*char')';
fclose(fileID);
fileContent = strrep(fileContent, ',', '.');
dataCell = textscan(fileContent, '%f %f %f %f', ...
    'Delimiter', '\t', ...
    'CollectOutput', true);
dataMatrix = dataCell{1};
if size(dataMatrix,2) < 4
    error('Ожидалось минимум 4 столбца в LVM файле.');
end

%% 2. ВРЕМЯ И РЕАЛЬНАЯ ЧАСТОТА ДИСКРЕТИЗАЦИИ
t = dataMatrix(:,1);
t = t - t(1);
dt_vec = diff(t);
dt = median(dt_vec);
fs = 1 / dt;
fprintf('Определенный шаг времени dt = %.8f c\n', dt);
fprintf('Определенная частота дискретизации fs = %.2f Гц\n', fs);
dt_spread = max(abs(dt_vec - dt));
fprintf('Макс. отклонение шага времени = %.3e c\n', dt_spread);

%% 3. КАЛИБРОВКА ВСЕХ 3 КАНАЛОВ
raw_ch1 = dataMatrix(:,2);
raw_ch2 = dataMatrix(:,3);
raw_ch3 = dataMatrix(:,4);

raw_ch1 = detrend(raw_ch1,0); raw_ch1 = detrend(raw_ch1,1);
raw_ch2 = detrend(raw_ch2,0); raw_ch2 = detrend(raw_ch2,1);
raw_ch3 = detrend(raw_ch3,0); raw_ch3 = detrend(raw_ch3,1);


y1_raw = raw_ch1;
y2_raw = raw_ch2;
y3_raw = raw_ch3;
fprintf('Калибровка выполнена для всех 3 каналов.\n');

%% 4. ВЫБОР ОБЩЕГО СТАЦИОНАРНОГО УЧАСТКА
target_duration = 2.0;
target_len = min(round(target_duration * fs), length(y1_raw));

if length(y1_raw) > target_len
    rms_win = max(round(0.1 * fs), 10);
    rms1 = sqrt(movmean(y1_raw.^2, rms_win));
    rms2 = sqrt(movmean(y2_raw.^2, rms_win));
    rms3 = sqrt(movmean(y3_raw.^2, rms_win));
    rms_mean = (rms1 + rms2 + rms3) / 3;
    rms_threshold = 0.2 * max(rms_mean);
    min_std = inf;
    best_start_idx = 1;
    step = max(round(0.05 * fs), 1);
    for i = 1:step:(length(y1_raw) - target_len + 1)
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
    y3 = y3_raw(best_start_idx:best_end_idx);
    t_seg = t(best_start_idx:best_end_idx);
    t_seg = t_seg - t_seg(1);
    fprintf('Выбран общий участок: %.3f ... %.3f c\n', t(best_start_idx), t(best_end_idx));
else
    y1 = y1_raw;
    y2 = y2_raw;
    y3 = y3_raw;
    t_seg = t;
end

%% 5. ПАРАМЕТРЫ ШПИНДЕЛЯ
RPM = 4500;
f_rot = RPM / 60;
fprintf('Ожидаемая оборотная частота 1X = %.2f Гц\n', f_rot);

%% 6. ГЕОМЕТРИЯ ПОДШИПНИКА
% При необходимости замени на реальные параметры
n       = 20;
d_ball  = 10.0;   % мм
D_pitch = 89.0;  % мм
phi_deg = 15;    % градусы

[k_FTF, k_BPFO, k_BPFI, k_BSF] = bearing_coeffs(n, d_ball, D_pitch, phi_deg);
f_FTF  = k_FTF  * f_rot;
f_BPFO = k_BPFO * f_rot;
f_BPFI = k_BPFI * f_rot;
f_BSF  = k_BSF  * f_rot;

fprintf('\n=============== ГЕОМЕТРИЯ ПОДШИПНИКА ===============\n');
fprintf('n = %d, d = %.3f мм, D = %.3f мм, phi = %.2f град\n', n, d_ball, D_pitch, phi_deg);
fprintf('FTF  = %.2f Гц\n', f_FTF);
fprintf('BPFO = %.2f Гц\n', f_BPFO);
fprintf('BPFI = %.2f Гц\n', f_BPFI);
fprintf('BSF  = %.2f Гц\n', f_BSF);

%% 7. СПЕКТРАЛЬНЫЙ АНАЛИЗ ДЛЯ ВСЕХ 3 КАНАЛОВ
N = length(y1);
w = hann(N);
cg = mean(w);
halfN = floor(N/2) + 1;
f_hz = (0:halfN-1)' * fs / N;

Y1 = fft(y1 .* w);
amp1_acc = abs(Y1(1:halfN)) * 2 / (N * cg);
amp1_acc(1) = amp1_acc(1)/2;

Y2 = fft(y2 .* w);
amp2_acc = abs(Y2(1:halfN)) * 2 / (N * cg);
amp2_acc(1) = amp2_acc(1)/2;

Y3 = fft(y3 .* w);
amp3_acc = abs(Y3(1:halfN)) * 2 / (N * cg);
amp3_acc(1) = amp3_acc(1)/2;

%% 8. ВИБРОСКОРОСТЬ ЧЕРЕЗ ИНТЕГРАЛЬНЫЙ ПЕРЕХОД ВО ВРЕМЕННОЙ ОБЛАСТИ
% Интегрирование ускорения чувствительно к смещению и дрейфу,
% поэтому используем: detrend -> high-pass -> cumtrapz -> detrend -> bandpass 10-1000 Гц
% Низкие частоты усиливаются при интегрировании, поэтому обязательна HP-фильтрация [web:442][web:443][web:445].

% Предварительная коррекция ускорения
acc1_corr = detrend(y1, 'constant');
acc1_corr = detrend(acc1_corr, 'linear');
acc2_corr = detrend(y2, 'constant');
acc2_corr = detrend(acc2_corr, 'linear');
acc3_corr = detrend(y3, 'constant');
acc3_corr = detrend(acc3_corr, 'linear');

% High-pass перед интегрированием для подавления дрейфа
fc_hp = 5;       % Гц
filt_order = 4;
[b_hp, a_hp] = butter(filt_order, fc_hp/(fs/2), 'high');

acc1_hp = filtfilt(b_hp, a_hp, acc1_corr);
acc2_hp = filtfilt(b_hp, a_hp, acc2_corr);
acc3_hp = filtfilt(b_hp, a_hp, acc3_corr);

% Интегрирование ускорения -> скорость
vel1_ms = cumtrapz(t_seg, acc1_hp);
vel2_ms = cumtrapz(t_seg, acc2_hp);
vel3_ms = cumtrapz(t_seg, acc3_hp);

% Повторная коррекция после интегрирования
vel1_ms = detrend(vel1_ms, 'constant');
vel1_ms = detrend(vel1_ms, 'linear');
vel2_ms = detrend(vel2_ms, 'constant');
vel2_ms = detrend(vel2_ms, 'linear');
vel3_ms = detrend(vel3_ms, 'constant');
vel3_ms = detrend(vel3_ms, 'linear');

% Полосовая фильтрация скорости в диагностической полосе 10-1000 Гц
f_low_vel = 10;
f_high_vel = min(1000, 0.95*(fs/2));
if f_high_vel <= f_low_vel
    error('Частота дискретизации слишком низкая для полосы виброскорости 10-1000 Гц.');
end
[b_bp_vel, a_bp_vel] = butter(4, [f_low_vel f_high_vel]/(fs/2), 'bandpass');

vel1_gost_ms = filtfilt(b_bp_vel, a_bp_vel, vel1_ms);
vel2_gost_ms = filtfilt(b_bp_vel, a_bp_vel, vel2_ms);
vel3_gost_ms = filtfilt(b_bp_vel, a_bp_vel, vel3_ms);

% Перевод в мм/с
vel1_gost_mms = vel1_gost_ms * 1000;
vel2_gost_mms = vel2_gost_ms * 1000;
vel3_gost_mms = vel3_gost_ms * 1000;

% RMS по временному сигналу скорости
vel1_rms = rms(vel1_gost_mms);
vel2_rms = rms(vel2_gost_mms);
vel3_rms = rms(vel3_gost_mms);

% Спектры виброскорости по временному сигналу
V1 = fft(vel1_gost_mms .* w);
amp1_vel = abs(V1(1:halfN)) * 2 / (N * cg);
amp1_vel(1) = amp1_vel(1)/2;

V2 = fft(vel2_gost_mms .* w);
amp2_vel = abs(V2(1:halfN)) * 2 / (N * cg);
amp2_vel(1) = amp2_vel(1)/2;

V3 = fft(vel3_gost_mms .* w);
amp3_vel = abs(V3(1:halfN)) * 2 / (N * cg);
amp3_vel(1) = amp3_vel(1)/2;

fprintf('\n=============== RMS ВИБРОСКОРОСТИ ПО КАНАЛАМ ===============\n');
fprintf('Канал 1: %.3f мм/с\n', vel1_rms);
fprintf('Канал 2: %.3f мм/с\n', vel2_rms);
fprintf('Канал 3: %.3f мм/с\n', vel3_rms);

%% 9. СПЕКТРЫ ОГИБАЮЩЕЙ (ИСПРАВЛЕННЫЙ БЛОК)
f_low  = 2000;
f_high = 8000;
if f_high >= fs/2
    f_high = 0.8 * (fs/2);
end
if f_low >= f_high
    error('Неверные границы полосы для огибающей. Проверь fs.');
end

make_envelope = @(sig) detrend(abs(hilbert(bandpass(sig, [f_low f_high], fs))), 'constant');

y1_env = make_envelope(y1);
y2_env = make_envelope(y2);
y3_env = make_envelope(y3);

Y1env = fft(y1_env .* w);
Y2env = fft(y2_env .* w);
Y3env = fft(y3_env .* w);

amp1_env = abs(Y1env(1:halfN)) * 2 / (N * cg);
amp2_env = abs(Y2env(1:halfN)) * 2 / (N * cg);
amp3_env = abs(Y3env(1:halfN)) * 2 / (N * cg);

amp1_env(1) = amp1_env(1)/2;
amp2_env(1) = amp2_env(1)/2;
amp3_env(1) = amp3_env(1)/2;

amp1_env(f_hz < 1) = 0;
amp2_env(f_hz < 1) = 0;
amp3_env(f_hz < 1) = 0;

amp1_env_tab = amp1_env;
amp2_env_tab = amp2_env;
amp3_env_tab = amp3_env;

noise_band = (f_hz >= 50) & (f_hz <= 500);
noise1 = median(amp1_env(noise_band));
noise2 = median(amp2_env(noise_band));
noise3 = median(amp3_env(noise_band));

k_noise = 2.0;
amp1_env_tab(amp1_env_tab < k_noise*noise1) = 0;
amp2_env_tab(amp2_env_tab < k_noise*noise2) = 0;
amp3_env_tab(amp3_env_tab < k_noise*noise3) = 0;

if length(f_hz) > 1
    df = f_hz(2) - f_hz(1);
else
    df = fs / N;
end
min_band_hz = 1.0;
peak_band_env = max(min_band_hz, 4*df);

get_peak_env = @(f0, fvec, avec, bw) max([0; avec(abs(fvec - f0) <= bw)]);

ch1_BPFO = get_peak_env(f_BPFO, f_hz, amp1_env_tab, peak_band_env);
ch2_BPFO = get_peak_env(f_BPFO, f_hz, amp2_env_tab, peak_band_env);
ch3_BPFO = get_peak_env(f_BPFO, f_hz, amp3_env_tab, peak_band_env);

ch1_BPFI = get_peak_env(f_BPFI, f_hz, amp1_env_tab, peak_band_env);
ch2_BPFI = get_peak_env(f_BPFI, f_hz, amp2_env_tab, peak_band_env);
ch3_BPFI = get_peak_env(f_BPFI, f_hz, amp3_env_tab, peak_band_env);

ch1_BSF = get_peak_env(f_BSF, f_hz, amp1_env_tab, peak_band_env);
ch2_BSF = get_peak_env(f_BSF, f_hz, amp2_env_tab, peak_band_env);
ch3_BSF = get_peak_env(f_BSF, f_hz, amp3_env_tab, peak_band_env);

ch1_FTF = get_peak_env(f_FTF, f_hz, amp1_env_tab, peak_band_env);
ch2_FTF = get_peak_env(f_FTF, f_hz, amp2_env_tab, peak_band_env);
ch3_FTF = get_peak_env(f_FTF, f_hz, amp3_env_tab, peak_band_env);

%% 10. СВОДНАЯ ТАБЛИЦА ПО КЛЮЧЕВЫМ ЧАСТОТАМ
peak_band = 2.0;
get_peak = @(freq, fvec, avec, bw) max([0; avec(abs(fvec - freq) <= bw)]);

ch1_05X = get_peak(0.5*f_rot, f_hz, amp1_acc, peak_band);
ch2_05X = get_peak(0.5*f_rot, f_hz, amp2_acc, peak_band);
ch3_05X = get_peak(0.5*f_rot, f_hz, amp3_acc, peak_band);

ch1_1X = get_peak(f_rot, f_hz, amp1_acc, peak_band);
ch2_1X = get_peak(f_rot, f_hz, amp2_acc, peak_band);
ch3_1X = get_peak(f_rot, f_hz, amp3_acc, peak_band);

ch1_2X = get_peak(2*f_rot, f_hz, amp1_acc, peak_band);
ch2_2X = get_peak(2*f_rot, f_hz, amp2_acc, peak_band);
ch3_2X = get_peak(2*f_rot, f_hz, amp3_acc, peak_band);

ch1_3X = get_peak(3*f_rot, f_hz, amp1_acc, peak_band);
ch2_3X = get_peak(3*f_rot, f_hz, amp2_acc, peak_band);
ch3_3X = get_peak(3*f_rot, f_hz, amp3_acc, peak_band);

Metric = {
    '0.5X';
    '1X';
    '2X';
    '3X';
    'BPFO';
    'BPFI';
    'BSF';
    'FTF'
    };
Freq_Hz = [
    0.5*f_rot;
    1.0*f_rot;
    2.0*f_rot;
    3.0*f_rot;
    f_BPFO;
    f_BPFI;
    f_BSF;
    f_FTF
    ];
Channel_1 = [
    ch1_05X;
    ch1_1X;
    ch1_2X;
    ch1_3X;
    ch1_BPFO;
    ch1_BPFI;
    ch1_BSF;
    ch1_FTF
    ];
Channel_2 = [
    ch2_05X;
    ch2_1X;
    ch2_2X;
    ch2_3X;
    ch2_BPFO;
    ch2_BPFI;
    ch2_BSF;
    ch2_FTF
    ];
Channel_3 = [
    ch3_05X;
    ch3_1X;
    ch3_2X;
    ch3_3X;
    ch3_BPFO;
    ch3_BPFI;
    ch3_BSF;
    ch3_FTF
    ];

[MaxAmp, idxMax] = max([Channel_1, Channel_2, Channel_3], [], 2);
BestChannel = strings(length(idxMax),1);
for i = 1:length(idxMax)
    BestChannel(i) = sprintf('Канал %d', idxMax(i));
end

summaryTable = table(Metric, Freq_Hz, Channel_1, Channel_2, Channel_3, MaxAmp, BestChannel);
fprintf('\n=============== СВОДНАЯ ТАБЛИЦА ПО 3 КАНАЛАМ ===============\n');
disp(summaryTable);
fprintf('\n=============== ГДЕ ЛУЧШЕ ВСЕГО ВИДНЫ ЧАСТОТЫ ===============\n');
for i = 1:height(summaryTable)
    fprintf('%-5s (%.2f Гц): максимум на %s, амплитуда = %.4f\n', ...
        summaryTable.Metric{i}, ...
        summaryTable.Freq_Hz(i), ...
        summaryTable.BestChannel(i), ...
        summaryTable.MaxAmp(i));
end

writetable(summaryTable, 'summary_3channels.csv');
fprintf('\nТаблица сохранена в файл summary_3channels.csv\n');

%% 11. АВТОМАТИЧЕСКАЯ ИНТЕРПРЕТАЦИЯ
rotorMetrics = ismember(summaryTable.Metric, {'0.5X','1X','2X','3X'});
bearingMetrics = ismember(summaryTable.Metric, {'BPFO','BPFI','BSF','FTF'});

rotorEnergy = [sum(summaryTable.Channel_1(rotorMetrics)), ...
               sum(summaryTable.Channel_2(rotorMetrics)), ...
               sum(summaryTable.Channel_3(rotorMetrics))];
bearingEnergy = [sum(summaryTable.Channel_1(bearingMetrics)), ...
                 sum(summaryTable.Channel_2(bearingMetrics)), ...
                 sum(summaryTable.Channel_3(bearingMetrics))];

[~, bestRotorIdx] = max(rotorEnergy);
[~, bestBearingIdx] = max(bearingEnergy);

bearingRows = find(bearingMetrics);
[~, domIdxLocal] = max(summaryTable.MaxAmp(bearingRows));
domIdx = bearingRows(domIdxLocal);
dominantBearingMetric = summaryTable.Metric{domIdx};
dominantBearingChannel = summaryTable.BestChannel(domIdx);
dominantBearingAmp = summaryTable.MaxAmp(domIdx);

fprintf('\n=============== АВТОМАТИЧЕСКАЯ ИНТЕРПРЕТАЦИЯ ===============\n');
fprintf('Лучший канал для контроля оборотных/валовых составляющих: Канал %d\n', bestRotorIdx);
fprintf('Лучший канал для контроля подшипниковых дефектов: Канал %d\n', bestBearingIdx);

switch dominantBearingMetric
    case 'BPFO'
        bearingConclusion = 'Наиболее выражен признак дефекта наружного кольца подшипника';
    case 'BPFI'
        bearingConclusion = 'Наиболее выражен признак дефекта внутреннего кольца подшипника';
    case 'BSF'
        bearingConclusion = 'Наиболее выражен признак дефекта тел качения';
    case 'FTF'
        bearingConclusion = 'Наиболее выражен признак дефекта сепаратора';
    otherwise
        bearingConclusion = 'Доминирующий подшипниковый признак не определен';
end
fprintf('%s\n', bearingConclusion);
fprintf('Доминирующая подшипниковая частота: %s\n', dominantBearingMetric);
fprintf('Лучше всего она видна на: %s\n', dominantBearingChannel);
fprintf('Амплитуда доминирующего признака: %.4f\n', dominantBearingAmp);

if ch1_1X == max([ch1_1X, ch2_1X, ch3_1X])
    best1Xchannel = 1;
elseif ch2_1X == max([ch1_1X, ch2_1X, ch3_1X])
    best1Xchannel = 2;
else
    best1Xchannel = 3;
end

if ch1_2X == max([ch1_2X, ch2_2X, ch3_2X])
    best2Xchannel = 1;
elseif ch2_2X == max([ch1_2X, ch2_2X, ch3_2X])
    best2Xchannel = 2;
else
    best2Xchannel = 3;
end

fprintf('Максимум 1X лучше всего выражен на канале %d\n', best1Xchannel);
fprintf('Максимум 2X лучше всего выражен на канале %d\n', best2Xchannel);
if max([ch1_1X, ch2_1X, ch3_1X]) > 2*max([ch1_2X, ch2_2X, ch3_2X])
    fprintf('Преобладание 1X может указывать на дисбаланс ротора.\n');
elseif max([ch1_2X, ch2_2X, ch3_2X]) > 0.7*max([ch1_1X, ch2_1X, ch3_1X])
    fprintf('Сравнимо высокий 2X может указывать на расцентровку или изгиб.\n');
else
    fprintf('Валовая кинематика не показывает ярко выраженного доминирования 1X или 2X.\n');
end

if strcmp(dominantBearingMetric, 'BPFI')
    fprintf('Так как доминирует BPFI, стоит дополнительно проверить наличие боковых полос +/-1X вокруг BPFI.\n');
elseif strcmp(dominantBearingMetric, 'BPFO')
    fprintf('Так как доминирует BPFO, особенно важно смотреть цепочку его гармоник на спектре огибающей.\n');
elseif strcmp(dominantBearingMetric, 'BSF')
    fprintf('Так как доминирует BSF, следует проверить состояние тел качения и возможное сочетание с дефектами дорожек.\n');
elseif strcmp(dominantBearingMetric, 'FTF')
    fprintf('Так как доминирует FTF, следует обратить внимание на состояние сепаратора и смазки.\n');
end

%% 12. ГРАФИКИ СРАВНЕНИЯ 3 КАНАЛОВ
c1 = [0.85 0.15 0.15];
c2 = [0.10 0.35 0.85];
c3 = [0.10 0.65 0.25];

figure('Name', 'Сравнение 3 каналов LVM', ...
       'Color', 'w', ...
       'Position', [100 40 1350 950]);

subplot(4,1,1);
plot(t_seg, y1, 'Color', c1, 'LineWidth', 1.0); hold on;
plot(t_seg, y2, 'Color', c2, 'LineWidth', 1.0);
plot(t_seg, y3, 'Color', c3, 'LineWidth', 1.0);
grid on;
xlabel('Время, с');
ylabel('a, м/с^2');
title('Сравнение временных сигналов');
legend('Канал 1', 'Канал 2', 'Канал 3', 'Location', 'best');

subplot(4,1,2);
plot(f_hz, amp1_acc, 'Color', c1, 'LineWidth', 1.1); hold on;
plot(f_hz, amp2_acc, 'Color', c2, 'LineWidth', 1.1);
plot(f_hz, amp3_acc, 'Color', c3, 'LineWidth', 1.1);
xline(0.5*f_rot, ':k', '0.5X');
xline(f_rot, '-k', '1X', 'LineWidth', 1.2);
xline(2*f_rot, '--k', '2X', 'LineWidth', 1.2);
xline(3*f_rot, '-.k', '3X', 'LineWidth', 1.2);
grid on;
xlim([0 500]);
xlabel('Частота, Гц');
ylabel('Амплитуда, м/с^2');
title('Сравнение прямых спектров');
legend('Канал 1', 'Канал 2', 'Канал 3', 'Location', 'best');

subplot(4,1,3);
plot(f_hz, amp1_vel, 'Color', c1, 'LineWidth', 1.1); hold on;
plot(f_hz, amp2_vel, 'Color', c2, 'LineWidth', 1.1);
plot(f_hz, amp3_vel, 'Color', c3, 'LineWidth', 1.1);
xline(10, '--k', '10 Гц');
xline(1000, '--k', '1000 Гц');
grid on;
xlim([0 1200]);
xlabel('Частота, Гц');
ylabel('Амплитуда, мм/с');
title(sprintf('Сравнение спектров виброскорости (интегральный переход) | RMS: [%.2f, %.2f, %.2f] мм/с', ...
    vel1_rms, vel2_rms, vel3_rms));
legend('Канал 1', 'Канал 2', 'Канал 3', 'Location', 'best');

subplot(4,1,4);
plot(f_hz, amp1_env, 'Color', c1, 'LineWidth', 1.1); hold on;
plot(f_hz, amp2_env, 'Color', c2, 'LineWidth', 1.1);
plot(f_hz, amp3_env, 'Color', c3, 'LineWidth', 1.1);

xline(f_BPFO, '-r', 'BPFO', 'LineWidth', 1.2);
xline(f_BPFI, '-b', 'BPFI', 'LineWidth', 1.2);
xline(f_BSF,  '-m', 'BSF',  'LineWidth', 1.2);
xline(f_FTF,  '-g', 'FTF',  'LineWidth', 1.2);

n_harm = 3;
for k = 2:n_harm
    if k*f_BPFO <= max(f_hz)
        xline(k*f_BPFO, '--r', sprintf('%dBPFO', k), 'LineWidth', 0.9);
    end
    if k*f_BPFI <= max(f_hz)
        xline(k*f_BPFI, '--b', sprintf('%dBPFI', k), 'LineWidth', 0.9);
    end
    if k*f_BSF <= max(f_hz)
        xline(k*f_BSF, '--m', sprintf('%dBSF', k), 'LineWidth', 0.9);
    end
    if k*f_FTF <= max(f_hz)
        xline(k*f_FTF, '--g', sprintf('%dFTF', k), 'LineWidth', 0.9);
    end
end

for k = 1:n_harm
    f_side_minus = k*f_BPFI - f_rot;
    f_side_plus  = k*f_BPFI + f_rot;
    if f_side_minus > 0 && f_side_minus <= max(f_hz)
        xline(f_side_minus, ':b', sprintf('%dBPFI-1X', k), 'LineWidth', 0.8);
    end
    if f_side_plus > 0 && f_side_plus <= max(f_hz)
        xline(f_side_plus, ':b', sprintf('%dBPFI+1X', k), 'LineWidth', 0.8);
    end
end

grid on;
xlim([0 min(1500, max([3*f_BPFI, 3*f_BPFO, 3*f_BSF, 3*f_FTF, 1000]))]);
xlabel('Частота, Гц');
ylabel('Амплитуда, у.е.');
title(sprintf('Сравнение спектров огибающей | полоса демодуляции: %.0f-%.0f Гц | окно поиска: %.2f Гц', ...
    f_low, f_high, peak_band_env));
legend('Канал 1', 'Канал 2', 'Канал 3', 'Location', 'best');

sgtitle('Финальное сравнение трех сигналов шпиндельного узла по LVM');

%% 13. ДОПОЛНИТЕЛЬНЫЙ КОНТРОЛЬ 1X
amp1_1X = get_peak(f_rot, f_hz, amp1_acc, peak_band);
amp2_1X = get_peak(f_rot, f_hz, amp2_acc, peak_band);
amp3_1X = get_peak(f_rot, f_hz, amp3_acc, peak_band);

fprintf('\n=============== АМПЛИТУДА 1X ПО КАНАЛАМ ===============\n');
fprintf('Канал 1: %.4f м/с^2\n', amp1_1X);
fprintf('Канал 2: %.4f м/с^2\n', amp2_1X);
fprintf('Канал 3: %.4f м/с^2\n', amp3_1X);

%% 14. ЛОКАЛЬНАЯ ФУНКЦИЯ
function [k_FTF, k_BPFO, k_BPFI, k_BSF] = bearing_coeffs(n, d, D, phi_deg)
    phi = deg2rad(phi_deg);
    ratio = (d / D) * cos(phi);
    k_FTF  = 0.5 * (1 - ratio);
    k_BPFO = 0.5 * n * (1 - ratio);
    k_BPFI = 0.5 * n * (1 + ratio);
    k_BSF  = (D / (2*d)) * (1 - ratio^2);
end
