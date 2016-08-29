n_epochs = length(time_M);
n_sta = size(pr1_R,3)+1;

target_sta = n_sta;
phase = 1;

name = cell(n_sta,1);
antenna = cell(n_sta,1);
time = cell(n_sta,1);
L1 = cell(n_sta,1);
L2 = cell(n_sta,1);
P1 = cell(n_sta,1);
P2 = cell(n_sta,1);
PCO1 = cell(n_sta,1);
PCO2 = cell(n_sta,1);
PCV1 = cell(n_sta,1);
PCV2 = cell(n_sta,1);
azim = cell(n_sta,1);
elev = cell(n_sta,1);

time_RM = time_R; time_RM(:,:,n_sta) = time_M;
pr1_RM = pr1_R; pr1_RM(:,:,n_sta) = pr1_M;
ph1_RM = ph1_R; ph1_RM(:,:,n_sta) = ph1_M;
pr2_RM = pr2_R; pr2_RM(:,:,n_sta) = pr2_M;
ph2_RM = ph2_R; ph2_RM(:,:,n_sta) = ph2_M;
snr1_RM = snr1_R; snr1_RM(:,:,n_sta) = snr1_M;
pos_RM = pos_R; pos_RM(:,:,n_sta) = pos_M(:,1);

for k = 1 : n_sta
    
    name{k} = cell2mat(marker_RM(:,:,k));
    antenna{k} = cell2mat(antmod_RM(:,:,k));
    time{k} = datenum(date_M);
    L1{k}   = NaN(nSatTot,n_epochs);
    L2{k}   = NaN(nSatTot,n_epochs);
    P1{k}   = NaN(nSatTot,n_epochs);
    P2{k}   = NaN(nSatTot,n_epochs);
    PCO1{k} = NaN(nSatTot,n_epochs);
    PCO2{k} = NaN(nSatTot,n_epochs);
    PCV1{k} = NaN(nSatTot,n_epochs);
    PCV2{k} = NaN(nSatTot,n_epochs);
    azim{k} = NaN(nSatTot,n_epochs);
    elev{k} = NaN(nSatTot,n_epochs);
    
    for t = 1 : n_epochs
        
        Eph_t = rt_find_eph(Eph, time_RM(t,1,k), constellations.nEnabledSat);
        
        %available satellites
        sat0 = find(pr1_RM(:,t,k) ~= 0);
        
        if (numel(sat0) >= 4)
            
            if (any(pos_RM(:,1,k)))
                flag_XR = 1;
            else
                flag_XR = 0;
            end
            
            %compute satellite azimuth and elevation
            [~, ~, XS, ~, ~, ~, ~, ~, ~, sat, el, az, ~, sys] = init_positioning(time_RM(t,1,k), pr1_RM(sat0,t,k), snr1_RM(sat0,t,k), Eph_t, SP3, iono, [], pos_RM(:,1,k), [], [], sat0, [], lambda(sat0,:), 0, 0, phase, flag_XR, 0, 0);

%             if ((any(ph1_RM(sat,t,k) == 0) || any(ph2_RM(sat,t,k) == 0) || ...
%                  any(pr1_RM(sat,t,k) == 0) || any(pr2_RM(sat,t,k) == 0)) && k == target_sta)
%                 continue
%             end
            
            azim{k}(sat,t) = az;
            elev{k}(sat,t) = el;
            
            %apply phase center variation
            if (~isempty(antenna_PCV) && antenna_PCV(k).n_frequency ~= 0) % rover
                PCO1{k}(sat,t) = PCO_correction(antenna_PCV(k), pos_RM(:,1,k), XS, sys, 1);
                PCV1{k}(sat,t) = PCV_correction(antenna_PCV(k), 90-el, az, sys, 1);
                index_pr = find(pr1_RM(sat,t,k) ~= 0);
                index_ph = find(ph1_RM(sat,t,k) ~= 0);
                pr1_RM(sat(index_pr),t,k) = pr1_RM(sat(index_pr),t,k) - (PCO1{k}(sat(index_pr),t) + PCV1{k}(sat(index_pr),t));
                ph1_RM(sat(index_ph),t,k) = ph1_RM(sat(index_ph),t,k) - (PCO1{k}(sat(index_ph),t) + PCV1{k}(sat(index_ph),t))./lambda(sat(index_ph),1);
                
                if (length(frequencies) == 2 || frequencies(1) == 2)
                    PCO2{k}(sat,t) = PCO_correction(antenna_PCV(k), pos_RM(:,1,k), XS, sys, 2);
                    PCV2{k}(sat,t) = PCV_correction(antenna_PCV(k), 90-el, az, sys, 2);
                    index_pr = find(pr2_RM(sat,t,k) ~= 0);
                    index_ph = find(ph2_RM(sat,t,k) ~= 0);
                    pr2_RM(sat(index_pr),t,k) = pr2_RM(sat(index_pr),t,k) - (PCO2{k}(sat(index_pr),t) + PCV2{k}(sat(index_pr),t));
                    ph2_RM(sat(index_ph),t,k) = ph2_RM(sat(index_ph),t,k) - (PCO2{k}(sat(index_ph),t) + PCV2{k}(sat(index_ph),t))./lambda(sat(index_ph),2);
                end
            end

            L1{k}(sat,t) = ph1_RM(sat,t,k);
            L2{k}(sat,t) = ph2_RM(sat,t,k);
            P1{k}(sat,t) = pr1_RM(sat,t,k);
            P2{k}(sat,t) = pr2_RM(sat,t,k);
        end
    end

    for PRN = 1 : nSatTot
        zero_idx = find(P1{k}(PRN,:) == 0);
        P1{k}(PRN,zero_idx) = NaN; %#ok<*FNDSB>
        
        zero_idx = find(P2{k}(PRN,:) == 0);
        P2{k}(PRN,zero_idx) = NaN;
    end
end

%compute diff_L4
[diff_L4, diff_P4, commontime, stations_idx, ~, ~, L4, P4] = compute_diff(L1, L2, P1, P2, name, time);

til_L2 = NaN(size(L2{target_sta}));
til_P2 = til_L2;
fix_til_L2 = til_L2;
fix_til_P2 = til_P2;

%interpolate dL4
for PRN = 1 : nSatTot
    
    %compute IPP
    [satel(PRN).ipp_lat, satel(PRN).ipp_lon, satel(PRN).elR] = IPP_satspec(elev, azim, commontime, stations_idx, PRN, pos_RM); %#ok<*SAGROW>
    
    %interpolate dL4 and compute ~L4
    [satel(PRN).til_L4] = planefit_satspec_diff_obs(diff_L4, commontime, satel(PRN).ipp_lon, satel(PRN).ipp_lat, PRN, target_sta, 1);
    
    %interpolate P4 and compute ~P4
    [satel(PRN).til_P4] = planefit_satspec_diff_obs(P4, commontime, satel(PRN).ipp_lon, satel(PRN).ipp_lat, PRN, target_sta, 0);

    %compute ~L2
    til_L2(PRN,stations_idx(target_sta,:)) = (L1{target_sta}(PRN,stations_idx(target_sta,:))*lambda(PRN,1) - satel(PRN).til_L4)/lambda(PRN,2);
    
    %compute ~P2
    til_P2(PRN,stations_idx(target_sta,:)) = P1{target_sta}(PRN,stations_idx(target_sta,:)) + satel(PRN).til_P4;
    
    %compute fix ~L2 (remove large outliers)
    fix_til_L2(PRN,:) = fix_jump(til_L2,PRN,0.6*10e7);
    
    %compute fix ~P2 (remove large outliers)
    fix_til_P2(PRN,:) = fix_jump(til_P2,PRN,0.6*10e7);
end

%write new RINEX file
pos = find(filerootOUT == '/'); if(isempty(pos)), pos = find(filerootOUT == '\'); end;
out_path = filerootOUT(1:pos(end));

pos = find(filename_M_obs == '/'); if(isempty(pos)), pos = find(filename_M_obs == '\'); end;
pos2 = find(filename_M_obs == '.');
SEID_filename = filename_M_obs(pos(end)+1:pos2-1);
SEID_ext = filename_M_obs(pos2:end);
outputfile_path = strcat(out_path, [SEID_filename '_SEID' SEID_ext]);
temporaryfile_path = strcat(out_path, [SEID_filename '_SEID_TEMP' SEID_ext]);

new_interval = 30;

%add back PCO, PCV
%P1_new = P1{target_sta}(:,1:end-1) + (PCO1{target_sta}(:,1:end-1) + PCV1{target_sta}(:,1:end-1));
%L1_new = L1{target_sta}(:,1:end-1) + (PCO1{target_sta}(:,1:end-1) + PCV1{target_sta}(:,1:end-1))./repmat(lambda(:,1),1,size(P1_new,2));
P2_new =     fix_til_P2(:,1:end-1) + (PCO2{target_sta}(:,1:end-1) + PCV2{target_sta}(:,1:end-1));
L2_new =     fix_til_L2(:,1:end-1) + (PCO2{target_sta}(:,1:end-1) + PCV2{target_sta}(:,1:end-1))./repmat(lambda(:,2),1,size(P2_new,2));

write_RINEX_obs(temporaryfile_path, '', antenna_PCV(target_sta).name, cell2mat(marker_M), ...
                 pr1_M(:,1:end-1), P2_new, ph1_M(:,1:end-1), L2_new, dop1_M(:,1:end-1), dop2_M(:,1:end-1), ...
                 snr1_M(:,1:end-1), snr2_M(:,1:end-1), time_M(1:end-1,1), date_M(1:end-1,:), ...
                 pos_M(:,1), new_interval, codeC1_M);

undersamplingRINEX(temporaryfile_path, outputfile_path, 0, new_interval, interval);

fprintf(['Output file: ' outputfile_path '\n']);

delete(temporaryfile_path);