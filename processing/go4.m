close all;
% clear;
pkg load signal

%% Parameters
theta0 = 47*pi/180;                 % elevation over the horizon
fs = 30*1e6;                        % sampling frequency (set by B210)
fref = 37.53472224;                 % Sentinel1 reference frequency
fc = 5405e6;                        % Sentinel1 center frequency
H = 693e3;                          % Sentinel1 altitude
c = 3e8;                            % speed of light

function PRI=find_pri(data,fs,fref)  % reference data, sampling rate
 corr_length=5E4;
% Swath EW
 PRI=[22777   % swath=14
      19355   % swath=15
      22779   % swath=16
      19777   % swath=17
      23018   % swath=18
% Swath IW
      21859
      25857
      22265];
 dt=PRI/fref; 
 di=(dt*fs)/1e6;
 prit=abs(xcorr(data(floor(length(data)/2)-corr_length:floor(length(data)/2)+corr_length)));
 prit(corr_length*2-30:corr_length*2+30)=0;  % remove center correlation peak (tau=0)
 [a,b2]=max(prit(corr_length*2:corr_length*2+1.2*max(di)));
 if (length(b2)<1) error("no PRI found");end
 swath=find(abs(di-b2)<5);
 PRI=PRI(swath)
%subplot(311)
%plot([-floor(length(prit)/2):floor(length(prit)/2)],prit)
%xlabel('sample offset (a.u.)')
%ylabel('autocorr. (a.u.)')
end

%% Load data
if (exist('res1')==0)
% load res1all.mat res;res1=res(13500*1000:20500*1000);clear res; 
% load res2all.mat res;res2=res(13500*1000:20500*1000);clear res;
 load res1all.mat res;res1=res(78000*1000:85900*1000);clear res; 
 load res2all.mat res;res2=res(78000*1000:85900*1000);clear res;
end

PRI=find_pri(res1,fs,fref);         % adapt PRI to IW
dt=PRI/fref; 
di=(dt*fs)/1e6;
beta_sat = -H/sin(theta0);
T0 = PRI/fref*1e-6;    
N0 = floor(T0*fs);T = N0/fs;        % N0: samples collected between pulses
Nr = round(32e3/3e8*fs)+1;
freq = (-(Nr-1)/2:(Nr-1)/2)/Nr*fs;
lambda = c/fc;   

linspeed = pi*(H+40000e3/pi)/(98.74*60); % 98.74 = Sentinel1 orbit period
dal_sat = linspeed*T;
P = floor(length(res1)/N0);

dsi_removal=0;                      % Direct Signal Interference removal: nice but slow

ktmp=find(abs(res1(N0+1:2*N0))>0.5*max(abs(res1(N0+1:2*N0))));ktmp=ktmp(1);
res1=res1(ktmp-1500+N0:end);
res2=res2(ktmp-1500+N0:end);

%% Load data
if (exist('xm')==0)
 Ns = 1;         % fit to the data
 raw_pre = zeros(Nr,P);
 raw1_mat = zeros(Nr,P);
 raw2_mat = zeros(Nr,P);
 raw1_max = zeros(P,1);
 % winr = hanning(Nr);
 for p = 1:P-1
     waitbar(p/P); % disp(p);
     indx = Ns+(p-1)*N0+1+floor((p-1)*0.45):Ns+(p-1)*N0+Nr+floor((p-1)*0.45); % fit to the data
     raw1 = res1(indx);
     raw2 = res2(indx);
     raw1_mat(:,p) = raw1;
     raw1_max(p) = max(abs(raw1));
     raw2_mat(:,p) = raw2;
     if (dsi_removal==1)
        L = 3;PSI = zeros(Nr,2*L+1);
        for ii = -L:L
            PSI(:,ii+L+1) = res1(indx-ii);
        end
        raw2 = raw2-PSI*pinv(PSI)*raw2;         % DSI removal
     end
     raw1_fft = fftshift(fft(raw1));
     raw2_fft = fftshift(fft(raw2));
     raw_pre(:,p) = raw2_fft.*conj(raw1_fft); % range correlation
 end

 figure;imagesc((abs(raw1_mat)));colormap(jet);axis xy;
 xlabel('slow time PRI index (a.u.)')
 ylabel('fast time index (a.u.)')

%% Imaging
 Nifft = 8192;beta0 = (0:Nifft-1)/Nifft;
 Nfft = 4096;al0 = (-Nfft/2:Nfft/2-1)/Nfft;
 Image_I0 = ifft(raw_pre,Nifft,1);
 Image_I = ifftshift(ifft(Image_I0,Nfft,2),2);

 beta_I = beta0*3e8/(fs/Nr);
 al_I = al0*lambda/dal_sat;

 Image_I_db = 10*log10(abs(Image_I)/max(abs(Image_I(:))));
 figure;imagesc(al_I,beta_I,Image_I_db);axis xy;
 colormap(jet);colorbar;caxis([-40,0]);
 xlabel('alpha');ylabel('beta (m)');
 ylabel(colorbar,'Normalized amplitude (dB)');title('Image_I_db');

%% Image on a-o-b plane
 [al_I_grid0,beta_I_grid0] = meshgrid(al_I,beta_I.');
 beta = (0:5:10000);al = (-5000:25:5000);
 [A0,B0] = meshgrid(al,beta.');
 al_grid0 = A0./(beta_sat-B0);
 beta_grid0 = sqrt(A0.^2+B0.^2)+B0-A0.^2./(beta_sat-B0)/2;

 Image_ab = interp2(al_I_grid0,beta_I_grid0,Image_I,al_grid0,beta_grid0,'linear',0);
 Image_ab_db = 10*log10(abs(Image_ab)/max(abs(Image_ab(:))));
 figure;imagesc(al,beta,Image_ab_db);axis xy;
 caxis([-40,0]);colormap(jet);colorbar;
 xlabel('alpha (m)');ylabel('beta (m)');
 ylabel(colorbar,'Normalized amplitude (dB)');

%% Image on x-o-y plane
 xm = linspace(0,12e3,2401);nxm = length(xm);
 ym = linspace(-5000,5000,401);nym = length(ym);
end
[X,Y] = meshgrid(xm,ym.');
A = Y;

tmpA = Y.^2;
tmpB = H/sin(theta0);
tmpC = sqrt((H*cot(theta0)+X).^2+Y.^2+H^2)+sqrt(X.^2+Y.^2);
B1 = -sqrt(4*tmpA.*tmpB.^2.*tmpC.^2-4*tmpA.*tmpC.^4+tmpB.^4.*tmpC.^2-2*tmpB.^2.*tmpC.^4+tmpC.^6)-tmpB.^3+tmpB.*tmpC.^2;
B2 = 2*(tmpB.^2-tmpC.^2);
B = B1./B2;

[al_I_grid,beta_I_grid] = meshgrid(al_I,beta_I.');
al_grid = A./(beta_sat-B);
beta_grid = sqrt(A.^2+B.^2)+B-A.^2./(beta_sat-B)/2;

Image_xy = interp2(al_I_grid,beta_I_grid,Image_I,al_grid,beta_grid,'linear',0);
Image_xy_db = 10*log10(abs(Image_xy)/max(abs(Image_xy(:))));
figure;imagesc(ym,xm,Image_xy_db.');axis xy;
caxis([-35,-10]);colormap(jet);colorbar;
xlabel('y (m)');ylabel('x (m)');
ylabel(colorbar,'Normalized amplitude (dB)');
