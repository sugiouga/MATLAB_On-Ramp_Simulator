classdef Controller<handle
    % Controller: シミュレーションの制御を行うクラス
    properties
        time_step = [];
    end

    methods
        function obj = Controller(simulation)
            % コンストラクタ
            obj.time_step = simulation.time_step;
        end

        function idm(obj, vehicle, leading_vehicle)
            % Intelligent Driver Model (IDM)を使用して車両の加速度を計算
            % vehicle: 対象車両オブジェクト
            % leading_vehicle: 前方車両オブジェクト

            if isempty(leading_vehicle)
                % 前方車両がいない場合は、参照速度に追従する
                if vehicle.velocity == vehicle.reference_velocity
                    vehicle.change_input_acceleration(0);
                else
                    acceleration = (vehicle.reference_velocity - vehicle.velocity) / obj.time_step;
                    vehicle.change_input_acceleration(acceleration);
                end
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

            vehicle.change_input_acceleration(acceleration);
        end
    end
end