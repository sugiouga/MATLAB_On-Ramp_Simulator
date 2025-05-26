classdef Simulation
    % シミュレーションの起動･ステップの実行･終了を行うクラス
    properties
        % シミュレーションの実行時間
        time = [];
        % シミュレーションの開始時間
        start_time = 0;
        % シミュレーションの終了時間
        end_time = 60;
        % シミュレーションの時間間隔
        time_step = 0.01;
        % シミュレーションのステップ数
        step = 0;

        % シミュレーションの結果を保存するフォルダ
        result_folder = '';

        % シミュレーションの終了フラグ
        isEnd = false;
        % 動画を保存するかどうかのフラグ
        isSaveVideo = True;
    end

    methods

        function obj = Simulation()
            % コンストラクタ
            % シミュレーションの時間を初期化
            obj.time = obj.start_time;

            % 日付時刻を含む結果保存フォルダ名を作成
            timestamp = datestr(now, 'yyyymmdd_HHMMSS');
            obj.result_folder = fullfile('simulation_results', timestamp);
            if ~exist(obj.result_folder, 'dir')
                mkdir(obj.result_folder);
            end

            % 描画の初期化
            obj.init_graphic(obj, Mainline, Onramp);

        end

        function run(obj)
            % シミュレーションの実行
            while ~obj.isEnd
                % シミュレーションのステップを実行
                obj.step_simulation();

                % 時間を更新
                obj.time = obj.time + obj.time_step;

                % 終了条件のチェック
                if obj.time >= obj.end_time
                    obj.isEnd = true;
                end
            end

            % シミュレーションの終了処理
            obj.end_simulation();
        end

    end
end