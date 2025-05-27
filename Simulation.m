classdef Simulation<handle
    % シミュレーションの起動･ステップの実行･終了を行うクラス
    properties
        % シミュレーションの実行時間
        time = [];
        % シミュレーションの開始時間
        start_time = 0;
        % シミュレーションの終了時間
        end_time = 30;
        % シミュレーションの時間間隔
        time_step = 0.01;
        % シミュレーションのステップ数
        step_number = 0;

        % グラフィックオブジェクト
        Graphic = [];
        Graphic_update_interval = 0.2; % グラフィックの更新間隔 (秒)

        % シミュレーションの結果を保存するフォルダ
        result_folder = '';

        % シミュレーションの終了フラグ
        isEnd = false;
        % 動画を保存するかどうかのフラグ
        isSaveVideo = true;
    end

    methods

        function obj = Simulation(mainline, onramp)
            % コンストラクタ
            % シミュレーションの時間を初期化
            obj.time = obj.start_time;

            % 日付時刻を含む結果保存フォルダ名を作成
            timestamp = datestr(now, 'yyyymmdd_HHMMSS');
            obj.result_folder = fullfile('simulation_results', timestamp);
            if ~exist(obj.result_folder, 'dir')
                mkdir(obj.result_folder);
            end

            % 描画の初期化
            obj.Graphic = Graphic(obj, mainline, onramp);

        end

        function step(obj, mainline, onramp)

            vehicles = [mainline.vehicles.values(); onramp.vehicles.values()];
            for vehicle = vehicles'
                % 車両の状態を更新
                vehicle.update_status(obj.time_step);

                % 車線合流の処理
                if strcmp(vehicle.lane_id, 'On-ramp')
                    % 車両が合流車線の終了位置を超えた場合
                    if vehicle.position > onramp.end_position
                        mainline.add_vehicle(vehicle);
                        onramp.remove_vehicle(vehicle.VEHICLE_ID);
                    end
                end
            end

            if mod(obj.time, obj.Graphic_update_interval) < obj.time_step
                % グラフィックの更新
                obj.Graphic.update_vehicle_graphic(obj, mainline, onramp);
            end

            % シミュレーションの時間を更新
            obj.time = obj.time + obj.time_step;

            % シミュレーションのステップ数を更新
            obj.step_number = obj.step_number + 1;

            % シミュレーションの終了条件をチェック
            if obj.time >= obj.end_time
                obj.isEnd = true;
            end

            if obj.isEnd
                % シミュレーションの終了処理
                disp('Simulation ended.');
                if obj.isSaveVideo
                    obj.Graphic.write_video(obj);
                end
                disp(['Results saved in: ', obj.result_folder]);
                return;
            end

        end

    end
end