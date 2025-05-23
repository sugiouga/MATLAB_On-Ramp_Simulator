classdef Lane<handle
    % 車両の走行レーンを表すクラス
    properties(GetAccess = public, SetAccess = private)
        LANE_ID = []; % 車線ID
        START_POSITION = []; % レーンの開始位置 (m)
        END_POSITION = []; % レーンの終了位置 (m)
        REFERENCE_VELOCITY = []; % レーンの参照速度 (m)
        WIDTH = 3.5; % レーンの幅 (m)

        vehicles = dictionary(); % 車両の辞書
        % 車両のをキー、車両オブジェクトを値とする辞書
    end

    methods
        function obj = Lane(lane_id, start_position, end_position, reference_velocity)
            % コンストラクタ
            % 車線の基本情報を初期化
            obj.LANE_ID = lane_id; % 車線ID
            obj.START_POSITION = start_position; % レーンの開始位置 (m)
            obj.END_POSITION = end_position; % レーンの終了位置 (m)
            obj.REFERENCE_VELOCITY = reference_velocity; % レーンの参照速度 (m/s)
        end

        function add_vehicle(obj, vehicle)
            % 車両をレーンに追加
            % vehicle: 車両オブジェクト
            obj.vehicles(vehicle.vehicle.id) = vehicle;
            vehicle.change_lane_id(obj.LANE_ID); % 車両のレーンIDを変更
        end

        function remove_vehicle(obj, vehicle_id)
            % 車両をレーンから削除
            % vehicle_id: 車両ID
            if isKey(obj.vehicles, vehicle_id)
                remove(obj.vehicles, vehicle_id);
            else
                error('Vehicle ID not found in lane');
            end
        end
    end
end