classdef VehicleManager<handle
    % VehicleManager: Vehicleを管理するユーティリティクラス
    properties(GetAccess = public, SetAccess = private)
        all_vehicles = dictionary(); % 本線に存在する車両の辞書
    end

    methods(Static)
        function generate_vehicle_in_lane(obj, vehicle_type, controller, lane, distance)
            % 車両を追加
            % vehicle_type: 車両タイプ
            % controller: 車両の制御器
            % lane: レーンオブジェクト
            % distance: 車間距離
            if strcmp(lane.LANE_ID, 'Mainline')
                mainline_vehicle_id = length(lane.vehicles) + 1;

                if mainline_vehicle_id == 1
                    init_position = lane.end_position;
                else
                    init_position = lane.vehicles(mainline_vehicle_id - 1).position - distance;
                end

                mainline_vehicle = Vehicle(sprintf('MainLine_Vehicle_%d', mainline_vehicle_id), vehicle_type, init_position, lane.reference_velocity, controller);
                lane.add_vehicle(mainline_vehicle);
                obj.mainline_vehicles(mainline_vehicle.VEHICLE_ID) = mainline_vehicle;
            elseif strcmp(lane.LANE_ID, 'Onramp')
                onramp_vehicle_id = length(lane.vehicles) + 1;

                if onramp_vehicle_id == 1
                    init_position = lane.start_position;
                else
                    init_position = obj.onramp_vehicles(onramp_vehicle_id - 1).position - distance;
                end

                onramp_vehicle = Vehicle(sprintf('Onramp_Vehicle_%d', onramp_vehicle_id), vehicle_type, init_position, lane.reference_velocity, controller);
                lane.add_vehicle(onramp_vehicle);
                obj.onramp_vehicles(onramp_vehicle.VEHICLE_ID) = onramp_vehicle;
            else
                error('Unknown LANE ID');
            end
        end

        function update_vehicle_status(obj, vehicle, time_step)
            % 車両を更新
            % vehicle: 車両オブジェクト
            % time_step: 時間ステップ

            for vehicle = vehicles.values()
                % 車両の状態を更新
                % 車両の加速度を制御器に基づいて更新
                if isempty(vehicle.controller)
                    % 制御器が設定されていない場合は，加速度を参照速度に追従するように設定
                    if vehicle.velocity == vehicle.lane.reference_velocity
                        vehicle.change_input_acceleration(0);
                    else
                        acceleration = (vehicle.lane.reference_velocity - vehicle.velocity) / time_step;
                        vehicle.change_input_acceleration(acceleration);
                    end
                end

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

                % 車両の状態を更新
                vehicle.update_state(time_step);

                % 車線合流の処理
                if strcmp(vehicle.lane_id, 'Onramp')
                    % 車両が合流車線の終了位置を超えた場合
                    if vehicle.position > lane.end_position
                        vehicle.change_lane_id('Mainline');
                        Mainline.add_vehicle(vehicle);
                        Onramp.remove_vehicle(vehicle.VEHICLE_ID);
                    end
                end
            end
        end
    end
end