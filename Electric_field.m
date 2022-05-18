classdef Electric_field < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        interfaz            matlab.ui.Figure
        reset               matlab.ui.control.Button
        Image               matlab.ui.control.Image
        Calcular            matlab.ui.control.Button
        numero_cargas       matlab.ui.control.NumericEditField
        NmerodecargasLabel  matlab.ui.control.Label
        tabla_cargas        matlab.ui.control.Table
    end

    %Se crea un objeto que no se muestra en el GUI
    properties (Access = private)
        Tabla_respaldo
    end

    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app)
            %Se definen que los valores a ingresar en la tabla son
            %numericos y se crea la fila inicial
            app.tabla_cargas.ColumnFormat = {'numeric', 'numeric', 'numeric'};
            app.tabla_cargas.Data = cell(1, 3);
        end

        % Cell edit callback: tabla_cargas
        function tabla_cargasCellEdit(app, event)

        end

        % Value changed function: numero_cargas
        function numero_cargasValueChanged(app, event)
            %Funcion que se activa cuando el text input que corresponde al
            %valor de numero de cargas cambia. Este valor es definido por
            %el usuario.            
            cantidad_cargas = app.numero_cargas.Value;
            %tamaño del cuadro de cargas y posicion
            [m, n] = size(app.tabla_cargas.Data);
            
            %Se respalda el contenido de toda la tabla para ingresar nuevas
            %cargas o eliminar las restantes
            app.Tabla_respaldo = app.tabla_cargas.Data;
            
            %Se evalua si se reduce el número de cargas a evaluar
            if cantidad_cargas < m
                d = cell(cantidad_cargas, n);
                %Se respalda el cuadro para no eliminar los datos ya
                %ingresados
                app.Tabla_respaldo = app.tabla_cargas.Data(1 : cantidad_cargas, 1 : n);
                d(1 : cantidad_cargas, 1 : n) = app.Tabla_respaldo;
                app.tabla_cargas.Data = d;
            %Si se desea aumentar el numero de cargas se agregan filas y se
            %mantienen las presentes
            else 
                d = cell(cantidad_cargas, n);
                d(1 : m, 1 : n) = app.Tabla_respaldo;
                app.tabla_cargas.Data = d;
            end            
        end

        % Button pushed function: Calcular
        function CalcularButtonPushed(app, event)
        %Se cierran todas las gráficas abiertas anteriormente para evitar
        %que se superpongan
        close all
        
        %-------Creación de los ejes x-y para las gráficas------------
        
        %Parámetro que define la cantidad de puntos en el eje x-y en donde
        %se evaluará el campo eléctrico y el potencial
        N = 20;
        [m, ~] = size(app.tabla_cargas.Data);
        
        %Se definen parámetros de desplazamiento para ajustar los valores
        %de los ejes automáticamente
        dx = abs(max(cell2mat(app.tabla_cargas.Data(:, 2)))) + abs(min(cell2mat(app.tabla_cargas.Data(:, 2)))) / 2;
        dy = abs(max(cell2mat(app.tabla_cargas.Data(:, 3)))) + abs(min(cell2mat(app.tabla_cargas.Data(:, 3)))) / 2; 
        minX = min(cell2mat(app.tabla_cargas.Data(:, 2))) - dx ; maxX = max(cell2mat(app.tabla_cargas.Data(:, 2))) + dx;
        minY = min(cell2mat(app.tabla_cargas.Data(:, 3))) - dy ; maxY = max(cell2mat(app.tabla_cargas.Data(:, 3))) + dy;
        
        %Con los mínimos y máximos, se generan los valores que tomarán los
        %ejes para la respectiva graficación
        x = linspace(minX, maxX, N);
        y = linspace(minY, maxY, N);
        [xG, yG]= meshgrid(x, y);
        
        %Constantes
        Eo = 8.854187817e-12;
        k = 1 / (4 * pi * Eo);
        
        %------Campo eléctrico por superposición de cargas------------
        
        Ex = 0;
        Ey = 0;
        
        %Se recorren todas las cargas de la tabla (filas)
        for i = 1 : m
            Qn = cell2mat(app.tabla_cargas.Data(i, 1));
            xC = cell2mat(app.tabla_cargas.Data(i, 2));
            yC = cell2mat(app.tabla_cargas.Data(i, 3));
            Rx = xG - xC;
            Ry = yG - yC;
            R = sqrt(Rx .^ 2 + Ry .^ 2) .^3;
            Ex = Ex + k .* Qn .* Rx ./ R;
            Ey = Ey + k .* Qn .* Ry ./ R;
        end 
        
        % Se normalizan las componentes vectoriales del campo eléctrico
        % resultante para que se vea de mejor manera el gráfico
        E = sqrt(Ex .^ 2 + Ey .^ 2);
        
        %componentes x
        u = Ex ./E;
        %componentes y
        v = Ey ./E;        
        
        %-----Potencial eléctrico por superposición de cargas---------
        
        %Función que calcula el valor del voltaje a una distancia r del
        %punto de medición (Campo escalar)
        function V= funcionpotencial(q, r)
            V = k * q / r;
        end
       
        %Se inicializa la matriz que contendrá los valores del
        %potencial evaluado en los puntos
        V = zeros(length(x), length(y));
        
        %Se toman los valores de carga, posición x y posición en y del
        %cuadro con datos ingresados por el usuario
        qq = cell2mat(app.tabla_cargas.Data(:, 1));
        qx = cell2mat(app.tabla_cargas.Data(:, 2));
        qy = cell2mat(app.tabla_cargas.Data(:, 3));
       
        %Se evalúa el potencial eléctrico en cada uno de los puntos de los
        %ejes x-y y se los guarda en la matriz inicializada previamente
        
        %Se recorren los valores de x (eje)
        for ii = 1 : length(x)
            %Se recorren los valores de y (eje)
            for jj = 1 : length(y)
                %Se repite el proceso para las n cargas a evaluar
                for kk = 1 : length(qq)
                    r = sqrt((x(ii) - qx(kk)).^ 2 + (y(jj) - qy(kk)) .^ 2);
                    V(ii, jj) = V(ii, jj) + funcionpotencial(qq(kk), r); 
                end
            end
        end
        
        %----------------Generación de gráficas-----------------------
        
        figure("Name", 'Campo eléctrico | Potencial eléctrico', "WindowState","maximized")
        
        %Lineas de campo eléctrico con función streamslice
        subplot(3, 19, [1, 2, 3, 4, 5, 6, 20, 21, 22, 23, 24, 25, 39, 40, 41, 42, 43, 44])
        streamslice(xG, yG, u, v );
        title('Lineas de campo eléctrico')
        
        %Mapa de calor de potencial en 3D
        subplot(3, 19, [8, 9, 10, 11, 12, 13, 27, 28, 29, 30, 31, 32, 46, 47, 48, 49, 50, 51])
        surf(x, y, V);
        shading interp
        colormap jet
        title('Mapa de calor de potencial')
        
        %Campos equipotenciales
        subplot(3, 19, [15, 16, 17, 18, 19, 34, 35, 36, 37, 38, 53, 54, 55, 56, 57])
        contourf(V, 10);
        shading interp
        colormap jet
        title('Campos equipotenciales')
        
        end

        % Button pushed function: reset
        function resetButtonPushed(app, event)
            %Función que borra los datos de la tabla    
            app.tabla_cargas.Data = cell(app.numero_cargas.Value, 3);
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create interfaz and hide until all components are created
            app.interfaz = uifigure('Visible', 'off');
            app.interfaz.Color = [0.9294 0.9608 0.9882];
            app.interfaz.Position = [100 100 377 380];
            app.interfaz.Name = 'Electric field and Potential plotter';
            app.interfaz.Icon = 'ico.png';

            % Create tabla_cargas
            app.tabla_cargas = uitable(app.interfaz);
            app.tabla_cargas.BackgroundColor = [0.9294 0.9608 0.9882];
            app.tabla_cargas.ColumnName = {'Carga'; 'x'; 'y'};
            app.tabla_cargas.ColumnEditable = true;
            app.tabla_cargas.CellEditCallback = createCallbackFcn(app, @tabla_cargasCellEdit, true);
            app.tabla_cargas.ForegroundColor = [0.1882 0.1569 0.4902];
            app.tabla_cargas.BusyAction = 'cancel';
            app.tabla_cargas.Position = [26 73 326 196];

            % Create NmerodecargasLabel
            app.NmerodecargasLabel = uilabel(app.interfaz);
            app.NmerodecargasLabel.HorizontalAlignment = 'right';
            app.NmerodecargasLabel.FontName = 'Segoe UI';
            app.NmerodecargasLabel.FontSize = 10;
            app.NmerodecargasLabel.FontWeight = 'bold';
            app.NmerodecargasLabel.FontColor = [0.7608 0.149 0.1137];
            app.NmerodecargasLabel.Position = [30 283 91 22];
            app.NmerodecargasLabel.Text = 'Número de cargas';

            % Create numero_cargas
            app.numero_cargas = uieditfield(app.interfaz, 'numeric');
            app.numero_cargas.Limits = [1 Inf];
            app.numero_cargas.RoundFractionalValues = 'on';
            app.numero_cargas.ValueChangedFcn = createCallbackFcn(app, @numero_cargasValueChanged, true);
            app.numero_cargas.FontName = 'Segoe UI';
            app.numero_cargas.FontSize = 13;
            app.numero_cargas.FontWeight = 'bold';
            app.numero_cargas.FontColor = [0.1882 0.1569 0.4902];
            app.numero_cargas.Position = [136 283 33 22];
            app.numero_cargas.Value = 1;

            % Create Calcular
            app.Calcular = uibutton(app.interfaz, 'push');
            app.Calcular.ButtonPushedFcn = createCallbackFcn(app, @CalcularButtonPushed, true);
            app.Calcular.BackgroundColor = [0.1882 0.1569 0.4902];
            app.Calcular.FontWeight = 'bold';
            app.Calcular.FontColor = [0.9294 0.9569 0.9882];
            app.Calcular.Position = [252 20 100 23];
            app.Calcular.Text = 'Graficar';

            % Create Image
            app.Image = uiimage(app.interfaz);
            app.Image.Position = [4 310 268 68];
            app.Image.ImageSource = 'escudo-inge-03.png';

            % Create reset
            app.reset = uibutton(app.interfaz, 'push');
            app.reset.ButtonPushedFcn = createCallbackFcn(app, @resetButtonPushed, true);
            app.reset.BackgroundColor = [0.1882 0.1569 0.4902];
            app.reset.FontWeight = 'bold';
            app.reset.FontColor = [0.9294 0.9569 0.9882];
            app.reset.Position = [26 20 100 23];
            app.reset.Text = 'RESET';

            % Show the figure after all components are created
            app.interfaz.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = Electric_field

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.interfaz)

            % Execute the startup function
            runStartupFcn(app, @startupFcn)

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.interfaz)
        end
    end
end