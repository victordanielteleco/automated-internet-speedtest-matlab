This a small script to make automated internet test, it uses speedtest cli from ookla, shows you different stadistics and plots the values,
it allows you to choose how much test you wanna make and seconds between test.

it is designed to run on windows 11 x64, and will show you your internet adapter properties in the command line,
developed and tested in Matlab R2020a
If you are gonna use it constantly, i recommend you to edit line 12, and uncommenting it:

    %cmdSpeedtest = ['cd "sustituye esto por la ruta donde está el ejecutable de speedtest, sin las comillas" & speedtest --format=json'];
replace "sustituye esto por la ruta donde está el ejecutable de speedtest, sin las comillas" with the path where speedtest.exe is without the quotes

you can choose to export or not to export the figures and the table with the results, also you can export a .csv to make stadistics outside matlab (in excel for example)

The motivation behind this project is to optimize time while i was testing a wifi mesh network

ps: speedtest cli has a maximum amount per day of test you can make fom the same ip, its about 30-40 

The Matlab script used to create the maps is available at: https://www.mathworks.com/matlabcentral/fileexchange/61340-multi-wall-cost231-signal-propagation-models-python-code
It was developed by Salaheddin Hosseinzadeh (https://github.com/hosseinzadeh88), and after analyzing his solution, it was decided that it would be useful for this project. 
This Matlab add-on (Multi wall (COST231) Signal Propagation Models) estimates signal loss using free space and COST231 propagation models. This two-dimensional method considers the walls between the transmitter and receiver. It only requires an image of the plane and the measurement between two points on it.
The author's excellent documentation has been key to understanding how it works and how to use it in order to implement it in this project.



