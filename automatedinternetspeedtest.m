close all
clear all

% sacar un CSV con velocidades netas y brutas para procesar los datos fuera de matlab


% Pregunta al usuario sobre la ruta del ejecutable speedtest
routeOption = input('¿Está el ejecutable speedtest en la ruta por default (D/d) o en otra (cualquier otra letra)?: ', 's');

% Define la ruta del ejecutable speedtest
if lower(routeOption) == 'd'
    %cmdSpeedtest = ['cd "sustituye esto por la ruta donde está el ejecutable de speedtest, sin las comillas" & speedtest --format=json'];
else
    speedtestPath = input('Por favor, introduzca la ruta completa del directorio donde está el ejecutable speedtest: ', 's');
    cmdSpeedtest = ['cd "' speedtestPath '" & speedtest --format=json'];
end

% Solicita al usuario el número de pruebas y el tiempo entre pruebas
numTests = input('Número de pruebas a realizar: ');
intervalSeconds = input('Tiempo en segundos entre cada prueba: ');


% Solicita el nombre de la prueba
testName = input('Introduzca el nombre de la prueba, si no desea exportar datos, déjelo en blanco: ', 's');

if isempty(testName)
    disp('nombre vacío, no se exportarán datos');
else
    exportacionbruta = input('¿Desea un archivo .csv con velocidades netas y brutas para procesar los datos fuera de matlab?: (Y/N)', 's');
end

% Inicializa los resultados
downloadSpeeds = NaN(1, numTests);
uploadSpeeds = NaN(1, numTests);
pingLatencies = NaN(1, numTests);
timestamps = NaT(1, numTests);
timestamps.TimeZone = 'UTC';

% Inicializa los resultados para netsh
receiveSpeeds = NaN(1, numTests);
transmitSpeeds = NaN(1, numTests);

% Define el comando para ejecutar netsh
cmdNetsh = 'netsh wlan show interfaces';

try
    for i = 1:numTests
        % Ejecuta el comando de netsh y captura la salida
        [statusNetsh, netshOut] = system(cmdNetsh);

        % Mostrar la salida del comando netsh en la línea de comandos de MATLAB
        disp(['Salida del comando netsh para la prueba ' num2str(i) ':']);
        disp(netshOut);

        if statusNetsh == 0
            % Extrae las velocidades de recepción y transmisión de la salida de netsh
            receiveSpeed = extractBetween(netshOut, "Velocidad de recepción (Mbps)   : ", newline);
            transmitSpeed = extractBetween(netshOut, "Velocidad de transmisión (Mbps) : ", newline);

            if ~isempty(receiveSpeed) && ~isempty(transmitSpeed)
                receiveSpeeds(i) = str2double(receiveSpeed{1});
                transmitSpeeds(i) = str2double(transmitSpeed{1});
            else
                error('No se encontraron velocidades de recepción o transmisión en la salida de netsh.');
            end
        else
            error('Error al ejecutar el comando netsh.');
        end

        % Ejecuta el comando de speedtest y captura la salida
        [statusSpeedtest, cmdout] = system(cmdSpeedtest);

        % Mostrar la salida del comando speedtest en la línea de comandos de MATLAB
        disp(['Salida del comando speedtest para la prueba ' num2str(i) ':']);
        disp(cmdout);

        if statusSpeedtest == 0
            % Divide la salida en líneas y busca la línea con "type":"result"
            lines = strsplit(cmdout, '\n');
            resultLine = '';
            for j = 1:length(lines)
                if contains(lines{j}, '"type":"result"')
                    resultLine = lines{j};
                    break;
                end
            end

            % Verifica si se encontró la línea de resultado
            if isempty(resultLine)
                error('No se encontró una línea de resultado en la salida JSON.');
            end

            % Intenta analizar la línea de resultado como JSON
            try
                data = jsondecode(resultLine);

                % Mostrar los datos decodificados para depuración
                disp('Datos decodificados:');
                disp(data);

                % Verifica si hay datos de resultado disponibles
                if isfield(data, 'type') && strcmp(data.type, 'result')
                    downloadSpeed = data.download.bandwidth * 8 / 1e6; % Convierte de bytes/s a Mbps
                    uploadSpeed = data.upload.bandwidth * 8 / 1e6;     % Convierte de bytes/s a Mbps
                    pingLatency = data.ping.latency;                  % Latencia de ping en ms
                    timestamp = datetime(data.timestamp, 'InputFormat', 'yyyy-MM-dd''T''HH:mm:ss''Z''', 'TimeZone', 'UTC'); % Zona horaria UTC

                    % Mostrar los resultados intermedios para depuración
                    disp(['Prueba ' num2str(i) ':']);
                    disp(['Velocidad de descarga: ' num2str(downloadSpeed) ' Mbps']);
                    disp(['Velocidad de subida: ' num2str(uploadSpeed) ' Mbps']);
                    disp(['Latencia de ping: ' num2str(pingLatency) ' ms']);
                    disp(['Timestamp: ' char(timestamp)]);

                    % Almacena los resultados en los vectores correspondientes
                    downloadSpeeds(i) = downloadSpeed;
                    uploadSpeeds(i) = uploadSpeed;
                    pingLatencies(i) = pingLatency;
                    timestamps(i) = timestamp;
                else
                    error('Datos incompletos en la salida JSON.');
                end
            catch ME
                error(['Error al analizar la salida JSON: ' ME.message]);
            end
        else
            error('Error al ejecutar el comando speedtest.');
        end

        % Espera el tiempo especificado antes de la próxima prueba (excepto en la última)
        if i < numTests
            disp(['Esperando ' num2str(intervalSeconds) ' segundos para la próxima prueba...']);
            pause(intervalSeconds); % Pausa de segundos especificados
        end
    end

    % Verifica si se obtuvieron datos válidos antes de graficar
    validData = ~isnan(downloadSpeeds) & ~isnan(uploadSpeeds) & ~isnan(pingLatencies) & ~isnat(timestamps);
    validNetshData = ~isnan(receiveSpeeds) & ~isnan(transmitSpeeds);

    if any(validData)
        % Calcula estadísticas para speedtest
        meanDownload = mean(downloadSpeeds(validData));
        meanUpload = mean(uploadSpeeds(validData));
        meanLatency = mean(pingLatencies(validData));
        minDownload = min(downloadSpeeds(validData));
        minUpload = min(uploadSpeeds(validData));
        minLatency = min(pingLatencies(validData));
        maxDownload = max(downloadSpeeds(validData));
        maxUpload = max(uploadSpeeds(validData));
        maxLatency = max(pingLatencies(validData));
        variationDownload = maxDownload - minDownload;
        variationUpload = maxUpload - minUpload;
        variationLatency = maxLatency - minLatency;

        disp('Resultados de las pruebas:');
        disp(['Velocidad de Descarga - Media: ' num2str(meanDownload) ' Mbps, Mínimo: ' num2str(minDownload) ' Mbps, Máximo: ' num2str(maxDownload) ' Mbps, Variación: ' num2str(variationDownload) ' Mbps']);
        disp(['Velocidad de Subida   - Media: ' num2str(meanUpload) ' Mbps, Mínimo: ' num2str(minUpload) ' Mbps, Máximo: ' num2str(maxUpload) ' Mbps, Variación: ' num2str(variationUpload) ' Mbps']);
        disp(['Latencia de Ping      - Media: ' num2str(meanLatency) ' ms,   Mínimo: ' num2str(minLatency) ' ms,   Máximo: ' num2str(maxLatency) ' ms,   Variación: ' num2str(variationLatency) ' ms']);

        % Genera los gráficos
        figure;

        % Gráfico para velocidades de descarga y subida
        subplot(2,1,1);
        plot(timestamps(validData), downloadSpeeds(validData), '-o', 'DisplayName', 'Velocidad de Descarga');
        hold on;
        plot(timestamps(validData), uploadSpeeds(validData), '-o', 'DisplayName', 'Velocidad de Subida');
        title('Prueba de Velocidad de Internet - Descarga y Subida');
        xlabel('Tiempo');
        ylabel('Mbps');
        legend('show');
        grid on;
        axis auto; % Ajusta automáticamente los límites de los ejes

        % Gráfico para latencia de ping
        subplot(2,1,2);
        plot(timestamps(validData), pingLatencies(validData), '-o', 'DisplayName', 'Latencia de Ping');
        title('Prueba de Velocidad de Internet - Latencia de Ping');
        xlabel('Tiempo');
        ylabel('ms');
        legend('show');
        grid on;
        axis auto; % Ajusta automáticamente los límites de los ejes
        
        if isempty(testName)
         disp('nombre vacío, no se exportarán datos');
        else
         % Guarda los gráficos como una imagen
         saveas(gcf, [testName '_internet_speed_test.png']);
        end
        
    else
        disp('No se han capturado datos válidos de velocidad de internet.');
    end

    if any(validNetshData)
        % Calcula estadísticas para netsh
        meanReceiveSpeed = mean(receiveSpeeds(validNetshData));
        meanTransmitSpeed = mean(transmitSpeeds(validNetshData));
        minReceiveSpeed = min(receiveSpeeds(validNetshData));
        minTransmitSpeed = min(transmitSpeeds(validNetshData));
        maxReceiveSpeed = max(receiveSpeeds(validNetshData));
        maxTransmitSpeed = max(transmitSpeeds(validNetshData));
        variationReceiveSpeed = maxReceiveSpeed - minReceiveSpeed;
        variationTransmitSpeed = maxTransmitSpeed - minTransmitSpeed;

        disp('Resultados de las pruebas netsh:');
        disp(['Velocidad de Recepción Neta - Media: ' num2str(meanReceiveSpeed) ' Mbps, Mínimo: ' num2str(minReceiveSpeed) ' Mbps, Máximo: ' num2str(maxReceiveSpeed) ' Mbps, Variación: ' num2str(variationReceiveSpeed) ' Mbps']);
        disp(['Velocidad de Transmisión Neta - Media: ' num2str(meanTransmitSpeed) ' Mbps, Mínimo: ' num2str(minTransmitSpeed) ' Mbps, Máximo: ' num2str(maxTransmitSpeed) ' Mbps, Variación: ' num2str(variationTransmitSpeed) ' Mbps']);

        % Genera los gráficos para netsh
        figure;
        plot(1:numTests, receiveSpeeds, 'r-o', 'DisplayName', 'Velocidad de Recepción Neta');
        hold on;
        plot(1:numTests, transmitSpeeds, 'b--*', 'DisplayName', 'Velocidad de Transmisión Neta');
        title('Prueba de Velocidad de Internet - Velocidades Netas');
        xlabel('Número de Prueba');
        ylabel('Mbps');
        legend('show');
        grid on;
        axis auto; % Ajusta automáticamente los límites de los ejes

            if isempty(testName)
             disp('nombre vacío, no se exportarán datos');
            else
              % Guarda el gráfico como una imagen
              saveas(gcf, [testName '_netsh_speed_test.png']);
            end
        

    else
        disp('No se han capturado datos válidos de velocidades netas.');
    end

    % Genera la tabla de estadísticas
    statsData = [
        meanDownload, minDownload, maxDownload, variationDownload; ...
        meanUpload, minUpload, maxUpload, variationUpload; ...
        meanLatency, minLatency, maxLatency, variationLatency; ...
        meanReceiveSpeed, minReceiveSpeed, maxReceiveSpeed, variationReceiveSpeed; ...
        meanTransmitSpeed, minTransmitSpeed, maxTransmitSpeed, variationTransmitSpeed
    ];

    % Nombres de las columnas y filas
    columnNames = {'Media', 'Mínimo', 'Máximo', 'Variación'};
    rowNames = {'Velocidad de Descarga (Mbps)', 'Velocidad de Subida (Mbps)', 'Latencia de Ping (ms)', 'Velocidad de Recepción Neta (Mbps)', 'Velocidad de Transmisión Neta (Mbps)'};

    % Crea la tabla de estadísticas
    figure;
    t = uitable('Data', statsData, 'ColumnName', columnNames, 'RowName', rowNames, 'Position', [20 20 650 150]);

    % Ajusta el tamaño de la figura para que se ajuste al tamaño de la tabla
    fig = ancestor(t, 'figure');
    fig.Position = [100 100 680 200]; % Ajusta la posición y tamaño de la figura
    
    % Ajusta el ancho de las columnas al contenido
    t.ColumnWidth = 'auto';

    % Añade el título usando annotation
    annotation('textbox', [0.2, 0.85, 0.6, 0.1], 'String', 'Estadísticas de Prueba de Velocidad de Internet', ...
               'HorizontalAlignment', 'center', 'FontSize', 12, 'FontWeight', 'bold', 'EdgeColor', 'none');

            if isempty(testName)
             disp('nombre vacío, no se exportarán datos');
            else
                % Captura la figura como una imagen
                frame = getframe(fig);
                imwrite(frame.cdata, [testName '_internet_speed_test_estadisticas.png']);

                % Guarda la tabla de estadísticas en un archivo CSV
                statsTable = array2table(statsData, 'VariableNames', columnNames, 'RowNames', rowNames);
                writetable(statsTable, [testName '_internet_speed_test_estadisticas.csv'], 'WriteRowNames', true);
                
                            if lower(exportacionbruta) == 'y'
                                % Guardar todas las mediciones en un archivo CSV para procesamiento externo
                            allData = table(timestamps', downloadSpeeds', uploadSpeeds', pingLatencies', receiveSpeeds', transmitSpeeds', ...
                                'VariableNames', {'Timestamp', 'DownloadSpeed_Mbps', 'UploadSpeed_Mbps', 'PingLatency_ms', 'ReceiveSpeed_Mbps', 'TransmitSpeed_Mbps'});
                            writetable(allData, [testName '_internet_speed_test_datos.csv']);
                            else
                            disp('no se generará exportación de datos en bruto en archivo .csv');
                            end
                
            end
    






catch ME
    % Manejo de errores
    disp(['Error: ' ME.message]);
end
