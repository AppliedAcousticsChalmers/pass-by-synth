clear all
T = 30;
grains = 12;
ssd = 154;
rpm = [2000 3000];
v = 20:70;

vs = repmat(v,1,length(rpm));
rpms = sort(repmat(rpm,1,length(v)));

parfor i = 1:length(vs)
    lightPropRoll(T,grains,rpms(i),vs(i),ssd);
end
%%
max_value = 0;
for i = 1:length(vs)
    formatSpec = 'lightRollProp_SSD%d_G%d_T%d_RPM%d_V%d.mat';
    fname = sprintf(formatSpec,ssd,grains,T,rpms(i),vs(i));
    load(fname)
    
    
    max_value = max(max(abs(s_prop+s_roll)), max_value);
    disp([i, max_value])
end


dname = 'stationarySignals';
mkdir(dname)

for i = 1:length(vs)
    formatSpec = 'lightRollProp_SSD%d_G%d_T%d_RPM%d_V%d.mat';
    fname = sprintf(formatSpec,ssd,grains,T,rpms(i),vs(i));
    load(fname)

    formatSpecRoll = 'lightRoll_SSD%d_G%d_T%d_RPM%d_V%d.wav';
    formatSpecProp = 'lightProp_SSD%d_G%d_T%d_RPM%d_V%d.wav';
    fnameProp = sprintf(strcat(dname,'/',formatSpecProp),ssd,grains,T,rpms(i),vs(i));
    fnameRoll = sprintf(strcat(dname,'/',formatSpecRoll),ssd,grains,T,rpms(i),vs(i));

    audiowrite(fnameRoll,s_roll/max_value,fs)
    audiowrite(fnameProp,s_prop/max_value,fs)
    
    disp(i)
end