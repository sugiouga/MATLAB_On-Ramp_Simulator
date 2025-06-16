classdef Vehicle<handle
    % 車両クラス
    properties(GetAccess = public, SetAccess = private)
        % 車両の基本情報
        VEHICLE_ID = []; % 車両ID
        VEHICLE_TYPE = []; % 車両タイプ
        VEHICLE_LENGTH = []; % 車両の長さ
        VEHICLE_WIDTH = []; % 車両の幅

        MIN_VELOCITY = 0; % 車両の最小速度
        MAX_VELOCITY = 30; % 車両の最大速度
        MIN_ACCELERATION = -3; % 車両の最小加速度
        MAX_ACCELERATION = 2; % 車両の最大加速度

        % 車両の状態
        position = []; % 車両の位置
        reference_position = []; % 車両の参照位置
        velocity = []; % 車両の速度
        reference_velocity = []; % 車両の参照速度
        acceleration = 0; % 車両の加速度
        input_acceleration = 0; % 車両の入力加速度
        jerk = 0; % 車両のジャーク
        fuel_consumption = 0; % 車両の燃料消費量
        controller = []; % 車両の制御器
        lane_id = []; % 車両の走行レーン

        % 車線変更するかどうかのフラグ
        isMergelane = false; % 車線変更フラグ
    end

    methods
        function obj = Vehicle(vehicle_id, vehicle_type, position, velocity, controller)
            % コンストラクタ
            % 車両の基本情報を初期化
            obj.VEHICLE_ID = vehicle_id; % 車両ID
            obj.VEHICLE_TYPE = vehicle_type; % 車両タイプ

            % 車両のタイプに応じて車両の長さと幅を設定
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
            obj.position = position; % 車両の位置 (m)
            obj.velocity = velocity; % 車両の速度 (m/s)
            obj.controller = controller; % 車両の制御器
        end

        function change_reference_velocity(obj, reference_velocity)
            % 車両の参照速度を変更
            obj.reference_velocity = reference_velocity;
        end

        function change_input_acceleration(obj, input_acceleration)
            % 車両の入力加速度を変更
            obj.input_acceleration = input_acceleration;
        end

        function change_controller(obj, controller)
            % 車両の制御器を変更
            obj.controller = controller;
        end

        function change_lane_id(obj, lane_id)
            % 車両の走行レーンを変更
            obj.lane_id = lane_id;
        end

        function change_isMergelane(obj, flag)
            % 車線変更フラグを変更
            obj.isMergelane = flag;
        end

        function update_state(obj, time_step)
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

            delta = 0.666;
            gamma_1 = 0.072;
            gamma_2 = 0.0344;
            d_1 = 0.0269;
            d_2 = 0.0171;
            d_3 = 0.000672;
            m = 1680;
            P_T = max(0, d_1 * obj.velocity + d_2 * obj.velocity^2 + d_3 * obj.velocity^3 + 0.001 * m * obj.acceleration * obj.velocity);
            % 燃料消費量を計算する
            if obj.acceleration <= 0
                obj.fuel_consumption = obj.fuel_consumption + time_step * delta; % 燃料消費量を更新
            else
                obj.fuel_consumption = obj.fuel_consumption + time_step * (delta + gamma_1 * P_T + gamma_2 * 0.001 * m * obj.acceleration^2 * obj.velocity); % 燃料消費量を更新
            end
        end
    end
end