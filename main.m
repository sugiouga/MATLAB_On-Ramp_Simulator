clear
close all
clc

% レーンの設定
mainline_start_position = -200; % 本線の開始位置 (m)
mainline_end_position = 400; % 本線の終了位置 (m)
mainline_reference_velocity = 20; % 本線の参照速度 (m/s)
onramp_start_position = -200; % 合流車線の開始位置 (m)
onramp_end_position = 300; % 合流車線の終了位置 (m)
onramp_reference_velocity = 15; % 合流車線の参照速度 (m/s)

% レーンオブジェクトの作成
mainline = Lane('Mainline', mainline_start_position, mainline_end_position, mainline_reference_velocity);
onramp = Lane('On-ramp', onramp_start_position, onramp_end_position, onramp_reference_velocity);

% 車両管理オブジェクトの作成
vehicle_manager = VehicleManager(mainline, onramp);

initial_headway = [0 3 3 3 8 3 3 3]; % 初期車間距離 (秒)
% 車両の生成
for i = 1 : length(initial_headway)
    % 本線に車両を追加
    mainline_vehicle_type = 'car'; % 車両タイプ
    mainline_controller = 'IDM'; % 車両の制御器
    mainline_distance = initial_headway(i) * mainline_reference_velocity; % 車間距離を生成
    vehicle_manager.generate_vehicle_in_lane(mainline_vehicle_type, mainline_controller, 'Mainline', mainline_distance);
end

for i = 1 : 1
    % 合流車線に車両を追加
    onramp_vehicle_type = 'car'; % 車両タイプ
    onramp_controller = 'MPC'; % 車両の制御器
    onramp_distance = 100; % 車間距離 (m)
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
                case 'IDM'
                    % IDMモデルを使用している場合
                    leading_vehicle = vehicle_manager.find_leading_vehicle_in_lane(vehicle, vehicle.lane_id);
                    vehicle.change_input_acceleration(controller.idm(vehicle, leading_vehicle));
                case 'MOBIL'
                    % MOBILモデルを使用している場合
                    if vehicle.position > 0 && vehicle.isMergelane == false
                        % 合流車線の車両の場合は、MOBILモデルを適用
                        controller.mobil(vehicle, 0.5);
                    else
                        leading_vehicle = vehicle_manager.find_leading_vehicle_in_lane(vehicle, vehicle.lane_id);
                        vehicle.change_input_acceleration(controller.idm(vehicle, leading_vehicle));
                    end
                case 'MPC'
                    % MPCを使用している場合

                    if vehicle.isMergelane == false && vehicle.position > 0
                        % 合流車線の車両で、まだ合流していない場合はMPCを適用
                        controller.mpc(vehicle, 5, 1, 1, 1, 100)
                        if vehicle.position < 0
                            vehicle.change_isMergelane(false);
                        end
                    else
                        leading_vehicle = vehicle_manager.find_leading_vehicle_in_lane(vehicle, vehicle.lane_id);
                        vehicle.change_input_acceleration(controller.idm(vehicle, leading_vehicle));
                    end
            end
        end
    end

    simulation.step(); % シミュレーションのステップを実行

end
