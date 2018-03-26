% FLUID
% Free Fluid Flux-Barriers Rotor for Synchronous Reluctance Motor Drawing
%
% Bacco, Giacomo 2018

clear all; close all; clc;
addpath(genpath('./'))


%% DATA
rotor.p = 2; % number of pole pairs
mm = 1e-3; % millimeters
rotor.Nb = 3; % number of flux-barriers
rotor.tb = [4 8 15]*mm; % flux-barrier widths
rotor.wc = [3 7 12 10]*mm; % flux-carrier widths
rotor.Nstep = [2, 4, 6]; % number of steps to draw the flux-barrier side

rotor.De = 200*mm; % [m], rotor outer diameter
rotor.wrib_t = 1*mm; % [m], tangential iron rib width
rotor.barrier_angles_el = [14,26,38]*2; % [deg], electrical flux-barrier angles
 rotor.barrier_end = 'rect'; % choose 'rect' or comment

rotor.wrib = [1,2,4]*mm; % [m], radial iron rib widths


%% barrier points computation
barrier = calc_fluid_barrier(rotor);


%% simple matlab plot
figure
hold all
axis equal
for bkk = 1:rotor.Nb
  plot(barrier(bkk).X, barrier(bkk).Y, '.-')
end
axis auto 

%% FEMM drawing

openfemm(1)
newdocument(0);

draw_fluid_barrier(barrier)

