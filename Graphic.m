classdef Graphic
    % グラフィッククラス
    properties(GetAccess = public, SetAccess = private)
        % 描画に関する変数
        graphic = []; % グラフィック
        vehicle_graphics = []; % 車両のグラフィック

        % グラフウィンドウの設定
        FIGURE_POSITION = [20, 300]; % グラフィックの左下隅の基準点
        FIGURE_WIDTH = 1000; % グラフィックの幅
        FIGURE_HEIGHT = 200; % グラフィックの高さ

        % 背景の設定
        BACKGROUND_X_RANGE = []; % 背景のx軸の範囲
        BACKGROUND_Y_RANGE = [6.5, 6.5]; % 背景のy軸の範囲
        BACKGROUND_COLOR = [0.65 0.995 0.95]; % 背景の色

        % レーンの設定
        MAINLINE_Y_OFFSET = 1; % 本線のy軸のオフセット
        ONRAMP_Y_OFFSET = 5; % 合流車線のy軸のオフセット

        % 動画保存の設定
        video_file_name = 'simulation_video.mp4'; % 動画ファイル名
        video_file_extension = 'MPEG-4'; % 動画ファイルの拡張子
        video_writer = []; % 動画ライター]
        video_frame_number = 1; % 動画フレーム番号
        video_frames = []; % 動画フレーム
        video_frame_rate = 10; % 動画フレームレート
    end

    methods(Static)

        function init_graphic(obj, simulation, mainline_lane, onramp_lane)
            % グラフィックの背景を作成
            % グラフウィンドウを作成
            obj.graphic = figure('Position', [obj.FIGURE_POSITION, obj.FIGURE_WIDTH, obj.FIGURE_HEIGHT]);

            if simulation.isSaveVideo
                % 動画の保存を開始
                total_frames = floor((simulation.end_time - simulation.start_time) / simulation.time_step); % 総フレーム数を計算
                obj.video_frames(total_frames + 1) = struct('cdata', [], 'colormap', []); % 動画フレームを初期化
            end

            % 背景を描画
            obj.BACKGROUND_X_RANGE = [mainline_lane.start_position, mainline_lane.end_position]; % 背景のx軸の範囲
            area(obj.BACKGROUND_X_RANGE, obj.BACKGROUND_Y_RANGE, 'FaceColor', obj.BACKGROUND_COLOR); % 背景を設定

            hold on;

            % レーンを描画
            % 本線
            plot([mainline_lane.start_position, mainline_lane.end_position], [MAINLINE_Y_OFFSET; MAINLINE_Y_OFFSET],'LineWidth',10,'Color',[0.7 0.7 0.7]); % 本線を描画
            % 合流車線
            onramp_x_range = onramp_lane.start_position .: 50 : onramp_lane.end_position + 50; % 合流車線のx軸の範囲
            onramp_curve = (obj.ONRAMP_Y_OFFSET - 2.8 ./ obj.MAINLINE_Y_OFFSET .+ exp(onramp_x_range - onramp_lane.end_position / 2)); % 合流車線の曲線)
            plot(onramp_x_range, onramp_curve, 'LineWidth', 10, 'Color', [0.7 0.7 0.7]); % 合流車線を描画

            axis(obj.BACKGROUND_X_RANGE, obj.BACKGROUND_Y_RANGE);
            grid on;
            xlabel('Position (m)', 'FontSize', 14, 'FontWeight', 'bold'); % x軸ラベルを設定

            if simulation.isSaveVideo
                drawnow;
                obj.video_frames(1) = getframe(obj.graphic); % 初期フレームを保存
            end

        end

        function update_vehicle_graphic(obj, simulation, mainline_lane, onramp_lane)
            % 車両のグラフィックを更新
            obj.vehicle_graphic = [];

            % 本線の車両を描画
            for vehicle = mainline_lane.vehicles.values()'
                x = vehicle.position; % 車両の位置
                y = 1 + MAINLINE_Y_OFFSET; % 本線のY座標
                if contains(vehicle.VEHICLE_ID, 'MainLine')
                    obj.vehicle_graphic(end+1) = plot(x, y, 'sk', 'LineWidth',0.01, 'MarkerSize', 4.5, 'MarkerFaceColor', [0 0.4470 0.7410]);
                    obj.vehicle_graphic(end+1) = plot(x-3, y, 'sk', 'LineWidth',0.01, 'MarkerSize', 6, 'MarkerFaceColor', [0 0.4470 0.7410]);
                elseif contains(vehicle.VEHICLE_ID, 'OnRamp')
                    obj.vehicle_graphic(end+1) = plot(x, y, 'sk', 'LineWidth',0.01, 'MarkerSize', 4.5,'MarkerFaceColor', [0.8500 0.3250 0.0980]);
                    obj.vehicle_graphic(end+1) = plot(x-3, y, 'sk', 'LineWidth',0.01, 'MarkerSize', 6,'MarkerFaceColor', [0.8500 0.3250 0.0980]);
                end
            end

            % 合流車線の車両を描画
            for vehicle = mainline_lane.vehicles.values()'
                x = vehicle.position; % 車両の位置
                y = (obj.ONRAMP_Y_OFFSET - 2.8 ./ obj.MAINLINE_Y_OFFSET .+ exp(x - onramp_lane.end_position / 2)); % 合流車線のY座標
                obj.vehicle_graphic(end+1) = plot(x, y, 'sk', 'LineWidth',0.01, 'MarkerSize', 4.5, 'MarkerFaceColor', [0.8500 0.3250 0.0980]);
                obj.vehicle_graphic(end+1) = plot(x-3, y, 'sk', 'LineWidth',0.01, 'MarkerSize', 6, 'MarkerFaceColor', [0.8500 0.3250 0.0980]);
            end

            graphic_title = sprintf('Simulation time 00:%d:%02d', floor(simulation.time_step * (simulation.step - 1) / 60), mod(floor(simulation.time_step * (simulation.step - 1)), 60));
            title(graphic_title, 'FontSize', 14, 'FontWeight', 'bold'); % タイトルを設定

            if simulation.isSaveVideo
                drawnow; % グラフィックを更新
                obj.video_frame_number = obj.video_frame_number + 1; % フレーム番号を更新
                obj.video_frames(obj.video_frame_number) = getframe(obj.graphic); % 現在のフレームを保存
            end

        end

        function write_video(obj, simulation)
            % 動画の保存を開始
            obj.video_file_name = fullfile(simulation.result_folder, obj.video_file_name); % 結果フォルダに動画ファイル名を設定
            obj.video_writer = VideoWriter(obj.video_file_name, obj.video_file_extension); % 動画ファイルを作成
            obj.video_writer.FrameRate = obj.video_frame_rate; % 動画のフレームレートを設定
            open(obj.video_writer); % 動画ファイルを開く
            writeVideo(obj.video_writer, obj.video_frames); % 初期フレームを動画に書き込む
            close(obj.video_writer); % 動画ファイルを閉じる
        end

    end
end