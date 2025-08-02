function predicted_outputs = predicted_outputs(model, Input, out_dim, scaling_factors, zGP_index, lim_types, shifts)
% PREDICTED_OUTPUTS 
    options.testing_trend=[ones(numel(Input(:,1)),out_dim)  Input];
    options.mean_only  = false; 
    
    pred_model=predict_ppgasp(model,Input,options);

    for i = 1:numel(zGP_index)
        type = lim_types(i);
        scaling_factor = scaling_factors(i);
        shift = shifts(i);

        if strcmp("upper",type) == 1
            pred_model.mean(:,zGP_index(i)) = shift+min(scaling_factor*pred_model.mean(:,zGP_index(i)),scaling_factor);
        end
        
        if strcmp("lower",type) == 1
            pred_model.mean(:,zGP_index(i)) = shift+max(scaling_factor*pred_model.mean(:,zGP_index(i)),0);
        end

        pred_model.sd(:,zGP_index(i)) = scaling_factor*pred_model.sd(:,zGP_index(i));
    end
   predicted_outputs = pred_model;
end

