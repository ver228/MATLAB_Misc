function result = nanwmean (values, weights)

    weighted = values.*weights;
    result = nansum(weighted)/sum(weights(~isnan(weighted)));

end