classdef Simulation
    % シミュレーションの起動･ステップの実行･終了を行うクラス
    properties
        % シミュレーションの実行時間
        time = [];
        % シミュレーションの開始時間
        START_TIME = 0;
        % シミュレーションの終了時間
        END_TIME = 60;
        % シミュレーションの時間間隔
        TIME_STEP = 0.01;
        % シミュレーションの終了フラグ
        isEnd = false;
        % 動画を保存するかどうかのフラグ
        isSaveVideo = True;
    end

    methods

        function obj = Simulation()
            % コンストラクタ
            % シミュレーションの時間を初期化
            obj.time = obj.START_TIME;

        end

    end
end