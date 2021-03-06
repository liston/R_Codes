# Install Libraries
install.packages("tidyverse")
install.packages("plotly")
install.packages("cowplot")
install.packages("grid")
# Call Libraries
library(tidyverse)
library(plotly)
library(cowplot)
library(grid)



  
# Main Path for getting the data in the form of CSVs
Main <- "https://raw.githubusercontent.com/CSSEGISandData/COVID-19/master/csse_covid_19_data/csse_covid_19_time_series"
# Update (Dated: *25-03-2020*)
# The data files currently in use below are deprecated. The new files on the same github repo are changed. Following message can be seen on [https://github.com/CSSEGISandData/COVID-19/tree/master/csse_covid_19_data/csse_covid_19_time_series](https://github.com/CSSEGISandData/COVID-19/tree/master/csse_covid_19_data/csse_covid_19_time_series)
# *---DEPRICATED WARNING---
#  The files below will no longer be updated. With the release of the new data structure, we are updating our time series tables to reflect these changes. Please reference time_series_covid19_confirmed_global.csv and time_series_covid19_deaths_global.csv for the latest time series data.*

# We are saving the links to each CSVs in separate objects
# Updated on 25-03-2020
# confirmed <-  file.path(Main,"time_series_19-covid-Confirmed.csv")
confirmed_Path <-  file.path(Main,"time_series_covid19_confirmed_global.csv")
# 
confirmed
# Updated on 25-03-2020
# Deaths <- file.path(Main,"time_series_19-covid-Deaths.csv")
Deaths_Path <- file.path(Main,"time_series_covid19_deaths_global.csv")
Deaths
# Updated on 25-03-2020
# The updated file on the recovered data is still awaited, for tutorial we are taking the deprecated file which will be updated later.
# Updated on 12-04-2020
# The csv is updated from  `time_series_19-covid-Recovered.csv` to `time_series_covid19_recovered_global.csv`
Recoverd_Path <- file.path(Main,"time_series_covid19_recovered_global.csv")
Recoverd

# Now, we are reading the data stored in each link
ConfirmedData <- read.csv(confirmed_Path,stringsAsFactors = FALSE)
DeathData     <- read.csv(Deaths_Path,stringsAsFactors = FALSE)
RecoveredData <- read.csv(Recoverd_Path,stringsAsFactors = FALSE)

# Based on the region, the information will be fetched and prepared
Region <- "Pakistan"

# This function is important for making the data to be used in animations generated by Plotly
accumulate_by <- function(dat, var) {
  var <- lazyeval::f_eval(var, dat) 
  lvls <- plotly:::getLevels(var) 
  dats <- lapply(seq_along(lvls), 
                 function(x) {
                   cbind.data.frame(dat[var %in% lvls[seq(1, x)], ],
                                    frame = lvls[[x]])}) 
  dplyr::bind_rows(dats)}

# This DataClean function is requried to change the wide table into long table and then filtering the data according to region mentioned above
DataClean <- function(data, region, CaseType) {
  CleanedData <- data %>% 
    pivot_longer(cols = starts_with("X"), 
                 names_to = "Date", 
                 names_prefix = "X", 
                 names_ptypes = list(week = integer()), 
                 values_to = CaseType, 
                 values_drop_na = TRUE)   %>% 
    mutate(Province.State = ifelse(Province.State %in% "", Country.Region, Province.State)) %>% 
    mutate(Date = as.Date(Date, "%m.%d.%y")) %>% 
    filter(Province.State == region) %>% 
    arrange(Date) %>% 
    mutate(ID = row_number()) 
  return(CleanedData)
  }

# Now we are cleaning data for each case
ConData <- DataClean(ConfirmedData,Region,"Confirmed") 

RecData <- DataClean(RecoveredData,Region,"Recovered") %>% select(ID,Recovered) 

DeData <-DataClean(DeathData,Region,"Deaths")          %>% select(ID,Deaths)


# In this code we are going to merge the cleaned data according to the ID column
AllData <- list(ConData, RecData, DeData)              %>% reduce(left_join, by = "ID")


# In this code, we are generating the frames for animations.
frames <- AllData %>% accumulate_by(~ID)


# METHOD 1 (Animated graphs using ggplotly() after making ggplot()): Now we will generate a combined plot by ggplot for all cases and their time series in region mentioned above

plot <- ggplot(data=frames,aes(x=Date, frame = frame)) + 
  geom_line(aes(y=Confirmed, colour="Confirmed"),size=1) + 
  geom_line(aes(y= Recovered, colour = "Recovered"),size=1) + 
  geom_line(aes(y= Deaths, colour = "Deaths"),size=1) + 
  labs(colour="Cases") + 
  scale_color_manual(values=c('#0751B8','#B82607', '#0BB807')) + 
  theme_bw()+ 
  theme(legend.box.background = element_rect(), 
        legend.box.margin = margin(6, 6, 6, 6)) + 
  labs(title = paste("Cases Over the Period of Time Since First Report in",Region), 
       subtitle = "YouTube Channel: Dr Rehan Zafar", 
       x = "Date",
       y="Cases") 


# Plot the plot
plot

# In fig1, we are going to produce the animations by using ggplotly()
fig1 <- ggplotly(plot) %>% 
  animation_opts(frame = 100, 
                 transition = 0, 
                 redraw = FALSE) %>% 
  animation_slider(currentvalue = list(prefix = "Day ")) 


# Plot the animated fig1
fig1

# In this code, we are going to generate the static plot for conifrmed cases only by using ggplot()
subplot1 <- ggplot(data=frames,aes(x=Date, frame = frame)) + 
  geom_line(aes(y=Confirmed, colour="Confirmed"), color = "#0751B8",size=1) +  
  labs(colour="Cases") + 
  theme_bw()

# Plot subplot1
subplot1

# In this code, we are going to generate the static plot for Receovered cases only by using ggplot()
subplot2 <- ggplot(data=frames,aes(x=Date, frame = frame)) + 
  geom_line(aes(y=Recovered, colour="Recovered"), color = "#0BB807",size=1) + 
  labs(colour="Cases") + 
  theme_bw()

# plot subplot2
subplot2

# In this code, we are going to generate the static plot for Deaths only by using ggplot()
subplot3 <- ggplot(data=frames,aes(x=Date, frame = frame)) +  
  geom_line(aes(y=Deaths, colour="Deaths"), color = "#B82607",size=1) +  
  labs(colour="Cases") +  
  theme_cowplot(12)

# plot subplot3
subplot3

# In this code, we will generate a new page for grid alignment of all three subplot1-3.
grid.newpage()
grid.draw(rbind(ggplotGrob(subplot1), 
                ggplotGrob(subplot2),
                ggplotGrob(subplot3), 
                size = "last"))

# This is another way to subplot three subplots 1-3.
cowplot::plot_grid(subplot1,subplot2,subplot3, labels = c('A', 'B','C'), label_size = 12, align = "v", ncol = 1)


# METHOD 2 (Animated graphs using plot_ly() without making ggplot()): Now We will use plot_ly() function to make an animated graph.

fig2 <- plot_ly() %>%  
  
  # We are going to add the information of Confirmed cases by using add_trace()
  add_trace(data=frames, 
            x = ~Date, 
            y = ~Confirmed, 
            name= 'Confirmed', 
            frame = ~frame,  
            type = 'scatter', 
            mode = 'lines+markers', 
            marker = list(size = 10, 
                          color = 'rgba(51, 153, 255, .5)', 
                          line = list(color = 'rgba(0, 38, 77, .8)', width = 2)), 
            line = list(color = 'rgba(0, 38, 77, .8)', 
                        width = 2)) %>% 
  
  # We are going to add the information of Recovered cases by using add_trace()
  add_trace(data=frames, 
            x = ~Date, 
            y = ~Recovered, 
            name='Recovered', 
            frame = ~frame,  
            type = 'scatter', 
            mode = 'lines+markers', 
            marker = list(size = 10, 
                          color = 'rgba(153, 255, 153, .8)', 
                          line = list(color = 'rgba(0, 179, 0, .8)', width = 2)), 
            line = list(color = 'rgba(0, 179, 0, .8)', 
                        width = 2)) %>% 
  
  # We are going to add the information of Deaths by using add_trace()
  add_trace(data=frames, 
            x = ~Date, 
            y = ~Deaths, 
            name='Deaths', 
            frame = ~frame, 
            type = 'scatter', 
            mode = 'lines+markers',
            marker = list(size = 10, 
                          color = 'rgba(255, 102, 102, .5)', 
                          line = list(color = 'rgba(152, 0, 0, .8)', width = 2)), 
            line = list(color = 'rgba(152, 0, 0, 1)', 
                        width = 2)) %>% 
  # Formating the layout of the graph
  layout(legend=list(x = 100, y = 0.5, yanchor="top"), 
         title = list(text=paste("<b> Cases Over the Period of Time in",Region, "Since First Report </b>"), 
                      size = 10), 
         xaxis=list(autoscale=FALSE,
                    range = c(head(frames$Date, n=1),tail(frames$Date, n=1)+2),
                    title = "<b> Days </b>"), 
         yaxis=list(title = "<b> Cases </b>")) %>%
  
  # Animation options
  animation_opts(10, easing = "elastic", redraw = TRUE)

# Plot the fig2
fig2

fig3 <- plot_ly() %>%  
  
  # We are going to add the information of Confirmed cases by using add_trace()
  add_trace(data=AllData, 
            x = ~Date, 
            y = ~Confirmed, 
            name= 'Confirmed', 
            type = 'scatter', 
            mode = 'lines+markers', 
            marker = list(size = 10, 
                          color = 'rgba(51, 153, 255, .5)', 
                          line = list(color = 'rgba(0, 38, 77, .8)', width = 2)), 
            line = list(color = 'rgba(0, 38, 77, .8)', 
                        width = 2)) %>% 
  
  # We are going to add the information of Recovered cases by using add_trace()
  add_trace(data=AllData, 
            x = ~Date, 
            y = ~Recovered, 
            name='Recovered', 
            type = 'scatter', 
            mode = 'lines+markers', 
            marker = list(size = 10, 
                          color = 'rgba(153, 255, 153, .8)', 
                          line = list(color = 'rgba(0, 179, 0, .8)', width = 2)), 
            line = list(color = 'rgba(0, 179, 0, .8)', 
                        width = 2)) %>% 
  
  # We are going to add the information of Deaths by using add_trace()
  add_trace(data=AllData, 
            x = ~Date, 
            y = ~Deaths, 
            name='Deaths', 
            type = 'scatter', 
            mode = 'lines+markers',
            marker = list(size = 10, 
                          color = 'rgba(255, 102, 102, .5)', 
                          line = list(color = 'rgba(152, 0, 0, .8)', width = 2)), 
            line = list(color = 'rgba(152, 0, 0, 1)', 
                        width = 2)) %>% 
  # Formating the layout of the graph
  layout(legend=list(x = 100, y = 0.5, yanchor="top"), 
         title = list(text=paste("<b> Cases Over the Period of Time in",Region, "Since First Report </b>"), 
                      size = 10), 
         xaxis=list(autoscale=FALSE,
                    range = c(head(frames$Date, n=1),tail(frames$Date, n=1)+2),
                    title = "<b> Days </b>"), 
         yaxis=list(title = "<b> Cases </b>"))
# Now If you want to generate three separate graphs by using plot_ly() function. First, subplotly1 represents the graph for confirmed cases. 

fig3

subplotly1 <-  plot_ly(AllData, 
                       x = ~Date, 
                       y = ~Confirmed,
                       name='Confirmed', 
                       type = 'scatter', 
                       mode = 'lines+markers',
                       marker = list(size = 10, 
                                     color = 'rgba(51, 153, 255, .5)', 
                                     line = list(color = 'rgba(0, 38, 77, .8)', width = 2)), 
                       line = list(color = 'rgba(0, 38, 77, .8)', 
                                   width = 2))
#plot Subplotly1
subplotly1

# Second, subplotly2 represents the graph for Recovered cases
subplotly2 <-  plot_ly(AllData, 
                       x = ~Date, 
                       y = ~Recovered,
                       name='Recovered', 
                       type = 'scatter', 
                       mode = 'lines+markers', 
                       marker = list(size = 10, 
                                     color = 'rgba(153, 255, 153, .8)', 
                                     line = list(color = 'rgba(0, 179, 0, .8)', width = 2)), 
                       line = list(color = 'rgba(0, 179, 0, .8)', 
                                   width = 2))

#plot subplotly2
subplotly2

# Third, subplotly3 represents the graph for confirmed cases
subplotly3 <- plot_ly(AllData, 
                      x = ~Date, 
                      y = ~Deaths,
                      name='Deaths',
                      type = 'scatter', 
                      mode = 'lines+markers',
                      marker = list(size = 10, 
                                    color = 'rgba(255, 102, 102, .5)', 
                                    line = list(color = 'rgba(152, 0, 0, .8)', width = 2)), 
                      line = list(color = 'rgba(152, 0, 0, 1)', 
                                  width = 2))

# plot subplotly3
subplotly3

# Now, if you want to make three subplotly1-3 horizontally 
figsubplotly <- subplot(subplotly1, subplotly2, subplotly3)

# plot figsubplotly
figsubplotly

# and if you want to change them vertically 
figsubplotlyrows <- subplot(subplotly1, subplotly2, subplotly3, nrows= 3, shareX = TRUE)

# plot figsubplotlyrows
figsubplotlyrows




  



























