function  [Stot, Fs] = audi_synth(fname, rpm, T_sec, grain_var)

% fname = 'runupMeas_r4';
%[rec,Fs] = audioread('runupMeas_allOnGround_r1.flac');
[rec,Fs] = audioread(strcat(fname,'_high.flac'));

%MIDDLE MIC
data_high = rec(:,1);

%ENGINE MIC
data2_high = rec(:,2);

%EXHAUST MIC
data3_high = rec(:,3);


fid = fopen(strcat(fname,'_high.txt'));
glist = textscan(fid,'%f %f %f', 'collectoutput', true, 'Delimiter',',\n');
fclose(fid);
glist = glist{1};

% S = struct('grain', cell(1, 1500), 'left', cell(1, 1500), 'right', cell(1, 1500));
n_grain = size(glist,1);
for i=1:n_grain
    
    idx_start = glist(i,1);
    idx_end = glist(i,2);
    N_tail = glist(i,3);
    
    data_grain = data_high( idx_start : idx_end );
    S(i).grain = data_grain;
    S(i).left = data_high( idx_start-N_tail : idx_start-1);
    S(i).right = data_high( idx_end+1 : idx_end+N_tail);
    
    data2_grain = data2_high( idx_start : idx_end );
    S2(i).grain = data2_grain;
    S2(i).left = data2_high( idx_start-N_tail : idx_start-1);
    S2(i).right = data2_high( idx_end+1 : idx_end+N_tail);
    
    data3_grain = data3_high( idx_start : idx_end );
    S3(i).grain = data3_grain;
    S3(i).left = data3_high( idx_start-N_tail : idx_start-1);
    S3(i).right = data3_high( idx_end+1 : idx_end+N_tail);
end
% synthesize constant rpm (TODO: include ac/de-celeration)
% rpm = 2000;
% grain_var = 10; % grain variability
% T_sec = 5; % duration in sec

grainN = Fs/(rpm/60);
[~, grain_max] = min(abs(glist(:,3)-grainN/2));
T_grains = ceil(T_sec*Fs/grainN/2)+1; % duration in grains

if grain_max < grain_var
    grain_max = grain_var;
end

h = nonRepeatingRand(grain_var,T_grains,2^8)+grain_max-grain_var;

clear Stot S.tapered S2.tapered

tape = min(glist(:,3));
const_win = 2*tape+1;
win_L = circshift(hann(const_win), (const_win+1)/2);
win_R = hann(const_win);
win_L = win_L(1:tape);
win_R = win_R(1:tape);

Stot1 = [];
Stot2 = [];
Stot3 = [];
for n = 1:T_grains-1
    S(h(n)).tapered = S(h(n)).grain;
    S2(h(n)).tapered = S2(h(n)).grain;
    S3(h(n)).tapered = S3(h(n)).grain;

    S(h(n)).tapered(end-tape+1:end)  = S (h(n)).grain(end-tape+1:end).*win_L + S (h(n+1)).left(end-tape+1:end).*win_R;
    S2(h(n)).tapered(end-tape+1:end) = S2(h(n)).grain(end-tape+1:end).*win_L + S2(h(n+1)).left(end-tape+1:end).*win_R;
    S3(h(n)).tapered(end-tape+1:end) = S3(h(n)).grain(end-tape+1:end).*win_L + S3(h(n+1)).left(end-tape+1:end).*win_R;

    % change for different mics
    Stot1 = [Stot1; S(h(n)).tapered]; % side mic
    Stot2 = [Stot2; S2(h(n)).tapered]; % front mic
    Stot3 = [Stot3; S3(h(n)).tapered]; % back mic
    %     Stot = [Stot; S2(h(n)).tapered]; % front mic
    %     Stot = [Stot; S3(h(n)).tapered]; $ back mic

end
Stot = [Stot1 Stot2 Stot3];
Stot = Stot(1:T_sec*Fs, :);
% soundsc(Stot,Fs)
% audiowrite('123.wav',Stot,Fs);
