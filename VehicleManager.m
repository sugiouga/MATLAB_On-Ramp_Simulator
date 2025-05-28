classdef VehicleManager<handle
    % VehicleManager: Vehicleを管理するユーティリティクラス

    properties(GetAccess = public, SetAccess = private)
        mainline;
        onramp;
        mainline_vehicle_id = []; % 本線の車両ID
        onramp_vehicle_id = []; % 合流車線の車両ID
    end

    methods

        function obj = VehicleManager(mainline, onramp)
            % コンストラクタ
            % レーンオブジェクト
            obj.mainline = mainline; % 本線のレーンオブジェクト
            obj.onramp = onramp; % 合流車線のレーンオブジェクト
            % 車両IDを初期化
            obj.mainline_vehicle_id = 0;
            obj.onramp_vehicle_id = 0;
        end

        function generate_vehicle_in_lane(obj, vehicle_type, controller, lane_id, distance)
            % 車両を追加
            % vehicle_type: 車両タイプ
            % controller: 車両の制御器
            % lane: レーンオブジェクト
            % distance: 車間距離
            if strcmp(lane_id, 'Mainline')
                obj.mainline_vehicle_id = obj.mainline_vehicle_id + 1;

                if obj.mainline_vehicle_id == 1
                    init_position = obj.mainline.end_position;
                else
                    init_position = obj.mainline.vehicles(sprintf('Mainline_vehicle_%d', obj.mainline_vehicle_id - 1)).position - distance;
                end

                mainline_vehicle = Vehicle(sprintf('Mainline_vehicle_%d', obj.mainline_vehicle_id), vehicle_type, init_position, obj.mainline.reference_velocity, controller);
                obj.mainline.add_vehicle(mainline_vehicle);
            elseif strcmp(lane_id, 'On-ramp')
                obj.onramp_vehicle_id = obj.onramp_vehicle_id + 1;

                if obj.onramp_vehicle_id == 1
                    init_position = obj.onramp.start_position;
                else
                    init_position = obj.onramp.vehicles(sprintf('On-ramp_vehicle_%d', obj.onramp_vehicle_id - 1)).position - distance;
                end

                onramp_vehicle = Vehicle(sprintf('On-ramp_vehicle_%d', obj.onramp_vehicle_id), vehicle_type, init_position, obj.onramp.reference_velocity, controller);
                obj.onramp.add_vehicle(onramp_vehicle);
            else
                error('Unknown LANE ID');
            end
        end

        function leading_vehicle = find_leading_vehicle_in_lane(obj, vehicle)
            % 車両の先行車両を見つける
            % vehicle: 対象の車両

            if strcmp(vehicle.lane_id, 'Mainline')
                vehicles = obj.mainline.vehicles.values();
            elseif strcmp(vehicle.lane_id, 'On-ramp')
                vehicles = obj.onramp.vehicles.values();
            end

            leading_vehicle = [];
            for v = vehicles'
                if v.position > vehicle.position
                    leading_vehicle = v; % 先行車両を見つけたら設定
                    break;
                end
            end
        end

    end
end