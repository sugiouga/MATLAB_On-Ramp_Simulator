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
        time_step = 0.1;
        % シミュレーションのステップ数
        step_number = 0;

        % グラフィックオブジェクト
        Graphic = [];
        Graphic_update_interval = 0.2; % グラフィックの更新間隔 (秒)

        % シミュレーションの結果を保存するフォルダ
        result_folder = '';

        % シミュレーションの終了フラグ
        isEnd = false;
        % csvファイルに保存するかどうかのフラグ
        isSaveCSV = true;
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
                vehicle.update_state(obj.time_step);

                % 車線合流の処理
                if strcmp(vehicle.lane_id, 'On-ramp')
                    % 車両が合流車線の終了位置を超えた場合
                    if vehicle.position > onramp.end_position
                        mainline.add_vehicle(vehicle);
                        onramp.remove_vehicle(vehicle.VEHICLE_ID);
                    end
                end

                if obj.isSaveCSV
                    % 車両の状態をCSVファイルに保存
                    save_vehicle_state_to_csv(vehicle, obj.time, obj.result_folder);
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

function save_vehicle_state_to_csv(vehicle, time, result_folder)
    % ビークルの状態をCSVファイルに保存する
    filename = [result_folder, filesep, vehicle.VEHICLE_ID, '.csv'];

    % ビークルの状態を取得
    data = {time, vehicle.position, vehicle.reference_position, vehicle.velocity, vehicle.reference_velocity, vehicle.acceleration, vehicle.input_acceleration, vehicle.jerk, vehicle.controller, vehicle.lane_id};

    % ヘッダーを追加 (ファイルが存在しない場合のみ)
    if exist(filename, 'file') ~= 2
        header = {'Time', 'Position', 'Reference Position', 'Velocity', 'Reference Velocity', 'Acceleration', 'Input_Acceleration', 'Jerk', 'Controller', 'Lane ID'};
        fid = fopen(filename, 'w');
        fprintf(fid, '%s,', header{1,1:end-1});
        fprintf(fid, '%s\n', header{1,end});
        fclose(fid);
    end

    % データを追記
    fid = fopen(filename, 'a');
    for i = 1:length(data)
        if isnumeric(data{i})
            fprintf(fid, '%g', data{i});
        else
            fprintf(fid, '%s', num2str(data{i}));
        end
        if i < length(data)
            fprintf(fid, ',');
        else
            fprintf(fid, '\n');
        end
    end
    fclose(fid);
end