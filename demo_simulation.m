
load('ref_9vol')
addpath ./utils
addpath ./NORDIC_Raw-main
addpath ./NIfTI_20140122
addpath ./Denoising-master
%%% A script demonstrating how to characterize noise estimation in the complex domain 
%%% using our extended MPPCA. 
%%%
%%% Referenece:  Xiaodong Ma, Xiaoping Wu, Kamil Ugurbil, NeuroImage 2020
%%%
%%% Author:      Xiaoping Wu, 8/13/2024


%% Simulate noisy data with 2 shell b1000 and b2000
mask0 = dwi0~=0;
%% parameter setting
%ks = 5; % kernel size for noise estimation
indz4test = 15:39; %41-10:49+10; % here a few slices (no smaller than 2*ks-1) are denoised for testing
nVols= 9; % number of images volumes to consider. 
% parallel computation

%% noise generation 
% noise level (percent)
levels= 5:1:5;%1:10;
kernelSizes= 7:2:7;
%Sigmas_mppca= [];
%PSNR_sig= zeros(length(levels), length(kernelSizes));
for idx=1: length(levels)
    for gh =1:1
        nVols = nVols;
    level = levels(idx);

    GenerateNoisyDataComplex;


    % %% Preprocess data by removing the backgrounds to accelerate computation
    % remove background to save computation power
    % [isub{1},isub{2},isub{3}]= ind2sub(size(mask0),find(mask0));
    % size_mask0 = size(mask0);
    % for ndim = 1:3
    %     ind_start{ndim} = max(min(isub{ndim})-ks,1);
    %     ind_end{ndim}   = min(max(isub{ndim})+ks,size_mask0(ndim));
    % end
    % full fov but with reduced background.
    % mask = mask0(ind_start{1}:ind_end{1},ind_start{2}:ind_end{2},ind_start{3}:ind_end{3});
    % dwi  = dwi0 (ind_start{1}:ind_end{1},ind_start{2}:ind_end{2},ind_start{3}:ind_end{3},:);
    % dwi_noisy = dwi0_noisy(ind_start{1}:ind_end{1},ind_start{2}:ind_end{2},ind_start{3}:ind_end{3},:);

    mask = mask0;
    dwi= dwi0;
    dwi_noisy= dwi0_noisy;
    Sigma= Sigma0;

ARG.temporal_phase = 3;
ARG.phase_filter_width = 3;
    mask = mask(:,:,indz4test);
    dwi = dwi(:,:,indz4test,:);
    dwi_noisy = dwi_noisy(:,:,indz4test,:);
    Sigma= Sigma(:,:,indz4test);

    % estimate noise
    im_r0 = dwi_noisy;
    im_r= im_r0(:,:,:,1:nVols);

    KSP2 = im_r;

dwi = dwi(:,:,:,1:nVols);
%% phase stablization
DD_phase=0*KSP2;

if           ARG.temporal_phase>0; % Standarad low-pass filtered map
    for slice=size(KSP2,3):-1:1
        for n=1:size(KSP2,4);
            tmp=KSP2(:,:,slice,n);
            for ndim=[1:2]; tmp=ifftshift(ifft(ifftshift( tmp ,ndim),[],ndim),ndim+0); end
            [nx, ny, nc, nb] = size(tmp(:,:,:,:,1,1));
            tmp = bsxfun(@times,tmp,reshape(tukeywin(ny,1).^ARG.phase_filter_width,[1 ny]));
            tmp = bsxfun(@times,tmp,reshape(tukeywin(nx,1).^ARG.phase_filter_width,[nx 1]));
            for ndim=[1:2]; tmp=fftshift(fft(fftshift( tmp ,ndim),[],ndim),ndim+0); end
            DD_phase(:,:,slice,n)=tmp;
        end
    end
end










for slice=size(KSP2,3):-1:1
    for n=1:size(KSP2,4);
        KSP2(:,:,slice,n)= KSP2(:,:,slice,n).*exp(-i*angle( DD_phase(:,:,slice,n)   ));
    end
end


%% gfactor estimation
KSP2(isnan(KSP2))=0;
KSP2(isinf(KSP2))=0;
    for jdx= 1: length(kernelSizes)
        ks= kernelSizes(jdx);
        % ks =5;
        % estimate noise from images
        [denoise_image_init,Sigma_mppca_realphase] = denoise_mppca3(real(KSP2),ks);
     %   [denoise_image_initcom,Sigma_mppca_comphase] = denoise_mppca3((KSP2),ks);
      
      %  [~,Sigma_mppcareal] = denoise_mppca3(real(im_r),ks);
      %  [~,Sigma_mppca] = denoise_mppca3(imag(im_r),ks);
     %   [~,Sigma_mppcaimag] = denoise_mppca3(imag(im_r),ks);
     %   PSNR_sigcom(idx, jdx)= PSNR(Sigma_mppca(mask), Sigma(mask));
      %    PSNR_sigreal(idx, jdx)= PSNR(Sigma_mppcareal(mask), Sigma(mask));
  
       %     PSNR_sigimag(idx, jdx)= PSNR(Sigma_mppcaimag(mask), Sigma(mask));
        %  PSNR_sig(idx, jdx)= PSNR(Sigma_mppca_realphase(mask), Sigma(mask));
  
    
    end

for n=1:size(KSP2,4);
    KSP2(:,:,:,n)= KSP2(:,:,:,n)./ (Sigma_mppca_realphase+eps);
end
    
    KSP2(isnan(abs(KSP2)))=0;
    %% step 1 denoise
    ks=5;
    
        [denoise_image,Sigma_mppca_realphase22] = denoise_mppca3(real(KSP2),ks);

     %   [denoise_image2,Sigma_mppca_comphase222] = denoise_mppca3((KSP2),ks);
    
    
for n=1:size(KSP2,4);
    denoise_image(:,:,:,n)= denoise_image(:,:,:,n).* Sigma_mppca_realphase;
end
% 
% for n=1:size(KSP2,4);
%     denoise_image2(:,:,:,n)= denoise_image2(:,:,:,n).* Sigma_mppca_realphase;
% end

    denoise_image(isnan(abs(denoise_image)))=0;

for n=1:size(KSP2,4);
    KSP2(:,:,:,n)= KSP2(:,:,:,n)./ (Sigma_mppca_realphase22+eps);
end
    
    KSP2(isnan(abs(KSP2)))=0;
    %% no local denoise
nonlocal_real=denoise_nonlocal_svs(real(KSP2),abs(denoise_image),ks);
% or mppca
nonlocal_com=denoise_nonlocal_mppca(KSP2(:,:,:,:),abs(denoise_image(:,:,:,:)),ks);

    
for n=1:size(KSP2,4);
    nonlocal_com(:,:,:,n)= nonlocal_com(:,:,:,n).* Sigma_mppca_realphase22;
end
    
for n=1:size(KSP2,4);
    nonlocal_com(:,:,:,n)= nonlocal_com(:,:,:,n).* Sigma_mppca_realphase;
end
    nonlocal_com(isnan(abs(nonlocal_com)))=0;

foldername = ['/denoise/',num2str(level)];
       str = sprintf('save %s/denoise.mat im_r denoise_image_init nonlocal_com denoise_image Sigma_mppca_realphase22 Sigma_mppca_realphase;',foldername);
           eval(str)

      
    end
end




