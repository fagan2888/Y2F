function compileSolverInterfaceCode( self )
%COMPILESOLVERINTERFACECODE Compiles the MEX code generated by
%GENERATECINTERFACECODE and GENERATEMEXINTERFACECODE.
%
% This file is part of the y2f project: http://github.com/embotech/y2f, 
% a project maintained by embotech under the MIT open-source license.
%
% (c) Gian Ulli and embotech GmbH, Zurich, Switzerland, 2013-2016.

solverName = self.default_codeoptions.name;
cName = [solverName '/interface/' solverName];
mexName = [solverName '/interface/' solverName '_mex'];
outputName = ['"' solverName '"'];
    
% move the (necessary) files of all solvers to the new directory and delete
% the folders of the "internal" solvers
for i=1:self.numSolvers
    % include
    dir2move = sprintf('%s/include',self.codeoptions{i}.name);
    if( exist(dir2move,'dir') )
        copyfile(dir2move, sprintf('%s/include',solverName), 'f');
    end
    % lib
    dir2move = sprintf('%s/lib',self.codeoptions{i}.name);
    if( exist(dir2move,'dir') )
        copyfile(dir2move, sprintf('%s/lib',solverName), 'f');
    end
    % obj
    dir2move = sprintf('%s/obj',self.codeoptions{i}.name);
    if( exist(dir2move,'dir') )
        copyfile(dir2move, sprintf('%s/obj',solverName), 'f');
    end
    % src
    dir2move = sprintf('%s/src',self.codeoptions{i}.name);
    if exist(dir2move,'dir')
        copyfile(dir2move, sprintf('%s/src',solverName), 'f');
    end
    % obj_target
    dir2move = sprintf('%s/obj_target',self.codeoptions{i}.name);
    if exist(dir2move,'dir')
        copyfile(dir2move, sprintf('%s/obj_target',solverName), 'f');
    end
    % lib_target
    dir2move = sprintf('%s/lib_target',self.codeoptions{i}.name);
    if exist(dir2move,'dir')
        copyfile(dir2move, sprintf('%s/lib_target',solverName), 'f');
    end
    
    % Delete files
    rmdir(self.codeoptions{i}.name, 's');
    delete([self.codeoptions{i}.name '*']);
end

% copy the O-files of all solvers into /interface
% we'll delete them later, but this makes compilation easier
for i=1:self.numSolvers
    if( ~ispc )
        copyfile(sprintf('%s/obj/%s.o',solverName,self.codeoptions{i}.name), sprintf('%s/interface',solverName), 'f');
    end
end

% Create a list of internal solver libraries for Windows
if (ispc)
    if( exist([solverName,filesep,'lib'],'dir') )        
        libs = cell(1,self.numSolvers);
        for i=1:self.numSolvers
            lib = dir([solverName,filesep,'lib/',self.codeoptions{i}.name,'*.lib']);
            libs{i} = ['-l' lib.name(1:end-4)];
            %libs{i} = ['-l' self.codeoptions{i}.name '_static'];
        end
    end
end

% final MEX build
if exist( [cName '.c'], 'file' ) && exist( [mexName '.c'], 'file' )
    mex('-c','-g','-outdir',[solverName '/interface'],[cName '.c'])
    mex('-c','-g','-outdir',[solverName '/interface'],[mexName '.c'])
    if( ispc ) % PC - we need additional libraries
        % figure our whether we need additional libraries indeed (Intel)
        clientPath = fileparts(which('generateCode'));
        intelLibsDir = [clientPath,filesep,'libs_intel'];
        if( exist( intelLibsDir, 'dir' ) )
            intelLibsDirFlag = ['-L', intelLibsDir];
        else
            intelLibsDirFlag = '';
        end
        addpath(intelLibsDir); savepath;
        if( exist([solverName,filesep,'lib'],'dir') )
            mex([solverName '/interface/*.obj'], '-output', outputName, ...
                ['-L' solverName '/lib'], libs{:}, ...
                intelLibsDirFlag,'-llibdecimal', '-llibirc', '-llibmmt', '-lsvml_dispmt',...
                '-lIPHLPAPI.lib');
        else
            % it seems that we have been compiling with VS only,
            % so we do not add the Intel libs and use only object files
            mex([solverName, '/interface/*.obj'], [solverName '/obj/*.obj'], '-lIPHLPAPI.lib', '-output', [outputName(2:end-1),'.',mexext]);
        end
        delete([solverName '/interface/*.obj']);
    elseif( ismac )
        mex([solverName '/interface/*.o'], '-output', outputName) 
        delete([solverName '/interface/*.o']);
    else % we're on a linux system
        mex([solverName '/interface/*.o'], '-output', outputName,'-lrt') 
        delete([solverName '/interface/*.o']);
    end
else
    fprintf('Could not find source file. This file is meant to be used for building from source code.');
end

end

