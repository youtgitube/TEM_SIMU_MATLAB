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
function [ExitWave] = multislice_X(InciWave, KeV, Lx, Ly, TransFuncs, SliceDist, StackNum, ProjPotDir, FileExtension)
%multislice_X.m performs the multislice procedure. See E. J. Kirkland
%Advanced Computing in Electron Microscopy for more details.
%   InciWave -- incident wave;
%   KeV -- Energy of incident electron beam (in KeV);
%   Lx, Ly -- sampling side lengths;
%   TransFuncs -- 3D array including transmission functions,
%       TransFuncs(:, :, i) denotes the ith transmission function. Note
%       that for a bulk (large volume) material possibly containing too
%       many transmission functions, creating such a 3D array might cause
%       memory overflow, thus input TransFuncs = 'files', the program will
%       load projected potential files under the given path (the optional
%       input), considering that for such bulk materials, these slices do
%       not need to be looped, these files are only loaded once.
%   SliceDist -- array whose elements are distances from the identically
%       indexed slice to the next slice;
%   StackNum -- number of stackings for the slices;
%   ProjPotDir -- directory where the projected potential (in V-Angs) are
%       stored. Also note that these ProjPot files are named in the same
%       style, name ordering is the same as the slice ordering.
%   FileExtension -- a required input if TransFuncDir is input. '*.txt' is
%       suggested.
%   Note: X denotes an experimental version.

WavLen = 12.3986 / sqrt((2 * 511.0 + KeV) * KeV);
switch nargin
    case 7
        TempWave = fftshift(InciWave);
        SliceNum = length(SliceDist);
        [Ny, Nx] = size(InciWave);
        for SliceIdx = 1 : SliceNum
            ShiftedPropKernels(:, :, SliceIdx) = fftshift(FresnelPropKernel_X(Lx, Ly, Nx, Ny, WavLen, SliceDist(SliceIdx)));
        end
        for StackIdx = 1 : StackNum
            for SliceIdx = 1 : SliceNum
                TempWave = TempWave .* fftshift(TransFuncs(:, :, SliceIdx));
                TempWave = ifft2(ShiftedPropKernels(:, :, SliceIdx) .* fft2(TempWave));
            end
        end
        ExitWave = ifftshift(TempWave);
    otherwise
        if ~isfolder(ProjPotDir)
          errorMessage = sprintf('Error: The following folder does not exist:\n%s', ProjPotDir);
          uiwait(warndlg(errorMessage));
          return;
        end
        InterCoeff = InteractionCoefficient(KeV);
        ProjPotFiles = dir(fullfile(ProjPotDir,FileExtension));
        FileNames = {ProjPotFiles.name}';
        SortedNames = natsortfiles(FileNames);
        TempWave = fftshift(InciWave);
        [Ny, Nx] = size(InciWave);
        for FileIdx = 1 : numel(SortedNames)
            TempProjPot = load(fullfile(ProjPotDir, SortedNames{FileIdx}));
            TempTransFunc = exp(1i * InterCoeff * TempProjPot);
            TempWave = TempWave .* fftshift(TempTransFunc);
            ShiftedPropKernel = fftshift(FresnelPropKernel_X(Lx, Ly, Nx, Ny, WavLen, SliceDist(FileIdx)));
            TempWave = ifft2(ShiftedPropKernel .* fft2(TempWave));
        end
        ExitWave = ifftshift(TempWave);
end

end
