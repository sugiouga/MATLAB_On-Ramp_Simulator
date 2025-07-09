clear
close all
clc

% レーンの設定
mainline_start_position = -100; % 本線の開始位置 (m)
mainline_end_position = 500; % 本線の終了位置 (m)
mainline_reference_velocity = 25; % 本線の参照速度 (m/s)
onramp_start_position = -100; % 合流車線の開始位置 (m)
onramp_end_position = 300; % 合流車線の終了位置 (m)
onramp_reference_velocity = 20; % 合流車線の参照速度 (m/s)

% レーンオブジェクトの作成
mainline = Lane('Mainline', mainline_start_position, mainline_end_position, mainline_reference_velocity);
onramp = Lane('On-ramp', onramp_start_position, onramp_end_position, onramp_reference_velocity);

% 車両管理オブジェクトの作成
vehicle_manager = VehicleManager(mainline, onramp);

% initial_headway = [0 2.5 3 3 8 3 3]; % 初期車間距離 (秒)
% initial_headway = [3.5 5.5 8 3 6 2 4 5];% 車両の生成
initial_headway = [0 8 6 6]; % 車両の生成
for i = 1 : length(initial_headway)
    % 本線に車両を追加
    mainline_vehicle_type = 'car'; % 車両タイプ
    mainline_controller = 'IDM'; % 車両の制御器
    mainline_distance = initial_headway(i) * mainline_reference_velocity; % 車間距離を生成
    vehicle_manager.generate_vehicle_in_lane(mainline_vehicle_type, mainline_controller, 'Mainline', mainline_distance);
end

onramp_end_position_vehicle = Vehicle('Onramp_end_position', 'car', onramp_end_position, 0, 'Stop'); % 合流車線の終端に停止車両を追加
onramp.add_vehicle(onramp_end_position_vehicle); % 合流車線の終端に停止車両を追加

initial_headway2 = 0;
% initial_headway2 = [0 3 2 4];
for i = 1 : length(initial_headway2)
    % 合流車線に車両を追加
    onramp_vehicle_type = 'car'; % 車両タイプ
    onramp_controller = 'MPC'; % 車両の制御器
    onramp_distance = 100; % 車間距離を生成
    vehicle_manager.generate_vehicle_in_lane(onramp_vehicle_type, onramp_controller, 'On-ramp', onramp_distance);
end

% シミュレーションオブジェクトの作成
simulation = Simulation(mainline, onramp);

% 車両の制御器の設定
controller = Controller(simulation, vehicle_manager);

while ~simulation.is_end

    vehicles = [mainline.vehicles.values(); onramp.vehicles.values()];
    % 車両の加速度を制御器に基づいて更新
    for vehicle = vehicles'
        % 車両の状態を更新
        % 車両の加速度を制御器に基づいて更新
        if isempty(vehicle.controller)
            % 制御器が設定されていない場合は，加速度を参照速度に追従するように設定
            vehicle.change_input_acceleration(controller.constant_speed(vehicle));
        else
            switch vehicle.controller
                case 'Stop'
                    vehicle.change_input_acceleration(0); % 停止車両の場合は加速度を0に設定
                case 'IDM'
                    % IDMモデルを使用している場合
                    leading_vehicle = vehicle_manager.find_leading_vehicle_in_lane(vehicle, vehicle.lane_id);
                    vehicle.change_input_acceleration(controller.idm(vehicle, leading_vehicle));
                case 'MOBIL'
                    % MOBILモデルを使用している場合
                    if vehicle.position > 0 && vehicle.isMergelane == false
                        % 合流車線の車両の場合は、MOBILモデルを適用
                        controller.mobil(vehicle, 0.1);
                    else
                        leading_vehicle = vehicle_manager.find_leading_vehicle_in_lane(vehicle, vehicle.lane_id);
                        vehicle.change_input_acceleration(controller.idm(vehicle, leading_vehicle));
                    end
                case 'MPC'
                    % MPCを使用している場合

                    if vehicle.isMergelane == false && vehicle.position > 0
                        % 合流車線の車両で、まだ合流していない場合はMPCを適用
                        vehicle.prediction_horizon = 5; % MPCの予測ホライズン (秒)
                        tau_interval = 1;% 合流タイミングの間隔 (秒)
                        weight.position = 0.001; % 位置の重み
                        weight.velocity = 0; % 速度の重み
                        weight.input = 0.1; % 加速度の重み
                        weight.jerk = 0; % ジャークの重み
                        weight.end_position = 0.003; % 合流車線の残りに関するの重み
                        weight.fuel = 1;
                        weight.delta = 0.01; % 減衰の重み

                        if vehicle.mpc_count == 0
                            vehicle.mpc_start_time = simulation.time; % MPCの開始時間を記録
                        end

                        if mod(vehicle.mpc_count, 10*tau_interval) == 0
                            vehicle.mpc_count = 1;
                            [vehicle.optimal_u_sequence, vehicle.optimal_tau vehicle.optimal_gap] = controller.lane_merge_mpc(vehicle, vehicle.prediction_horizon, tau_interval, weight);
                        end

                        vehicle.change_input_acceleration(vehicle.optimal_u_sequence(vehicle.mpc_count));
                        vehicle.mpc_count = vehicle.mpc_count + 1;

                        if vehicle.optimal_tau == 0 && vehicle.optimal_gap == 1
                            vehicle.change_isMergelane(true); % 合流フラグを立てる
                        end

                        headway_time = 3; % 車間距離の目標時間 (秒)
                        leading_vehicle = vehicle_manager.find_leading_vehicle_in_lane(vehicle, 'Mainline');
                        vehicle.target_position = leading_vehicle.position + vehicle.velocity * headway_time; % 目標位置を更新
                    elseif vehicle.isMergelane == true && vehicle.position > 0
                        % 合流車線の車両で、合流済みの場合はMPCを適用
                        vehicle.prediction_horizon = 3; % MPCの予測ホライズン (秒)
                        vehicle.optimal_u_sequence = controller.cruise_control_mpc(vehicle, vehicle.prediction_horizon, weight);
                        vehicle.change_input_acceleration(vehicle.optimal_u_sequence(1));

                        headway_time = 3; % 車間距離の目標時間 (秒)
                        leading_vehicle = vehicle_manager.find_leading_vehicle_in_lane(vehicle, vehicle.lane_id);
                        vehicle.target_position = leading_vehicle.position + vehicle.velocity * headway_time; % 目標位置を更新

                    else
                        leading_vehicle = vehicle_manager.find_leading_vehicle_in_lane(vehicle, vehicle.lane_id);
                        vehicle.change_input_acceleration(controller.idm(vehicle, leading_vehicle));
                    end
            end
        end
    end

    simulation.step(); % シミュレーションのステップを実行

end
