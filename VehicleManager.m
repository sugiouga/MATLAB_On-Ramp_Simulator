classdef VehicleManager<handle
    % VehicleManager: Vehicleを管理するユーティリティクラス

    properties(GetAccess = public, SetAccess = private)
        mainline_vehicle_id = []; % 本線の車両ID
        onramp_vehicle_id = []; % 合流車線の車両ID
    end

    methods

        function obj = VehicleManager()
            % コンストラクタ
            % 車両IDを初期化
            obj.mainline_vehicle_id = 0;
            obj.onramp_vehicle_id = 0;
        end

        function generate_vehicle_in_lane(obj, vehicle_type, controller, lane, distance)
            % 車両を追加
            % vehicle_type: 車両タイプ
            % controller: 車両の制御器
            % lane: レーンオブジェクト
            % distance: 車間距離
            if strcmp(lane.LANE_ID, 'Mainline')
                obj.mainline_vehicle_id = obj.mainline_vehicle_id + 1;

                if obj.mainline_vehicle_id == 1
                    init_position = lane.end_position;
                else
                    init_position = lane.vehicles(sprintf('Mainline_vehicle_%d', obj.mainline_vehicle_id - 1)).position - distance;
                end

                mainline_vehicle = Vehicle(sprintf('Mainline_vehicle_%d', obj.mainline_vehicle_id), vehicle_type, init_position, lane.reference_velocity, controller);
                lane.add_vehicle(mainline_vehicle);
            elseif strcmp(lane.LANE_ID, 'On-ramp')
                obj.onramp_vehicle_id = obj.onramp_vehicle_id + 1;

                if obj.onramp_vehicle_id == 1
                    init_position = lane.start_position;
                else
                    init_position = lane.vehicles(sprintf('On-ramp_vehicle_%d', obj.onramp_vehicle_id - 1)).position - distance;
                end

                onramp_vehicle = Vehicle(sprintf('On-ramp_vehicle_%d', obj.onramp_vehicle_id), vehicle_type, init_position, lane.reference_velocity, controller);
                lane.add_vehicle(onramp_vehicle);
            else
                error('Unknown LANE ID');
            end
        end

    end
end