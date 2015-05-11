function [r,t] = fres1(n1, n2, theta, rp)
% Function [r,t] = fres1(n1, n2, theta, rp) computes the Fresnel
% reflection and transmission coefficients for light incident from media 1
% (n1) onto the n1-n2 interface.
%
% Inputs:   n1 - Incident medium refractive index
%           n2 - Medium 2 refractive index
%           theta - angle of incidence (from interface normal) [radians]
%           rp - polarization state. Enter 's' for E-field polarized
%           perpendicular to the plane of incidence, 'p' for parallel
%           polarization.
%
%           Note - phase convention is that of Yeh, Optics in Layered
%           Media. That is, E-field components parallel to the interface
%           point in the same direction in derivation. Convention for
%           imaginary part is physicists...N = n+ik. Note this code will
%           not work with gain media (positive imaginary part is forced).

if nargin < 4           % Default is s - polarization
    rp = 's';
end

k1x = n1.*cos(theta);                   % Normal k1-vector
k1z = n1.*sin(theta);                   % Tangential k1-vector
k2t = sqrt(n2.^2-k1z.^2);               % Normal k2-vector
k2x = real(k2t)+1i.*abs(imag(k2t));     % Ensure imaginary part is > 0
%k2x = k2t;
if (rp == 'p')          % Formulas for p-polarization
    r = ((n1.^2).*k2x - (n2.^2).*k1x)./((n1.^2).*k2x + (n2.^2).*k1x);
    t = 2.*n1.*n2.*k1x./((n1.^2).*k2x + (n2.^2).*k1x);
else                    % Formulas for s-polarization
    r = (k1x-k2x)./(k1x+k2x);
    t = 2.*k1x./(k1x+k2x);
end