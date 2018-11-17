function lightPropRoll(T, grains, rpm, v, ssd)
% ssd is in mm
if ~isempty(ssd)
    formatSpec = 'lightRollProp_SSD%d_G%d_T%d_RPM%d_V%d.mat';
    fname = sprintf(formatSpec,ssd,grains,T,rpm,v);
else
    formatSpec = 'lightRollProp_G%d_T%d_RPM%d_V%d.mat';
    fname = sprintf(formatSpec,grains,T,rpm,v);
end

[s_prop,fs] = audi_synth(['/Users/gz/Documents/MATLAB/myScripts/audi_synth/' ...
                    'runupMeas_allOnGround_r1'], rpm, T, grains);

N = T*fs;
t = linspace(0, T, T*fs);

s_prop = s_prop(:,2);

cn = dsp.ColoredNoise(1,N,1);
s_roll = cn();
s_roll = s_roll/max(abs(s_roll));
s_prop = max(abs(s_roll))*s_prop/max(abs(s_prop)); % comparable amplitude with noise
% s_roll = max(abs(s_prop))*s_roll/max(abs(s_roll)); % comparable amplitude with noise
                                           % (otherwise the filter outputs a click in the
                                           % beginning)

[lw_prop, lw_roll, fc] = cnossos_source_third(v);
fc = [12.5 16 20 25 31.5 40 fc 12.5e3 16e3 20e3];

octFilt = octaveFilter(fc(1),'1/3 octave','SampleRate',fs,'FilterOrder',6);
for i = 1:length(fc)
    octFilt.CenterFrequency = fc(i);
    % adjust propulsion sound power level
    s_prop_filt(i,:) = octFilt(s_prop);
    xdft = fft(s_prop_filt(i,:));
    xdft = xdft(1:N/2+1);
    psdx = (1/(fs*N)) * abs(xdft).^2;
    psdx(2:end-1) = 2*psdx(2:end-1);
    SPL_oct(i) = 20*log10(sqrt(mean(s_prop_filt(i,:).^2))/2e-5);
    PSD_oct_prop(i) = 10*log10(mean(psdx/1e-12));
end
reset(octFilt)
release(octFilt)

PSD_low_diff = PSD_oct_prop(7) - PSD_oct_prop(1:6);
PSD_high_diff = PSD_oct_prop(end-3) - PSD_oct_prop(end-2:end);


for i = 1:3
    % lw_roll_ext(i,:) = [repmat(lw_roll(i,1),1,5) lw_roll(i,:) repmat(lw_roll(i,end),1,3)];
    % lw_prop_ext(i,:) = [repmat(lw_prop(i,1),1,5) lw_prop(i,:) repmat(lw_prop(i,end),1,3)];
    lw_roll_ext(i,:) = [repmat(0,1,6) lw_roll(i,:) repmat(0,1,3)];
    % lw_prop_ext(i,:) = [repmat(0,1,5) lw_prop(i,:) repmat(0,1,3)];
    lw_prop_ext(i,:) = [lw_prop(i,1)-PSD_low_diff lw_prop(i,:) lw_prop(i,end)-PSD_high_diff];
end

lw_roll = lw_roll_ext;
lw_prop = lw_prop_ext;

Pac0 = 1e-12;

octFilt = octaveFilter(fc(1),'1/3 octave','SampleRate',fs,'FilterOrder',6);
for i = 1:length(fc)
    % air attenuation
    octFilt.CenterFrequency = fc(i);
    % adjust rolling noise sound power level
    s_roll_filt(i,:) = octFilt(s_roll);
    xdft = fft(s_roll_filt(i,:));
    xdft = xdft(1:N/2+1);
    psdx = (1/(fs*N)) * abs(xdft).^2;
    psdx(2:end-1) = 2*psdx(2:end-1);
    SPL_oct(i) = 20*log10(sqrt(mean(s_roll_filt(i,:).^2))/2e-5);
    PSD_oct(i) = 10*log10(mean(psdx/1e-12));
    psdx = psdx*10^((lw_roll(1,i)-PSD_oct(i))/10);
    
    s_roll_filt(i,:) = s_roll_filt(i,:).*10.^((lw_roll(1,i)-PSD_oct(i))/20);
end
reset(octFilt)
release(octFilt)

octFilt = octaveFilter(fc(1),'1/3 octave','SampleRate',fs,'FilterOrder',6);
for i = 1:length(fc)
    % air attenuation
    octFilt.CenterFrequency = fc(i);
    % adjust propulsion sound power level
    s_prop_filt(i,:) = octFilt(s_prop);
    xdft = fft(s_prop_filt(i,:));
    xdft = xdft(1:N/2+1);
    psdx = (1/(fs*N)) * abs(xdft).^2;
    psdx(2:end-1) = 2*psdx(2:end-1);
    SPL_oct(i) = 20*log10(sqrt(mean(s_prop_filt(i,:).^2))/2e-5);
    PSD_oct_prop(i) = 10*log10(mean(psdx/1e-12));
    psdx = psdx*10^((lw_prop(1,i)-PSD_oct_prop(i))/10);

    s_prop_filt(i,:) = s_prop_filt(i,:).*10.^((lw_prop(1,i)-PSD_oct_prop(i))/20);
end

s_roll = sum(s_roll_filt,1)';
s_prop = sum(s_prop_filt,1)';

if ~isempty(ssd)
    h = make_wfs_prefilter(fs, 343/(ssd/1000)/2, 120, 1024);
    s_prop = filter(h,1,s_prop);
    s_roll = filter(h,1,s_roll);
end

save(fname,'s_prop','s_roll','fs','T','grains','rpm','v','ssd')
disp(fname)
