classdef Map<handle
    % マップクラス
    properties(GetAccess = public, SetAccess = private)
        % マップの基本情報
        MAP_ID = []; % マップID

        Lanes = dictionary; % レーンの辞書
    end

    methods
        function obj = Map(map_id)
            % コンストラクタ
            % マップの基本情報を初期化
            obj.MAP_ID = map_id; % マップID
        end

        function add_lane(obj, lane)
            % レーンをマップに追加
            % lane: レーンオブジェクト
            obj.Lanes(lane.LANE_ID) = lane;
        end
    end
end