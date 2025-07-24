% 2つのcsvファイルを取り込んで比較するグラフ
function MakeFigure()
    % 2つのcsvファイルを取り込んで比較するグラフ
    % ファイル名を指定

    clear;
    close all;
    clc;

    file1 = '250725_MOBIL_Gap1\On-ramp_vehicle_1.csv';
    file2 = '250725_MPC_Gap1\On-ramp_vehicle_1.csv';

    % csvファイルを読み込む
    data1 = readtable(file1);
    data2 = readtable(file2);

    % 時間と位置のデータを抽出
    time1 = data1.Time;
    position1 = data1.Position;
    velocity1 = data1.Velocity;
    acceleration1 = data1.Acceleration;
    fuel_consumption1 = data1.Fuel_Consumption;

    time2 = data2.Time;
    position2 = data2.Position;
    velocity2 = data2.Velocity;
    acceleration2 = data2.Acceleration;
    fuel_consumption2 = data2.Fuel_Consumption;
    target_position2 = data2.Target_Position;

    % グラフを作成
    figure(1);
    plot(time2, position2, 'b-', 'DisplayName', 'MPC', 'LineWidth', 2);
    hold on;
    plot(time1, position1, 'r-', 'DisplayName', 'MOBIL', 'LineWidth', 2);
    % グラフの設定
    xlabel('Time (s)');
    ylabel('Position (m)');
    title('Vehicle Position Comparison');
    legend show;
    % グリッドを表示
    grid on;

    figure(2);
    plot(time2, velocity2, 'b-', 'DisplayName', 'MPC', 'LineWidth', 2);
    hold on;
    plot(time1, velocity1, 'r-', 'DisplayName', 'MOBIL', 'LineWidth', 2);
    % グラフの設定
    xlim([5 30]); % x軸の範囲を設定
    xlabel('Time (s)');
    ylabel('Velocity (m/s)');
    title('Vehicle Velocity Comparison');
    legend show;
    ylim([-5 35]); % y軸の範囲を設定
    % グリッドを表示
    grid on;

    figure(3);
    plot(time2, acceleration2, 'b-', 'DisplayName', 'MPC', 'LineWidth', 2);
    hold on;
    plot(time1, acceleration1, 'r-', 'DisplayName', 'MOBIL', 'LineWidth', 2);
    % グラフの設定
    xlabel('Time (s)');
    ylabel('Acceleration (m/s^2)');
    title('Vehicle Acceleration Comparison');
    legend show;
    % グリッドを表示
    grid on;

    figure(4);
    plot(time2, fuel_consumption2, 'b-', 'DisplayName', 'MPC', 'LineWidth', 2);
    hold on;
    plot(time1, fuel_consumption1, 'r-', 'DisplayName', 'MOBIL', 'LineWidth', 2);
    % グラフの設定
    xlabel('Time (s)');
    ylabel('Fuel Consumption (L)');
    title('Vehicle Fuel Consumption Comparison');
    legend show;
    % グリッドを表示
    grid on;

    figure(5);
    plot(position2, velocity2, 'b-', 'DisplayName', 'MPC', 'LineWidth', 2);
    hold on;
    plot(position1, velocity1, 'r-', 'DisplayName', 'MOBIL', 'LineWidth', 2);
    % グラフの設定
    xlabel('Position (m)');
    ylabel('Velocity (m/s)');
    title('Vehicle Position vs Velocity Comparison');
    legend show;
    % グリッドを表示
    grid on;

    figure(6);
    plot(position2, acceleration2, 'b-', 'DisplayName', 'MPC', 'LineWidth', 2);
    hold on;
    plot(position1, acceleration1, 'r-', 'DisplayName', 'MOBIL', 'LineWidth', 2);
    % グラフの設定
    xlabel('Position (m)');
    ylabel('Acceleration (m/s^2)');
    title('Vehicle Position vs Acceleration Comparison');
    legend show;
    % グリッドを表示
    grid on;

    figure(7);
    plot(time2, target_position2 - position2, 'b-', 'DisplayName', 'MPC', 'LineWidth', 2);
    hold on;
    xlim([5 30]); % x軸の範囲を設定
    xlabel('Time (s)');
    ylabel('Target Position - Current Position (m)');
    title('Tracking Error');
    legend show;
    % グリッドを表示
    grid on;
end