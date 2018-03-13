% FLUID
% Free Fluid Barriers Rotor for Synchronous Reluctance Motor Drawing
%
% Bacco, Giacomo 2018

clear all; close all; clc;
addpath('./tools')
tic

%% DATA
p = 2; % number of pole pairs
mm = 1e-3; % millimeters
Nb = 3; % number of flux-barriers
tb = [4 7 15]*mm; % flux-barrier widths
wc = [3 6 12 10]*mm; % flux-carrier widths
Nstep = 5; % number of steps to draw the flux-barrier side

Dr = 200*mm; % [m], rotor outer diameter
wrib_t = 1*mm; % [m], tangential iron rib width
Dend = Dr - 2*wrib_t; % [m], flux-barrier end diameter
Dsh = Dend - 2*( sum(tb) + sum(wc) ); % [m], shaft diameter
R0 = Dsh/2; % [m], shaft radius
barrier_angles_el = [14,26,38]*2; % [deg], electrical flux-barrier angles
barrier_angles = barrier_angles_el/p; % [deg], flux-barrier angles

% wm = []
wrib = [1,5,10]*mm; % [m], radial iron rib widths


%% IMPLICIT FUNCTIONS
% definition of fluid past a cylinder functions
psi_fluid = @(rho,xi,rho0) (rho.^2 - rho0^2)./rho.*sin(xi);
phi_fluid = @(rho,xi,rho0) (rho.^2 + rho0^2)./rho.*cos(xi);
xi_fluid  = @(psi,rho,rho0) asin(psi.*rho./(rho.^2 - rho0^2));
rho_fluid = @(psi,xi,rho0) ( psi + sqrt(psi.^2 + 4*sin(xi).^2*rho0^2) )./(2*sin(xi));

r_map = @(rho) rho.^(1/p);
th_map = @(xi) xi./p;
rho_map = @(r) r.^p;
xi_map = @(th) th.*p;

vr = @(r,th,R0) p*(r.^(p-1) - R0^(2*p)./r.^(p+1)).*cos(p*th);
vt = @(r,th,R0) -p*(r.^(p-1) + R0^(2*p)./r.^(p+1)).*sin(p*th);
vx = @(vr_v,vth_v,th) vr_v.*cos(th) - vth_v.*sin(th);
vy = @(vr_v,vth_v,th) vr_v.*sin(th) + vth_v.*cos(th);



%% Precomputations
rho0 = rho_map(R0);

%% Central base points
RA = Dend/2 - [0, cumsum( tb(1:end-1))] - cumsum(wc(1:end-1)); % top
RB = RA - tb; % bottom
te_qAxis = pi/(2*p); % q-axis angle in rotor reference frame

% get A' and B' considering rib and magnet widths
mCentral = tan(te_qAxis); % slope
qCentral = repmat( -wrib/2/cos(te_qAxis), 1, 2); % intercept

psiCentralPtA = psi_fluid(rho_map(RA), xi_map(te_qAxis), rho0);
psiCentralPtB = psi_fluid(rho_map(RB), xi_map(te_qAxis), rho0);
psiCentralPt = [psiCentralPtA, psiCentralPtB];
psiA = psiCentralPtA;
psiB = psiCentralPtB;

CentralPt_Eq = @(th) ...
  r_map( rho_fluid(psiCentralPt, th, rho0) ).*...
  ( sin(th) - mCentral*cos(th) ) - qCentral;

options.Display = 'off'; % turn off folve display
options.Algorithm = 'levenberg-marquardt'; % non-square systems
options.FunctionTolerance = 10*eps;
options.StepTolerance = 1e4*eps;

X0 = repmat(te_qAxis,1,2*Nb);
options = GetFSolveOptions(options);
teABprime = fsolve(CentralPt_Eq, X0, options);
teAprime = teABprime(1:Nb);
teBprime = teABprime(Nb+1:end);


%% Outer base points C (top)
aph_b = barrier_angles*pi/180;
te_b = pi/2/p - aph_b;
xb = Dend/2*cos(te_b);
yb = Dend/2*sin(te_b);

options.Algorithm = 'trust-region-dogleg'; % non-square systems

BarrierEndSystem = @(th,xd,yd,xo,yo,R) ...
  [xd - r_map(rho_fluid(psiA', p*th, rho0)).*cos( th )
   yd - r_map(rho_fluid(psiA', p*th, rho0)).*sin( th )
  (xd - xo).^2 + (yd - yo).^2 - R.^2
  (xb' - xo).^2 + (yb' - yo).^2 - R.^2
  (xo - xd).*vx( vr( r_map(rho_fluid(psiA', p*th, rho0)),th,R0 ), vt( r_map(rho_fluid(psiA', p*th, rho0)) ,th,R0 ), th) + (yo - yd).*vy(  vr( r_map(rho_fluid(psiA', p*th, rho0)),th,R0 ), vt( r_map(rho_fluid(psiA', p*th, rho0)) ,th,R0 ), th)
  (xo - xb').*yb' - (yo - yb').*xb'
%   th - xi_fluid((rho_fluid(p*th, psi_d, rho0)), psi_d, rho0)/p % serve?
  ];

X0 = [ te_b', 0*xb', 0*yb', 0*xb', 0*yb', 0*xb'];
% X0 = [ aph_b, 0, 0, 0, 0, 0];
X = fsolve( @(x) BarrierEndSystem( x(:,1),x(:,2),x(:,3),x(:,4),x(:,5),x(:,6) ), X0, options);

xOC = X(:,4);
yOC = X(:,5);
xC = X(:,2);
yC = X(:,3);


%% Outer base points D (bottom)
aph_b = barrier_angles*pi/180;
te_b = pi/2/p - aph_b;
xb = Dend/2*cos(te_b);
yb = Dend/2*sin(te_b);

options.Algorithm = 'levenberg-marquardt'; % non-square systems

BarrierEndSystem = @(th,xd,yd,xo,yo,R) ...
  [xd - r_map(rho_fluid(psiB', p*th, rho0)).*cos( th )
   yd - r_map(rho_fluid(psiB', p*th, rho0)).*sin( th )
  (xd - xo).^2 + (yd - yo).^2 - R.^2
  (xb' - xo).^2 + (yb' - yo).^2 - R.^2
  (xo - xd).*vx( vr( r_map(rho_fluid(psiB', p*th, rho0)),th,R0 ), vt( r_map(rho_fluid(psiB', p*th, rho0)) ,th,R0 ), th) + (yo - yd).*vy(  vr( r_map(rho_fluid(psiB', p*th, rho0)),th,R0 ), vt( r_map(rho_fluid(psiB', p*th, rho0)) ,th,R0 ), th)
  (xo - xb').*yb' - (yo - yb').*xb'
%   th - xi_fluid((rho_fluid(p*th, psi_d, rho0)), psi_d, rho0)/p % serve?
  ];

X0 = [ te_b', xb', .8*yb', xb'*.9, yb'*.9, xb'*.1];
X = fsolve( @(x) BarrierEndSystem( x(:,1),x(:,2),x(:,3),x(:,4),x(:,5),x(:,6) ), X0, options);

xOD = X(:,4);
yOD = X(:,5);
xD = X(:,2);
yD = X(:,3);


%% plot
% % draw the rotor
figure
hold on
tt = linspace(0,pi/p,50);
plot(R0*cos(tt), R0*sin(tt), 'k');
plot(Dr/2*cos(tt), Dr/2*sin(tt), 'k');
axis equal
% plot the flux-barrier central point
plot(RA.*exp(j*teAprime), 'rd')
plot(RB.*exp(j*teBprime), 'bo')

plot(xb, yb,'ko')

plot(xOC, yOC,'go')
plot(xC, yC,'ro')
plot(xOD, yOD,'co')
plot(xD, yD,'bo')

% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
toc