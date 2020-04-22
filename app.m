classdef app < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        OCRUIFigure           matlab.ui.Figure
        LoadImageButton       matlab.ui.control.Button
        ImageNameLabel        matlab.ui.control.Label
        UIAxes                matlab.ui.control.UIAxes
        ResultsTextAreaLabel  matlab.ui.control.Label
        ResultsTextArea       matlab.ui.control.TextArea
        TopicsTextAreaLabel   matlab.ui.control.Label
        TopicsTextArea        matlab.ui.control.TextArea
    end

    properties (Access = public)
        Image % Original Image
        Iocr % Image with Bounding Boxes
    end

    methods (Access = private)
    
        function Analyze(app)
            trainedLanguage = 'train\tessdata\train.traineddata';
            ocrResults = ocr(app.Image, 'Language', trainedLanguage);
            % ocrResults = ocr(app.Image);
            
            % word = ocrResults.Words;
            app.Iocr = insertObjectAnnotation(app.Image, 'rectangle', ocrResults.WordBoundingBoxes, ocrResults.Words);
            imshow(app.Iocr, 'parent', app.UIAxes);
            drawnow;
            
            data = strrep(ocrResults.Text, newline, ' ');
            app.ResultsTextArea.Value = data;
            
            cleanedData = split(data, '.');
            cleanedData = tokenizedDocument(cleanedData);
            cleanedData = addPartOfSpeechDetails(cleanedData);
            cleanedData = removeStopWords(cleanedData);
            cleanedData = normalizeWords(cleanedData,'Style','lemma');
            cleanedData = erasePunctuation(cleanedData);
            
            bag = bagOfWords(cleanedData);
            bag = removeInfrequentWords(bag, 1);
            T = topkwords(bag);
            
            app.TopicsTextArea.Value = join(T.Word, newline);
            % app.TopicsTextArea.Value = join(string(T.Count), newline);
        end
        
    end

    % Callbacks that handle component events
    methods (Access = private)

        % Button pushed function: LoadImageButton
        function LoadImage(app, event)
            [filename, pathname] = uigetfile({'*.jpeg;*.jpg'}, 'File Selector');
            fullpathname = strcat(pathname, filename);
            app.ImageNameLabel.Text = fullpathname;
            app.Image = imread(fullpathname);
            % imshow(app.Image, 'parent', app.UIAxes);
            % drawnow;
            figure(app.OCRUIFigure)
            app.Analyze();
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create OCRUIFigure and hide until all components are created
            app.OCRUIFigure = uifigure('Visible', 'off');
            app.OCRUIFigure.Position = [100 100 640 480];
            app.OCRUIFigure.Name = 'OCR';

            % Create LoadImageButton
            app.LoadImageButton = uibutton(app.OCRUIFigure, 'push');
            app.LoadImageButton.ButtonPushedFcn = createCallbackFcn(app, @LoadImage, true);
            app.LoadImageButton.Position = [21 439 100 22];
            app.LoadImageButton.Text = 'Load Image';

            % Create ImageNameLabel
            app.ImageNameLabel = uilabel(app.OCRUIFigure);
            app.ImageNameLabel.Position = [141 439 480 22];
            app.ImageNameLabel.Text = 'Image Name';

            % Create UIAxes
            app.UIAxes = uiaxes(app.OCRUIFigure);
            title(app.UIAxes, 'Detected Words')
            app.UIAxes.Position = [21 21 360 400];

            % Create ResultsTextAreaLabel
            app.ResultsTextAreaLabel = uilabel(app.OCRUIFigure);
            app.ResultsTextAreaLabel.HorizontalAlignment = 'right';
            app.ResultsTextAreaLabel.Position = [370 397 46 22];
            app.ResultsTextAreaLabel.Text = 'Results';

            % Create ResultsTextArea
            app.ResultsTextArea = uitextarea(app.OCRUIFigure);
            app.ResultsTextArea.Position = [431 141 190 280];

            % Create TopicsTextAreaLabel
            app.TopicsTextAreaLabel = uilabel(app.OCRUIFigure);
            app.TopicsTextAreaLabel.HorizontalAlignment = 'right';
            app.TopicsTextAreaLabel.Position = [376 87 40 22];
            app.TopicsTextAreaLabel.Text = 'Topics';

            % Create TopicsTextArea
            app.TopicsTextArea = uitextarea(app.OCRUIFigure);
            app.TopicsTextArea.Position = [431 21 190 90];

            % Show the figure after all components are created
            app.OCRUIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = app

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.OCRUIFigure)

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.OCRUIFigure)
        end
    end
end