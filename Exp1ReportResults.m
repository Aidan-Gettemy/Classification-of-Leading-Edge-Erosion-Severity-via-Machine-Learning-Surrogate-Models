% We need a script in order to make some summary tables
addpath erosionfuncs\
% % First, plot a representation of the three blade shapes:
% shapes = ["Linear","Quadratic","Cubic"];
% nodeLocs = [0, 2.8667, 5.6, 8.333, 11.75, ...
%     15.85, 19.95, 24.05, 28.15, 32.25, 36.35, ...
%     40.45, 44.55, 48.65, 52.75, 56.1667, 58.9, 61.633];
% 
% reg1 = [nodeLocs(4) nodeLocs(6)];
% reg2 = [nodeLocs(6) nodeLocs(8)];
% reg3 = [nodeLocs(8) nodeLocs(10)];
% reg4 = [nodeLocs(10) nodeLocs(12)];
% reg5 = [nodeLocs(12) nodeLocs(14)];
% reg6 = [nodeLocs(14) nodeLocs(18)];
% 
% total_len = nodeLocs(18) - nodeLocs(4);
% 
% mids = zeros(6,1);
% 
% for i = 1:6
%     phrase = "reg"+num2str(i);
%     phrase = "("+phrase+"(2)+"+phrase+"(1))/2" +"-nodeLocs(4)";
%     phrase = "("+phrase+")/total_len";
%     phrase = "mids("+num2str(i)+",1) = "+phrase+";";
%     eval(phrase)
% end
% f = figure;
% f.Position = [50 50 1350 550];
% for j = 1:3
%     subplot(1,3,j)
%     bladeprofs = zeros(10,6);
%     alphas = linspace(0,1,5);
%     hold on
%     lgd = {};
%     sty = ["-","--","-.",":"];
%     markers = ["o","^","diamond","*"];
%     for i = 1:numel(alphas)
%         bladeprofs(i,:) = erShape(j,alphas(i));
%         plot(mids,bladeprofs(i,:),lineWidth=5,Marker=markers(1+mod(i,numel(markers))),LineStyle=sty(1+mod(i,numel(sty))))
%         lgd{i} = "severity "+num2str(alphas(i));
%     end
%     ylim([0,1])
%     xlabel("Region Location (% of radius)",FontSize=14)
%     ylabel("Severity Level",FontSize=14)
%     legend(lgd,location="northwest",FontSize=14)
%     title("#"+num2str(j)+": "+shapes(j)+" Erosion Level Profiles",FontSize=14)
%     g = gca();g.FontSize=14;
% end
% 
% saveID = "Plots/"+"BladeProfilesPlots.png";
% print('-dpng',saveID)
%% Look at the results
clc;close;clear;
% Grab the data
tables = cell(1,3);
for i = 1:3
    sh = i;
    elan = parquetread("MorrisResultAnalysisTable"+num2str(sh)+".parquet");
    % Establish the proper row names
    elan.Properties.RowNames=elan.x__index_level_0__;
    % Drop the old row name column
    elan.x__index_level_0__ = [];
    tables{i} = elan;
end
%% Extract columns
tab = tables{1};
varnames = tab.Properties.RowNames;
%% Grab the groups
statis = 4;
group1 = varnames([1:6]+(statis-1)*32);
group2 = varnames([7:16]+(statis-1)*32);
group3 = varnames([17,18,31,32]+(statis-1)*32);
group4 = varnames([19:24]+(statis-1)*32);
group5 = varnames([25:30]+(statis-1)*32);
%% Plot a bargraph of the mu and sigma for each group.  
% For each group plot each shape of blade on a subplot, 
% Mu and Sigma side by side 
best_sigmas = [];
best_mus = [];
iter = 1;
for i = 1:5
    eval("group = group"+i);
    figure
    for j = 1:3
        tab = tables{j};
        mus = tab(group,"ErosionSeverityMuStar").Variables;
        sigma = tab(group,"ErosionSeveritySigma").Variables;

        [sortedmus,indm] = sortrows(mus,"descend");
        [sortedsigmas,inds] = sortrows(sigma,"descend");
        gm = group(indm);
        gs = group(inds);
        best_mus{iter} = gm{1};
        best_sigs{iter} = gs{1};
        iter = iter +1 ;
        subplot(3,2,2*(j-1)+1)
        bar(group(indm),sortedmus)
        title("Group "+num2str(i) + " Shape "+num2str(j)+" Mu")
        subplot(3,2,2*(j-1)+2)
        bar(group(inds),sortedsigmas)
        title("Group "+num2str(i) + " Shape "+num2str(j)+" Sigma")
    end
end
%% List all the best QOIs for Shape # 1
clc
shape = 1;
for i =1:numel(best_mus)/3
    disp(["Mu",best_mus{3*(i-1)+shape},"Sigma",best_sigs{3*(i-1)+shape}])
end
%% Make a table of just the target QOIs for each shape
group = varnames([4,12,24,30,31]);
figure
I = zeros(5,6);
for j = 1:3
    tab = tables{j};
    mus = tab(group,"ErosionSeverityMuStar").Variables;
    sigma = tab(group,"ErosionSeveritySigma").Variables;
    I(:,j) = mus;I(:,j+3) = sigma;
    [sortedmus,indm] = sortrows(mus,"descend");
    [sortedsigmas,inds] = sortrows(sigma,"descend");
    gm = group(indm);
    gs = group(inds);
    best_mus{iter} = gm{1};
    best_sigs{iter} = gs{1};
    iter = iter +1 ;
    subplot(3,2,2*(j-1)+1)
    bar(group(indm),sortedmus)
    title("Group Target" + " Shape "+num2str(j)+" Mu for Erosion")
    subplot(3,2,2*(j-1)+2)
    bar(group(inds),sortedsigmas)
    title("Group Target" + " Shape "+num2str(j)+" Sigma for Erosion")
end
for i = 1:3
    tabnames(i) = "Shape "+num2str(i)+" mu* ";
end
for i = 4:6
    tabnames(i) = "Shape "+num2str(i-3)+" sigma ";
end
newtab = array2table(I,"RowNames",group,"VariableNames",tabnames);
writetable(newtab,'Plots/MorrisTable.csv','Delimiter',',','WriteRowNames',true)

%% Morris Method Plot All
tab = tables{1};
lgd = {"ErosionSeverity","WindDir","WindSpeed","AirDensity","WindShear"};

mus = zeros(5,5);
sigma = zeros(5,5);

for i = 1:5
    mus(:,i) = tab(group,lgd{i}+"MuStar").Variables;
    sigma(:,i) = tab(group,lgd{i}+"Sigma").Variables;
end
shapes = ["o","diamond",">","square","pentagram"];
clrs = ["#0072BD","#D95319","#EDB120","#7E2F8E","#77AC30"];
hold on
for i = 1:5
    for j = 1:5
        scatter(mus(i,j),sigma(i,j),50,'filled','Marker',shapes(j),'MarkerEdgeColor','k','MarkerFaceColor',clrs(i));
        lgd2{(i-1)*5+j} = '';
    end

    
    lgd2(5*i) = group(i);
end
legend(lgd2,"Location","southeast")
g = gca();
g.FontSize = 18;
grid on
%% Make and save Each output one at a time
clrs = ["k","k","k","k","k","k"];
ttls  = ["Blade root moment","Blade tip acceleration","Lift coefficient",...
    "Drag coefficient","Generator power"];
ttlshort = ["root","tip","l","d","gp"];
lgd = {"Erosion", "Wind direction", "Wind speed", "Air density", "Wind shear"};
f = figure;
f.Position = [50 50 1000 600];
tiledlayout(2,3,"TileSpacing","tight")
for i = 1:5
    
    nexttile
    hold on
    for j = 1:5
        scatter(mus(i,j),sigma(i,j),100,'filled','Marker',shapes(j),...
            'MarkerEdgeColor','k','MarkerFaceColor','white','LineWidth',2);
        lgd2{j} = lgd{j};
    end
    
    grid on
    
    title(ttls(i),'FontSize',20,'FontWeight','normal','FontName','Helvetica')
    xlim([0,1.3])
    ylim([0,1])
    yscale log
    xscale log
    if i == 4 || i == 5 || i == 6
        xlabel("\mu^* (log scale)",'FontName','Helvetica','FontSize',20)
    else
        g = gca;
        %g.XTickLabel = [];
       
    end
    if i == 1 || i ==4
        ylabel("\sigma (log scale)",'FontName','Helvetica','FontSize',20)
    else
        g = gca;
        %g.YTickLabel= [];
        
    end
    g = gca();
    
    g.FontName='Helvetica';

    saveID = "Plots/"+"MorrisPlots"+ttlshort(i)+".png";
    %print('-dpng',saveID)
    if i == 5
        %f = figure;
        %f.Position = [50 50 700 600];
        nexttile
        hold on
        % Plot whatever you like
        for j = 1:5
            scatter(1,5-j,100,'filled','Marker',shapes(j),...
                'MarkerEdgeColor','k','MarkerFaceColor','white','LineWidth',2);
            text(1,5-j,sprintf('  %s',lgd{j}),...
                'FontSize',20,'FontName','Helvetica','HorizontalAlignment','left');
        end
        
        g = gca;g.FontSize = 20;
        xlim([0,10])
        ylim([-1,6])
        axis off;
        
        
    end

end

saveID = "Plots/"+"MorrisPlotsNEW.pdf";
ax = gcf;
exportgraphics(ax,saveID,'Resolution',300)