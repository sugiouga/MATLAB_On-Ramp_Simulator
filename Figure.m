classdef Figure<handle
    % グラフィッククラス
    properties(GetAccess = public, SetAccess = private)
        % 描画に関する変数
        figure = []; % グラフィック

        % グラフウィンドウの設定
        FIGURE_POSITION = [20, 300]; % グラフィックの左下隅の基準点
        FIGURE_WIDTH = 2000; % グラフィックの幅
        FIGURE_HEIGHT = 252; % グラフィックの高さ

        % 背景の設定
        BACKGROUND_X_RANGE = []; % 背景のx軸の範囲
        BACKGROUND_Y_RANGE = [2.5, 2.5]; % 背景のy軸の範囲
        BACKGROUND_COLOR = [0.65 0.995 0.95]; % 背景の色

        % レーンの設定
        MAINLINE_Y_OFFSET = 1; % 本線のy軸のオフセット
        ONRAMP_Y_OFFSET = 1.2; % 合流車線のy軸のオフセット

        % 動画保存の設定
        video_frame_number = 1; % 動画フレーム番号
        video_total_frame_number = []; % 総フレーム数
        video_frames = []; % 動画フレーム
    end

    methods

        function obj = Figure(simulation)
            % コンストラクタ
            % グラフィックの初期化
            mainline = simulation.mainline; % 本線のレーンオブジェクト
            onramp = simulation.onramp; % 合流車線のレーンオブジェクト

            % グラフィックの背景を作成
            % グラフウィンドウを作成
            obj.figure = figure('Position', [obj.FIGURE_POSITION, obj.FIGURE_WIDTH, obj.FIGURE_HEIGHT]);

            % 背景を描画
            obj.BACKGROUND_X_RANGE = [mainline.start_position, mainline.end_position]; % 背景のx軸の範囲
            area(obj.BACKGROUND_X_RANGE, obj.BACKGROUND_Y_RANGE, 'FaceColor', obj.BACKGROUND_COLOR); % 背景を設定

            hold on;

            % レーンを描画
            % 本線
            plot([mainline.start_position, mainline.end_position], [obj.MAINLINE_Y_OFFSET; obj.MAINLINE_Y_OFFSET],'LineWidth',20,'Color',[0.7 0.7 0.7]); % 本線を描画
            % 合流車線
            plot([onramp.start_position, onramp.end_position], [obj.ONRAMP_Y_OFFSET; obj.ONRAMP_Y_OFFSET],'LineWidth',20,'Color',[0.7 0.7 0.7]); % 合流車線を描画
            % onramp_x_range = onramp.start_position : 50 : onramp.end_position + 50; % 合流車線のx軸の範囲
            % onramp_curve = obj.ONRAMP_Y_OFFSET - (obj.ONRAMP_Y_OFFSET - obj.MAINLINE_Y_OFFSET - 0.2) ./ (1 + exp(-0.02*(onramp_x_range - onramp.end_position / 2))); % 合流車線の曲線
            % plot(onramp_x_range, onramp_curve, 'LineWidth', 10, 'Color', [0.7 0.7 0.7]); % 合流車線を描画

            axis([mainline.start_position, mainline.end_position, obj.MAINLINE_Y_OFFSET - 1, obj.ONRAMP_Y_OFFSET + 1]); % 軸の範囲を設定
            set(gca, 'YTick', []); % Y軸の目盛りを非表示にする
            xlabel('Position (m)', 'FontSize', 14, 'FontWeight', 'bold'); % x軸ラベルを設定
            grid on; % グリッドを表示

            % x = -100 ~ 0 に白線を引く
            plot([mainline.start_position, mainline.end_position], [obj.MAINLINE_Y_OFFSET-0.17, obj.MAINLINE_Y_OFFSET-0.17], 'LineWidth', 2, 'Color', [1 1 1]); % 白線を描画
            plot([onramp.start_position, onramp.end_position], [obj.ONRAMP_Y_OFFSET+0.17, obj.ONRAMP_Y_OFFSET+0.17], 'LineWidth', 2, 'Color', [1 1 1]); % 白線を描画
            plot([mainline.start_position, 0], [(obj.MAINLINE_Y_OFFSET+obj.ONRAMP_Y_OFFSET)/2, (obj.MAINLINE_Y_OFFSET+obj.ONRAMP_Y_OFFSET)/2], 'LineWidth', 2, 'Color', [1 1 1]); % 白線を描画
            plot([onramp.end_position, mainline.end_position], [(obj.MAINLINE_Y_OFFSET+obj.ONRAMP_Y_OFFSET)/2+0.05, (obj.MAINLINE_Y_OFFSET+obj.ONRAMP_Y_OFFSET)/2+0.05], 'LineWidth', 2, 'Color', [1 1 1]); % 白線を描画

            % x = 0 ~ 300 に点線を引く
            plot([0, onramp.end_position], [(obj.MAINLINE_Y_OFFSET+obj.ONRAMP_Y_OFFSET)/2, (obj.MAINLINE_Y_OFFSET+obj.ONRAMP_Y_OFFSET)/2], 'LineWidth', 2, 'Color', [1 1 1], 'LineStyle', '--'); % 点線を描画

            % x = 0 に藍色の線を引く
            plot([0, 0], [obj.MAINLINE_Y_OFFSET - 0.4, obj.ONRAMP_Y_OFFSET + 0.4], 'LineWidth', 2, 'Color', [0.2941 0.0000 0.5098]); % 藍色の線を描画
            % Launch MPC と表示（藍色）
            % text(0, obj.ONRAMP_Y_OFFSET + 0.5, 'Launch MPC', ...
            %     'FontSize', 12, 'FontWeight', 'bold', 'Color', [0.2941 0.0000 0.5098], 'HorizontalAlignment', 'center');
            text(0, obj.ONRAMP_Y_OFFSET + 0.5, 'Launch MOBIL', ...
                'FontSize', 12, 'FontWeight', 'bold', 'Color', [0.2941 0.0000 0.5098], 'HorizontalAlignment', 'center');

            % % x = 100 に藍色の線を引く
            % plot([200, 200], [obj.MAINLINE_Y_OFFSET - 0.4, obj.ONRAMP_Y_OFFSET + 0.4], 'LineWidth', 2, 'Color', [0.2941 0.0000 0.5098]); % 藍色の線を描画
            % % Prediction horizon と表示（藍色）
            % text(200, obj.ONRAMP_Y_OFFSET + 0.5, 'Prediction horizon', ...
            %     'FontSize', 12, 'FontWeight', 'bold', 'Color', [0.2941 0.0000 0.5098], 'HorizontalAlignment', 'center');

            % x = 300 に藍色の線を引く
            plot([300, 300], [obj.MAINLINE_Y_OFFSET - 0.4, obj.ONRAMP_Y_OFFSET + 0.4], 'LineWidth', 2, 'Color', [0.2941 0.0000 0.5098]); % 藍色の線を描画
            % End of Merging lane と表示（藍色）
            text(300, obj.ONRAMP_Y_OFFSET + 0.5, 'End of Merging lane', ...
                'FontSize', 12, 'FontWeight', 'bold', 'Color', [0.2941 0.0000 0.5098], 'HorizontalAlignment', 'center');

            % 本線のタイトル
            text(mainline.start_position + 10, obj.MAINLINE_Y_OFFSET - 0.4, 'Main lane', ...
                'FontSize', 12, 'FontWeight', 'bold', 'Color', [0 0 1]);

            % 合流車線のタイトル
            text(onramp.start_position + 10, obj.ONRAMP_Y_OFFSET + 0.4, 'Merging lane', ...
                'FontSize', 12, 'FontWeight', 'bold', 'Color', [1 0 0]);

            if simulation.is_save_video
                % 動画の保存を開始
                obj.video_total_frame_number = floor((simulation.end_time - simulation.start_time) / simulation.figure_update_interval); % 総フレーム数を計算
                empty_frame = struct('cdata', [], 'colormap', []);
                obj.video_frames = repmat(empty_frame, obj.video_total_frame_number + 1, 1); % 構造体配列で初期化

                drawnow;
                obj.video_frames(1) = getframe(obj.figure); % 初期フレームを保存
            end

        end

        function update_vehicle_figure(obj, simulation)
            % 車両のグラフィックを更新
            vehicle_figure = [];

            mainline = simulation.mainline; % 本線のレーンオブジェクト
            onramp = simulation.onramp; % 合流車線のレーンオブジェクト

            % 本線の車両を描画
            for vehicle = mainline.vehicles.values()'
                x = vehicle.position; % 車両の位置
                y = obj.MAINLINE_Y_OFFSET-0.05; % 本線のY座標
                if contains(vehicle.VEHICLE_ID, 'Mainline')
                    vehicle_figure(end + 1) = plot(x, y, 'sk', 'LineWidth',0.02, 'MarkerSize', 9, 'MarkerFaceColor', [0 0.4470 0.7410]);
                    % vehicle_figure(end + 1) = plot(x-1, y, 'sk', 'LineWidth',0.02, 'MarkerSize', 9, 'MarkerFaceColor', [0 0.4470 0.7410]);
                elseif contains(vehicle.VEHICLE_ID, 'On-ramp')
                    vehicle_figure(end + 1) = plot(x, y, 'sk', 'LineWidth',0.02, 'MarkerSize', 9, 'MarkerFaceColor', [0.8500 0.3250 0.0980]);
                    % vehicle_figure(end + 1) = plot(x-1, y, 'sk', 'LineWidth',0.02, 'MarkerSize', 9, 'MarkerFaceColor', [0.8500 0.3250 0.0980]);
                end
            end

            % 合流車線の車両を描画
            for vehicle = onramp.vehicles.values()'
                if ~strcmp(vehicle.VEHICLE_ID, 'Onramp_end_position')
                    x = vehicle.position; % 車両の位置
                    y = obj.ONRAMP_Y_OFFSET+0.05; % 合流車線のY座標
                    % y = obj.ONRAMP_Y_OFFSET - (obj.ONRAMP_Y_OFFSET - obj.MAINLINE_Y_OFFSET - 0.2) ./ (1 + exp(-0.02*(x - onramp.end_position / 2)));; % 合流車線のY座標
                    vehicle_figure(end + 1) = plot(x, y, 'sk', 'LineWidth',0.02, 'MarkerSize', 9, 'MarkerFaceColor', [0.8500 0.3250 0.0980]);
                    % vehicle_figure(end + 1) = plot(x-1, y, 'sk', 'LineWidth',0.02, 'MarkerSize', 9, 'MarkerFaceColor', [0.8500 0.3250 0.0980]);
                end
            end

            minutes = floor(simulation.time / 60);
            seconds = floor(mod(simulation.time, 60));
            tenths = floor(mod(simulation.time, 1) * 10);
            figure_title = sprintf('Simulation time %02.f:%02.f.%01.f', minutes, seconds, tenths);
            title(figure_title, 'FontSize', 14, 'FontWeight', 'bold'); % タイトルを設定

            if simulation.is_save_video
                drawnow; % グラフィックを更新
                obj.video_frame_number = obj.video_frame_number + 1; % フレーム番号を更新
                obj.video_frames(obj.video_frame_number) = getframe(obj.figure); % 現在のフレームを保存
            end
            delete(vehicle_figure);

        end

        function write_video(obj, simulation, video_file_name, video_file_extension, video_frame_rate)
            % 動画の保存を開始
            video_path = fullfile(simulation.result_folder, video_file_name); % 動画ファイルのパスを設定
            video_writer = VideoWriter(video_path, video_file_extension); % 動画ファイルを作成
            video_writer.FrameRate = video_frame_rate; % 動画のフレームレートを設定
            open(video_writer); % 動画ファイルを開く
            writeVideo(video_writer, obj.video_frames); % フレームを書き込む
            close(video_writer); % 動画ファイルを閉じる
        end

        function plot_time_series_data(obj, simulation)
            % CSVファイルからグラフィックをプロット

            % 結果フォルダのパスを取得
            result_folder = simulation.result_folder;

            mainline_csv_files = dir(fullfile(result_folder, 'Mainline_vehicle_*.csv'));
            onramp_csv_files = dir(fullfile(result_folder, 'On-ramp_vehicle_*.csv'));

            % ファイル名からビークルIDを抽出してソート
            mainline_vehicle_ids = arrayfun(@(x) str2double(extractBetween(x.name, 'Mainline_vehicle_', '.csv')), mainline_csv_files);
            [~, mainline_sorted_indices] = sort(mainline_vehicle_ids);
            mainline_csv_files = mainline_csv_files(mainline_sorted_indices);

            onramp_vehicle_ids = arrayfun(@(x) str2double(extractBetween(x.name, 'On-ramp_vehicle_', '.csv')), onramp_csv_files);
            [~, onramp_sorted_indices] = sort(onramp_vehicle_ids);
            onramp_csv_files = onramp_csv_files(onramp_sorted_indices);

            % 位置のプロット
            figure(1);
            hold on;
            title('Position');
            xlabel('Time [s]');
            ylabel('Position [m]');

            legend('show', 'Interpreter', 'none', 'Location', 'southeast'); % 右下に表示
            ylim([simulation.mainline.start_position simulation.mainline.end_position]); % Y軸の範囲を設定
            grid on;

            % 速度のプロット
            figure(2);
            hold on;
            title('Velocity');
            xlabel('Time [s]');
            ylabel('Velocity [m/s]');
            legend('show', 'Interpreter', 'none', 'Location', 'southeast'); % 右下に表示
            ylim([0 35]); % Y軸の範囲を設定
            grid on;

            % 加速度のプロット
            figure(3);
            hold on;
            title('Acceleration');
            xlabel('Time [s]');
            ylabel('Acceleration [m/s^2]');
            legend('show', 'Interpreter', 'none', 'Location', 'southeast'); % 右下に表示
            ylim([-6 6]); % Y軸の範囲を設定
            grid on;

            % ジャークのプロット
            figure(4);
            hold on;
            title('Jerk');
            xlabel('Time [s]');
            ylabel('Jerk [m/s^3]');
            legend('show', 'Interpreter', 'none', 'Location', 'southeast'); % 右下に表示
            ylim([-5 5]); % Y軸の範囲を設定
            grid on;

            % 燃料消費量のプロット
            figure(5);
            hold on;
            title('Fuel Consumption');
            xlabel('Time [s]');
            ylabel('Fuel Consumption [mL]');
            legend('show', 'Interpreter', 'none', 'Location', 'northwest'); % 左上に表示
            ylim([0 150]); % Y軸の範囲を設定
            grid on;

            % 位置と目標位置の差分のプロット
            figure(6);
            hold on;
            title('Position Error');
            xlabel('Time [s]');
            ylabel('Position Error [m]');
            legend('show', 'Interpreter', 'none', 'Location', 'southeast');
            ylim([-200 200]); % Y軸の範囲を設定
            grid on;

            % MainLineの車両をプロット
            for i = 1:length(mainline_csv_files)
                % ファイル名を取得
                file_path = fullfile(result_folder, mainline_csv_files(i).name);

                % ビークルIDを抽出
                vehicle_id = extractBetween(mainline_csv_files(i).name, 'Mainline_vehicle_', '.csv');

                % CSVファイルを読み込む
                data = readtable(file_path, 'VariableNamingRule', 'preserve');

                % 時間、位置、速度、加速度、ジャークを取得
                Time = data.Time;
                Position = data.Position;
                Target_Position = data.Target_Position; % 目標位置
                Velocity = data.Velocity;
                Acceleration = data.Acceleration;
                Jerk = data.Jerk;
                Fuel_Consumption = data.Fuel_Consumption;

                line_style = ':'; % 点線
                line_color = [0.5, 0.5, 0.5]; % グレー

                % 位置のプロット
                figure(1);
                plot(Time, Position, 'LineWidth', 2, 'LineStyle', line_style, 'Color', line_color, ...
                    'DisplayName', ['Mainline vehicle ' char(vehicle_id)]);
                % --- IDを黒色で表示 ---
                % text(Time(end), Position(end), char(vehicle_id), 'Color', 'k', 'FontWeight', 'bold', 'FontSize', 10);

                % 速度のプロット
                figure(2);
                plot(Time, Velocity, 'LineWidth', 2, 'LineStyle', line_style, 'Color', line_color, ...
                    'DisplayName', ['Mainline vehicle ' char(vehicle_id)]);
                % text(Time(end), Velocity(end), char(vehicle_id), 'Color', 'k', 'FontWeight', 'bold', 'FontSize', 10);

                % 加速度のプロット
                figure(3);
                plot(Time, Acceleration, 'LineWidth', 2, 'LineStyle', line_style, 'Color', line_color, ...
                    'DisplayName', ['Mainline vehicle ' char(vehicle_id)]);
                % text(Time(end), Acceleration(end), char(vehicle_id), 'Color', 'k', 'FontWeight', 'bold', 'FontSize', 10);

                % ジャークのプロット
                figure(4);
                plot(Time, Jerk, 'LineWidth', 2, 'LineStyle', line_style, 'Color', line_color, ...
                    'DisplayName', ['Mainline vehicle ' char(vehicle_id)]);
                % text(Time(end), Jerk(end), char(vehicle_id), 'Color', 'k', 'FontWeight', 'bold', 'FontSize', 10);

                % 燃料消費量のプロット
                figure(5);
                plot(Time, Fuel_Consumption, 'LineWidth', 2, 'LineStyle', line_style, 'Color', line_color, ...
                    'DisplayName', ['Mainline vehicle ' char(vehicle_id)]);

            end

            % OnRampの車両をプロット
            for i = 1:length(onramp_csv_files)
                % ファイル名を取得
                file_path = fullfile(result_folder, onramp_csv_files(i).name);

                % ビークルIDを抽出
                vehicle_id = extractBetween(onramp_csv_files(i).name, 'On-ramp_vehicle_', '.csv');

                % CSVファイルを読み込む
                data = readtable(file_path, 'VariableNamingRule', 'preserve');

                % 時間、位置、速度、加速度、ジャークを取得
                Time = data.Time;
                Position = data.Position;
                Target_Position = data.Target_Position; % 目標位置
                Velocity = data.Velocity;
                Acceleration = data.Acceleration;
                Jerk = data.Jerk;
                Fuel_Consumption = data.Fuel_Consumption;

                line_style = '-'; % 実線
                line_color = 'b'; % 青色

                % 位置のプロット
                figure(1);
                plot(Time, Position, 'LineWidth', 2, 'LineStyle', line_style, 'Color', line_color, ...
                    'DisplayName', ['On-ramp vehicle ' char(vehicle_id)]);
                % --- IDを青色で表示 ---
                % text(Time(end), Position(end), char(vehicle_id), 'Color', 'b', 'FontWeight', 'bold', 'FontSize', 10);

                % 速度のプロット
                figure(2);
                plot(Time, Velocity, 'LineWidth', 2, 'LineStyle', line_style, 'Color', line_color, ...
                    'DisplayName', ['On-ramp vehicle ' char(vehicle_id)]);
                % text(Time(end), Velocity(end), char(vehicle_id), 'Color', 'b', 'FontWeight', 'bold', 'FontSize', 10);

                % 加速度のプロット
                figure(3);
                plot(Time, Acceleration, 'LineWidth', 2, 'LineStyle', line_style, 'Color', line_color, ...
                    'DisplayName', ['On-ramp vehicle ' char(vehicle_id)]);
                % text(Time(end), Acceleration(end), char(vehicle_id), 'Color', 'b', 'FontWeight', 'bold', 'FontSize', 10);

                % ジャークのプロット
                figure(4);
                plot(Time, Jerk, 'LineWidth', 2, 'LineStyle', line_style, 'Color', line_color, ...
                    'DisplayName', ['On-ramp vehicle ' char(vehicle_id)]);
                % text(Time(end), Jerk(end), char(vehicle_id), 'Color', 'b', 'FontWeight', 'bold', 'FontSize', 10);

                % 燃料消費量のプロット
                figure(5);
                plot(Time, Fuel_Consumption, 'LineWidth', 2, 'LineStyle', line_style, 'Color', line_color, ...
                    'DisplayName', ['On-ramp vehicle ' char(vehicle_id)]);

                % 位置と目標位置の差分のプロット
                figure(6);
                plot(Time, Target_Position - Position, 'LineWidth', 2, 'LineStyle', line_style, 'Color', line_color, ...
                    'DisplayName', ['On-ramp vehicle ' char(vehicle_id)]);

            end

            % 各プロットをPNGファイルとして保存
            saveas(figure(1), fullfile(result_folder, 'Position.png'));
            saveas(figure(2), fullfile(result_folder, 'Velocity.png'));
            saveas(figure(3), fullfile(result_folder, 'Acceleration.png'));
            saveas(figure(4), fullfile(result_folder, 'Jerk.png'));
            saveas(figure(5), fullfile(result_folder, 'FuelConsumption.png'));
            saveas(figure(6), fullfile(result_folder, 'PositionError.png'));

        end

    end
end