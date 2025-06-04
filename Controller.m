classdef Controller<handle
    % Controller: シミュレーションの制御を行うクラス
    properties
        time_step = [];
        vehicle_manager = []; % 車両管理オブジェクト
    end

    methods
        function obj = Controller(simulation, vehicle_manager)
            % コンストラクタ
            obj.time_step = simulation.time_step;
            obj.vehicle_manager = vehicle_manager; % 車両管理オブジェクト
        end

        function acceleration = idm(obj, vehicle, leading_vehicle)
            % Intelligent Driver Model (IDM)を使用して車両の加速度を計算
            % vehicle: 対象車両オブジェクト
            % leading_vehicle: 前方車両オブジェクト

            if isempty(leading_vehicle)
                % 前方車両がいない場合は、参照速度に追従する
                if vehicle.velocity == vehicle.reference_velocity
                    acceleration = 0;
                else
                    acceleration = (vehicle.reference_velocity - vehicle.velocity) / obj.time_step;
                end
                return;
            end

            max_acceleration = vehicle.MAX_ACCELERATION;
            desired_velocity = vehicle.reference_velocity;
            min_distance = 2.0;
            desired_headway_time = 1.5;
            comfort_braking_deceleration = 2.0;
            delta = 4;

            distance_to_leading = leading_vehicle.position - vehicle.position;
            related_velocity = vehicle.velocity - leading_vehicle.velocity;

            desired_gap = min_distance + desired_headway_time * vehicle.velocity + (vehicle.velocity * related_velocity) / (2 * sqrt(max_acceleration * comfort_braking_deceleration));
            acceleration = max_acceleration * (1 - (vehicle.velocity / desired_velocity)^delta - (desired_gap / distance_to_leading)^2);

        end

        function mobil(obj, vehicle, politeness_factor)
            % MOBIL (Minimizing Overall Braking Induced by Lane changes)を使用して車両の加速度を計算
            % vehicle: 対象車両オブジェクト
            % leading_vehicle: 前方車両オブジェクト

            p = politeness_factor; % ポライトネスファクター
            threshold_acceleration = -3; % 加速度のしきい値

            if ~isempty(obj.vehicle_manager.find_surround_vehicles_in_lane(vehicle, 'Mainline', 50, 'rear'))
                leading_vehicle = obj.vehicle_manager.find_leading_vehicle_in_lane(vehicle, 'On-ramp');
                obj.idm(vehicle, leading_vehicle);
                return;
            else
                % MOBIL制御を適用

                % 合流車線の車両
                onramp_following_vehicle = obj.vehicle_manager.find_following_vehicle_in_lane(vehicle, 'On-ramp');
                onramp_leading_vehicle = obj.vehicle_manager.find_leading_vehicle_in_lane(vehicle, 'On-ramp');
                if isempty(onramp_following_vehicle)
                    original_onramp_following_vehicle_acceleration = 0;
                    new_onramp_following_vehicle_acceleration = 0;
                else
                    original_onramp_following_vehicle_acceleration = obj.idm(onramp_following_vehicle, vehicle);
                    new_onramp_following_vehicle_acceleration = obj.idm(onramp_following_vehicle, onramp_leading_vehicle);
                end

                % 本線の車両
                mainline_following_vehicle = obj.vehicle_manager.find_following_vehicle_in_lane(vehicle, 'Mainline');
                mainline_leading_vehicle = obj.vehicle_manager.find_leading_vehicle_in_lane(vehicle, 'Mainline');
                if isempty(mainline_following_vehicle)
                    original_mainline_following_vehicle_acceleration = 0;
                    new_mainline_following_vehicle_acceleration = 0;
                else
                    original_mainline_following_vehicle_acceleration = obj.idm(mainline_following_vehicle, mainline_leading_vehicle);
                    new_mainline_following_vehicle_acceleration = obj.idm(mainline_following_vehicle, vehicle);
                end

                original_acceleration = obj.idm(vehicle, onramp_leading_vehicle);
                new_acceleration = obj.idm(vehicle, mainline_leading_vehicle);

                delta_acceleration = new_acceleration - original_acceleration + p * (new_mainline_following_vehicle_acceleration - original_mainline_following_vehicle_acceleration + new_onramp_following_vehicle_acceleration - original_onramp_following_vehicle_acceleration);

                % delta_acceleration
                if delta_acceleration > threshold_acceleration
                    % 車線変更を行う
                    % new_mainline_following_vehicle_acceleration
                    if new_mainline_following_vehicle_acceleration >= mainline_following_vehicle.MIN_ACCELERATION
                        % 新しい後続車が安全に減速できる場合
                        vehicle.change_isChangelane(true);
                        vehicle.change_input_acceleration(new_acceleration);
                        return
                    end
                end

                % 車線変更を行わない場合
                vehicle.change_input_acceleration(original_acceleration);

            end

        end

        function F_matrix = get_F_matrix(prediction_horizon, time_step)
            % 状態遷移行列Fを計算
            % prediction_horizon: 予測ホライズン
            % time_step: 時間ステップ

            N = prediction_horizon / time_step; % 予測ホライズンを時間ステップで割る
            h = time_step; % 時間ステップをhとする

            A_matrix = [1 h;
                        0 1];

            F_matrix = zeros(2*N, 2);
            for k = 1:N
                F_matrix(2*k-1:2*k, 1:2) = A_matrix^k;
            end
        end

        function G_matrix = get_G_matrix(prediction_horizon, time_step)
            % 制御入力行列Gを計算
            % prediction_horizon: 予測ホライズン
            % time_step: 時間ステップ

            N = prediction_horizon / time_step; % 予測ホライズンを時間ステップで割る
            h = time_step; % 時間ステップをhとする

            A_matrix = [1 h;
                        0 1];
            B_matrix = [0.5*h^2;
                        h];
            G_matrix = zeros(2*N, N);

            for i = 1:N
                for j = 1:i
                    G_matrix(2*i-1:2*i, j) = (A_matrix^(i-j)) * B_matrix;
                end
            end
        end

    end
end