This a small script to make automated internet test, it uses speedtest cli from ookla, shows you different stadistics and plots the values

it is designed to run on windows 11 x64, and will show you your internet adapter properties in the command line,
developed and tested in Matlab R2020a
If you are gonna use it constantly, i recommend you to edit line 12, and uncommenting it:

    %cmdSpeedtest = ['cd "sustituye esto por la ruta donde está el ejecutable de speedtest, sin las comillas" & speedtest --format=json'];
replace "sustituye esto por la ruta donde está el ejecutable de speedtest, sin las comillas" with the path without the quotes

you can choose to export or not to export the figures and the table with the results, also you can export a .csv to make stadistics outside matlab (in excel for example)

The motivation behind this project is to optimize time while i was testing a wifi mesh network

ps: speedtest cli has a maximum amount per day of test you can make fom the same ip, its about 30-40 
