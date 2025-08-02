function predicted_outputs = predicted_outputs2(model, Input, out_dim, scaling_factors, zGP_index, lim_types, shifts, yRLs, original_input)
% PREDICTED_OUTPUTS2
% There might be an issue with the testing trend, which requires a new
% approach
    %options.testing_trend=[ones(numel(Input(:,1)),out_dim)  Input];
    %options.mean_only  = false; 
    

    pred_model=predict_ppgasp(model,Input);

    for i = 1:numel(zGP_index)
        yRL = yRLs(:,i);
        H=@(xd)[ones(size(xd,1),1) xd];%
        B=H(original_input)\yRL;
        mu = @(x) H(x)*B;

        type = lim_types(i);
        scaling_factor = scaling_factors(i);
        shift = shifts(i);

        if strcmp("upper",type) == 1
            pmean = pred_model.mean(:,zGP_index(i))+mu(Input);
            pmean = shift + min(-scaling_factor*pmean+scaling_factor,scaling_factor);
            pred_model.mean(:,zGP_index(i)) = pmean;
        end
        
        if strcmp("lower",type) == 1
            pmean = pred_model.mean(:,zGP_index(i))+mu(Input);
            pmean = shift + max(scaling_factor*pmean,0);
            pred_model.mean(:,zGP_index(i)) = pmean;
        end

        pred_model.sd(:,zGP_index(i)) = scaling_factor*pred_model.sd(:,zGP_index(i));
    end
   predicted_outputs = pred_model;
end

