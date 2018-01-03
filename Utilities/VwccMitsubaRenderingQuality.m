classdef VwccMitsubaRenderingQuality < VseStyle
    % Choose overall rendering quality parameters.
    
    properties
        integratorPluginType = 'direct';
        integratorProperties;
        
        samplerPluginType = 'ldsampler';
        samplerProperties;
    end
    
    methods
        function obj = VwccMitsubaRenderingQuality(varargin)
            obj.elementTypeFilter = 'none';
            obj.elementNameFilter = 'none';
            obj.destination = 'Mitsuba';
            
            parser = MipInputParser();
            parser.addProperties(obj);
            parser.parseMagically(obj);
        end
        
        function addIntegratorProperty(obj, name, type, value)
            property = struct( ...
                'name', name, ...
                'type', type, ...
                'value', value);
            if isempty(obj.integratorProperties)
                obj.integratorProperties = property;
            else
                obj.integratorProperties(end+1) = property;
            end
        end
        
        function addSamplerProperty(obj, name, type, value)
            property = struct( ...
                'name', name, ...
                'type', type, ...
                'value', value);
            if isempty(obj.samplerProperties)
                obj.samplerProperties = property;
            else
                obj.samplerProperties(end+1) = property;
            end
        end
        
        function scene = applyToWholeScene(obj, scene, hints)
            integrator = scene.find('', 'type', 'integrator');
            integrator.pluginType = obj.integratorPluginType;
            integrator.nested = {};
            for pp = 1:numel(obj.integratorProperties)
                p = obj.integratorProperties(pp);
                integrator.setProperty(p.name, p.type, p.value);
            end
            
            sampler = scene.find('', 'type', 'sampler');
            sampler.pluginType = obj.samplerPluginType;
            sampler.nested = {};
            for pp = 1:numel(obj.samplerProperties)
                p = obj.samplerProperties(pp);
                sampler.setProperty(p.name, p.type, p.value);
            end
        end
    end
end
