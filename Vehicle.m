classdef Vehicle<handle
    % 車両クラス
    properties(GetAccess = public, SetAccess = private)
        % 車両の基本情報
        VEHICLE_TYPE = []; % 車両タイプ
        VEHICLE_LENGTH = []; % 車両の長さ
        VEHICLE_WIDTH = []; % 車両の幅

        MIN_VELOCITY = 0; % 車両の最小速度
        MAX_VELOCITY = 30; % 車両の最大速度
        MIN_ACCELERATION = -5; % 車両の最小加速度
        MAX_ACCELERATION = 5; % 車両の最大加速度

        % 車両の状態
        lane = []; % 車両の走行レーン
        position = []; % 車両の位置
        velocity = []; % 車両の速度
        acceleration = 0; % 車両の加速度
        input_acceleration = 0; % 車両の入力加速度
        jerk = 0; % 車両のジャーク
    end

    methods
        function obj = Vehicle(vehicle_type, lane, position, velocity)
            % コンストラクタ
            % 車両の基本情報を初期化
            obj.VEHICLE_TYPE = vehicle_type;

            % 車両の長さと幅を設定
            switch vehicle_type
                case 'car'
                    obj.VEHICLE_LENGTH = 5.25; % 車両の長さ (m)
                    obj.VEHICLE_WIDTH = 1.69; % 車両の幅 (m)
                case 'truck'
                    obj.VEHICLE_LENGTH = 12; % 車両の長さ (m)
                    obj.VEHICLE_WIDTH = 2.5; % 車両の幅 (m)
                otherwise
                    error('Unknown vehicle type');
            end

            % 車両の初期位置と速度を設定
            obj.lane = lane; % 車両の走行レーン
            obj.position = position; % 車両の位置 (m)
            obj.velocity = velocity; % 車両の速度 (m/s)

        end

        function change_lane(obj, lane)
            % 車両の走行レーンを変更
            obj.lane = lane;
        end

        function change_input_acceleration(obj, input_acceleration)
            % 車両の入力加速度を変更
            obj.input_acceleration = input_acceleration;
        end

        function update_status(obj, time_step)
            % 車両の状態を更新

            % 車両の加速度入力を制限する
            if obj.input_acceleration < obj.MIN_ACCELERATION
                obj.input_acceleration = obj.MIN_ACCELERATION;
            elseif obj.input_acceleration > obj.MAX_ACCELERATION
                obj.input_acceleration = obj.MAX_ACCELERATION;
            end

            % ジャークを計算する
            obj.jerk = (obj.input_acceleration - obj.acceleration) / time_step;

            % 車両の加速度を更新する
            obj.acceleration = obj.input_acceleration;

            % 車両の位置･速度を更新する
            obj.position = obj.position + obj.velocity * time_step + 0.5 * obj.acceleration * time_step^2;
            obj.velocity = obj.velocity + obj.acceleration * time_step;

            % 車両の速度を制限する
            if obj.velocity < obj.MIN_VELOCITY
                obj.velocity = obj.MIN_VELOCITY;
            elseif obj.velocity > obj.MAX_VELOCITY
                obj.velocity = obj.MAX_VELOCITY;
            end
        end

    end
end