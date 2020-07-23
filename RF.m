clc
clear all
% load('Ruido.mat','SignaldB');
%%
PondA = [-44.7 -39.4 -34.6 -30.2 -26.2 -22.5 -19.1 -16.1 -13.4 -10.9 -8.6 ...
        -6.6 -4.8 -3.2 -1.9 -0.8 0 0.6 1 1.2 1.3 1.2 1 0.5 -.1 -1.1 -2.5 -4.3 -6.6 -9.3]; % Ponderación A De 25 HZ a 16 kHz x1/3Oct
Name = ['ALE' 'FEL' 'PEZ' 'PIE'];
med = [1 2 3];
c = 1;
C = 0;
%% CALIBRACIONES
for A=1:4
    C=C+1;
    cal = ['CAL_',num2str(Name(c:c+2)),'_01.wav']; % Nombre de la calibración
    [cal, fs]=audioread(cal);
    RmsCal=rms(cal(length(cal)/2:length(cal)/2+fs));
    CalRMS(C) = RmsCal;
    c=c+3;
end
c = 1;
C = 0;
%% Filtro
filtro = fdesign.octave(3,'Class 0','N,F0',6,1,fs); %Tercio de octava, 6to orden
F0 = validfrequencies(filtro);
%% Obtención de datos
for A=1:4
    for med=1:3
    signal = ['RF_',num2str(Name(c:c+2)),'_',num2str(med),'.wav']; % Nombre de la calibración
    [signal, fs]=audioread(signal);
    signalPA = transpose(signal)*10/CalRMS(A);
    C=1;
        for i=1:length(F0)
             filtro.F0 = F0(i); %Asigna la frecuencia del filtro
             Hd = design(filtro,'butter');
             SignalxBanda(:,i) = filter(Hd,signalPA);
             SignaldB(med,i,A) = 20*log10((rms(SignalxBanda(:,i)))/2e-5); %Paso a dBZ
             clear SignalxBanda
        end
    SignaldBA(C,:) = SignaldB(med,:,A)+PondA; %Paso a dBA
    C=C+1;
    end
c=c+3;
end
save('Ruido.mat','SignaldB','SignaldBA','F0')