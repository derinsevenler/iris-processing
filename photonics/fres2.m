function [r123, t123] = fres2(nVec, d, theta, lambda, rp)
% Function [r123, t123] = fres2(nvec, d, theta, lambda, rp) computes reflecion
% and transmission coefficients for a simple 3 layer system.
%
% Inputs:       nveec - refractive index of the system [n1, n2, n3]
%               d - thickness of the intermediate layer [same as
%               wavelength
%               theta - angle of incidence (measured form normal) [rad/s]
%               lambda - wavelength of incidnet light [micron]
%               rp -  polarization state. Enter 's' for E-field polarized
%           perpendicular to the plane of incidence, 'p' for parallel
%           polarization.
%
%           Note - phase convention is that of Yeh, Optics in Layered
%           Media. That is, E-field components parallel to the interface
%           point in the same direction in derivation. Convention for
%           imaginary part is physicists...N = n+ik. Note this code will
%           not work with gain media (positive imaginary part is forced).

if nargin < 5, rp = 's'; end
n1 = nVec(1);
n2 = nVec(2);
n3 = nVec(3);

k01 = 2*pi*n1./lambda;
k02 = 2*pi*n2./lambda;
k1z = k01.*sin(theta);
k2t = sqrt(k02.^2-k1z.^2);
k2x = real(k2t)+1i.*abs(imag(k2t));     % Ensure imaginary part is > 0
%k2x = k2t;
theta2 = acos(k2x./k02);

% Reflection and transmission coefficiencts for the 12 and 23 interfaces
[r12,t12] = fres1(n1,n2,theta,rp);  
[r23,t23] = fres1(n2,n3,theta2,rp);

% Fresnel 3-layer formula
r123 = (r12+r23.*exp(2*1i.*k2x.*d))./(1+r12.*r23.*exp(2.*1i*k2x.*d));
t123 = (t23.*t12.*exp(1i.*k2x.*d))./(1+r12.*r23.*exp(2.*1i*k2x.*d));
