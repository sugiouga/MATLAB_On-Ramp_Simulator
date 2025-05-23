classdef VehicleManager<handle
    % VehicleManager: Vehicleを管理するユーティリティクラス
    properties(GetAccess = public, SetAccess = private)
        mainline_vehicles = dictionary(); % 本線に存在する車両の辞書
        onramp_vehicles = dictionary(); % 合流車線に存在する車両の辞書
    end

    methods(Static)
        function generate_vehicle_in_lane(obj, vehicle_type, controller, lane_id, distance)
            % 車両を追加
            % vehicle_type: 車両タイプ
            % controller: 車両の制御器
            % lane_id: 車両が存在するレーンのID
            % distance: 車間距離
            lane = lane_id;
            if strcmp(lane_id, 'Mainline')
                mainline_vehicle_id = length(obj.mainline_vehicles) + 1;

                if mainline_vehicle_id == 1
                    init_position = lane.END_POSITION;
                else
                    init_position = obj.mainline_vehicles(mainline_vehicle_id - 1).position - distance;
                end

                mainline_vehicle = Vehicle(sprintf('MainLine_Vehicle_%d', mainline_vehicle_id), vehicle_type, init_position, lane.REFERENCE_VELOCITY, controller);
                lane.add_vehicle(mainline_vehicle);
                obj.mainline_vehicles(mainline_vehicle.VEHICLE_ID) = mainline_vehicle;
            elseif strcmp(lane_id, 'Onramp')
                onramp_vehicle_id = length(obj.onramp_vehicles) + 1;

                if onramp_vehicle_id == 1
                    init_position = lane.START_POSITION;
                else
                    init_position = obj.onramp_vehicles(onramp_vehicle_id - 1).position - distance;
                end

                onramp_vehicle = Vehicle(sprintf('Onramp_Vehicle_%d', onramp_vehicle_id), vehicle_type, init_position, lane.REFERENCE_VELOCITY, controller);
                lane.add_vehicle(onramp_vehicle);
                obj.onramp_vehicles(onramp_vehicle.VEHICLE_ID) = onramp_vehicle;
            else
                error('Unknown lane ID');
            end
        end

        function vehicles = get_vehicles_in_lane(obj, lane_id)
            % 車両を取得
            % lane_id: 車両が存在するレーンのID
            if strcmp(lane_id, 'Mainline')
                vehicles = obj.mainline_vehicles;
            elseif strcmp(lane_id, 'Onramp')
                vehicles = obj.onramp_vehicles;
            else
                error('Unknown lane ID');
            end
        end

        function update_vehicle_in_lane(obj, lane_id)
            % 車両を更新
            % lane_id: 車両が存在するレーンのID
            if strcmp(lane_id, 'Mainline')
                vehicles = obj.mainline_vehicles;
            else strcmp(lane_id, 'Onramp')
                vehicles = obj.onramp_vehicles;
            end

            for vehicle = vehicles.values()
                % 車両の状態を更新
                % 車両の加速度を制御器に基づいて更新
                if isempty(vehicle.controller)
                    % 制御器が設定されていない場合は，加速度を参照速度に追従するように設定
                    if vehicle.velocity < vehicle.lane.REFERENCE_VELOCITY
                        vehicle.change_input_acceleration(vehicle.lane.REFERENCE_VELOCITY - vehicle.velocity);
                    else
                        vehicle.change_input_acceleration(0);
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
                vehicle.update_state();

                % 車線合流の処理
                if strcmp(lane_id, 'Onramp')
                    % 車両が合流車線の終了位置を超えた場合
                    if vehicle.position > lane.END_POSITION
                        vehicle.change_lane_id('Mainline');
                        obj.mainline_vehicles(vehicle.VEHICLE_ID) = vehicle;
                        obj.onramp_vehicles.remove(vehicle.VEHICLE_ID);
                        Mainline.add_vehicle(vehicle);
                        Onramp.remove_vehicle(vehicle.VEHICLE_ID);
                    end
                end
            end
        end
    end
end