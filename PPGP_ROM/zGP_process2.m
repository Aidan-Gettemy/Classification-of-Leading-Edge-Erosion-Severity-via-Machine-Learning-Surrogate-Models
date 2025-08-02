function [zgp_output, scaling_factor, shift, yRL] = zGP_process2(original_output, Input, lim_type)
% ZGP_PROCESS2; This does not use the built in testing trend and instead
% makes its own at each step
    
    % Preprocess the data so that its largest magnitude is 1
    Out_train_star = original_output./max(abs(original_output));
    % scaling factor
    scaling_factor = max(abs(original_output));
    xd = Input;
    % Set the upper bound for the zGP
    if strcmp(lim_type,"upper")==1
        UB = max(Out_train_star);
        % Reconfigure the Starting Data
        yimp = Out_train_star;
        inds=find(yimp>UB);
        yimp(inds)=UB;
        ystart=yimp;
        shift=0;
    end
    
    % Set the lower bound for the zGP
    if strcmp(lim_type,"lower")==1
        LB = min(Out_train_star); % Set becuase we are dealing with standard deviations
        % Reconfigure the Starting Data
        yimp = Out_train_star;
        inds = find(yimp<LB);
        yimp(inds) = LB;
        ystart=yimp;
        shift = min(original_output);
    end
    
    % Define how many samples to take to estimate the non-limited data
    Ngibbs=2000;
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %This is where we start the negative samples
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % We assume that the original data was non-negative
    if strcmp(lim_type,"upper")==1
        if UB~=0 % shift and flip to have >=0 as the constraint
            ystart=-(ystart-UB);
        end
    end

    if strcmp(lim_type,"lower")==1
        if LB~=0 % shift and to have >=0 as the constraint
            ystart=ystart-LB;
        end
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %This is where we start the negative samples
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    % Define X
    X = Input;
    % This does "batch sampling" to get an intitial set of negative samplings
    output=RLW_init_impute(X,ystart); 
    yimputesave=output{1};
    sigsp=output{2};
    yimp=median(yimputesave,2);
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %This next  bit is all to arrange order of the design to have [positive
    %outpus, closest zeros in design  space]; This is what gets fed into
    %zGP_gibbs_nrz_optmean
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    y=yimp;
    N=length(y);
    indsp=find(y>0);
    indsz=find(y<0);
    yp=y(indsp);
    Np=length(indsp);
    xdp=X(indsp,:);
    yn=y(indsz);
    Nz=length(indsz);
    xdn=X(indsz,:);
    yRL=median(yimputesave,2);
    distnp=zeros(Nz,Np);

    %%%%%%%%%%%%%%%%%%%%%%%%
    %extra snip to calculate probs of zeros
    %%%%%%%%%%%%%%%%%%%%%%%%%
    mat52 = @(d) (1+sqrt(5)*d+(5/3)*d.^2).*exp(-sqrt(5)*d); 
    Np=length(indsp);
    B=zeros(Nz); %correlation matrix of xp points
    Btemp=zeros(Nz);
    
    H=@(xd)[ones(size(xd,1),1) xd];
    B=H(xd)\yRL;
    mu = @(x) H(x)*B;  
    modelp=ppgasp(xdp,yp-mu(xdp));

    %options.trend=[ones(Np,1)  xdp];
    %options.zero_mean  = false;
    %options.nugget_est = false;
    
    %modelp=ppgasp(xdp,yp,options);
    
    %options.testing_trend=[ones(Nz,1)  xdn];
    %options.mean_only  = false;
    
    pred_model=predict_ppgasp(modelp,xdn);
    pmean=pred_model.mean+mu(xdn);
    % figure(1)
    % plot(pmean,'*')
    psd=pred_model.sd;
    %hold on
    for k=1:length(pmean)
        %line([k k],[pmean(k)-2*psd(k) pmean(k)+2*psd(k)])
        Pn(k)=1/2*(1+erf(-pmean(k)/(psd(k)*sqrt(2))));
    end
    %line([0 100],[0 0],'linewidth',3)
      
    for j=1:Nz
        for k=1:Np
            distnp(j,k)=sqrt((xdn(j,1)-xdp(k,1)).^2+(xdn(j,2)-xdp(k,2)).^2);
        end
    end
    mindist=min(distnp');
    [valsmd  indsmd]=sort(mindist);
    [valspn  indspn]=sort(Pn);
    Ntemp=round(.66*length(indspn));%.66
    indsadd=intersect(indspn(1:Ntemp), indsmd(1:Ntemp));
    
    Ninclude=length(indsadd);
    indsrest=setdiff(1:1:Nz,indsadd);
    xzs=[xdn(indsadd,:); xdn(indsrest,:)];
    xall=[xdp; xzs];
    yall=[yRL(indsp); yRL(indsz(indsadd)); yRL(indsz(indsrest))];
    xp_zp=[xdp; xdn(indsadd,:)];
    yp_zp=[yRL(indsp); yRL(indsz(indsadd))];
    
    %options.trend=[ones(Np+Ninclude,1)  xp_zp];
    %options.zero_mean  = false;
    %options.nugget_est = false;
    model=ppgasp(xp_zp,yp_zp-mu(xp_zp));
    
    % figure(2)
    % plot(mindist,Pn,'*')
    % hold on
    % plot(mindist(indsadd),Pn(indsadd),'r*')
    
    % Imputation 
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %Imputing negative responses to design points that have zero outputs via zGP
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    locs=[0 0]; % specific for another problem, leave as zeros for now
    output=zGP_gibbs_nrz_optmean(xall,yall,Ngibbs,locs, Ninclude); %This takes the initial set of negative samples and refines them with Gibbs sampling
                    %output{1} is set of Gibbs samplings for all y
                    %output{2} are (square of) range parameter
    
                    %samples          
    temp=output{1};
    
    for kk=1:size(X,1)  %rearrange response back to original design
        inds(kk)=find(X(kk,2)==xall(:,2));
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %This is the main output of the zGP algorithm. 
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Return the estimated values
    yzgp=mean(temp(inds,1001:5:end),2);
    
    % Now that we have the zGP ready data, we can train the GP
    H=@(xd)[ones(size(xd,1),1) xd];%
    B=H(xd)\yRL;
    mu = @(x) H(x)*B;
    % % We assume that our bounds are greater than zero
    % if strcmp(lim_type,"upper")==1
    %      if UB~=0
    %         yzgp=-yzgp+UB;
    %     end
    % end
    % 
    % if strcmp(lim_type,"lower")==1
    %      if LB~=0
    %         yzgp=yzgp-LB;
    %     end
    % end
    % 
    % % The data is back to the state that it was when we shifted it back to
    % % zero.
    zgp_output = yzgp-mu(xd);
end

