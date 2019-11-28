%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   Copyright (C) 2019  Francis Black Lee and Li Xian

%   This program is free software: you can redistribute it and/or modify
%   it under the terms of the GNU General Public License as published by
%   the Free Software Foundation, either version 3 of the License, or
%   (at your option) any later version.

%   This program is distributed in the hope that it will be useful,
%   but WITHOUT ANY WARRANTY; without even the implied warranty of
%   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%   GNU General Public License for more details.

%   You should have received a copy of the GNU General Public License
%   along with this program.  If not, see <https://www.gnu.org/licenses/>.

%   Email: warner323@outllok.com
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [probe] = GenerateProbe_X(OTF, xp, yp, Lx, Ly, Nx, Ny)
%GenerateProbe_X.m generates an electron probe.
%   OTF -- prepared objective transfer function in reciprocal space;
%   Lx, Ly, Nx, Ny -- sampling parameters, L denotes side length and N the
%       sampling number in real space;
%   xp, yp -- probe position in real space;
% Note: X denotes an experimental version!

dx = Lx / Nx;
dy = Ly / Ny;
fx = -1 / (2 * dx) : 1 / Lx : 1 / (2 * dx) - 1 / Lx;
fy = -1 / (2 * dy) : 1 / Ly : 1 / (2 * dy) - 1 / Ly;
[FX, FY] = meshgrid(fx, fy);
probe = ifftshift(ifft2(fftshift(OTF .* exp(-1i * 2 * pi * (FX * xp + FY * yp)))));

NormCoeff = sqrt(sum(sum(abs(probe.^2))) * dx * dy);
probe = probe / NormCoeff;

end
