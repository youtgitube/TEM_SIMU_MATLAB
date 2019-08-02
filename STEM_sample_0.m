% ADF-STEM sample: silicon [110]
clc;
close all;
clear all;
%% Lattice generation: silicon [110]
W_B = waitbar(0, 'Preparing the specimen...');

Lattice_Const = [3.8396, 5.4300]; % [a b]
LayerDist = [1.9198, 1.9198]; % distance between each slice
Cell_Num = [3, 2]; % expand the unit cell by Expan_Nx = 3 and Expan_Ny = 2, adaptive
CoordShift = Cell_Num / 2 + 1; % center the lattice
DistError = 1e-2;
% Laters: Each column for an atom
LayerA = [0, 0.5; 0, 0.75];
LayerB = [0, 0.5; 0.25, 0.5];
% Expansion:
LayerA_base = LayerA;
LayerB_base = LayerB;
for i = 1: Cell_Num(1) + 1
    LayerA = [LayerA, [LayerA_base(1, :) + i; LayerA_base(2, :)]];
    LayerB = [LayerB, [LayerB_base(1, :) + i; LayerB_base(2, :)]];
end
LayerA_base = LayerA;
LayerB_base = LayerB;
for i = 1: Cell_Num(2) + 1
    LayerA = [LayerA, [LayerA_base(1, :); LayerA_base(2, :) + i]];
    LayerB = [LayerB, [LayerB_base(1, :); LayerB_base(2, :) + i]];
end
LayerA(1, :) = LayerA(1, :) - CoordShift(1);
LayerA(2, :) = LayerA(2, :) - CoordShift(2);
LayerB(1, :) = LayerB(1, :) - CoordShift(1);
LayerB(2, :) = LayerB(2, :) - CoordShift(2);
[rowA, columnA] = find((LayerA(1, :) <= Cell_Num(1) / 2 + DistError) & (LayerA(1, :) >= -Cell_Num(1) / 2 - DistError) ...
                     & (LayerA(2, :) <= Cell_Num(2) / 2 + DistError) & (LayerA(2, :) >= -Cell_Num(2) / 2 - DistError));
LayerA = LayerA(:,columnA);
LayerA = (uniquetol(LayerA', DistError, 'ByRows', true))';
LayerA(1, :) = Lattice_Const(1) * LayerA(1, :);
LayerA(2, :) = Lattice_Const(2) * LayerA(2, :);
[rowB, columnB] = find((LayerB(1, :) <= Cell_Num(1) / 2 + DistError) & (LayerB(1, :) >= -Cell_Num(1) / 2 - DistError) ...
                     & (LayerB(2, :) <= Cell_Num(2) / 2 + DistError) & (LayerB(2, :) >= -Cell_Num(2) / 2 - DistError));
LayerB = LayerB(:,columnB);
LayerB = (uniquetol(LayerB', DistError, 'ByRows', true))';
LayerB(1, :) = Lattice_Const(1) * LayerB(1, :);
LayerB(2, :) = Lattice_Const(2) * LayerB(2, :);
%% basic settings
% sampling:
Lx = Cell_Num(1) * Lattice_Const(1);
Ly = Cell_Num(2) * Lattice_Const(2);
Nx = 512;
Ny = 512;
dx = Lx / Nx;
dy = Ly / Ny;
x = -Lx / 2 : dx : Lx / 2 - dx;
y = -Ly / 2 : dy : Ly / 2 - dy;
[X, Y] = meshgrid(x, y);
fx = -1 / (2 * dx) : 1 / Lx : 1 / (2 * dx) - 1 / Lx;
fy = -1 / (2 * dy) : 1 / Ly : 1 / (2 * dy) - 1 / Ly;
[Fx, Fy] = meshgrid(fx, fy);
% STEM settings:
Params.KeV = 200;
InterCoeff = InteractionCoefficient(Params.KeV);
WaveLength = 12.3986 / sqrt((2 * 511.0 + Params.KeV) * Params.KeV);  %wavelength
WaveNumber = 2 * pi / WaveLength;     %wavenumber
Params.amax = 10.37;
Params.Cs = 1.3;
Params.df = 600;

detector = Fx.^2 + Fy.^2;
detector_cri = detector;
HighAngle = 200 * 0.001;
LowAngle = 40 * 0.001;
detector((detector_cri > (sin(LowAngle) / WaveLength)^2) & (detector_cri < (sin(HighAngle) / WaveLength)^2)) = 1;
detector((detector_cri < (sin(LowAngle) / WaveLength)^2) | (detector_cri > (sin(HighAngle) / WaveLength)^2)) = 0;
%% Transmission functions
% Layer A:
Proj_PotA = ProjectedPotential(Lx, Ly, Nx, Ny, 14 * ones(size(LayerA, 2), 1), LayerA(1, :), LayerA(2, :));
% Layer B:
Proj_PotB = ProjectedPotential(Lx, Ly, Nx, Ny, 14 * ones(size(LayerB, 2), 1), LayerB(1, :), LayerB(2, :));
% test
figure;
imagesc(x, y, Proj_PotA);
colormap('gray');
figure;
imagesc(x, y, Proj_PotB);
colormap('gray');

TF_A = exp(1i * InterCoeff * Proj_PotA / 1000);
TF_B = exp(1i * InterCoeff * Proj_PotB / 1000);
TF_A = BandwidthLimit(TF_A, Lx, Ly, Nx, Ny, 0.67);
TF_B = BandwidthLimit(TF_B, Lx, Ly, Nx, Ny, 0.67);
TransFuncs(:, :, 1) = TF_A;
TransFuncs(:, :, 2) = TF_B;

waitbar(0, W_B, 'Specimen preparation completed, start scanning...');
%% Scanning module
% Scanning parameters:
Scan_Nx = 16; % scanning sampling number, adaptive
Scan_Ny = 16;
Scan_Lx = Lx / 1.5; % scanning side length, adaptive
Scan_Ly = Ly / 1.5;
Scan_dx = Scan_Lx / Scan_Nx;
Scan_dy = Scan_Ly / Scan_Ny;
ADF_x = -Scan_Lx / 2 : Scan_dx : Scan_Lx / 2 - Scan_dx;
ADF_y = -Scan_Ly / 2 : Scan_dy : Scan_Ly / 2 - Scan_dy;
STEM_IMAGE = zeros(Scan_Ny, Scan_Nx);
figure;
StackNum = 20; % determines the thickness of the specimen
TotalNum = Scan_Ny * Scan_Nx;
for i=1:Scan_Ny
    yp = ADF_y(i);
    for j=1:Scan_Nx
        xp = ADF_x(j);
        Probe = ProbeCreate(Params, xp, yp, Lx, Ly, Nx, Ny);
        Trans_Wave = multislice(Probe, WaveLength, Lx, Ly, TransFuncs, LayerDist, StackNum);
        Trans_Wave_Far = ifftshift(fft2(fftshift(Trans_Wave))*dx^2);
        DetectInten = abs(Trans_Wave_Far.^2).*detector;
        STEM_IMAGE(i,j) = sum(sum(DetectInten));
        CurrentNum = (i - 1) * Scan_Nx + j;
        imagesc(x, -y, STEM_IMAGE);
        map = colormap(gray);
        axis square;
        title('Example');
        drawnow;
        % Save gif to local directory
%         F = getframe(gcf); 
%         I = frame2im(F); 
%         [I, map] = rgb2ind(I, 256); 
%         if CurrentNum == 1 
%             imwrite(I,map,'D:\Francis. B. Lee\Practice\Conventional Multislice in MATLAB\Specimen_Thickness\Secret\secret.gif','gif','Loopcount',inf,'DelayTime',0.02); 
%         else
%             imwrite(I,map,'D:\Francis. B. Lee\Practice\Conventional Multislice in MATLAB\Specimen_Thickness\Secret\secret.gif','gif','WriteMode','append','DelayTime',0.02); 
%         end
        waitbar(roundn(CurrentNum / TotalNum, -3), W_B, [num2str(roundn((CurrentNum / TotalNum), -3) * 100), '%']);
    end
end
delete(W_B);