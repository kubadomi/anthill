clear all
clc
opts = delimitedTextImportOptions("NumVariables", 16);
opts.VariableNames = ["time", "season", "living", "eggs", "larvas", "pupas", "imagos", "old_ones", "dead", "food", "working", "sleeping", "eating", "waiting", "reproducting", "heavines"];
opts.VariableTypes = ["double", "categorical", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double"];

% Import data
raport = readtable("C:\Users\Adrian\Downloads\raport.txt", opts);
figure(1)

plot(raport.time,raport.living);
xlabel("Time[s]");
ylabel("Number of living")

figure(2)
plot(raport.time,raport.eggs);
xlabel("Time[s]");
ylabel("Number of eggs")

figure(3)
plot(raport.time,raport.larvas);
xlabel("Time[s]");
ylabel("Number of larvas")

figure(4)
plot(raport.time,raport.pupas);
xlabel("Time[s]");
ylabel("Number of pupas")

figure(5)
plot(raport.time,raport.imagos);
xlabel("Time[s]");
ylabel("Number of imagos")

figure(6)
plot(raport.time,raport.old_ones);
xlabel("Time[s]");
ylabel("Number of Old Ones")

figure(7)
plot(raport.time,raport.dead);
xlabel("Time[s]");
ylabel("Number of dead")

figure(8)
plot(raport.time,raport.food);
xlabel("Time[s]");
ylabel("Number of food")

figure(9)
plot(raport.time,raport.working);
xlabel("Time[s]");
ylabel("Number of working")

figure(10)
plot(raport.time,raport.sleeping);
xlabel("Time[s]");
ylabel("Number of sleeping")

figure(11)
plot(raport.time,raport.eating);
xlabel("Time[s]");
ylabel("Number of eating")

figure(12)
plot(raport.time,raport.waiting);
xlabel("Time[s]");
ylabel("Number of waiting")

figure(13)
plot(raport.time,raport.reproducting);
xlabel("Time[s]");
ylabel("Number of reproducting")

figure(14)
plot(raport.time,raport.heavines);
xlabel("Time[s]");
ylabel("Number of heavines")
