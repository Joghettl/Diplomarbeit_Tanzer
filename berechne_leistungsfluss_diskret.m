% Die Funktion wurde von einem anderen Programm (selbst geschrieben)
% übernommen -> Passt daher von der Nomenklatur nicht 100 % zum dynamischen
% Skript
function [T_res, U_out, d_out, x_out, U, delta] = berechne_leistungsfluss_diskret(P_load, Q_load, n_active, p, L_line_mesh)
    Z_bez = (p.Un^2)/p.Sn; % Bezugsimpedanz
    
    n_total = 4; % Anzahl der netzknoten
    n_ss = 3; 
    
    
    % Doppelleitung
    Z_line_1 = (p.R_per_km+ 1j*p.X_per_km)* p.L_total; %Leitungsimpedanz 1 System
    Y_shunt_1 = 1j * 2* pi *p.f * p.C_per_km * p.L_total; % Queradmittanz 
    
    y_series = n_active * (1 /(Z_line_1 /Z_bez)); % bez. Längsadmittanz
    y_shunt_half = n_active * ((Y_shunt_1 * Z_bez) / 2); % bez. halbe Queradmittanz
    
    % Mesh-Leitung
    Z_phys_mesh = (p.R_per_km + 1j*p.X_per_km) * L_line_mesh; % Vermaschungsleitung Längsimpedanz
    Y_shunt_phys_mesh = 1j * 2 * pi * p.f * p.C_per_km * L_line_mesh; % Vermaschungsleitung Queradmittanz
    
    y_series_mesh = 1 /(Z_phys_mesh / Z_bez); % bez.Längsimpedanz
    y_shunt_half_mesh = (Y_shunt_phys_mesh * Z_bez) / 2; % bez. Queradmittanz
    if(L_line_mesh > 200)
        y_series_mesh = 0; 
        y_shunt_half_mesh = 0;
    end
    
    % Gesamt-Längssadmittanz
    y_ser_tot = y_series + y_series_mesh; % bez. Längsadmittanz
    y_sh_tot  = y_shunt_half + y_shunt_half_mesh; %bez. Queradmittanz
    
    % Externe Netze
    z_grid_abs = 1.1*(p.Un)^2/p.Sk; % Netzimpedanz
    X_grid = 1*2*pi*p.f*(z_grid_abs/((1/p.Tg)^2+(2*pi*p.f)^2)^(1/2)); % Netzreaktanz
    R_grid = (z_grid_abs^2-X_grid^2)^(1/2); % Netzwiderstand
    y_grid = 1 /((R_grid+ 1j*X_grid)/Z_bez); % Netzadmittanz bezogen
    
    z_grid2_abs = (1.1 * p.Un^2 / p.Sk2) / Z_bez; % Netzimpedanz 2 bezogen
    y_grid2 = 1 / (z_grid2_abs * exp(1j * atan(p.XR2))); % Netzadmittanz 2 bezogen
    
   
    % Admittanzmatrix

    Y_bus = zeros(n_total, n_total);
    
    % Netzanbindung  der Netzimpedanz 1 an SS1 
    Y_bus(1,1) = y_grid; 
    Y_bus(2,2) = y_grid; 
    Y_bus(1,2) = -y_grid; 
    Y_bus(2,1) = -y_grid;
    
    % Leitung zwischen SS1 und SS2 
    Y_bus(2,2) = Y_bus(2,2) + y_ser_tot + y_sh_tot;
    Y_bus(3,3) = Y_bus(3,3) + y_ser_tot +y_sh_tot;
    Y_bus(2,3) = -y_ser_tot;
    Y_bus(3,2) = -y_ser_tot;
    
    % Netzanbindung der Netzimpedanz 2 an SS2
    Y_bus(3,3) = Y_bus(3,3) + y_grid2;
    Y_bus(4,4) = y_grid2;
    Y_bus(3,4) = -y_grid2;
    Y_bus(4,3) = -y_grid2;
    
 
    % Newton-Raphson-Verfahren
  
    Y_mag = abs(Y_bus); 
    theta = angle(Y_bus);
    U = ones(n_total, 1); 
    delta = zeros(n_total, 1); 
    
    idx_P = 2:n_total; % Knoten 2, 3, 4
    idx_Q = 2:n_ss;    % Knoten 2, 3
    n_ang = length(idx_P);
    n_vol = length(idx_Q);
    
    for iter = 1:p.max_iter
        P_c = zeros(n_total, 1); 
        Q_c = zeros(n_total, 1);
        for i = 1:n_total
            for j = 1:n_total
                P_c(i) = P_c(i) + U(i)*U(j)* Y_mag(i,j)*cos(theta(i,j) + delta(j) - delta(i)); %Leistungsgleichungen
                Q_c(i) = Q_c(i) - U(i)* U(j)*Y_mag(i,j)*sin(theta(i,j) + delta(j) - delta(i)); % Blindleistungsgleichung
            end
        end
        
        dP = zeros(n_ang, 1); dQ = zeros(n_vol, 1);
        for ir = 1:n_ang
            i = idx_P(ir);
            if i == 2
                dP(ir) = p.P_gen - P_c(i);             % Generator 1 an SS1
            elseif i == 3
                dP(ir) = P_load + p.P_gen - P_c(i);    % Last + Gen 2 an SS2
            elseif i == 4
                dP(ir) = 0 - P_c(i);                   % Generator am PV-Knoten
            end
        end
        for ir = 1:n_vol
            i = idx_Q(ir);
            if i == 2, dQ(ir) = p.Q_gen - Q_c(i);
            elseif i == 3, dQ(ir) = Q_load + p.Q_gen - Q_c(i);
            end
        end
        
        mis = [dP; dQ]; 
        if norm(mis) < p.epsilon, break; end
        
        J11 = zeros(n_ang, n_ang); J12 = zeros(n_ang, n_vol); % Inititialisierung Jacobimatrix
        J21 = zeros(n_vol, n_ang); J22 = zeros(n_vol, n_vol); 
        
        for r1 = 1:n_ang
            i = idx_P(r1);
            % Leistungsgleichungen, Ableitung nach Spannungswinkel delta
            for r2 = 1:n_ang
                j = idx_P(r2);
                if i == j, J11(r1,r2) = -Q_c(i) - (U(i)^2)*imag(Y_bus(i,i)); 
                else, J11(r1,r2) = U(i)*U(j)*(real(Y_bus(i,j))*sin(delta(i)-delta(j)) - imag(Y_bus(i,j))*cos(delta(i)-delta(j))); end
            end
            %Leistunggleichung, Ableitung nach der Spannung
            for r2 = 1:n_vol
                j = idx_Q(r2);
                if i == j, J12(r1,r2) = (P_c(i)/U(i)) + U(i)*real(Y_bus(i,i)); % Hauptdiogonal Elemente 
                else, J12(r1,r2) = U(i)*(real(Y_bus(i,j))*cos(delta(i)-delta(j)) + imag(Y_bus(i,j))*sin(delta(i)-delta(j))); end  % Nebendiagonal Elemente 
            end
        end
        % Blindleistungsgleichung, Ableitung nach dem Spannungswinkel
        for r1 = 1:n_vol
            i = idx_Q(r1);
            for r2 = 1:n_ang
                j = idx_P(r2);
                if i == j, J21(r1,r2) = P_c(i) - (U(i)^2)*real(Y_bus(i,i)); % Hauptdiogonal Elemente
                else, J21(r1,r2) = U(i)*U(j)*(-real(Y_bus(i,j))*cos(delta(i)-delta(j)) -imag(Y_bus(i,j))*sin(delta(i)-delta(j))); end % Nebendiagonal Elemente 
            end
         % Blindleistungsgleichung, Ableitung nach der Spannung
            for r2 = 1:n_vol
                j = idx_Q(r2);
                if i == j, J22(r1,r2) = (Q_c(i)/U(i)) - U(i)*imag(Y_bus(i,i)); %Hauptiagonal Elemente
                else, J22(r1,r2) = U(i)*(real(Y_bus(i,j))*sin(delta(i)-delta(j)) - imag(Y_bus(i,j))*cos(delta(i)-delta(j))); end % Nebendiagonalelemente 
            end
        end
        
        dx = [J11 J12; J21 J22] \ mis; % Abweichung
        delta(idx_P) = delta(idx_P) + dx(1:n_ang); % Update für Iterationsschritt
        U(idx_Q) = U(idx_Q) + dx(n_ang+1:end); % Update für Iterationsschritt
    end
    
    %Postprocessing, Berechnung von P_recv
    delta_deg = delta * 180/pi;
    
   
    V1_c = U(2) * exp(1j *delta(2)); 
    V2_c = U(3) * exp(1j * delta(3));
   
    I_line_21_arr = (V1_c - V2_c) * y_series - V2_c * y_shunt_half; %Strom über Leitung 
    P_recv_out = real(V2_c * conj(I_line_21_arr)); % P_recv berechnet
    
    T_res = table(n_active, P_load, Q_load, U(3), delta_deg(3), iter, P_recv_out, ...
                  'VariableNames', {'LTG', 'P_soll', 'Q_soll', 'U_End', 'd_End', 'Iter', 'P_recv'});
                  
    for k = 1:3 
        T_res.(['U' num2str(k)]) = U(k); T_res.(['d' num2str(k)]) = delta_deg(k);
    end
    
    U_out = U(1:3);
    d_out = delta_deg(1:3);
    x_out = [0, p.L_total];
end