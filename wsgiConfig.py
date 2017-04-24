import sys
import os

if len(sys.argv) < 3:
    pass
else:
    projectPath =  sys.argv[1]
    projectName = sys.argv[2]

    wsgiDirPath = '{}/{}'.format(projectPath, projectName)
    wsgiFilePath = '{}/wsgi.py'.format(wsgiDirPath)
    FILE = open(wsgiFilePath,'r')
 
    newLine = []
 
    for line in FILE:
         if "sys.path.append" in line:
             newLine.append('sys.path.append(\'' +wsgiDirPath + '\')\n')
         else:
             newLine.append(line)

    FILE.close()

    # rewrite file
    FILE = open(wsgiFilePath,'w')
    for line in newLine:
        FILE.write(line)
    FILE.close()
