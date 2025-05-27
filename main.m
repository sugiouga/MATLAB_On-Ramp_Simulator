clear
close all

% レーンの設定
mainline_start_position = 0; % 本線の開始位置 (m)
mainline_end_position = 500; % 本線の終了位置 (m)
mainline_reference_velocity = 20; % 本線の参照速度 (m/s)
onramp_start_position = 0; % 合流車線の開始位置 (m)
onramp_end_position = 400; % 合流車線の終了位置 (m)
onramp_reference_velocity = 20; % 合流車線の参照速度 (m/s)

% レーンオブジェクトの作成
mainline = Lane('Mainline', mainline_start_position, mainline_end_position, mainline_reference_velocity);
onramp = Lane('On-ramp', onramp_start_position, onramp_end_position, onramp_reference_velocity);

VehicleManager = VehicleManager(); % 車両管理オブジェクトの作成

% 車両の生成
for i = 1 : 16
    % 本線に車両を追加
    mainline_vehicle_type = 'car'; % 車両タイプ
    mainline_controller = []; % 車両の制御器
    mainline_distance = 150 - 100*rand; % 車間距離 (m)
    VehicleManager.generate_vehicle_in_lane(mainline_vehicle_type, mainline_controller, mainline, mainline_distance);
end

for i = 1 : 1
    % 合流車線に車両を追加
    onramp_vehicle_type = 'car'; % 車両タイプ
    onramp_controller = []; % 車両の制御器
    onramp_distance = 50; % 車間距離 (m)
    VehicleManager.generate_vehicle_in_lane(onramp_vehicle_type, onramp_controller, onramp, onramp_distance);
end

% シミュレーションオブジェクトの作成
Simulation = Simulation(mainline, onramp);

while ~Simulation.isEnd

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
                acceleration = (vehicle.reference_velocity - vehicle.velocity) / time_step;
                vehicle.change_input_acceleration(acceleration);
            end
        else
            switch vehicle.controller
                case 'IDM'
                    % IDM制御器を使用している場合
                    vehicle.change_input_acceleration(IDM);
                case 'MPC'
                    % MPC制御器を使用している場合
                    vehicle.change_input_acceleration(MPC);
                otherwise
                    error('Unknown controller type');
            end
        end
    end

    Simulation.step(mainline, onramp); % シミュレーションのステップを実行

end