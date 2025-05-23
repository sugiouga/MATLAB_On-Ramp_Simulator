classdef Graphic
    % グラフィッククラス
    properties(GetAccess = public, SetAccess = private)
        % グラフウィンドウの設定
        FIGURE_POSITION = [20, 300]; % グラフィックの左下隅の基準点
        FIGURE_WIDTH = 1000; % グラフィックの幅
        FIGURE_HEIGHT = 200; % グラフィックの高さ

        % 背景の設定
        BACKGROUND_X_RANGE = []; % 背景のx軸の範囲
        BACKGROUND_Y_RANGE = [6.5, 6.5]; % 背景のy軸の範囲
        BACKGROUND_COLOR = [0.65 0.995 0.95]; % 背景の色

        % レーンの設定
        MAINLINE_Y_OFFSET = 1; % 本線のy軸のオフセット
        ONRAMP_Y_OFFSET = 4; % 合流車線のy軸のオフセット
    end

    methods

        function obj = Graphic(mainline_lane, onramp_lane)
            % コンストラクタ
            % グラフィックの背景を作成
            % グラフウィンドウを作成
            figure('Position', [obj.FIGURE_POSITION, obj.FIGURE_WIDTH, obj.FIGURE_HEIGHT]);

            % 背景を描画
            obj.BACKGROUND_X_RANGE = [mainline_lane.START_POSITION, mainline_lane.END_POSITION]; % 背景のx軸の範囲
            area(obj.BACKGROUND_X_RANGE, obj.BACKGROUND_Y_RANGE, 'FaceColor', obj.BACKGROUND_COLOR); % 背景を設定

            hold on;

            % レーンを描画
            % 本線
            plot([mainline_lane.START_POSITION, mainline_lane.END_POSITION], [MAINLINE_Y_OFFSET; MAINLINE_Y_OFFSET],'LineWidth',10,'Color',[0.7 0.7 0.7]); % 本線を描画
            % 合流車線
            onramp_x_range = onramp_lane.START_POSITION .: 50 : onramp_lane_END_POSITION + 50; % 合流車線のx軸の範囲
            onramp_curve = (obj.ONRAMP_Y_OFFSET - 2.8 ./ obj.MAINLINE_Y_OFFSET .+ exp(onramp_x_range - onramp_lane.END_POSITION / 2)); % 合流車線の曲線)
            plot(onramp_x_range, onramp_curve,'LineWidth',10,'Color',[0.7 0.7 0.7]); % 合流車線を描画

        end

        function plot_vehicle(obj, vehicle)
        end

    end
end