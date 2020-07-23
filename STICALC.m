

% STI IEC 60268-16
% METODO INDIRECTO
% para funcionar (no se xq,ya fue) antes de correr este codigo
% hay que correr esta linea : M2 = MicSTI('ALE',2,48000)
%
fs = 48000;
Nombres = ['ALE' 'FEL' 'PEZ' 'PIE'];
Pos = [ 1 2 3 ];
ExtDatadBZ = xlsread('dBZ');
ExtDataSNR = xlsread('SNR');

for aux=2:13;
    
    dBZ = ExtDatadBZ(aux,:);

    SNR = ExtDataSNR(aux,:);
    
    I = 10.^(dBZ/10);
    
    aux2=1;
    aux3=1;
             
    M(aux) = MicSTI ( Nombres(aux2:aux2+2) , Pos(aux3) , fs );
    [ SM(aux) , SF(aux) ] = STI( M(aux) , dBZ , SNR , I );
    aux3 = aux3 + 1;
    if aux3 == 3;
        aux2 = aux2 + 1;
        aux3 = 1;
    end;
end;
SM = transpose(SM);
SF = transpose(SF); % :)
    
    