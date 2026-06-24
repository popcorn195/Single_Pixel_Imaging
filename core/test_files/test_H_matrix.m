% p : base speckle pattern size (16, 32, 64)
% Mx : effective imaging area width
% My : effective imaging area height
% Nx : subpixel shifts in x (2, 4, 8)
% Ny : subpixel shifts in y
% N : number of random speckle patterns

clear;
clc;
close all;

%% Parameters

p = 16;

Nx = 2;
Ny = 2;

binFactor = 8;

Mx = p;
My = p;

%% Generate one speckle pattern

cc = generate_speckle(p);

%% Pixel expansion

c = pixel_bin(cc, binFactor);

Mx_hr = Mx * binFactor;
My_hr = My * binFactor;

%% Figure

figure('Name','Subpixel Shift Visualisation',...
       'Position',[100 100 1400 700]);

frameCount = 1;

for j = 0:Ny

    for i = 0:Nx

        %% Convert shift index to subpixel displacement

        dx = round(i * binFactor / Nx);
        dy = round(j * binFactor / Ny);

        %% Shift

        shifted = zeros(size(c));

        shifted(1+dy:end,1+dx:end) = ...
            c(1:end-dy,1:end-dx);

        %% Effective area extraction

        row_start = floor(size(shifted,1)/2 - My_hr/2) + 1;
        col_start = floor(size(shifted,2)/2 - Mx_hr/2) + 1;

        effective = shifted( ...
            row_start:row_start+My_hr-1,...
            col_start:col_start+Mx_hr-1);

        %% Simulated H row

        H_row = effective(:)';

        H_visual = reshape(H_row,[My_hr,Mx_hr]);

        %% Display

        clf;

        subplot(2,3,1);
        imagesc(cc);
        axis image;
        colormap(gray);
        title('Original Speckle');

        subplot(2,3,2);
        imagesc(c);
        axis image;
        title(sprintf('Pixel Binned (%dx)',binFactor));

        subplot(2,3,3);
        imagesc(shifted);
        axis image;
        title(sprintf('Shifted Pattern\n(dx=%d, dy=%d)',dx,dy));

        subplot(2,3,4);
        imagesc(effective);
        axis image;
        title('Effective Imaging Area');

        subplot(2,3,5);
        imagesc(H_visual);
        axis image;
        title('Corresponding H Row');

        subplot(2,3,6);

        rectangle( ...
            'Position',...
            [col_start,row_start,Mx_hr,My_hr],...
            'EdgeColor','r',...
            'LineWidth',2);

        hold on;
        imagesc(shifted);

        axis image;
        title('Crop Region');

        sgtitle(sprintf( ...
            'Shift (%d,%d)   |   Frame %d / %d',...
            i,j,frameCount,(Nx+1)*(Ny+1)));

        drawnow;

        pause(1);

        frameCount = frameCount + 1;

    end
end