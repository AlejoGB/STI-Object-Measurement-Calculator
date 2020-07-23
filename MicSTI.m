classdef MicSTI < handle
   properties (SetAccess = public)
      % INPUT
      Nomb;         % Nombre de mic ['ALE' 'FEL' 'PEZ' 'PIE']
      Med;          % Numero de la medicion [1 2 3]
      SNR;          % SNR de la posicion dada 
      FS;           % Frecuencia de muestreo  
        %%%%%%%%%%%%% Nombre Archivos
 
      DataMicNombre;
      
        %%%%%%%%%%%%% Data
      DataMic;
      Tiempo;
      LongDataMic;
      % OUTPUT
      
      Pos     = 0;  % Posiciòn del microfono (a partir de Nombre y Med)
      mF      = 0;
       
   end
   methods
      function obj = MicSTI(N,M,F) %inicializar clase
        obj.Nomb = N;
        obj.Med  = M;
        obj.FS   = F;
        obj.DataMicNombre = ['PA_',obj.Nomb,'_',num2str(obj.Med),'.wav' ];
        obj.DataMic = audioread(obj.DataMicNombre); %data RIR
        obj.LongDataMic = size(obj.DataMic);
        obj.Tiempo = transpose(linspace(0,obj.FS,obj.LongDataMic(1))); %vector tiempo
      end
      function [ STIMale , STIFemale ] = STI(obj,dBZ,SNR,I) %calcular sti 
          %   dBZ por banda
          %
          FMod = [ 0.63 0.8 1 1.25 1.6 2 2.5 3.15 4 5 6.3 8 10 12.5 ]; % 14 frecs de modulacion
          AMK =  [ 46 27 12 6.5 7.5 8 12 ]; %absoulte speech reception threshold (?)
          %weighting and redundancy factors for female and male speech 
          AlfaMale = [ 0.085 0.127 0.230 0.233 0.309 0.224 0.173 ];
          BetaMale = [ 0.085 0.078 0.065 0.011 0.047 0.095 1 ];
          
          AlfaFemale = [ 1 0.117 0.223 0.216 0.328 0.250 0.194 ];
          BetaFemale = [ 1 0.099 0.066 0.062 0.025 0.076 1 ];
          
          filtro = fdesign.octave(1,'Class 0','N,F0',6,1,obj.FS);
          F0 = validfrequencies(filtro);
          %FM = FMod(aux);
          for j=1:7  % 7 bandas de interes
            % Hz: 125  250  500  1K  2K  4K  8K
            filtro.F0 = F0(j+2);
            Hd = design(filtro,'butter');
            DataFilt = filter(Hd,obj.DataMic);
            
            
            for aux=1:14 %frecuencias modulantes
                %funcion de transferencia
                func = DataFilt.*exp((-2i)*pi*FMod(aux).*obj.Tiempo);
                FTM(aux) = trapz(func)/trapz(DataFilt.^2).*(1+10.^(-SNR(j)/10)).^(-1);
                
                %correcion x enmascaramiento
                if j > 1 
                    if ( dBZ(j-1) < 63 ) % dB de la banda anterior
                        amdB = 0.5.*dBZ(j)-65;
                    end;
                    if ( 63 <= dBZ(j-1)) && ( dBZ(j-1) <= 67 )
                        amdB = 1.8.*dBZ(j)-146.9;
                    end;
                    if ( 67 <= dBZ(j-1)) && ( dBZ(j-1) <= 100 )
                        amdB = 0.5.*dBZ(j)-49.8;
                    end;
                    if ( 100 <= dBZ(j-1) )
                        amdB = -10;
                    end;
                    amF = 10^(amdB/10);                                        
                end;
                if j==1
                    amF = 0;
                end;
                
                %intensidad de enmascaramiento
                if j > 1
                    IM = I(j-1)*amF;
                else
                    IM = 0;
                end;
                
                %umbral de intensidad del receptor
                IR = 10^(AMK(j)/10);
                
                %funcion de transferencia correjida
            
                FTMC(aux) = abs( FTM(aux)*(dBZ(j)/(dBZ(j)+IM+IR)) );
                
                %SNR efectivo
                
                SNREF(aux) = 10*log10(FTMC(aux)/(1-FTMC(aux)));
                
                %indice de transmision para cada FMod
                
                TI(aux) = (SNREF(aux)+15)/30;
                               
                
                
                
                
            end;
            
            %indice de modulacion para cada banda de octava
            MTI(j) = abs((1/14)*sum(TI));
            if MTI(j) > 1
                MTI(j) = 1;
            end;
            
            
          end;
          SumMTIMale = 0;
          SumMTIFemale = 0;
          for j=1:7
            SumMTIMale = SumMTIMale + AlfaMale(j)*MTI(j);
            SumMTIFemale = SumMTIFemale + AlfaFemale(j)*MTI(j);
          end;
         
          SumMTIMale2 = 0;
          SumMTIFemale2 = 0;
          for j=1:6
              if j==1
                  SumMTIMale2 = BetaMale(j)*(MTI(j))^(1/2);
                  SumMTIFemale2 = BetaFemale(j)*(MTI(j))^(1/2);
              else
              SumMTIMale2 = SumMTIMale2 + BetaMale(j)*(MTI(j)*MTI(j-1))^(1/2);
              SumMTIFemale2 = SumMTIFemale2 + BetaFemale(j)*(MTI(j)*MTI(j-1))^(1/2);
              end;
          end;
          STIMale = SumMTIMale - SumMTIMale2;
          STIFemale = SumMTIFemale - SumMTIFemale2;
      end
   end
end


