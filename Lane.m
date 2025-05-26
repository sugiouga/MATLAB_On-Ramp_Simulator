classdef Lane<handle
    % 車両の走行レーンを表すクラス
    properties(GetAccess = public, SetAccess = private)
        LANE_ID = []; % 車線ID
        WIDTH = 3.5; % レーンの幅 (m)

        % レーンの設定
        start_position = []; % レーンの開始位置 (m)
        end_position = []; % レーンの終了位置 (m)
        reference_velocity = []; % レーンの参照速度 (m)

        vehicles = dictionary(); % 車両の辞書
        % 車両のをキー、車両オブジェクトを値とする辞書
    end

    methods
        function obj = Lane(lane_id, start_position, end_position, reference_velocity)
            % コンストラクタ
            % 車線の基本情報を初期化
            obj.LANE_ID = lane_id; % 車線ID
            obj.start_position = start_position; % レーンの開始位置 (m)
            obj.end_position = end_position; % レーンの終了位置 (m)
            obj.reference_velocity = reference_velocity; % レーンの参照速度 (m/s)
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