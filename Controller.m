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
                acceleration = (vehicle.reference_velocity - vehicle.velocity) / vehicle.time_step; % 参照速度に追従するように加速度を計算
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
                        vehicle.change_isChangelane(true);
                        vehicle.change_input_acceleration(new_acceleration);
                        return
                    end
                end

                % 車線変更を行わない場合
                vehicle.change_input_acceleration(original_acceleration);

            end

        end

        function mpc(obj, vehicle, prediction_horizon)
            % ゲーム理論に基づくMPCを使用して車両の加速度を計算
            % vehicle: 対象車両オブジェクト
            % prediction_horizon: 予測ホライズン

            tau_feasible_set = 0 : 2*obj.time_step : prediction_horizon; % 予測ホライズンに基づく時間ステップの集合
            end_step = prediction_horizon / obj.time_step; % 予測ホライズンを時間ステップで割る

            total_costs = zeros(size(tau_feasible_set)); % 各時間ステップのコストを格納する配列
            optimal_u_sequences = cell(size(tau_feasible_set)); % 各時間ステップの最適な制御入力を格納するセル配列

            % 車両の周囲の車両を取得
            mainline_leading_vehicle = obj.vehicle_manager.find_leading_vehicle_in_lane(vehicle, 'Mainline');
            mainline_following_vehicle = obj.vehicle_manager.find_following_vehicle_in_lane(vehicle, 'Mainline');
            mainline_following_2nd_vehicle = obj.vehicle_manager.find_following_vehicle_in_lane(mainline_following_vehicle, 'Mainline');
            onramp_leading_vehicle = obj.vehicle_manager.find_leading_vehicle_in_lane(vehicle, 'On-ramp');

            vehicle_state = [vehicle.position; vehicle.velocity]; % 車両の現在の状態
            if ~isempty(onramp_leading_vehicle)
                onramp_leading_vehicle_state = [onramp_leading_vehicle.position; onramp_leading_vehicle.velocity]; % 合流車線の先行車両の状態
            end
            mainline_leading_vehicle_state = [mainline_leading_vehicle.position; mainline_leading_vehicle.velocity]; % 本線の先行車両の状態
            mainline_following_vehicle_state = [mainline_following_vehicle.position; mainline_following_vehicle.velocity]; % 本線の後続車両の状態
            mainline_following_2nd_vehicle_state = [mainline_following_2nd_vehicle.position; mainline_following_2nd_vehicle.velocity]; % 本線の2番目の後続車両の状態

            for tau_idx = 1:length(tau_feasible_set)
                current_tau = tau_feasible_set(tau_idx);

                if ~isempty(mainline_leading_vehicle)
                    mainline_leading_vehicle_future_state = obj.predict_vehicle_future_state(mainline_leading_vehicle, prediction_horizon, zeros(end_step, 1)); % 本線の先行車両の未来の状態を予測
                end

                % 入力に関する制約を設定
                u0_sequence = zeros(end_step, 1);
                lb = vehicle.MIN_ACCELERATION * ones(end_step, 1); % 制御入力の下限
                ub = vehicle.MAX_ACCELERATION * ones(end_step, 1); % 制御入力の上限

                objective_function = @(u_sequence) sum(u_sequence.^2); % 評価関数を定義

                nonlcon = @safety_distance; % 非線形制約関数

                [optimal_u_sequence, cost] = fmincon(objective_function, u0_sequence, [], [], [], [], lb, ub, nonlcon);

                total_costs(tau_idx) = cost; % 各時間ステップのコストを格納
                optimal_u_sequences{tau_idx} = optimal_u_sequence; % 各時間ステップの最適な制御入力を格納
            end

            % 最小コストの時間ステップを選択
            [~, min_cost_index] = min(total_costs);

            optimal_tau = tau_feasible_set(min_cost_index); % 最小コストの時間ステップを取得
            optimal_u_sequence = optimal_u_sequences{min_cost_index}; % 最小コストの制御入力シーケンスを取得

            if optimal_tau == 0
                vehicle.change_isChangelane(true); % 車線変更を行わない
            end
            vehicle.change_input_acceleration(optimal_u_sequence(1)); % 車両の加速度を更新

            % 安全な車間距離に関する制約条件に関する関数
            function [c, ceq] = safety_distance(u_sequence)
                min_distance = 20;

                onramp_end_position = obj.onramp_end_position; % 合流車線の終端位置

                tau_k = ceil(current_tau / obj.time_step + 1); % 現在のtauを時間ステップで割る
                c_before_tau_k = zeros(tau_k, 1); % tau_kまでの制約条件
                c_after_tau_k = zeros(2*(end_step - tau_k + 1), 1); % tau_k以降の制約条件

                for step = 1 : end_step
                    vehicle_state = obj.predict_vehicle_next_state(vehicle_state, u_sequence(step));
                    if step <= tau_k
                        % 合流車線の先行車両との車間距離制約
                        if ~isempty(onramp_leading_vehicle)
                            onramp_leading_vehicle_state = obj.predict_vehicle_next_state(onramp_leading_vehicle_state, 0); % 合流車線の先行車両の状態を更新
                            if onramp_leading_vehicle_state(1) < onramp_end_position
                                c_before_tau_k(step) = vehicle_state(1) - onramp_leading_vehicle_state(1) + min_distance; % 車間距離の制約
                            else
                                c_before_tau_k(step) = vehicle_state(1) - onramp_end_position; % 合流車線の終端位置を超えない制約
                            end
                        else
                            c_before_tau_k(step) = vehicle_state(1) - onramp_end_position; % 合流車線の終端位置を超えない制約
                        end
                    else
                        if vehicle_state(1) > mainline_following_vehicle_state(1)
                            % 車両が後続車両よりも前にいる場合
                            % 本線の先行車両との車間距離制約
                            mainline_leading_vehicle_state = obj.predict_vehicle_next_state(mainline_leading_vehicle_state, 0); % 本線の先行車両の状態を更新
                            c_after_tau_k(2*(step - tau_k) + 1) = vehicle_state(1) - mainline_leading_vehicle_state(1) + min_distance; % 車間距離の制約
                            % 本線の後続車両との車間距離制約
                            mainline_following_vehicle_state = obj.predict_vehicle_next_state(mainline_following_vehicle_state, obj.idm_using_state(mainline_following_vehicle_state, vehicle_state));
                            c_after_tau_k(2*(step - tau_k) + 2) = mainline_following_vehicle_state(1) - vehicle_state(1) + min_distance; % 後続車両との車間距離の制約
                        else
                            % 車両が後続車両よりも後ろにいる場合
                            % 本線の後続車両との車間距離制約
                            mainline_following_vehicle_state = obj.predict_vehicle_next_state(mainline_following_vehicle_state, 0);
                            c_after_tau_k(2*(step - tau_k) + 1) = vehicle_state(1) - mainline_following_vehicle_state(1) + min_distance; % 後続車との車間距離の制約
                            % 本線の2番目の後続車両との車間距離制約
                            mainline_following_2nd_vehicle_state = obj.predict_vehicle_next_state(mainline_following_2nd_vehicle_state, obj.idm_using_state(mainline_following_2nd_vehicle_state, vehicle_state));
                            c_after_tau_k(2*(step - tau_k) + 2) = mainline_following_2nd_vehicle_state(1) - vehicle_state(1) + min_distance; % 2番目の後続車両との車間距離の制約
                        end
                    end
                end

                c = [c_before_tau_k; c_after_tau_k]; % 制約条件を結合
                ceq = []; % 等式制約はなし
            end
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

            F_matrix = get_F_matrix(prediction_horizon, obj.time_step);
            G_matrix = get_G_matrix(prediction_horizon, obj.time_step);

            vehicle_future_state = F_matrix * [vehicle.position; vehicle.velocity] + G_matrix * input_sequence;

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

    end
end