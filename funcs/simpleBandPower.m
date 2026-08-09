function bp = simpleBandPower(x, Fs, freqBand)
    % simpleBandPower estimates signal power in a frequency band
    % without using the Signal Processing Toolbox.
    %
    % x        : time-series signal
    % Fs       : sampling frequency in Hz
    % freqBand : [fmin fmax] in Hz

    x = x(:);

    % Remove mean so DC offset does not dominate low-frequency power
    x = x - mean(x);

    N = numel(x);

    % FFT
    X = fft(x);

    % Two-sided power spectral density estimate
    P2 = (abs(X).^2) / (Fs * N);

    % Convert to one-sided PSD
    if mod(N,2) == 0
        P1 = P2(1:N/2+1);
        P1(2:end-1) = 2*P1(2:end-1);
        f = Fs*(0:N/2)'/N;
    else
        P1 = P2(1:(N+1)/2);
        P1(2:end) = 2*P1(2:end);
        f = Fs*(0:(N-1)/2)'/N;
    end

    % Select frequencies in band
    idx = f >= freqBand(1) & f <= freqBand(2);

    % Integrate PSD over selected band
    bp = trapz(f(idx), P1(idx));
end