clear
close all
clc

% レーンの設定
mainline_start_position = -200; % 本線の開始位置 (m)
mainline_end_position = 400; % 本線の終了位置 (m)
mainline_reference_velocity = 25; % 本線の参照速度 (m/s)
onramp_start_position = -200; % 合流車線の開始位置 (m)
onramp_end_position = 300; % 合流車線の終了位置 (m)
onramp_reference_velocity = 20; % 合流車線の参照速度 (m/s)

% レーンオブジェクトの作成
mainline = Lane('Mainline', mainline_start_position, mainline_end_position, mainline_reference_velocity);
onramp = Lane('On-ramp', onramp_start_position, onramp_end_position, onramp_reference_velocity);

% 車両管理オブジェクトの作成
vehicle_manager = VehicleManager(mainline, onramp);

% 車両の生成
for i = 1 : 16
    % 本線に車両を追加
    mainline_vehicle_type = 'car'; % 車両タイプ
    mainline_controller = 'IDM'; % 車両の制御器
    mainline_distance = 150 - 80*rand; % 車間距離を生成
    vehicle_manager.generate_vehicle_in_lane(mainline_vehicle_type, mainline_controller, 'Mainline', mainline_distance);
end

for i = 1 : 1
    % 合流車線に車両を追加
    onramp_vehicle_type = 'car'; % 車両タイプ
    onramp_controller = 'MOBIL'; % 車両の制御器
    onramp_distance = 80; % 車間距離 (m)
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
            if vehicle.velocity == vehicle.reference_velocity
                vehicle.change_input_acceleration(0);
            else
                acceleration = (vehicle.reference_velocity - vehicle.velocity) / simulation.time_step;
                vehicle.change_input_acceleration(acceleration);
            end
        else
            switch vehicle.controller
                case 'IDM'
                    % IDMモデルを使用している場合
                    leading_vehicle = vehicle_manager.find_leading_vehicle_in_lane(vehicle, vehicle.lane_id);
                    vehicle.change_input_acceleration(controller.idm(vehicle, leading_vehicle));
                case 'MOBIL'
                    % MOBILモデルを使用している場合
                    if vehicle.position > 0 && strcmp(vehicle.lane_id, 'On-ramp')
                        % 合流車線の車両の場合は、MOBILモデルを適用
                        controller.mobil(vehicle, 0.5);
                    else
                        leading_vehicle = vehicle_manager.find_leading_vehicle_in_lane(vehicle, vehicle.lane_id);
                        vehicle.change_input_acceleration(controller.idm(vehicle, leading_vehicle));
                    end
            end
        end
    end

    simulation.step(); % シミュレーションのステップを実行

end
