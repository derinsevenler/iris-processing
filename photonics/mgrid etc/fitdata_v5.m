% function fitdata_v5(filenameIn)
function fitdata(data_in,lambda,ox_nominal,method);
%
%V4: Compressed coefficient algorithms. Redefined angular weight of CaFE algorithm
%V5: Organized functions by fitting method. Implemented SWdry, SWwet,
%SRIBdry, SRIBWet. Improved commenting.
%
%This function fits IRIS/SRIB/CaFE data.  The input data can be a 2D matrix.
%All options,data, etc are stored within a file, named filenameIn

%Note this function requires that the index data files be present in
%a working path directory as well as nLUT_MGrid() where air, oxide, Si, and
%buffer are designated material by their filenames minus the extention

fittingtimestart = tic();
load(filenameIn);

FitEnabled = 0; 
% 0 = SRIB Algorithm
% 1 = Single Wavelength Algorithm
% 2 = Spectrum Algorithm
% 3 = NA Algorithm
% 4 = Oblique imaging algorithm

if (mean(nodeInfo.fittingmethod(1:2) == 'SW'))  % Riemann sum
    FitEnabled = 1;
elseif (mean(nodeInfo.fittingmethod(1:2) == 'RS'))  % Riemann sum
    FitEnabled = 2;
elseif (mean(nodeInfo.fittingmethod(1:2) == 'Ca'))  % CaFE
    FitEnabled = 3;
elseif (mean(nodeInfo.fittingmethod(1:2) == 'OI'))  % CaFE
    FitEnabled = 4;
end

lambda = data_wav;

% Reshape into a 2d matrix
R = reshape(data,nodeInfo.number_wavelengths,nodeInfo.width*nodeInfo.height);

% Self-Reference region correction, is disabled, value will be 1.0
for i = 1:nodeInfo.number_wavelengths
    R(i,:) = R(i,:).*nodeInfo.self_reference_region(i); %MGrid inverts the SR
end


%% FIT IS DONE HERE
fitted = struct();
fit_params = [1 nodeInfo.thickness 0];

% disable warnings due to space (1GB limitations)
% http://blogs.mathworks.com/loren/2006/10/18/controlling-warning-messages-and-state/
disable_warnings = warning('off','all'); %disable warnings


if (FitEnabled == 0) % SRIB FITTING
    if size(lambda,2) >3
        fittingfunc = @Model_SRIB4LED;
    else
        fittingfunc = @Model_SRIB3LED;
        fit_params = [1 nodeInfo.thickness];
    end
    
    if (nodeInfo.normalize > 0)
        R=0.33*R./(ones(size(R,1),1)*max(R));
    end
    
    clearGlobal();
    setupFunc = str2func(['setup_' nodeInfo.fittingmethod]);
    setupFunc(lambda);
    if (nodeInfo.silicon_mirror_correction > 0)
        RSi = calc_R_SRIB(0);
        RSiCorrection = repmat(RSi,[1 size(data,2)*size(data,3)]);
        R = RSiCorrection.*R;
    end
    
elseif (FitEnabled == 1) % IRIS SW FITTING
    if size(lambda,2) >3
        fittingfunc = @Model_SW4LED;
    else
        fittingfunc = @Model_SW3LED;
        fit_params = [1 nodeInfo.thickness];
    end
    
    clearGlobal();
    setupFunc = str2func(['setup_' nodeInfo.fittingmethod]);
    setupFunc(lambda);
    if (nodeInfo.silicon_mirror_correction > 0)
        RSi = calc_R_SW(0);
        RSiCorrection = repmat(RSi,[1 size(data,2)*size(data,3)]);
        R = RSiCorrection.*R;
    end

elseif (FitEnabled == 2) % IRIS Spectrum FITTING 
    if size(lambda,2) >3
        fittingfunc = @Model_Spectrum4LED;
    else
        fittingfunc = @Model_Spectrum3LED;
        fit_params = [1 nodeInfo.thickness];
    end
    
    clearGlobal();
    setupFunc = str2func(['setup_' nodeInfo.fittingmethod]);
    setupFunc(nodeInfo.fittinginstr);
    if (nodeInfo.silicon_mirror_correction > 0)
        RSi = calc_R_Spectrum(0);
        RSiCorrection = repmat(RSi,[1 size(data,2)*size(data,3)]);
        R = RSiCorrection.*R;
    end
    
elseif (FitEnabled == 3) % CaFE Algorithm
    if size(lambda,2) >3
        fittingfunc = @Model_CaFE4LED;
    else
        fittingfunc = @Model_CaFE3LED;
        fit_params = [1 nodeInfo.thickness];
    end
    
    clearGlobal();
    setupFunc = str2func(['setup_' nodeInfo.fittingmethod]);
    setupFunc(nodeInfo.fittinginstr);
    if (nodeInfo.silicon_mirror_correction > 0)
        RSi = calc_R_CaFE(0);
        RSiCorrection = repmat(RSi,[1 size(data,2)*size(data,3)]);
        R = RSiCorrection .* R;
    end
elseif (FitEnabled == 4) %% Angle Illumination Algorithm
    if size(lambda,2) >3
        fittingfunc = @ModelOIRIS_RSum4LED;
    end
    
    clearGlobal();
    setupFunc = str2func(['setup_' nodeInfo.fittingmethod]);
    setupFunc(nodeInfo.fittinginstr);
    
    if (nodeInfo.silicon_mirror_correction > 0)
        RSi = calc_R_OIRIS(0);
        RSiCorrection = repmat(RSi,[1 size(data,2)*size(data,3)]);
        R = RSiCorrection .* R;
    end
end

%% MAIN LOOP HERE, DOES NOT USE PARFOR, NOT ELEGANT C/P
for n=1:size(R,2)
    %% TO USE OPTIONS, UNCOMMENT THIS and PREVIOUS LINES
%     tic
    [beta, r, j] = nlinfit(lambda,R(:,n),fittingfunc,fit_params);
%     toc
    fitted.amp(n)=beta(1); %AMP
    fitted.ox(n)= beta(2); %PHASE
    
    if (fitted.ox(n) < 0) %throw away garbage data
        fitted.ox(n) = 0.0;
    end
    if size(fit_params,2) == 3
        fitted.dc(n)= beta(3); %DC
    else
        fitted.dc(n)= 0; %DC
    end
    
    fitted.res(:,n) = r; %residuals
end

% reenable warnings
warning(disable_warnings)  % restore state

fittingtime = toc(fittingtimestart);
nodeInfo.fittingtime = fittingtime;


%% OUTPUT VARIABLEs, PREPARE
data_fitted = fitted.ox; %use existing output variable

if (nodeInfo.includeall > 0)
    nodeInfo.fitted = fitted; %save amp,phase,dc, and residuals
end

%%% extract Filename Information
expr = ['(?<scanname>\w*)DataSet(?<scantime>\d*)\_(?<scannumber>\d*)\.mat' ];
[names] = regexpi(filenameIn, expr, 'names');
if (isempty(names))
    % wrong filename, just do nothing
    newfilename = [fn '_FITTED.mat'];
else
    newfilename = [names.scanname 'Fitted' ...
        names.scantime '_' names.scannumber '.mat'];
end

if (nodeInfo.plotfit > 0)
    index = 1;
    if (FitEnabled == 0)
        PlotModel_SRIB([fitted.amp(index) fitted.ox(index) fitted.dc(index)],setupFunc,lambda);
    elseif(FitEnabled == 1)
        PlotModel_SW([fitted.amp(index) fitted.ox(index) fitted.dc(index)],setupFunc,lambda);
    elseif(FitEnabled == 2)
        PlotModel_Spectrum([fitted.amp(index) fitted.ox(index) fitted.dc(index)],setupFunc,lambda);
    elseif(FitEnabled == 3)
        PlotModel_CaFE([fitted.amp(index) fitted.ox(index) fitted.dc(index)],setupFunc,lambda);
    elseif(FitEnabled == 4)
        PlotModelOIRIS([fitted.amp(index) fitted.ox(index) fitted.dc(index)],setupFunc,lambda);
    end
else
    save(newfilename,'data_fitted','data_date','data_wav','nodeInfo');
end

%% EDITABLE MODELS LIBRARY
%  DRY, WET, DRY_ITO, WET_ITO

%%% Start the definitions of the fitting algorithms and models
function clearGlobal()
global r1; global r2; global x; global kz;
clear global r1; clear global r2; clear global x; clear global kz;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  SRIB Fit %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Emre Ozkumur, 2008
%
% Assumptions: Real indices of refraction, Single wavelength, Paraxial NA
function setup_SRIBDry(lambda)
layers = {'Air' 'SiO2' 'Si'};
gen_coeffs_SRIB(layers,lambda);
function setup_SRIBWet(lambda)
layers = {'H2O' 'SiO2' 'Si'};
gen_coeffs_SRIB(layers,lambda);

function f = Model_SRIB4LED(param,lambda) %Previously ModelOzkumur4LED
f=param(1)*calc_R_SRIB(param(2))+param(3);
function f = Model_SRIB3LED(param,lambda)%Previously ModelOzkumur3LED
f=param(1)*calc_R_SRIB(param(2));

function gen_coeffs_SRIB(layers,lambda) %Previously called reflectivity()
global r1_mat r2_mat kz_mat;
n1 = real(nLUT_MGrid(lambda,layers{1}));
n2 = real(nLUT_MGrid(lambda,layers{2}));
n3 = real(nLUT_MGrid(lambda,layers{3}));

r1_mat = ((n1 - n2)./(n1 + n2))';
r2_mat = ((n2 - n3)./(n2 + n3))';
kz_mat = (2.*pi.*n2 ./ lambda)';

function [R] = calc_R_SRIB(T)
global r1_mat r2_mat kz_mat;
R = gen_R_SRIB(T, r1_mat, r2_mat, kz_mat);

function [R] = gen_R_SRIB(d, r1, r2, kz)
R=(r1.^2+r2.^2+2*r1.*r2.*cos(2*kz*d))./(1+r1.^2.*r2.^2+2.*r1.*r2.*cos(2*kz*d));

function f = PlotModel_SRIB(param,setupfunc,lambda) %Previously PlotModelOzkumur
if size(lambda,2) == 3
    func = str2func('ModelSRIB3LED');
elseif size(lambda,2) > 3
    func = str2func('ModelSRIB4LED');
end

sensitivity = 100;
lambdastart = (lambda(1)-50);
lambdastop = (lambda(end)+50);
lambdarange = lambdastop - lambdastart;
allxvals = lambdastart:lambdarange/sensitivity:lambdastop;
setupfunc(allxvals);
allyvals = func([param(1) param(2) param(3)],allxvals);

plot(allxvals,allyvals,'--');
hold on;

clearGlobal();
setupfunc(lambda);
xvals = lambda;
yvals = func(param,lambda);
plot(xvals,yvals,'Color',[0.8 0.2 0.2],'LineStyle','none','Marker','x',...
    'LineWidth',2,...
    'MarkerEdgeColor','k',...
    'MarkerFaceColor','g',...
    'MarkerSize',5);
title({sprintf('Mag = %.3f, DC = %.3f',...
    param(1), param(3)),sprintf('Phase = %.3f',param(2))},'FontSize',12);
xlim([allxvals(1) allxvals(end)]);
xlabel('Wavelength (nm)');
ylabel('Interference (A.U.)');
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%  Single Wavelength Fit %%%%%%%%%%%%%%%%%%%%%%%%%%
% George|Rahul, 2010
%
% Assumptions: Single wavelength, Paraxial NA
function setup_SWDry(lambda)
layers = {'Air' 'SiO2' 'Si'};
gen_coeffs_SW(layers,lambda);
function setup_SWWet(lambda)
layers = {'H2O' 'SiO2' 'Si'};
gen_coeffs_SW(layers,lambda);

function f = Model_SW4LED(param,lambda)
%IRIS - Near normal incidence
f=param(1)*calc_R_SW(param(2))+param(3);
function f = Model_SW3LED(param,lambda)
%IRIS - Near normal incidence
f=param(1)*calc_R_SW(param(2));

function gen_coeffs_SW(layers,lambda)
global r1_mat r2_mat kz_mat;
n1 = nLUT_MGrid(lambda,layers{1});
n2 = nLUT_MGrid(lambda,layers{2});
n3 = nLUT_MGrid(lambda,layers{3});

r1_mat = ((n1 - n2)./(n1 + n2))';
r2_mat = ((n2 - n3)./(n2 + n3))';
kz_mat = (2.*pi.*n2 ./ lambda)';

function [R] = calc_R_SW(T)
global r1_mat r2_mat kz_mat;
R = gen_R_SW(T, r1_mat, r2_mat, kz_mat);

function [R] = gen_R_SW(d, r1, r2, kz)
R = abs((r1+r2.*exp(-1j*2*kz*d))./(1+r1.*r2.*exp(-1i*2*kz*d))).^2;

function f = PlotModel_SW(param,setupfunc,lambda)
if size(lambda,2) == 3
    func = str2func('Model_SW3LED');
elseif size(lambda,2) > 3
    func = str2func('Model_SW4LED');
end

sensitivity = 100;
lambdastart = (lambda(1)-50);
lambdastop = (lambda(end)+50);
lambdarange = lambdastop - lambdastart;
allxvals = lambdastart:lambdarange/sensitivity:lambdastop;
setupfunc(allxvals);
allyvals = func([param(1) param(2) param(3)],allxvals);

plot(allxvals,allyvals,'--');
hold on;

clearGlobal();
setupfunc(lambda);
xvals = lambda;
yvals = func(param,lambda);
plot(xvals,yvals,'Color',[0.8 0.2 0.2],'LineStyle','none','Marker','x',...
    'LineWidth',2,...
    'MarkerEdgeColor','k',...
    'MarkerFaceColor','g',...
    'MarkerSize',5);
title({sprintf('Mag = %.3f, DC = %.3f',...
    param(1), param(3)),sprintf('Phase = %.3f',param(2))},'FontSize',12);
xlim([allxvals(1) allxvals(end)]);
xlabel('Wavelength (nm)');
ylabel('Interference (A.U.)');
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  Spectrum Fit %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Alexander Reddington, 2011
%
% Assumptions: Paraxial NA
function setup_RSDry(fittinginstr)
layers = {'Air' 'SiO2' 'Si'};
gen_coeffs_Spectrum(layers,fittinginstr);
function setup_RSWet(fittinginstr)
layers = {'H2O' 'SiO2' 'Si'};
gen_coeffs_Spectrum(layers,fittinginstr)

function f = Model_Spectrum4LED(param,lambda) %Previously ModelIRIS_RSum4LED
%IRIS - Near normal incidence
f=param(1)*calc_R_Spectrum(param(2))+param(3);
function f = Model_Spectrum3LED(param,lambda) %Previously ModelIRIS_RSum3LED
%IRIS - Near normal incidence
f=param(1)*calc_R_Spectrum(param(2));

function gen_coeffs_Spectrum(layers,fittinginstr)
global weight_mat step_wavelength_mat r1_mat r2_mat kz_mat;

load(fittinginstr); %there should be a IRIS1, IRIS2, SSFM, Italian.mat file here

if strcmpi(fittinginstr, 'SSFM')==1
    lambda = [wavelength.LD658; wavelength.LD670; wavelength.LD685];
    weight_mat = [weight.LD658; weight.LD670; weight.LD685];
    step_wavelength_mat = [step_wavelength.LD658; step_wavelength.LD670; step_wavelength.LD685];
else
    lambda = [wavelength.blue; wavelength.green; wavelength.amber; wavelength.red];
    weight_mat = [weight.blue; weight.green; weight.amber; weight.red];
    step_wavelength_mat = [step_wavelength.blue; step_wavelength.green; step_wavelength.amber; step_wavelength.red];
end

n1 = nLUT_MGrid(lambda,layers{1});
n2 = nLUT_MGrid(lambda,layers{2});
n3 = nLUT_MGrid(lambda,layers{3});
r1_mat = (n1 - n2)./(n1 + n2);
r2_mat = (n2 - n3)./(n2 + n3);
kz_mat = 2.*pi.*n2 ./ lambda;
 
function [R] = calc_R_Spectrum(T) %Previously calc_R_RSum
global weight_mat step_wavelength_mat r1_mat r2_mat kz_mat;
R = gen_R_Spectrum(T, weight_mat, r1_mat, r2_mat, kz_mat, step_wavelength_mat);

function [R] = gen_R_Spectrum(d, weight, r1, r2, kz, stepsize)  %Previously gen_R_Spectrum
R_temp = abs((r1+r2.*exp(-1j*2*kz*d))./(1+r1.*r2.*exp(-1i*2*kz*d))).^2;
R = sum(weight.*R_temp.*stepsize,2);

function f = PlotModel_Spectrum(param,setupfunc,lambda)%Previously PlotModelIRIS_RSum
R = param(1)*calc_R_Spectrum(param(2))+param(3);
plot(lambda,R,'Color',[0.8 0.2 0.2],'LineStyle','none','Marker','x',...
    'LineWidth',2,...
    'MarkerEdgeColor','k',...
    'MarkerFaceColor','g',...
    'MarkerSize',5);
title({sprintf('Mag = %.3f, DC = %.3f',...
    param(1), param(3)),sprintf('Phase = %.3f',param(2))},'FontSize',12);
xlim([lambda(1) lambda(end)]);
xlabel('Wavelength (nm)');
ylabel('Interference (A.U.)');
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  CaFE (NA) Fit %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Alexander Reddington, 2012
%
% Assumptions: CaFE - NA = 0.5, WD = 20mm
function setup_CaFEDry(fittinginstr)
NA = 0.5;
WD = 20;
step_NA = 100;
layers = {'Air' 'SiO2' 'Si'};
gen_coeff_CaFE(layers, NA, WD, step_NA, fittinginstr);

function f = Model_CaFE4LED(param,lambda)
% Non-normal incidence IRIS
f = param(1)*calc_R_CaFE(param(2))+param(3);
function f = Model_CaFE3LED(param,lambda)
% Non-normal incidence IRIS
f = param(1)*calc_R_CaFE(param(2));

function gen_coeff_CaFE(layers,NA,WD,step_NA,fittinginstr)
%% Initialize variables
global theta weight_theta step_theta_mat weight_mat step_wavelength_mat rs1_mat rs2_mat rp1_mat rp2_mat kz_mat;

if strcmpi(fittinginstr,'SingleWavelength');
    wavelength.blue = 455;
    wavelength.green = 518;
    wavelength.amber = 598;
    wavelength.red = 630;
    
    weight.blue = 1;
    weight.green = 1;
    weight.amber = 1;
    weight.red = 1;
    
    step_wavelength.blue = 1;
    step_wavelength.green = 1;
    step_wavelength.amber = 1;
    step_wavelength.red = 1;
else
    load(fittinginstr); %there should be a CaFE.mat file here
end

if NA~=0
    step = NA/step_NA;
    stepNA = 0:step:NA;
else
    stepNA = 0;
end
theta = asin(stepNA);

%Calculate the radii for every theta
radii = WD.*sin(theta);
% area_total = pi * (radii(end))^2;
area_ring = 0;

%Determine the area of each ring (theta+1 - theta) and step_size
step_theta = 1;
size_theta = size(theta,2);
if size_theta >1
    for i = 1:length(theta)-1
        step_theta(1,i) = (theta(i+1) - theta(i));
        area_ring(1,i) = pi * (radii(i+1)^2- radii(i)^2);
    end
    theta = theta(2:end);
    size_theta = size(theta,2);
end

%Normalize the integral to 1
pp = spline(theta,area_ring);
m = quad(@(theta)ppval(pp,theta),theta(1),theta(end));
area_norm = area_ring./m;

%Calculate indices of refraction and angles in each layer
lambda = [wavelength.blue; wavelength.green; wavelength.amber; wavelength.red];
n1 = repmat(nLUT_MGrid(lambda,layers{1}),[1 1 size_theta]);
n2 = repmat(nLUT_MGrid(lambda,layers{2}),[1 1 size_theta]);
n3 = repmat(nLUT_MGrid(lambda,layers{3}),[1 1 size_theta]);
theta1 = repmat(reshape(theta,[1 1 size(theta,2)]),[size(n1,1) size(n1,2) 1]);
theta2 = asin(n1./n2.*sin(theta1));
theta3 = asin(n2./n3.*sin(theta2));

%Fresnel polarized coefficients, p .62-63 Yeh
rs1_mat = (n1.*cos(theta1) - n2.*cos(theta2))./(n1.*cos(theta1) + n2.*cos(theta2));
rs2_mat = (n2.*cos(theta2) - n3.*cos(theta3))./(n2.*cos(theta2) + n3.*cos(theta3));
rp1_mat = (n1.*cos(theta2) - n2.*cos(theta1))./(n1.*cos(theta2) + n2.*cos(theta1));
rp2_mat = (n2.*cos(theta3) - n3.*cos(theta2))./(n2.*cos(theta3) + n3.*cos(theta2));
kz_mat = 2.*pi.*n2 ./ repmat(lambda,[1 1 size_theta]) .* cos(theta2);

%% Generate matrices for calculations
% weight_theta = repmat(reshape(area_ring./area_total,[1 1 size(theta,2)]),[size(n1,1) size(n1,2) 1]);
weight_theta = repmat(reshape(area_norm,[1 1 size(theta,2)]),[size(n1,1) size(n1,2) 1]);
step_theta_mat = repmat(reshape(step_theta,[1 1 size(theta,2)]),[size(n1,1) size(n1,2) 1]);
weight_mat = [weight.blue;weight.green;weight.amber;weight.red];
step_wavelength_mat = [step_wavelength.blue;step_wavelength.green;step_wavelength.amber;step_wavelength.red];
clear lambda step_theta weight n1 n2 n3 theta1 theta2 theta3 step_wavelength;

function [R] = calc_R_CaFE(T)
global theta weight_theta step_theta_mat weight_mat step_wavelength_mat rs1_mat rs2_mat rp1_mat rp2_mat kz_mat;
R = gen_R_CaFE(T, weight_mat, rs1_mat, rs2_mat, rp1_mat, rp2_mat, kz_mat, step_wavelength_mat, theta, step_theta_mat, weight_theta);

function [R] = gen_R_CaFE(d, weight, rs1, rs2, rp1, rp2, kz, step_wavelength, theta, step_theta, weight_theta)
%Calculate Rs and Rp
Rs_angles = abs((rs1+rs2.*exp(-1j*2*kz*d))./(1+rs1.*rs2.*exp(-1i*2*kz*d))).^2;
Rp_angles = abs((rp1+rp2.*exp(-1j*2*kz*d))./(1+rp1.*rp2.*exp(-1i*2*kz*d))).^2;

%Average S and P for unpolarized light, p. 79 Yeh
Rangles = (Rs_angles+Rp_angles)./2;

if theta(end) == 0
    R_temp = sum( Rangles .* step_theta,3);
else
    R_temp = sum( Rangles .* step_theta .*weight_theta,3);
end

% Riemann Sum of R_temp over the LED bandwidths
R = sum(weight .* R_temp .* step_wavelength,2);

function f = PlotModel_CaFE(param,setupfunc,lambda)
R = param(1)*calc_R_CaFE(param(2))+param(3);
plot(lambda,R,'Color',[0.8 0.2 0.2],'LineStyle','none','Marker','x',...
    'LineWidth',2,...
    'MarkerEdgeColor','k',...
    'MarkerFaceColor','g',...
    'MarkerSize',5);
title({sprintf('Mag = %.3f, DC = %.3f',...
    param(1), param(3)),sprintf('Phase = %.3f',param(2))},'FontSize',12);
xlim([lambda(1) lambda(end)]);
xlabel('Wavelength (nm)');
ylabel('Interference (A.U.)');
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  Oblique imaging fit %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function setup_OIRIS(fittinginstr)
layers = {'Air' 'SiO2' 'Si'};
gen_coeffs_OIRIS(layers,fittinginstr);

function f = ModelOIRIS_RSum4LED(param,lambda)
%IRIS - Near normal incidence
    f=param(1)*calc_R_OIRIS(param(2))+param(3);
return;

function gen_coeffs_OIRIS(layers,fittinginstr)
%% Initialize variables
%Make all needed constants for calculating R a global 
global weight_mat step_wavelength_mat r12_s r23_s kz

%Loads wavelength information
load(fittinginstr);

%Assign the structs from OIRIS.mat to 2D matrices
lambda = [wavelength.blue; wavelength.green; wavelength.amber; wavelength.red];
weight_mat = [weight.blue; weight.green; weight.amber; weight.red];
step_wavelength_mat = [step_wavelength.blue; step_wavelength.green; step_wavelength.amber; step_wavelength.red];
    
%Calculate indices of refraction
n1 = nLUT_MGrid(lambda,layers{1});
n2 = nLUT_MGrid(lambda,layers{2});
n3 = nLUT_MGrid(lambda,layers{3});

%Calculate fresnel coefficients
realtheta=pi/4;
theta2 = asin((n1.*sin(realtheta))./n2);
theta3 = asin((n2.*sin(theta2))./n3);

r12_s = (n1.*cos(realtheta) - n2.*cos(theta2))./(n1.*cos(realtheta) + n2.*cos(theta2));
r23_s = (n2.*cos(theta2) - n3.*cos(theta3))./(n2.*cos(theta2) + n3.*cos(theta3));
kz = 2*pi*n2.*cos(theta2)./lambda;


function [R] = calc_R_OIRIS(T)
%Call in the globals for constants
global weight_mat step_wavelength_mat r12_s r23_s kz
R = gen_R_OIRIS(T, weight_mat, step_wavelength_mat, r12_s, r23_s, kz); %Input all constants and T into calc_R_OIRIS

function [R] = gen_R_OIRIS(d, weight, stepsize, r12_s, r23_s, kz)
Rs = abs((r12_s + r23_s.*exp(-2*1i*kz*d))./(1+r12_s.*r23_s.*(exp(-2*1i*kz*d)))).^2;
%R_temp = abs((r1+r2.*exp(-1j*2*kz*d))./(1+r1.*r2.*exp(-1i*2*kz*d))).^2; %Calculate R with the OIRIS model
R = sum(weight.*Rs.*stepsize,2); %Reimann Sum of LED bandwidth

function f = PlotModelOIRIS(param,setupfunc,lambda)
R = param(1)*calc_R_OIRIS(param(2))+param(3);
plot(lambda,R,'Color',[0.8 0.2 0.2],'LineStyle','none','Marker','x',...
    'LineWidth',2,...
    'MarkerEdgeColor','k',...
    'MarkerFaceColor','g',...
    'MarkerSize',5);
title({sprintf('Mag = %.3f, DC = %.3f',...
    param(1), param(3)),sprintf('Phase = %.3f',param(2))},'FontSize',12);
xlim([lambda(1) lambda(end)]);
xlabel('Wavelength (nm)');
ylabel('Interference (A.U.)');
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function setup_DryITO(lambda)
global r1; global r2; global x;
for n=1:length(lambda)
    r1(n) = reflectivity('air','measITO_B3W3',lambda(n)); %r1 = reflectance between AIR/SIO2
    r2(n) = reflectivity('measITO_B3W3','sio2',lambda(n)); %r2 = reflectance between SIO2/SI
    r3(n) = reflectivity('sio2','si',lambda(n)); %r3 = reflectance between SIO2/SI
    x1(n)=2*pi*real(nLUTname(lambda(n),'sio2'))/lambda(n);
    x2(n)=2*pi*real(nLUTname(lambda(n),'measITO_B3W3'))/lambda(n);
end;
OX=20.0; %OX=10.5;
Rsi=(r2.^2+r3.^2+2*r2.*r3.*cos(2*x1*OX))./(1+r1.^2.*r2.^2+2.*r1.*r2.*cos(2*x1*OX)); %OX is the added SIO2 layer
% setup global variables for use in the Model Equation
x = x2; r1 = r1; r2 = sqrt(Rsi);
function setup_WetITO(lambda)
global r1; global r2; global x;
for n=1:length(lambda)
    r1(n) = reflectivity('buffer','measITO_B3W3',lambda(n)); %r1 = reflectance between WATER/SIO2
    r2(n) = reflectivity('measITO_B3W3','sio2',lambda(n)); %r2 = reflectance between SIO2/SI
    r3(n) = reflectivity('sio2','si',lambda(n)); %r3 = reflectance between SIO2/SI
    x1(n)=2*pi*real(nLUTname(lambda(n),'sio2'))/lambda(n);
    x2(n)=2*pi*real(nLUTname(lambda(n),'measITO_B3W3'))/lambda(n);
end;
OX=20.0; %OX=10.5;
Rsi=(r2.^2+r3.^2+2*r2.*r3.*cos(2*x1*OX))./(1+r1.^2.*r2.^2+2.*r1.*r2.*cos(2*x1*OX)); %OX is the added SIO2 layer
% setup global variables for use in the Model Equation
x = x2; r1 = r1; r2 = sqrt(Rsi);