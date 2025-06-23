classdef Controller<handle
    % Controller: シミュレーションの制御を行うクラス
    properties
        time_step = [];
        onramp_end_position = []; % 合流車線の終端位置
        vehicle_manager = []; % 車両管理オブジェクト
    end

    methods
        function obj = Controller(simulation, vehicle_manager)
            % コンストラクタ
            obj.time_step = simulation.time_step;
            obj.onramp_end_position = simulation.onramp.end_position; % 合流車線の終端位置
            obj.vehicle_manager = vehicle_manager; % 車両管理オブジェクト
        end

        function acceleration = constant_speed(obj, vehicle)
            % 定速走行を行う車両の加速度を計算
            % vehicle: 対象車両オブジェクト

            if vehicle.velocity == vehicle.reference_velocity
                acceleration = 0; % 参照速度に達している場合は加速度は0
            else
                acceleration = (vehicle.reference_velocity - vehicle.velocity) / obj.time_step; % 参照速度に追従するように加速度を計算
            end
        end

        function acceleration = idm(obj, vehicle, leading_vehicle)
            % Intelligent Driver Model (IDM)を使用して車両の加速度を計算
            % vehicle: 対象車両オブジェクト
            % leading_vehicle: 前方車両オブジェクト

            if isempty(leading_vehicle)
                acceleration = obj.constant_speed(vehicle); % 前方車両がいない場合は定速走行
                return;
            end

            max_acceleration = vehicle.MAX_ACCELERATION;
            desired_velocity = vehicle.reference_velocity;
            min_distance = 2.0;
            desired_headway_time = 3;
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

            if ~isempty(obj.vehicle_manager.find_surround_vehicles_in_lane(vehicle, 'Mainline', 30, 'rear'))
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
                        vehicle.change_isMergelane(true);
                        vehicle.change_input_acceleration(new_acceleration);
                        return
                    end
                end

                % 車線変更を行わない場合
                vehicle.change_input_acceleration(original_acceleration);

            end

        end

        function [optimal_u_sequence optimal_tau] = lane_merge_mpc(obj, vehicle, prediction_horizon, tau_interval, weight)
            % ゲーム理論に基づくMPCを使用して車両の加速度を計算
            % vehicle: 対象車両オブジェクト
            % prediction_horizon: 予測ホライズン

            tau_feasible_set = 0 : tau_interval : round(prediction_horizon); % 予測ホライズンに基づく時間ステップの集合

            total_costs = zeros(2, length(tau_feasible_set)); % 各時間ステップのコストを格納する配列
            optimal_u_sequences = cell(2, length(tau_feasible_set)); % 各時間ステップの最適な制御入力を格納するセル配列
            end_step = prediction_horizon / obj.time_step; % 予測ホライズンを時間ステップで割る
            min_distance = 5; % 最小車間距離
            threshold_distance_front = 20; % 車線変更のしきい値距離
            threshold_distance_rear = 40;
            headway_time = 3;
            min_acceleration = vehicle.MIN_ACCELERATION; % 最小加速度

            mpc_interval = round(tau_interval / obj.time_step); % tauを時間ステップで割る
            if isempty(vehicle.optimal_u_sequence)
                u0_sequence = zeros(end_step, 1); % 前の制御入力シーケンスが空の場合はゼロで初期化
            else
                u0_sequence = [vehicle.optimal_u_sequence(mpc_interval+1 : end_step, :); zeros(mpc_interval, 1)];
            end

            F_matrix = obj.get_F_matrix(prediction_horizon, obj.time_step); % 状態遷移行列を取得
            G_matrix = obj.get_G_matrix(prediction_horizon, obj.time_step); % 制御入力行列を取得

            % 車両の周囲の車両を取得
            mainline_leading_vehicle = obj.vehicle_manager.find_leading_vehicle_in_lane(vehicle, 'Mainline');
            mainline_following_vehicle = obj.vehicle_manager.find_following_vehicle_in_lane(vehicle, 'Mainline');
            mainline_following_2nd_vehicle = obj.vehicle_manager.find_following_vehicle_in_lane(mainline_following_vehicle, 'Mainline');

            % 各車両の初期状態を設定
            vehicle_state = [vehicle.position; vehicle.velocity]; % 対象車両の状態

            leading_vehicle_predict_state = obj.predict_vehicle_future_state(mainline_leading_vehicle, prediction_horizon, zeros(end_step, 1)); % 前方車両の予測状態
            following_vehicle_predict_state = obj.predict_vehicle_future_state(mainline_following_vehicle, prediction_horizon, zeros(end_step, 1)); % 後続車両の予測状態
            following_2nd_vehicle_predict_state = obj.predict_vehicle_future_state(mainline_following_2nd_vehicle, prediction_horizon, zeros(end_step, 1)); % 2台目の後続車両の予測状態

            for gap_idx = 1:2

                lb = vehicle.MIN_ACCELERATION * ones(end_step, 1); % 制御入力の下限
                ub = vehicle.MAX_ACCELERATION * ones(end_step, 1); % 制御入力の上限

                for tau_idx = 1:length(tau_feasible_set)
                    current_tau = tau_feasible_set(tau_idx); % 現在の時間ステップ
                    tau_k = round(current_tau / obj.time_step + 1); % 現在のtauを時間ステップで割る

                    A = [G_matrix(1:2:end-1, :); -G_matrix(2*tau_k-1:2:end-1, :); G_matrix(2:2:end, :); -G_matrix(2:2:end, :)];
                    b = [-F_matrix(1:2:end-1, :) * vehicle_state; F_matrix(2*tau_k-1:2:end-1, :) * vehicle_state; - F_matrix(2:2:end, :) * vehicle_state; F_matrix(2:2:end, :) * vehicle_state];

                    if gap_idx == 1
                        % 後続車両の前に合流する場合の制約条件
                        b(1:tau_k-1) = b(1:tau_k-1) + obj.onramp_end_position;
                        b(tau_k:end_step) = b(tau_k:end_step) + leading_vehicle_predict_state(2*tau_k-1:2:end-1) - threshold_distance_front; % 前方車両との距離制約を追加
                        b(end_step+1:2*end_step-tau_k+1) = b(end_step+1:2*end_step-tau_k+1) - following_vehicle_predict_state(2*tau_k-1:2:end-1) - threshold_distance_rear; % 後続車両との距離制約を追加
                        b(2*end_step-tau_k+2:3*end_step-tau_k+1) = b(2*end_step-tau_k+2:3*end_step-tau_k+1) + vehicle.MAX_VELOCITY;
                        b(3*end_step-tau_k+2:end) = b(3*end_step-tau_k+2:end) - vehicle.MIN_VELOCITY;

                        objective_function = @(u_sequence) weight.input * sum((exp(weight.delta*[end_step:-1:1])'.*u_sequence).^2) +...
                        weight.velocity * sum((exp(weight.delta*[end_step:-1:tau_k])'.*(leading_vehicle_predict_state(2*tau_k-1:2:end) - (F_matrix(2*tau_k-1:2:end, :)*vehicle_state + G_matrix(2*tau_k-1:2:end, :)*u_sequence))).^2) +...
                        weight.position * sum((exp(weight.delta*[end_step:-1:1])'.*(leading_vehicle_predict_state(1:2:end-1) - (F_matrix(2:2:end, :)*vehicle_state + G_matrix(2:2:end, :)*u_sequence)*headway_time - min_distance)).^2) +...
                        weight.end_position * sum((exp(weight.delta*[tau_k-1:-1:1])'.*(obj.onramp_end_position - (F_matrix(1:2:2*tau_k-2, :)*vehicle_state + G_matrix(1:2:2*tau_k-2, :)*u_sequence))).^2) +...
                        weight.jerk * sum((exp(weight.delta*[end_step:-1:2])'.*(u_sequence(2:end) - u_sequence(1:end-1))).^2); % 目的関数を定義
                    else
                        % ./(following_vehicle_predict_state(1:2:end-1) - (F_matrix(1:2:end-1, :)*vehicle_state + G_matrix(1:2:end-1, :)*u_sequence))
                        % 後続車両の後に合流する場合の制約条件

                        b(1:tau_k-1) = b(1:tau_k-1) + obj.onramp_end_position;
                        b(tau_k:end_step) = b(tau_k:end_step) + following_vehicle_predict_state(2*tau_k-1:2:end-1) - threshold_distance_front; % 後続車両との距離制約を追加
                        b(end_step+1:2*end_step-tau_k+1) = b(end_step+1:2*end_step-tau_k+1) - following_2nd_vehicle_predict_state(2*tau_k-1:2:end-1) - threshold_distance_rear; % 2台目の後続車両との距離制約を追加
                        b(2*end_step-tau_k+2:3*end_step-tau_k+1) = b(2*end_step-tau_k+2:3*end_step-tau_k+1) + vehicle.MAX_VELOCITY;
                        b(3*end_step-tau_k+2:end) = b(3*end_step-tau_k+2:end) - vehicle.MIN_VELOCITY;

                        objective_function = @(u_sequence) weight.input * sum((exp(weight.delta*[end_step:-1:1])'.*u_sequence).^2) +...
                        weight.velocity * sum((exp(weight.delta*[end_step:-1:tau_k])'.*(following_vehicle_predict_state(2*tau_k-1:2:end) - (F_matrix(2*tau_k-1:2:end, :)*vehicle_state + G_matrix(2*tau_k-1:2:end, :)*u_sequence))).^2) +...
                        weight.position * sum((exp(weight.delta*[end_step:-1:1])'.*(following_vehicle_predict_state(1:2:end-1) - (F_matrix(2:2:end, :)*vehicle_state + G_matrix(2:2:end, :)*u_sequence)*headway_time - min_distance)).^2) +...]
                        weight.end_position * sum((exp(weight.delta*[tau_k-1:-1:1])'.*(obj.onramp_end_position - (F_matrix(1:2:2*tau_k-2, :)*vehicle_state + G_matrix(1:2:2*tau_k-2, :)*u_sequence))).^2) +...
                        weight.jerk * sum((exp(weight.delta*[end_step:-1:2])'.*(u_sequence(2:end) - u_sequence(1:end-1))).^2); % 目的関数を定義
                    end

                    option = optimoptions('fmincon', 'Display', 'off', 'Algorithm', 'sqp'); % 最適化オプションを設定
                    [optimal_u_sequence, cost, exitflag] = fmincon(objective_function, u0_sequence, A, b, [], [], lb, ub, [], option); % 最適化問題を解く
                    if exitflag < 0
                        cost = inf; % 最適化が失敗した場合はコストを無限大に設定
                    end

                    total_costs(gap_idx, tau_idx) = cost; % 各時間ステップのコストを格納
                    optimal_u_sequences{gap_idx}{tau_idx} = optimal_u_sequence; % 各時間ステップの最適な制御入力を格納
                end
            end

            % 最小コストの時間ステップを選択
            [min_cost_each_gap optimal_tau] = min(total_costs, [], 2); % 各車線変更の最小コストを取得
            [min_cost, optimal_gap] = min(min_cost_each_gap); % 最小コストとそのインデックスを取得

            optimal_u_sequence = optimal_u_sequences{optimal_gap}{optimal_tau(optimal_gap)}; % 最小コストの制御入力シーケンスを取得
            optimal_tau = tau_interval*(optimal_tau(optimal_gap) - 1);

            if min_cost == inf
                optimal_tau = -1;
            end

            disp(['Vehicle ID: ', vehicle.VEHICLE_ID]); % 車両IDを表示
            % disp(['Vehicle ID: ', vehicle.VEHICLE_ID, ' is merging lane.']); % 車両IDを表示
            disp(['Minimum cost: ', num2str(min_cost)]); % 最小コストを表示
            disp(['Optimal gap: ', num2str(optimal_gap), ', Optimal tau: ', num2str(optimal_tau), ', Optimal Acceleration: ', num2str(optimal_u_sequence(1))]); % 最適な車線変更と時間ステップを表示

        end

        function optimal_u_sequence = cruise_control_mpc(obj, vehicle, prediction_horizon, weight)
            % 定速走行のためのMPCを使用して車両の加速度を計算
            % vehicle: 対象車両オブジェクト
            % prediction_horizon: 予測ホライズン

            end_step = prediction_horizon / obj.time_step; % 予測ホライズンを時間ステップで割る
            min_distance = 5; % 最小車間距離
            threshold_distance = 30; % 車線変更のしきい値距離
            headway_time = 3;

            if isempty(vehicle.optimal_u_sequence)
                u0_sequence = zeros(end_step, 1); % 前の制御入力シーケンスが空の場合はゼロで初期化
            else
                u0_sequence = [vehicle.optimal_u_sequence(2:end_step, :); 0]; % 前の制御入力シーケンスを使用して初期化
            end

            lb = vehicle.MIN_ACCELERATION * ones(end_step, 1); % 制御入力の下限
            ub = vehicle.MAX_ACCELERATION * ones(end_step, 1); % 制御入力の上限

            F_matrix = obj.get_F_matrix(prediction_horizon, obj.time_step); % 状態遷移行列を取得
            G_matrix = obj.get_G_matrix(prediction_horizon, obj.time_step); % 制御入力行列を取得

            % 車両の周囲の車両を取得
            mainline_leading_vehicle = obj.vehicle_manager.find_leading_vehicle_in_lane(vehicle, 'Mainline');
            mainline_following_vehicle = obj.vehicle_manager.find_following_vehicle_in_lane(vehicle, 'Mainline');

            vehicle_state = [vehicle.position; vehicle.velocity]; % 対象車両の状態

            leading_vehicle_predict_state = obj.predict_vehicle_future_state(mainline_leading_vehicle, prediction_horizon, zeros(end_step, 1)); % 前方車両の予測状態
            following_vehicle_predict_state = obj.predict_vehicle_future_state(mainline_following_vehicle, prediction_horizon, zeros(end_step, 1)); % 後続車両の予測状態

            A = [G_matrix(1:2:end-1, :); -G_matrix(1:2:end-1, :); G_matrix(2:2:end, :); -G_matrix(2:2:end, :)];
            b = [-F_matrix(1:2:end-1, :) * vehicle_state; F_matrix(1:2:end-1, :) * vehicle_state; -F_matrix(2:2:end, :) * vehicle_state; F_matrix(2:2:end, :) * vehicle_state];

            b(1:end_step) = b(1:end_step) + leading_vehicle_predict_state(1:2:end-1) - threshold_distance; % 前方車両との距離制約を追加
            b(end_step+1:2*end_step) = b(end_step+1:2*end_step) - following_vehicle_predict_state(1:2:end-1) - threshold_distance; % 後続車両との距離制約を追加
            b(2*end_step+1:3*end_step) = b(2*end_step+1:3*end_step) + vehicle.MAX_VELOCITY;
            b(3*end_step+1:end) = b(3*end_step+1:end) - vehicle.MIN_VELOCITY;

            objective_function = @(u_sequence) weight.input * sum((exp(weight.delta*[end_step:-1:1])'.*u_sequence).^2) +...
            weight.velocity * sum((exp(weight.delta*[end_step:-1:1])'.*(leading_vehicle_predict_state(2:2:end) - (F_matrix(2:2:end, :)*vehicle_state + G_matrix(2:2:end, :)*u_sequence))).^2) +...
            weight.position * sum((exp(weight.delta*[end_step:-1:1])'.*(leading_vehicle_predict_state(1:2:end-1) - (F_matrix(2:2:end, :)*vehicle_state + G_matrix(2:2:end, :)*u_sequence)*headway_time - min_distance)).^2) +...
            weight.jerk * sum((exp(weight.delta*[end_step:-1:2])'.*(u_sequence(2:end) - u_sequence(1:end-1))).^2); % 目的関数を定義

            option = optimoptions('fmincon', 'Display', 'off', 'Algorithm', 'sqp'); % 最適化オプションを設定
            optimal_u_sequence = fmincon(objective_function, u0_sequence, A, b, [], [], lb, ub, [], option); % 最適化問題を解く

            % disp(['Vehicle ID: ', vehicle.VEHICLE_ID, ' is on cruise control.']); % 車両IDを表示
            % disp(['Optimal Acceleration: ', num2str(optimal_u_sequence(1))]); % 最適な車線変更と時間ステップを表示

        end


        function vehicle_next_state = predict_vehicle_next_state(obj, vehicle_state, input)
            % 車両の次の状態を予測する
            % vehicle: 対象車両オブジェクト
            % u_sequence: 制御入力のシーケンス

            A_matrix = [1 obj.time_step;
                        0 1];
            B_matrix = [0.5 * obj.time_step^2;
                        obj.time_step];

            vehicle_next_state = A_matrix * vehicle_state + B_matrix * input;
        end

        function vehicle_future_state = predict_vehicle_future_state(obj, vehicle, prediction_horizon, input_sequence)
            % 車両の状態を予測する
            % vehicle: 対象車両オブジェクト
            % prediction_horizon: 予測ホライズン
            % input_sequence: 制御入力のシーケンス

            N = prediction_horizon / obj.time_step; % 予測ホライズンを時間ステップで割る
            h = obj.time_step; % 時間ステップをhとする

            F_matrix = obj.get_F_matrix(prediction_horizon, obj.time_step);
            G_matrix = obj.get_G_matrix(prediction_horizon, obj.time_step);

            vehicle_future_state = F_matrix * [vehicle.position; vehicle.velocity] + G_matrix * input_sequence;
        end

        function acceleration = idm_using_state(obj, vehicle_state, leading_vehicle_state)
            % Intelligent Driver Model (IDM)を使用して車両の加速度を計算
            % vehicle_state: 対象車両の状態 [位置; 速度]
            % leading_vehicle_state: 前方車両の状態 [位置; 速度]

            max_acceleration = vehicle_state(2); % 最大加速度
            desired_velocity = vehicle_state(2); % 参照速度
            min_distance = 2.0; % 最小車間距離
            desired_headway_time = 1.5; % 目標車間時間
            comfort_braking_deceleration = 2.0; % 快適な減速

            distance_to_leading = leading_vehicle_state(1) - vehicle_state(1);
            related_velocity = vehicle_state(2) - leading_vehicle_state(2);

            desired_gap = min_distance + desired_headway_time * vehicle_state(2) + (vehicle_state(2) * related_velocity) / (2 * sqrt(max_acceleration * comfort_braking_deceleration));
            acceleration = max_acceleration * (1 - (vehicle_state(2) / desired_velocity)^4 - (desired_gap / distance_to_leading)^2);
        end

        function F_matrix = get_F_matrix(obj, prediction_horizon, time_step)
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

        function G_matrix = get_G_matrix(obj, prediction_horizon, time_step)
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

